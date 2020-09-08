//
//  CountDownable.swift
//  PasscodeLock
//
//  Created by Gapo on 9/7/20.
//  Copyright © 2020 Yanko Dimitrov. All rights reserved.
//

import Foundation

protocol CountDownable: class {
    func handleUpdateCountDownUI(minute: String, second: String)
    func handleCountDownComplete()
    var countDownSecond: Int {get set}
    var timer: RepeatingTimer? {get set}
}

extension CountDownable where Self: UIView {
    func startCountDown() {
        timer?.clear()
        timer = RepeatingTimer.init(timeInterval: 1)
        timer?.eventHandler = {
            self.countdown()
        }
        timer?.resume()
    }

    func stopCountDown() {
        timer?.clear()
        timer = nil
    }

    func countdown() {
        if countDownSecond == 0 {
            DispatchQueue.main.async { [weak self] in
                print("-1")
                self?.handleCountDownComplete()
            }
        } else {
            countDownSecond -= 1
            let (minute, second) = parseSecondToData(second: countDownSecond)
            DispatchQueue.main.async { [weak self] in
                print("-1")
                self?.handleUpdateCountDownUI(minute: minute, second: second)
            }
        }
    }

    private func parseSecondToData(second: Int) -> (minute: String, second: String) {
        let secondEnd = second % 60
        let minute = second / 60

        let prefixSecond = secondEnd < 10 ? "0" : ""
        let prefixMinute = minute < 10 ? "0" : ""

        return ("\(prefixMinute)\(minute)", "\(prefixSecond)\(secondEnd)")
    }
}

/// RepeatingTimer mimics the API of DispatchSourceTimer but in a way that prevents
/// crashes that occur from calling resume multiple times on a timer that is
/// already resumed (noted by https://github.com/SiftScience/sift-ios/issues/52
class RepeatingTimer {

    let timeInterval: TimeInterval

    init(timeInterval: TimeInterval) {
        self.timeInterval = timeInterval
    }

    private lazy var timer: DispatchSourceTimer? = {
        let t = DispatchSource.makeTimerSource()
        t.schedule(deadline: .now() + self.timeInterval, repeating: self.timeInterval)
        t.setEventHandler(handler: { [weak self] in
            self?.eventHandler?()
        })
        return t
    }()

    var eventHandler: (() -> Void)?

    private enum State {
        case suspended
        case resumed
    }

    private var state: State = .suspended

    deinit {
        timer?.setEventHandler {}
        timer?.cancel()
        /*
         If the timer is suspended, calling cancel without resuming
         triggers a crash. This is documented here https://forums.developer.apple.com/thread/15902
         */
        eventHandler = nil
        timer = nil
    }

    func resume() {
        if state == .resumed {
            return
        }
        state = .resumed
        timer?.resume()
    }

    func suspend() {
        if state == .suspended {
            return
        }
        state = .suspended
        timer?.suspend()
    }

    func clear() {
        timer?.setEventHandler {}
        timer?.cancel()
    }
}

