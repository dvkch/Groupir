//
//  LinkedMedias.swift
//  Groupir
//
//  Created by Stanislas Chevallier on 24/10/2021.
//

import Foundation

struct LinkedMedia: Codable, Equatable {
    let mediaID1: String
    let mediaID2: String
    
    enum CodingKeys: String, CodingKey {
        case mediaID1 = "media_id1"
        case mediaID2 = "media_id2"
    }
}
