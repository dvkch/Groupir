//
//  Album.swift
//  Groupir
//
//  Created by Stanislas Chevallier on 24/10/2021.
//

import Foundation
import Photos

struct Album: Codable {
    
    // MARK: Init
    init(title: String, medias: [Media] = []) {
        uniqueID = UUID().uuidString
        self.title = title
        mediaIDs = medias.sorted().map(\.asset).map(\.localIdentifier)
    }

    init(from decoder: Decoder) throws {
        // we need a custom intializer because in older version `uniqueID` didn't exist, and we dont want to loose those groups!
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uniqueID = try container.decodeIfPresent(String.self, forKey: .uniqueID) ?? UUID().uuidString
        title = try container.decode(String.self, forKey: .title)
        mediaIDs = try container.decode([String].self, forKey: .mediaIDs)
    }
    
    // MARK: Properties
    let uniqueID: String
    var title: String = "Group"
    private(set) var mediaIDs: [String]
    var medias: [Media] {
        return MediasManager.shared.medias(in: self)
    }

    enum CodingKeys: String, CodingKey {
        case uniqueID = "unique_id"
        case title = "title"
        case mediaIDs = "media_ids"
    }
    
    mutating func add(medias: [Media]) {
        let allMedias = self.medias + medias
        mediaIDs = allMedias.sorted().map(\.asset).map(\.localIdentifier)
    }
}

extension Album: Group {
    mutating func remove(medias: [Media]) {
        let mediaIDsToRemove = Set(medias.map(\.asset).map(\.localIdentifier))
        mediaIDs.removeAll(where: { mediaIDsToRemove.contains($0) })
    }
}
