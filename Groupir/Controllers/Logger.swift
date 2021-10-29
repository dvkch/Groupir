//
//  Logger.swift
//  Groupir
//
//  Created by Stanislas Chevallier on 29/10/2021.
//

import Foundation
import os

class Logger {
    enum Tag: String {
        case codable = "Codable"
        case fileManager = "FileManager"
        case tempURL = "TempURL"

        var asOSLog: OSLog {
            return OSLog(subsystem: Bundle.main.bundleIdentifier!, category: rawValue)
        }
    }
    
    private static func log(level: OSLogType, tag: Tag, _ message: String) {
        #if DEBUG
        os_log(level, log: tag.asOSLog, "%{public}s", message)
        #else
        os_log(level, log: tag.asOSLog, "%s", message)
        #endif
    }
    
    static func i(_ tag: Tag, _ message: String) {
        log(level: .info, tag: tag, message)
    }
    
    static func w(_ tag: Tag, _ message: String) {
        log(level: .debug, tag: tag, message)
    }

    static func e(_ tag: Tag, _ message: String) {
        log(level: .error, tag: tag, message)
    }
}
