//
//  EnterPasscodeStateTests.swift
//  PasscodeLock
//
//  Created by Yanko Dimitrov on 8/28/15.
//  Copyright © 2015 Yanko Dimitrov. All rights reserved.
//

import XCTest

class NotificaionObserver: NSObject {
    
    var called = false
    var callCounter = 0
    
    func observe(notification: Notification.Name) {
        
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(self.handle), name: notification, object: nil)
    }
    
    @objc func handle(notification: Notification) {
        
        called = true
        callCounter += 1
    }
}

class EnterPasscodeStateTests: XCTestCase {
    
    var passcodeLock: FakePasscodeLock!
    var passcodeState: EnterPasscodeState!
    var repository: FakePasscodeRepository!
    
    override func setUp() {
        super.setUp()
        
        repository = FakePasscodeRepository()
        
        let config = FakePasscodeLockConfiguration(repository: repository)
        
        passcodeState = EnterPasscodeState()
        passcodeLock = FakePasscodeLock(state: passcodeState, configuration: config)
    }
    
    func testAcceptCorrectPasscode() {
        
        class MockDelegate: FakePasscodeLockDelegate {
            
            var called = false
            
            override func passcodeLockDidSucceed(_ lock: PasscodeLockType) {
                
                called = true
            }
        }
        
        let delegate = MockDelegate()
        
        passcodeLock.delegate = delegate
        passcodeState.accept(passcode: repository.fakePasscode, from: passcodeLock)
        
        XCTAssertEqual(delegate.called, true, "Should call the delegate when the passcode is correct")
    }
    
    func testAcceptIncorrectPasscode() {
        
        class MockDelegate: FakePasscodeLockDelegate {
            
            var called = false
            
            override func passcodeLockDidFail(_ lock: PasscodeLockType) {
                
                called = true
            }
        }
        
        let delegate = MockDelegate()
        
        passcodeLock.delegate = delegate
        passcodeState.accept(passcode: "0000", from: passcodeLock)
        
        XCTAssertEqual(delegate.called, true, "Should call the delegate when the passcode is incorrect")
    }
    
    func testIncorrectPasscodeNotification() {
        
        let observer = NotificaionObserver()

        observer.observe(notification: PasscodeLockIncorrectPasscodeNotification)
        
        passcodeState.accept(passcode: "0", from: passcodeLock)
        passcodeState.accept(passcode: "0", from: passcodeLock)
        passcodeState.accept(passcode: "0", from: passcodeLock)
        
        XCTAssertEqual(observer.called, true, "Should send a notificaiton when the maximum number of incorrect attempts is reached")
    }
    
    func testIncorrectPasscodeSendNotificationOnce() {
        
        let observer = NotificaionObserver()

        observer.observe(notification: PasscodeLockIncorrectPasscodeNotification)
        
        passcodeState.accept(passcode: "0", from: passcodeLock)
        passcodeState.accept(passcode: "0", from: passcodeLock)
        passcodeState.accept(passcode: "0", from: passcodeLock)
        
        passcodeState.accept(passcode: "0", from: passcodeLock)
        passcodeState.accept(passcode: "0", from: passcodeLock)
        passcodeState.accept(passcode: "0", from: passcodeLock)

        XCTAssertEqual(observer.callCounter, 1, "Should send the notification only once")
    }
}
