//
//  MediaPreviewItem.swift
//  Groupir
//
//  Created by Stanislas Chevallier on 29/10/2021.
//

import Photos
import QuickLook

class MediaPreviewItem: NSObject {

    // MARK: Init
    init(media: Media) {
        self.media = media
        let orderedResources = media.exportableResources.sorted(by: { $0.resource.type.previewIndex < $1.resource.type.previewIndex })
        self.resource = orderedResources.first!.resource
        self.tempURL = resource.sy_privateFileURL?.tempURL
        super.init()
    }

    // MARK: Properties
    let media: Media
    private let resource: PHAssetResource
    private let tempURL: TempURL?
}

extension MediaPreviewItem: QLPreviewItem {
    var previewItemURL: URL? {
        return tempURL?.url ?? resource.sy_privateFileURL
    }
}

fileprivate extension PHAssetResourceType {
    var previewIndex: Int {
        switch self {
        case .fullSizeVideo:    return 0
        case .video:            return 1
        case .fullSizePhoto:    return 2
        case .alternatePhoto:   return 3
        case .photo:            return 4
        default:                return 5
        }
    }
}
