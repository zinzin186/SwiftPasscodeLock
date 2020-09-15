//
//  RemovePasscodeState.swift
//  PasscodeLock
//
//  Created by Kevin Seidel on 06/10/16.
//  Copyright © 2016 Yanko Dimitrov. All rights reserved.
//

import Foundation

struct RemovePasscodeState: PasscodeLockStateType {
    let title: String
    let description: String
    let isCancellableAction = false
    var isTouchIDAllowed: Bool { return false }

    init() {
        title = "Nhập mã PIN để tiếp tục"
        description = ""
    }

    mutating func accept(passcode: String, from lock: PasscodeLockType) {
        lock.repository.delete { (isSucceed) in
            if isSucceed{
                lock.delegate?.passcodeLockDidSucceed(lock)
                lock.configuration.setIncorrectPasscodeAttempts(0)
            }else{
                let oldValue = lock.configuration.getIncorrectPasscodeAttempts()
                lock.configuration.setIncorrectPasscodeAttempts(oldValue + 1)

                if lock.configuration.getIncorrectPasscodeAttempts() >= lock.configuration.maximumIncorrectPasscodeAttempts {
                    NotificationCenter.default.post(name: PasscodeLockIncorrectPasscodeNotification, object: nil)
                    lock.configuration.setIncorrectPasscodeAttempts(0)
                }

                lock.delegate?.passcodeLockDidFail(lock)
            }
        }
    }

    private mutating func postNotification() {
        NotificationCenter.default.post(name: PasscodeLockIncorrectPasscodeNotification, object: nil)
    }
}
