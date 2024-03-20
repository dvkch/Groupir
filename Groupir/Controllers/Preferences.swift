//
//  Preferences.swift
//  Groupir
//
//  Created by Stanislas Chevallier on 22/10/2021.
//

import Foundation
import SYKit

class Preferences {

    // MARK: Init
    static let shared = Preferences()
    private init() { }

    // MARK: File size cache
    @PrefValue(key: "cached_file_sizes", defaultValue: [:], ubiquitous: nil)
    private(set) var cachedFileSizes: [String: UInt64]
    
    func cacheFileSizes(from medias: [Media]) {
        var sizes = [String: UInt64]()
        sizes.reserveCapacity(medias.count)
        medias.forEach { media in sizes[media.asset.localIdentifier] = media.size }
        cachedFileSizes = sizes
    }
    
    // MARK: Merged groups
    @PrefValue(key: "linked_medias", defaultValue: [], ubiquitous: nil)
    private(set) var linkedMedias: [LinkedMedia]
    
    func link(media media1: Media, to media2: Media) {
        linkedMedias.append(LinkedMedia(mediaID1: media1.asset.localIdentifier, mediaID2: media2.asset.localIdentifier))
    }
    
    func unlink(group: Event) {
        group.medias.forEachWithPrevious { media, prevMedia in
            guard let prevMedia = prevMedia else { return }
            linkedMedias.removeAll(where: { $0.mediaID1 == prevMedia.asset.localIdentifier && $0.mediaID2 == media.asset.localIdentifier })
        }
    }
}
