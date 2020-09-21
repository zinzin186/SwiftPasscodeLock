//
//  PasscodeLockViewController.swift
//  PasscodeLock
//
//  Created by Yanko Dimitrov on 8/28/15.
//  Copyright © 2015 Yanko Dimitrov. All rights reserved.
//

import UIKit
public enum LockState {
    case enter
    case set
    case change
    case remove

    func getState() -> PasscodeLockStateType {
        switch self {
            case .enter: return EnterPasscodeState()
            case .set: return SetPasscodeState()
            case .change: return ChangePasscodeState()
            case .remove: return RemovePasscodeState()
        }
    }
}
public typealias ResultVerifyPasscode = (PasscodeLockStateType) -> (Bool)
open class PasscodeLockViewController: UIViewController, PasscodeLockTypeDelegate {
        
    private static var nibName: String { return "PasscodeLockView" }

    open class var nibBundle: Bundle {
        return bundleForResource(name: nibName, ofType: "nib")
    }

    
    
    
    @IBOutlet weak var lockImageView: UIImageView!
    @IBOutlet open var placeholders: [PasscodeSignPlaceholderView] = [PasscodeSignPlaceholderView]()
    @IBOutlet open weak var titleLabel: UILabel?
    @IBOutlet open weak var descriptionLabel: UILabel?
    @IBOutlet open weak var cancelButton: UIButton?
    @IBOutlet open weak var placeholdersX: NSLayoutConstraint?
    @IBOutlet weak var forgotCodeButton: UIButton!
    
    @IBOutlet weak var topConstraintOfTitleLabel: NSLayoutConstraint!
    //    open var successCallback: ((_ lock: PasscodeLockType) -> Void)?
    open var forgotPasscodeCallback: (() -> Void)?
    open var enterPasscodeCallback: ((_ passcode: String, _ isEnableEnterPIN: Bool) -> Void)?
    open var enterFullPasscodeCallback: ((_ passcode: String) -> Void)?
    open var dismissCompletionCallback: (() -> Void)?
    open var animateOnDismiss: Bool
    open var notificationCenter: NotificationCenter?

    internal let passcodeConfiguration: PasscodeLockConfigurationType
    internal var passcodeLock: PasscodeLock
    internal var isPlaceholdersAnimationCompleted = true

    private var shouldTryToAuthenticateWithBiometrics = true
    private var stage: LockState = .set
    private let timeToEnableEnterPIN: Int = 20
    private var timeCountDownEnterPIN: Int = 20
    private var remainCountdown = 0
    private var timer: RepeatingTimer?
    private var isEnableEnterPIN: Bool = true
    private var passcodeLockStateType: PasscodeLockStateType
    private var maximumIncorrectPasscodeAttempts: Int = 3
    // MARK: - Initializers

    public init(state: PasscodeLockStateType, configuration: PasscodeLockConfigurationType, animateOnDismiss: Bool = true) {
        self.passcodeLockStateType = state
        self.animateOnDismiss = animateOnDismiss
        passcodeConfiguration = configuration
        self.maximumIncorrectPasscodeAttempts = configuration.maximumIncorrectPasscodeAttempts
        passcodeLock = PasscodeLock(state: state, configuration: configuration)
        let this = type(of: self)
        super.init(nibName: this.nibName, bundle: this.nibBundle)

        passcodeLock.delegate = self
        notificationCenter = NotificationCenter.default
    }

    public convenience init(state: LockState, configuration: PasscodeLockConfigurationType, animateOnDismiss: Bool = true) {
        self.init(state: state.getState(), configuration: configuration, animateOnDismiss: animateOnDismiss)
        self.stage = state
    }

    public required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    open override var preferredStatusBarStyle: UIStatusBarStyle{
        return .lightContent
    }

    deinit {
        resetTimer()
        clearEvents()
    }

    // MARK: - View

