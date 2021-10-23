//
//  Group.swift
//  Groupir
//
//  Created by Stanislas Chevallier on 21/10/2021.
//

import Foundation

struct Group {
    fileprivate(set) var medias: [Media] = []
    var size: UInt64 {
        return medias.map(\.size).reduce(0, +)
    }
}

extension Group {
    static func group(medias: [Media]) -> [Group] {
        var groups: [Group] = []
        medias.sorted().forEachWithPrevious { media, prevMedia in
            guard let prevMedia = prevMedia else {
                groups.append(Group())
                return
            }
            
            if (media.date - prevMedia.date) > 3600 {
                groups.append(Group())
            }
            
            groups[groups.count - 1].medias.append(media)
        }
        return groups
    }
}
