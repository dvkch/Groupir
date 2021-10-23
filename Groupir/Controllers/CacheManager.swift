//
//  CacheManager.swift
//  Groupir
//
//  Created by Stanislas Chevallier on 22/10/2021.
//

import Foundation

class CacheManager {

    // MARK: Init
    static let shared = CacheManager()
    private init() {
        fileSizes = UserDefaults.standard.codableValue([String: UInt64].self, for: "cached_file_sizes") ?? [:]
    }

    // MARK: File size cache
    private(set) var fileSizes: [String: UInt64] {
        didSet {
            UserDefaults.standard.setCodable(fileSizes, for: "cached_file_sizes")
        }
    }
    
    func cacheFileSizes(from medias: [Media]) {
        var sizes = [String: UInt64]()
        sizes.reserveCapacity(medias.count)
        medias.forEach { media in sizes[media.asset.localIdentifier] = media.size }
        self.fileSizes = sizes
    }
}
