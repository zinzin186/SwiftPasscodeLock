//
//  PasscodeSignButton.swift
//  PasscodeLock
//
//  Created by Yanko Dimitrov on 8/28/15.
//  Copyright © 2015 Yanko Dimitrov. All rights reserved.
//

import UIKit

@IBDesignable
open class PasscodeSignButton: UIButton {
    @IBInspectable
    open var passcodeSign: String = "1"

    @IBInspectable
    open var borderColor: UIColor = .white {
        didSet {
            setupView()
        }
    }

    @IBInspectable
    open var borderRadius: CGFloat = 38.5 {
        didSet {
            setupView()
        }
    }

    @IBInspectable
    open var highlightBackgroundColor: UIColor = .clear {
        didSet {
            setupView()
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)

        setupView()
        setupActions()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setupActions()
    }

    open override var intrinsicContentSize: CGSize {
        return CGSize(width: 75, height: 75)
    }

    private var defaultBackgroundColor: UIColor = UIColor.init(red: 1, green: 1, blue: 1, alpha: 0.2)

    private func setupView() {
        layer.borderWidth = 0
        layer.cornerRadius = borderRadius
        layer.borderColor = borderColor.cgColor
        self.setTitleColor(UIColor.white, for: .normal)
        self.backgroundColor = defaultBackgroundColor
        self.titleLabel?.font = UIFont.systemFont(ofSize: 36)
    }

    private func setupActions() {
        addTarget(self, action: #selector(PasscodeSignButton.handleTouchDown), for: .touchDown)
        addTarget(self, action: #selector(PasscodeSignButton.handleTouchUp), for: [.touchUpInside, .touchDragOutside, .touchCancel])
    }

    @objc func handleTouchDown() {
        animateBackgroundColor(highlightBackgroundColor)
    }

    @objc func handleTouchUp() {
        animateBackgroundColor(defaultBackgroundColor)
    }

    private func animateBackgroundColor(_ color: UIColor) {
        UIView.animate(
            withDuration: 0.3,
            delay: 0.0,
            usingSpringWithDamping: 1,
            initialSpringVelocity: 0.0,
            options: [.allowUserInteraction, .beginFromCurrentState],
            animations: {
                self.backgroundColor = color
            },
            completion: nil
        )
    }
}
