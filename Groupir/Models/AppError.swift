//
//  AppError.swift
//  Groupir
//
//  Created by Stanislas Chevallier on 21/10/2021.
//

import Foundation

enum AppError: Error {
    case noPhotosAccess
}

extension AppError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .noPhotosAccess: return "Access denied"
        }
    }
}
