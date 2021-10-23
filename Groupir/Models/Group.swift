//
//  Group.swift
//  Groupir
//
//  Created by Stanislas Chevallier on 21/10/2021.
//

import Foundation

struct Group: Equatable {
    // MARK: Init
    fileprivate(set) var medias: [Media] = []
    var size: UInt64 {
        return medias.map(\.size).reduce(0, +)
    }

    // MARK: Formatters
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        formatter.timeZone = TimeZone.autoupdatingCurrent
        return formatter
    }()

    private static let sizeFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter
    }()
}

extension Group: Comparable {
    static func < (lhs: Group, rhs: Group) -> Bool {
        return lhs.size < rhs.size
    }
}

extension Group: CustomStringConvertible {
    var description: String {
        "\(Group.dateFormatter.string(from: medias.first!.date)), \(medias.count) medias, \(Group.sizeFormatter.string(fromByteCount: Int64(size)))"
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
