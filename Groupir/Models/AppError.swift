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
    case noRootGroup
    case couldntAddToAlbum
    case couldntRemoveFromAlbum
}

extension AppError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .noPhotosAccess:           return "Access denied"
        case .noFileURL:                return "No file URL"
        case .noRootGroup:              return "No root group"
        case .couldntAddToAlbum:        return "Couldn't add to album"
        case .couldntRemoveFromAlbum:   return "Couldn't remove from album"
        }
    }
}

extension AppError: RecoverableError {
    var recoveryOptions: [String] {
        switch self {
        case .noPhotosAccess:           return ["Change permissions"]
        case .noFileURL:                return []
        case .noRootGroup:              return []
        case .couldntAddToAlbum:        return []
        case .couldntRemoveFromAlbum:   return []
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
            
        case .noRootGroup:
            return false
            
        case .couldntAddToAlbum:
            return false
            
        case .couldntRemoveFromAlbum:
            return false
        }
    }
}
