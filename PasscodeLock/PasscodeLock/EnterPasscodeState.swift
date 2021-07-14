//
//  EnterPasscodeState.swift
//  PasscodeLock
//
//  Created by Yanko Dimitrov on 8/28/15.
//  Copyright © 2015 Yanko Dimitrov. All rights reserved.
//

import Foundation

public let PasscodeLockIncorrectPasscodeNotification = Notification.Name("passcode.lock.incorrect.passcode.notification")

struct EnterPasscodeState: PasscodeLockStateType {
    let title: String
    let description: String
    let isCancellableAction: Bool
    var isTouchIDAllowed = true

    init(allowCancellation: Bool = false) {
        isCancellableAction = allowCancellation
        title = LocalizedPasscodeManager.shared.localizedDataSource?.getLocallizeText(key: "chat.passcode_enter_pass") ?? "Nhập mã PIN để tiếp tục"
        description = ""
    }

    mutating func accept(passcode: String, from lock: PasscodeLockType) {
        lock.repository.check(passcode: passcode) { (isVerify) in
            if isVerify{
                lock.delegate?.passcodeLockConfirmDidSucceed(lock, passcode: passcode)
                lock.configuration.setIncorrectPasscodeAttempts(0)
            }else{
                let oldValue = lock.configuration.getIncorrectPasscodeAttempts()
                lock.configuration.setIncorrectPasscodeAttempts(oldValue + 1)

                if lock.configuration.getIncorrectPasscodeAttempts() >= lock.configuration.maximumIncorrectPasscodeAttempts {
                    NotificationCenter.default.post(name: PasscodeLockIncorrectPasscodeNotification, object: nil)
                    lock.configuration.setIncorrectPasscodeAttempts(0)
                }

                lock.delegate?.passcodeLockConfirmDidFail(lock)
            }
        }
    }

    private mutating func postNotification() {
        NotificationCenter.default.post(name: PasscodeLockIncorrectPasscodeNotification, object: nil)
    }
}
