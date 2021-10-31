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
        self.exportableMedia = media.exportableResources.sorted(by: { $0.kind < $1.kind }).first!
        super.init()
    }

    // MARK: Properties
    let media: Media
    private let exportableMedia: ExportableMedia
}

extension MediaPreviewItem: QLPreviewItem {
    var previewItemURL: URL? {
        return exportableMedia.sharingURL
    }
}
