//
//  EventGroup.swift
//  Groupir
//
//  Created by Stanislas Chevallier on 21/10/2021.
//

import Foundation

struct Event {

    // MARK: Properties
    private(set) var uniqueID = UUID().uuidString
    private(set) var medias: [Media] = []

    var title: String {
        Event.dateFormatter.string(from: medias.first?.date ?? Date(timeIntervalSince1970: 0))
    }

    var mediaIDs: [String] {
        medias.map(\.asset.localIdentifier)
    }

    // MARK: Medias
    mutating func merge(withNextGroup group: Event) {
        if let endOfThisGroup = medias.last, let topOfNextGroup = group.medias.first {
            PrefsManager.shared.link(media: endOfThisGroup, to: topOfNextGroup)
        }
        medias.append(contentsOf: group.medias)
        medias.sort()

        // helpful to force refreshing the section headers after a merge
        uniqueID = UUID().uuidString
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

extension Event: Group {}

extension Event {
    static func group(medias: [Media]) -> [Event] {
        var groups: [Event] = []
        medias.sorted().forEachWithPrevious { media, prevMedia in
            guard let prevMedia = prevMedia else {
                groups.append(Event(medias: [media]))
                return
            }
            
            let link = LinkedMedia(mediaID1: prevMedia.asset.localIdentifier, mediaID2: media.asset.localIdentifier)
            if (media.date - prevMedia.date) > 3600 && !PrefsManager.shared.linkedMedias.contains(link) {
                groups.append(Event())
            }
            
            groups[groups.count - 1].medias.append(media)
        }
        return groups
    }
}
