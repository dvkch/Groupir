//
//  EventGroup.swift
//  Groupir
//
//  Created by Stanislas Chevallier on 21/10/2021.
//

import Foundation

struct EventGroup {

    // MARK: Properties
    let uniqueID = UUID().uuidString
    private(set) var medias: [Media] = []
    
    // MARK: Medias
    mutating func merge(withNextGroup group: EventGroup) {
        if let endOfThisGroup = medias.last, let topOfNextGroup = group.medias.first {
            PrefsManager.shared.link(media: endOfThisGroup, to: topOfNextGroup)
        }
        medias.append(contentsOf: group.medias)
        medias.sort()
    }
    
    mutating func remove(medias: [Media]) {
        self.medias.removeAll(where: { medias.contains($0) })
    }
    
    // MARK: Formatters
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.timeZone = TimeZone.autoupdatingCurrent
        return formatter
    }()
}

extension EventGroup: Group {
    var title: String {
        EventGroup.dateFormatter.string(from: medias.first?.date ?? Date(timeIntervalSince1970: 0))
    }

    var mediaIDs: [String] {
        medias.map(\.asset).map(\.localIdentifier)
    }
}

extension EventGroup {
    static func group(medias: [Media]) -> [EventGroup] {
        var groups: [EventGroup] = []
        medias.sorted().forEachWithPrevious { media, prevMedia in
            guard let prevMedia = prevMedia else {
                groups.append(EventGroup(medias: [media]))
                return
            }
            
            let link = LinkedMedia(mediaID1: prevMedia.asset.localIdentifier, mediaID2: media.asset.localIdentifier)
            if (media.date - prevMedia.date) > 3600 && !PrefsManager.shared.linkedMedias.contains(link) {
                groups.append(EventGroup())
            }
            
            groups[groups.count - 1].medias.append(media)
        }
        return groups
    }
}
