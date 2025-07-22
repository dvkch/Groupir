//
//  Album.swift
//  Groupir
//
//  Created by Stanislas Chevallier on 24/10/2021.
//

import Foundation
import Photos

struct Album {
    
    // MARK: Init
    init(album: PHAssetCollection, medias: [Media] = []) {
        self.album = album
        self.medias = medias
        self.mediaIDs = Set(medias.map(\.asset.localIdentifier))
    }

    // MARK: Properties
    let album: PHAssetCollection
    var uniqueID: String { album.localIdentifier }
    var title: String { album.localizedTitle ?? "" }

    let medias: [Media]
    let mediaIDs: Set<String>
}

extension Album: Group {
    
}

extension Album: CollectionViewIndexable {
    var collectionViewIndex: (id: String, title: String) {
        return (uniqueID, title)
    }
}
