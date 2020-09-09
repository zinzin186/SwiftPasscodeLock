//
//  SetPasscodeState.swift
//  PasscodeLock
//
//  Created by Yanko Dimitrov on 8/28/15.
//  Copyright © 2015 Yanko Dimitrov. All rights reserved.
//

import Foundation

struct SetPasscodeState: PasscodeLockStateType {
    
    let title: String
    let description: String
    let isCancellableAction = true
    var isTouchIDAllowed = false
    
    init(title: String, description: String) {
        
        self.title = title
        self.description = description
    }
    
    init() {
        
        title = "Tạo mã PIN cho\nTrò chuyện bí mật"
        description = ""
    }
    
    func accept(passcode: String, from lock: PasscodeLockType) {
//        if lock.repository.check(passcode: passcode) {
//            lock.delegate?.passcodeLockDidSucceed(lock)
//            lock.configuration.setIncorrectPasscodeAttempts(0)
//        }
        lock.changeState(ConfirmPasscodeState(passcode: passcode))

    }
}
struct SetNewPasscodeState: PasscodeLockStateType {
    
    let title: String
    let description: String
    let isCancellableAction = true
    var isTouchIDAllowed = false
    
    init(title: String, description: String) {
        
        self.title = title
        self.description = description
    }
    
    init() {
        
        title = "Nhập mã PIN mới"
        description = ""
    }
    
    func accept(passcode: String, from lock: PasscodeLockType) {
        
        lock.changeState(ConfirmNewPasscodeState(passcode: passcode))

    }
}
