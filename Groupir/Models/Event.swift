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

    private var startDate: Date {
        medias.first?.date ?? Date(timeIntervalSince1970: 0)
    }

    var title: String {
        Event.dateFormatter.string(from: startDate)
    }

    var mediaIDs: Set<String> {
        Set(medias.map(\.asset.localIdentifier))
    }

    // MARK: Medias
    mutating func merge(withNextGroup group: Event) {
        if let endOfThisGroup = medias.last, let topOfNextGroup = group.medias.first {
            Preferences.shared.link(media: endOfThisGroup, to: topOfNextGroup)
        }
        medias.append(contentsOf: group.medias)
        medias.sort()

        // helpful to force refreshing the section headers after a merge
        uniqueID = UUID().uuidString
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
        let calendar = Calendar.autoupdatingCurrent

        var groups: [Event] = []
        medias.sorted().forEachWithPrevious { media, prevMedia in
            guard let prevMedia = prevMedia else {
                groups.append(Event(medias: [media]))
                return
            }
            
            let link = LinkedMedia(mediaID1: prevMedia.asset.localIdentifier, mediaID2: media.asset.localIdentifier)
            if !calendar.isDate(media.date, inSameDayAs: prevMedia.date) && (media.date - prevMedia.date) > 7200 && !Preferences.shared.linkedMedias.contains(link) {
                groups.append(Event())
            }
            
            groups[groups.count - 1].medias.append(media)
        }
        return groups
    }
}
