//
//  ChangePasscodeState.swift
//  PasscodeLock
//
//  Created by Yanko Dimitrov on 8/28/15.
//  Copyright © 2015 Yanko Dimitrov. All rights reserved.
//

import Foundation

public protocol LocalizedDataSource: class {
    func getLocallizeText(key: String) -> String
    func getLocallizeText(key: String, with pluralizedManyValue: Int) -> String
}

public class LocalizedPasscodeManager: NSObject {
    public weak var localizedDataSource: LocalizedDataSource?
    public static let shared = LocalizedPasscodeManager()
     
}

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

                lock.delegate?.passcodeLockConfirmDidFail(lock)
            }
        }
    }
}
