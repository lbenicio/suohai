//
//  NotificationCenter+Extension.swift
//  Suohai
//

//  SPDX-License-Identifier: GPL-3.0-only
//

import Cocoa

extension NotificationCenter {
    @MainActor
    static func post(suohaiNotification name: SuohaiNotification, object: Any? = nil) {
        NotificationCenter.default.post(name: name.notificationName, object: object)
    }

    static func addObserver(observer: Any, selector: Selector, name: SuohaiNotification, object: Any? = nil) {
        NotificationCenter.default.addObserver(observer, selector: selector, name: name.notificationName, object: object)
    }

    static func removeObserver(observer: Any, name: SuohaiNotification, object: Any? = nil) {
        NotificationCenter.default.removeObserver(observer, name: name.notificationName, object: object)
    }
}
