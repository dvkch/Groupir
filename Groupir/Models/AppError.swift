//
//  AppError.swift
//  Groupir
//
//  Created by Stanislas Chevallier on 21/10/2021.
//

import UIKit

enum AppError: Error {
    case noPhotosAccess
    case noFileURL
}

extension AppError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .noPhotosAccess: return "Access denied"
        case .noFileURL: return "No file URL"
        }
    }
}

extension AppError: RecoverableError {
    var recoveryOptions: [String] {
        switch self {
        case .noPhotosAccess:
            return ["Change to permissions"]
        case .noFileURL:
            return []
        }
    }

    func attemptRecovery(optionIndex recoveryOptionIndex: Int) -> Bool {
        switch self {
        case .noPhotosAccess:
            guard let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) else { return false }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            return true
            
        case .noFileURL:
            return false
        }
    }
}
