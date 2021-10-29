//
//  GroupAction.swift
//  Groupir
//
//  Created by Stanislas Chevallier on 29/10/2021.
//

import UIKit

enum GroupAction: CaseIterable {
    case mergeWithPrevious, splitByDate, addToAlbum, share, delete
    
    var title: String {
        switch self {
        case .mergeWithPrevious:    return "Merge with previous group"
        case .splitByDate:          return "Split by date"
        case .addToAlbum:           return "Add all to album..."
        case .share:                return "Share"
        case .delete:               return "Delete"
        }
    }
    
    var imageName: String {
        switch self {
        case .mergeWithPrevious:    return "arrow.triangle.merge"
        case .splitByDate:          return "arrow.triangle.branch"
        case .addToAlbum:           return "folder.badge.plus"
        case .share:                return "square.and.arrow.up"
        case .delete:               return "trash"
        }
    }
    
    var image: UIImage? {
        return UIImage(systemName: imageName)
    }
    
    func isAvailable(for group: Groupable) -> Bool {
        switch self {
        case .mergeWithPrevious:    return group is Event
        case .splitByDate:          return group is Event
        case .addToAlbum:           return group is Event
        case .share:                return true
        case .delete:               return true
        }
    }
    
    static func available(for group: Groupable) -> [GroupAction] {
        return allCases.filter { $0.isAvailable(for: group) }
    }
}
