//
//  Group.swift
//  Groupir
//
//  Created by Stanislas Chevallier on 24/10/2021.
//

import Foundation
import QuickLook

protocol Groupable: CustomStringConvertible {
    var uniqueID: String { get }
    var title: String { get }
    var medias: [Media] { get }
    var mediaIDs: [String] { get }
    var size: UInt64 { get }

    mutating func remove(medias: [Media])
}

extension Groupable {
    var size: UInt64 {
        return medias.map(\.size).reduce(0, +)
    }
    
    var details: String {
        return "\(medias.count) medias, \(GroupSizeFormatter.string(fromByteCount: Int64(size)))"
    }
    
    func contains(anyMediaIn medias: [Media]) -> Bool {
        return Set(self.mediaIDs).intersection(Set(medias.map(\.asset.localIdentifier))).isNotEmpty
    }

    var description: String {
        return "\(type(of: self)): \(details)"
    }
}

protocol Group: Groupable, Hashable, Comparable { }

extension Group {
    func hash(into hasher: inout Hasher) {
        hasher.combine(uniqueID.hashValue)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.uniqueID == rhs.uniqueID
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.size < rhs.size
    }
}

private let GroupSizeFormatter: ByteCountFormatter = {
    let formatter = ByteCountFormatter()
    formatter.countStyle = .binary
    return formatter
}()
