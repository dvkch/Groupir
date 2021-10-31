//
//  Media.swift
//  Groupir
//
//  Created by Stanislas Chevallier on 21/10/2021.
//

import Foundation
import Photos
import BrightFutures
import QuickLook

class Media {
    // MARK: Init
    init?(asset: PHAsset) {
        guard let date = [asset.creationDate, asset.modificationDate].compactMap({ $0 }).min() else { return nil }

        self.asset = asset
        self.date = date
        
        if let size = PrefsManager.shared.cachedFileSizes[asset.localIdentifier] {
            self.size = size
        }
        else {
            self.size = 0
            self.size = resources.map(\.sy_fileSize).reduce(0, +)
        }
    }
    
    // MARK: Properties
    let asset: PHAsset
    let date: Date
    private(set) var size: UInt64
    var filename: String {
        return exportableResources.first!.filename
    }

    // MARK: Resources
    private var loadedResources: [PHAssetResource]?
    private var resources: [PHAssetResource] {
        // this call is expensive, let's make sure we don't call it unless we have to (hence the assets size cache)
        loadedResources = loadedResources ?? PHAssetResource.assetResources(for: asset)
        return loadedResources!
    }

    var exportableResources: [ExportableMedia] {
        var resources = self.resources
            .filter { !$0.type.isUnknown } // remove unknown kinds, usually AAE files
            .filter { $0.type != .adjustmentData } // remove adjustment files
            .filter { $0.type != .adjustmentBasePhoto } // remove PenultimateFullSizeRender, used to show previous edit version
        
        var exportabledMedias = [ExportableMedia]()
        
        // Video
        if let edit = resources.first(where: { $0.type == .fullSizeVideo }), let original = resources.first(where: { $0.type == .video }) {
            exportabledMedias.append(ExportableMedia(asset: asset, kind: .video, resource: edit, originalResource: original))
            resources.removeAll { $0 == edit }
            resources.removeAll { $0 == original }
            resources.removeAll { $0.type == .fullSizePhoto }
        }
        else if let original = resources.first(where: { $0.type == .video }) {
            exportabledMedias.append(ExportableMedia(asset: asset, kind: .video, resource: original, originalResource: nil))
            resources.removeAll { $0 == original }
            resources.removeAll { $0.type == .fullSizePhoto }
        }
        
        // Photo
        if let edit = resources.first(where: { $0.type == .fullSizePhoto }), let original = resources.first(where: { $0.type == .photo }) {
            exportabledMedias.append(ExportableMedia(asset: asset, kind: .photo, resource: edit, originalResource: original))
            resources.removeAll { $0 == edit }
            resources.removeAll { $0 == original }
        }
        else if let original = resources.first(where: { $0.type == .photo }) {
            exportabledMedias.append(ExportableMedia(asset: asset, kind: .photo, resource: original, originalResource: nil))
            resources.removeAll { $0 == original }
        }

        // Live photo
        if let edit = resources.first(where: { $0.type == .fullSizePairedVideo }), let original = resources.first(where: { $0.type == .pairedVideo }) {
            exportabledMedias.append(ExportableMedia(asset: asset, kind: .livePhoto, resource: edit, originalResource: original))
            resources.removeAll { $0 == edit }
            resources.removeAll { $0 == original }
        }
        else if let original = resources.first(where: { $0.type == .pairedVideo }) {
            exportabledMedias.append(ExportableMedia(asset: asset, kind: .livePhoto, resource: original, originalResource: nil))
            resources.removeAll { $0 == original }
        }
        
        // RAW
        if let original = resources.first(where: { $0.type == .alternatePhoto }) {
            exportabledMedias.append(ExportableMedia(asset: asset, kind: .photo, resource: original, originalResource: nil))
            resources.removeAll { $0 == original }
        }
        
        #if DEBUG
        if resources.count > 0 {
            let hash = resources.reduce(into: [:], { hash, resource in hash[resource.originalFilename] = resource.type.description })
            fatalError("UNHANDLED RESOURCES: \(hash)")
        }
        #endif
        
        return exportabledMedias
    }

    func obtainExportURL(allowRetry: Bool = true) -> Future<[ExportableMedia], AppError> {
        return Future.init { resolver in
            resolver(.success(exportableResources))
        }
    }
    
    var mediaPreviewItem: MediaPreviewItem {
        return MediaPreviewItem(media: self)
    }
}

extension Media: Equatable {
    static func == (lhs: Media, rhs: Media) -> Bool {
        return lhs.asset == rhs.asset
    }
}

extension Media: Comparable {
    static func < (lhs: Media, rhs: Media) -> Bool {
        return lhs.date < rhs.date
    }
}

extension Media: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(asset.localIdentifier)
    }
}
