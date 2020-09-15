//
//  UserDefaultsPasscodeRepository.swift
//  PasscodeLock
//
//  Created by Yanko Dimitrov on 8/29/15.
//  Copyright © 2015 Yanko Dimitrov. All rights reserved.
//

import Foundation
import PasscodeLock

public enum PasscodeError: Error {
    case noPasscode
}

class UserDefaultsPasscodeRepository: PasscodeRepositoryType {
    
    
    private let passcodeKey = "passcode.lock.passcode"

    private lazy var defaults: UserDefaults = {
        UserDefaults.standard
    }()

    var hasPasscode: Bool {
        if passcode != nil {
            return true
        }

        return false
    }

    private var passcode: String? {
        return defaults.value(forKey: passcodeKey) as? String ?? nil
    }

    func save(passcode: String, completion: @escaping (_ isSucceed: Bool)->Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {[weak self] in
            guard let self = self else {return}
            self.defaults.set(passcode, forKey: self.passcodeKey)
            self.defaults.synchronize()
            completion(true)
        }
        
    }

    func check(passcode: String, completion: @escaping(_ isVerify: Bool)->Void){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            completion(self.passcode == passcode)
        }
    }

    func delete(completion: @escaping (_ isSucceed: Bool)->Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {[weak self] in
            guard let self = self else {return}
            self.defaults.removeObject(forKey: self.passcodeKey)
            self.defaults.synchronize()
            completion(true)
        }
    }
}