    open override func viewDidLoad() {
        super.viewDidLoad()
        updatePasscodeView()
        setupEvents()
        checkContinueCountdown()
        if stage == .enter{
            forgotCodeButton.isHidden = false
        }else{
            forgotCodeButton.isHidden = true
        }
        if UIScreen.main.bounds.height <= 667{
            self.topConstraintOfTitleLabel.constant = 60
            self.lockImageView.isHidden = true
        }
    }

    
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if shouldTryToAuthenticateWithBiometrics {
            authenticateWithTouchID()
        }
    }

    
    internal func updatePasscodeView() {
        titleLabel?.text = passcodeLock.state.title
        descriptionLabel?.text = passcodeLock.state.description
        self.descriptionLabel?.isHidden = true
    }

    // MARK: - Events

    private func setupEvents() {
        notificationCenter?.addObserver(self, selector: #selector(PasscodeLockViewController.appWillEnterForegroundHandler(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
        notificationCenter?.addObserver(self, selector: #selector(PasscodeLockViewController.appDidEnterBackgroundHandler(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
        notificationCenter?.addObserver(self, selector: #selector(showCoundownWhenOverMaxIncorrect), name: PasscodeLockIncorrectPasscodeNotification, object: nil)
    }

    private func clearEvents() {
        notificationCenter?.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        notificationCenter?.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        notificationCenter?.removeObserver(self, name: PasscodeLockIncorrectPasscodeNotification, object: nil)
    }

    @objc open func appWillEnterForegroundHandler(_ notification: Notification) {
        authenticateWithTouchID()
    }

    @objc open func appDidEnterBackgroundHandler(_ notification: Notification) {
        shouldTryToAuthenticateWithBiometrics = false
    }

    // MARK: - Actions

    @IBAction func passcodeSignButtonTap(_ sender: PasscodeSignButton) {
        guard isPlaceholdersAnimationCompleted else { return }
        if let enterPasscodeCallback = self.enterPasscodeCallback{
            enterPasscodeCallback(sender.passcodeSign, isEnableEnterPIN)
        }
        guard isEnableEnterPIN else {
            print("DisableEnterPIN")
            return
        }
        passcodeLock.addSign(sender.passcodeSign)
    }

    @IBAction func cancelButtonTap(_ sender: UIButton) {
        if sender.isSelected{
            dismissPasscodeLock(passcodeLock)
        }else{
            passcodeLock.removeSign()
        }
    }

    @IBAction func getPassCode(_ sender: Any) {
        if let forgotPasscodeCallback = self.forgotPasscodeCallback{
            forgotPasscodeCallback()
        }
    }
    private func authenticateWithTouchID() {
        if passcodeConfiguration.shouldRequestTouchIDImmediately && passcodeLock.isTouchIDAllowed {
            passcodeLock.authenticateWithTouchID()
        }
    }

    internal func dismissPasscodeLock(_ lock: PasscodeLockType, completionHandler: (() -> Void)? = nil) {
        // if presented as modal
        if presentingViewController?.presentedViewController == self {
            dismiss(animated: animateOnDismiss) { [weak self] in
                self?.dismissCompletionCallback?()
                completionHandler?()
            }
        } else {
            // if pushed in a navigation controller
            _ = navigationController?.popViewController(animated: animateOnDismiss)
            dismissCompletionCallback?()
            completionHandler?()
        }
    }

    // MARK: - Animations

    internal func animateWrongPassword() {
        cancelButton?.isSelected = true
        isPlaceholdersAnimationCompleted = false

        animatePlaceholders(placeholders, toState: .error)

        placeholdersX?.constant = -40
        view.layoutIfNeeded()

        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 0.2,
            initialSpringVelocity: 0,
            options: [],
            animations: {
                self.placeholdersX?.constant = 0
                self.view.layoutIfNeeded()
            },
            completion: { completed in
                self.isPlaceholdersAnimationCompleted = true
                self.animatePlaceholders(self.placeholders, toState: .inactive)
            }
        )
    }

    internal func animatePlaceholders(_ placeholders: [PasscodeSignPlaceholderView], toState state: PasscodeSignPlaceholderView.State) {
        placeholders.forEach { $0.animateState(state) }
    }

    private func animatePlacehodlerAtIndex(_ index: Int, toState state: PasscodeSignPlaceholderView.State) {
        guard index < placeholders.count && index >= 0 else { return }

        placeholders[index].animateState(state)
    }

    // MARK: - PasscodeLockDelegate

    open func passcodeLockConfirmDidSucceed(_ lock: PasscodeLockType, passcode: String) {
        cancelButton?.isSelected = false
        animatePlaceholders(placeholders, toState: .inactive)
//        dismissPasscodeLock(lock) { [weak self] in
//            self?.enterFullPasscodeCallback?(passcode)
//        }
        self.enterFullPasscodeCallback?(passcode)
    }

    open func passcodeLockConfirmDidFail(_ lock: PasscodeLockType) {
        self.titleLabel?.text = "Mã PIN không đúng"
        animateWrongPassword()
    }

    @objc private func showCoundownWhenOverMaxIncorrect(){
        saveCountdown()
        startCountDownToEnableUnlock()
    }
    private func startCountDownToEnableUnlock(){
        self.descriptionLabel?.isHidden = false
        startTimer()
        
    }
    public func resetTimer() {
        self.timeCountDownEnterPIN = (remainCountdown > 0) ? remainCountdown : timeToEnableEnterPIN
        remainCountdown = 0
        
        timer?.clear()
        if timer != nil {
            timer = nil
        }
    }
    private func startTimer() {
        resetTimer()
        self.updateUIWhenCoundown(seconds: self.timeCountDownEnterPIN)
        self.isEnableEnterPIN = false
        timer = RepeatingTimer(timeInterval: 1)
        timer?.eventHandler = {[weak self] in
            guard let self = self else {return}
            if self.timeCountDownEnterPIN > 0 {
                self.timeCountDownEnterPIN -= 1
            } else {
                self.resetTimer()
                self.timeCountDownEnterPIN = 0
                self.maximumIncorrectPasscodeAttempts = self.passcodeConfiguration.maximumIncorrectPasscodeAttempts
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.updateUIWhenCoundown(seconds: self?.timeCountDownEnterPIN ?? 0)
            }
        }
        timer?.resume()
    }
    func updateUIWhenCoundown(seconds: Int){
        self.descriptionLabel?.text = "Thử lại sau \(seconds) giây"
        
        if seconds == 0 {
            self.allowEnterPIN()
        }
    }
    private func allowEnterPIN(){
        self.descriptionLabel?.text = ""
        self.descriptionLabel?.isHidden = true
        self.isEnableEnterPIN = true
    }
    open func passcodeLockDidChangeState(_ lock: PasscodeLockType, state: PasscodeLockStateType) {
        self.passcodeLockStateType = state
        updatePasscodeView()
        animatePlaceholders(placeholders, toState: .inactive)
        cancelButton?.isSelected = true
    }

    open func passcodeLock(_ lock: PasscodeLockType, addedSignAt index: Int) {
        animatePlacehodlerAtIndex(index, toState: .active)
        cancelButton?.isSelected = false
        
        
    }
    var currentPass: String?
    open func passcodeLock(_ lock: PasscodeLockType, fillPasscode passcode: String, lockState: PasscodeLockStateType) {
        cancelButton?.isSelected = true
        if stage == .set{
            if currentPass == passcode{
                animateWrongPassword()
                let alert = UIAlertController(title: nil, message: "Mã PIN mới không được trùng với mã PIN cũ", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {[weak self] (_) in
                    self?.passcodeLock.changeState(SetNewPasscodeState())
                }))
                self.present(alert, animated: true, completion: nil)
            }else{
                passcodeLockStateType.accept(passcode: passcode, from: lock)
            }
            
        }else{
            if stage == .change{
                currentPass = passcode
            }
            if let callback = enterFullPasscodeCallback{
                callback(passcode)
            }
        }
    }

    open func updateVerifyResult(isVerify: Bool, message: String, state: LockState){
        self.titleLabel?.text = message
        if isVerify{
            if state == .change{
                self.stage = .set
                passcodeLock.changeState(SetNewPasscodeState())
            }
        }else{
            self.maximumIncorrectPasscodeAttempts -= 1
            if self.maximumIncorrectPasscodeAttempts == 0{
                showCoundownWhenOverMaxIncorrect()
            }
            animateWrongPassword()
        }
        
        
    }
    open func passcodeLock(_ lock: PasscodeLockType, removedSignAt index: Int) {
        animatePlacehodlerAtIndex(index, toState: .inactive)

        if index == 0 {
            cancelButton?.isSelected = true
        }
    }
}
extension PasscodeLockViewController{
    public func checkContinueCountdown() {
        let countdown = remainCountdownTime()
        if countdown > 0 {
            remainCountdown = countdown
            self.startCountDownToEnableUnlock()
        }
    }
    public func remainCountdownTime() -> Int {
        guard let timeInterval = UserDefaults.standard.value(forKey: "TIME_COUNT_DOWN") as? Int else  {return 0}
        let lastTime = TimeInterval(timeInterval)
        let spaceTime = timeToEnableEnterPIN - Int((Date().timeIntervalSince1970 - lastTime))
        return spaceTime
    }
    public func saveCountdown() {
        let timeInterval = Date().timeIntervalSince1970
        UserDefaults.standard.set(Int(timeInterval), forKey: "TIME_COUNT_DOWN")
        UserDefaults.standard.synchronize()
    }
    
}
