//
//  NSMenuItem+Extension.swift
//  Suohai
//

//  SPDX-License-Identifier: GPL-3.0-only
//

import Cocoa

extension NSMenuItem {
    public convenience init(title string: String, target: AnyObject? = nil, action selector: Selector? = nil, keyEquivalent charCode: String? = nil) {
        self.init(title: string, action: selector, keyEquivalent: charCode ?? "")
        self.target = target
    }
}
