//
//  Date+SY.swift
//  Groupir
//
//  Created by Stanislas Chevallier on 21/10/2021.
//

import Foundation

extension Date {
    static func -(lhs: Date, rhs: Date) -> TimeInterval {
        return lhs.timeIntervalSince1970 - rhs.timeIntervalSince1970
    }
}
