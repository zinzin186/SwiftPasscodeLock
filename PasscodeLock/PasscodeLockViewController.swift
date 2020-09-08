//
//  PasscodeLockViewController.swift
//  PasscodeLock
//
//  Created by Yanko Dimitrov on 8/28/15.
//  Copyright © 2015 Yanko Dimitrov. All rights reserved.
//

import UIKit

open class PasscodeLockViewController: UIViewController, PasscodeLockTypeDelegate {
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

    private static var nibName: String { return "PasscodeLockView" }

    open class var nibBundle: Bundle {
        return bundleForResource(name: nibName, ofType: "nib")
    }

    @IBOutlet open var placeholders: [PasscodeSignPlaceholderView] = [PasscodeSignPlaceholderView]()
    @IBOutlet open weak var titleLabel: UILabel?
    @IBOutlet open weak var descriptionLabel: UILabel?
    @IBOutlet open weak var cancelButton: UIButton?
    @IBOutlet open weak var deleteSignButton: UIButton?
    @IBOutlet open weak var placeholdersX: NSLayoutConstraint?
    @IBOutlet weak var forgotCodeButton: UIButton!
    
    open var successCallback: ((_ lock: PasscodeLockType) -> Void)?
    open var dismissCompletionCallback: (() -> Void)?
    open var animateOnDismiss: Bool
    open var notificationCenter: NotificationCenter?

    internal let passcodeConfiguration: PasscodeLockConfigurationType
    internal var passcodeLock: PasscodeLockType
    internal var isPlaceholdersAnimationCompleted = true

    private var shouldTryToAuthenticateWithBiometrics = true
    private var stage: LockState = .set
    private var maxNumberEnterWrong: Int = 5
    private let timeToEnableEnterPIN: Int = 20
    private var timeCountDownEnterPIN: Int = 20
    private var remainCountdown = 0
    private var timer: RepeatingTimer?
    private var isEnableEnterPIN: Bool = true
    // MARK: - Initializers

    public init(state: PasscodeLockStateType, configuration: PasscodeLockConfigurationType, animateOnDismiss: Bool = true) {
        self.animateOnDismiss = animateOnDismiss
        passcodeConfiguration = configuration
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

    deinit {
        clearEvents()
    }

    // MARK: - View

    open override func viewDidLoad() {
        super.viewDidLoad()
        updatePasscodeView()
        deleteSignButton?.isEnabled = false
        setupEvents()
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
        
//        cancelButton?.isHidden = !passcodeLock.state.isCancellableAction
    }

    // MARK: - Events

    private func setupEvents() {
        notificationCenter?.addObserver(self, selector: #selector(PasscodeLockViewController.appWillEnterForegroundHandler(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
        notificationCenter?.addObserver(self, selector: #selector(PasscodeLockViewController.appDidEnterBackgroundHandler(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    private func clearEvents() {
        notificationCenter?.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        notificationCenter?.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
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
        guard isEnableEnterPIN else {
            print("Counting time")
            return
        }
        passcodeLock.addSign(sender.passcodeSign)
    }

    @IBAction func cancelButtonTap(_ sender: UIButton) {
        dismissPasscodeLock(passcodeLock)
    }

    @IBAction func deleteSignButtonTap(_ sender: UIButton) {
        passcodeLock.removeSign()
    }

    @IBAction func getPassCode(_ sender: Any) {
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
        deleteSignButton?.isEnabled = false
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

    open func passcodeLockDidSucceed(_ lock: PasscodeLockType) {
        deleteSignButton?.isEnabled = true
        animatePlaceholders(placeholders, toState: .inactive)
        if self.stage == LockState.enter{
            maxNumberEnterWrong = 5
        }
        dismissPasscodeLock(lock) { [weak self] in
            self?.successCallback?(lock)
        }
    }

    open func passcodeLockDidFail(_ lock: PasscodeLockType) {
        animateWrongPassword()
        if self.stage == LockState.enter{
            maxNumberEnterWrong -= 1
            if maxNumberEnterWrong <= 0{
                //Qua 5 lan cho phep nhap ma PIN sai
                //Thu lai sau 20 giay
                self.startCountDownToEnableUnlock()
            }
        }
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
        self.isEnableEnterPIN = false
        timer = RepeatingTimer(timeInterval: 1)
        timer?.eventHandler = {
            
            if self.timeCountDownEnterPIN > 0 {
                self.timeCountDownEnterPIN -= 1
            } else {
                self.resetTimer()
                self.timeCountDownEnterPIN = 0
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
    open func passcodeLockDidChangeState(_ lock: PasscodeLockType) {
        updatePasscodeView()
        animatePlaceholders(placeholders, toState: .inactive)
        deleteSignButton?.isEnabled = false
    }

    open func passcodeLock(_ lock: PasscodeLockType, addedSignAt index: Int) {
        animatePlacehodlerAtIndex(index, toState: .active)
        deleteSignButton?.isEnabled = true
    }

    open func passcodeLock(_ lock: PasscodeLockType, removedSignAt index: Int) {
        animatePlacehodlerAtIndex(index, toState: .inactive)

        if index == 0 {
            deleteSignButton?.isEnabled = false
        }
    }
}
