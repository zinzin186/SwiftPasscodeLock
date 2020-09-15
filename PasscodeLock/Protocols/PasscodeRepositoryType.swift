//
//  PasscodeRepositoryType.swift
//  PasscodeLock
//
//  Created by Yanko Dimitrov on 8/28/15.
//  Copyright © 2015 Yanko Dimitrov. All rights reserved.
//

import Foundation

public protocol PasscodeRepositoryType {
    
    var hasPasscode: Bool { get }
    
//    func save(passcode: String)
//    func check(passcode: String) -> Bool
    func check(passcode: String, completion: @escaping(_ isVerify: Bool)->Void)
    func save(passcode: String, completion: @escaping(_ isSucceed: Bool)->Void)
    func delete(completion: @escaping(_ isSucceed: Bool)->Void)
}
