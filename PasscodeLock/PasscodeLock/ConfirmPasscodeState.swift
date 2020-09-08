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
        description = "Nhập lại mã PIN của bạn"
    }
    
    func accept(passcode: String, from lock: PasscodeLockType) {
        
        if passcode == passcodeToConfirm {
            
            lock.repository.save(passcode: passcode)
            lock.delegate?.passcodeLockDidSucceed(lock)
        
        } else {
            let mismatchTitle = "Mã PIN không đúng"
            let mismatchDescription = "Thử lại sau 20 giây"
            
            lock.changeState(SetPasscodeState(title: mismatchTitle, description: mismatchDescription))
            
            lock.delegate?.passcodeLockDidFail(lock)
        }
    }
}
