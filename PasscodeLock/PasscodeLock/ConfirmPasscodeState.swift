//
//  ConfirmPasscodeState.swift
//  PasscodeLock
//
//  Created by Yanko Dimitrov on 8/28/15.
//  Copyright © 2015 Yanko Dimitrov. All rights reserved.
//

import Foundation

struct ConfirmPasscodeState: PasscodeLockStateType {
    
    let title: String
    let description: String
    let isCancellableAction = true
    var isTouchIDAllowed = false
    
    private var passcodeToConfirm: String
    
    init(passcode: String) {
        
        passcodeToConfirm = passcode
        title = "Nhập lại mã PIN để xác nhận"
        description = ""
    }
    
    func accept(passcode: String, from lock: PasscodeLockType) {
        
        if passcode == passcodeToConfirm {
            lock.repository.save(passcode: passcode) { (isSucceed) in
                if isSucceed{
                    lock.delegate?.passcodeLockDidSucceed(lock)
                }
            }
//            lock.repository.save(passcode: passcode)
            
        
        } else {
            lock.delegate?.passcodeLockDidFail(lock)
        }
    }
}

struct ConfirmNewPasscodeState: PasscodeLockStateType {
    
    let title: String
    let description: String
    let isCancellableAction = true
    var isTouchIDAllowed = false
    
    private var passcodeToConfirm: String
    
    init(passcode: String) {
        
        passcodeToConfirm = passcode
        title = "Xác nhận mã PIN"
        description = ""
    }
    
    func accept(passcode: String, from lock: PasscodeLockType) {
        
        if passcode == passcodeToConfirm {
            lock.repository.save(passcode: passcode) { (isSucceed) in
                if isSucceed{
                    lock.delegate?.passcodeLockDidSucceed(lock)
                }
            }
//            lock.repository.save(passcode: passcode)
//            lock.delegate?.passcodeLockDidSucceed(lock)
        
        } else {
            lock.delegate?.passcodeLockDidFail(lock)
        }
    }
}
