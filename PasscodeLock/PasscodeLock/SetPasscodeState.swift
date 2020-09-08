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
        
        title = "Nhập mã PIN cho trò chuyện bí mật"
        description = "Ghi nhớ mã PIN để xem lại trò chuyện. Trò chuyện sẽ mất nếu bạn quên mã PIN"
    }
    
    func accept(passcode: String, from lock: PasscodeLockType) {
        
        lock.changeState(ConfirmPasscodeState(passcode: passcode))

    }
}
