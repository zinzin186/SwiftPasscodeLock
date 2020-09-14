//
//  ChangePasscodeState.swift
//  PasscodeLock
//
//  Created by Yanko Dimitrov on 8/28/15.
//  Copyright © 2015 Yanko Dimitrov. All rights reserved.
//

import Foundation

struct ChangePasscodeState: PasscodeLockStateType {
    
    let title: String
    let description: String
    let isCancellableAction = true
    var isTouchIDAllowed = false
    
    init() {
        
        title = "Nhập mã PIN cũ"
        description = ""
    }
    
    func accept(passcode: String, from lock: PasscodeLockType) {
        lock.repository.check(passcode: passcode) { (isVerify) in
            if isVerify{
                lock.changeState(SetNewPasscodeState())
            }else{
                if lock.configuration.getIncorrectPasscodeAttempts() >= lock.configuration.maximumIncorrectPasscodeAttempts {
                    NotificationCenter.default.post(name: PasscodeLockIncorrectPasscodeNotification, object: nil)
                    lock.configuration.setIncorrectPasscodeAttempts(0)
                }

                lock.delegate?.passcodeLockDidFail(lock)
            }
        }
        
//        if lock.repository.check(passcode: passcode) {
//
//            lock.changeState(SetNewPasscodeState())
//
//        } else {
//
//            lock.delegate?.passcodeLockDidFail(lock)
//        }
    }
}
