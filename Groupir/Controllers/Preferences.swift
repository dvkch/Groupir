//
//  Preferences.swift
//  Groupir
//
//  Created by Stanislas Chevallier on 22/10/2021.
//

import Foundation

class Preferences {

    // MARK: Init
    static let shared = PrefsManager()
    private init() {
        cachedFileSizes = UserDefaults.standard.codableValue([String: UInt64].self, for: "cached_file_sizes") ?? [:]
        linkedMedias = UserDefaults.standard.codableValue([LinkedMedia].self, for: "linked_medias") ?? []
    }

    // MARK: File size cache
    private(set) var cachedFileSizes: [String: UInt64] {
        didSet {
            UserDefaults.standard.setCodable(cachedFileSizes, for: "cached_file_sizes")
        }
    }
    
    func cacheFileSizes(from medias: [Media]) {
        var sizes = [String: UInt64]()
        sizes.reserveCapacity(medias.count)
        medias.forEach { media in sizes[media.asset.localIdentifier] = media.size }
        cachedFileSizes = sizes
    }
    
    // MARK: Merged groups
    private(set) var linkedMedias: [LinkedMedia] {
        didSet {
            UserDefaults.standard.setCodable(linkedMedias, for: "linked_medias")
        }
    }
    
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
