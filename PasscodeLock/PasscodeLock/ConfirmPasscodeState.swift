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
        title = LocalizedPasscodeManager.shared.localizedDataSource?.getLocallizeText(key: "chat.passcode_create_retype_pass") ?? "Nhập lại mã PIN để xác nhận"
        description = ""
    }
    
    func accept(passcode: String, from lock: PasscodeLockType) {
        if passcode == passcodeToConfirm {
            lock.delegate?.passcodeLockConfirmDidSucceed(lock, passcode: passcode)
        } else {
            lock.delegate?.passcodeLockConfirmDidFail(lock)
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
            lock.delegate?.passcodeLockConfirmDidSucceed(lock, passcode: passcode)
        } else {
            lock.delegate?.passcodeLockConfirmDidFail(lock)
        }
    }
}
