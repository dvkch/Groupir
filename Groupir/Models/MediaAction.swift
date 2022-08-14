//
//  MediaAction.swift
//  Groupir
//
//  Created by Stanislas Chevallier on 29/10/2021.
//

import UIKit

enum MediaAction: CaseIterable {
    case addToAlbum, removeFromAlbum, share, delete
    
    var title: String {
        switch self {
        case .addToAlbum:           return "Add to album..."
        case .removeFromAlbum:      return "Remove from album"
        case .share:                return "Share"
        case .delete:               return "Delete"
        }
    }
    
    var imageName: String {
        switch self {
        case .addToAlbum:           return "folder.badge.plus"
        case .removeFromAlbum:      return "folder.badge.minus"
        case .share:                return "square.and.arrow.up"
        case .delete:               return "trash"
        }
    }
    
    var image: UIImage? {
        return UIImage(systemName: imageName)
    }
    
    func isAvailable(for media: Media) -> Bool {
        switch self {
        case .addToAlbum:           return !MediasManager.shared.isInAlbum(media: media)
        case .removeFromAlbum:      return MediasManager.shared.isInAlbum(media: media)
        case .share:                return true
        case .delete:               return true
        }
    }
    
    static func available(for media: Media) -> [MediaAction] {
        return allCases.filter { $0.isAvailable(for: media) }
    }
    
    static func available(for medias: [Media]) -> [MediaAction] {
        let compatibleActions = medias
            .map { Set(available(for: $0)) }
            .reduce(Set(allCases), { acc, res in acc.intersection(res) })
        return allCases.filter { compatibleActions.contains($0) }
    }
}
