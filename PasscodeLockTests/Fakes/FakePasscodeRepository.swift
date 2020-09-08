//
//  FakePasscodeRepository.swift
//  PasscodeLock
//
//  Created by Yanko Dimitrov on 8/28/15.
//  Copyright © 2015 Yanko Dimitrov. All rights reserved.
//

import Foundation

class FakePasscodeRepository: PasscodeRepositoryType {
    
    var hasPasscode: Bool { return true }
    private var passcode: String? { return fakePasscode }
    
    var fakePasscode = "1234" //["1", "2", "3", "4"]
    
    var savePasscodeCalled = false
    var savedPasscode = String()
    
    func save(passcode: String) {
        
        savePasscodeCalled = true
        savedPasscode = passcode
    }
    
    func delete() {
        
    }
    
    func check(passcode: String) -> Bool {
        return passcode == fakePasscode
    }
}
