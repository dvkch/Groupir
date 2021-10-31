//
//  ExportableMedia.swift
//  Groupir
//
//  Created by Stanislas Chevallier on 23/10/2021.
//

import UIKit
import Photos

class ExportableMedia: NSObject {
    
    // MARK: Init
    init(asset: PHAsset, kind: Kind, resource: PHAssetResource, originalResource: PHAssetResource?) {
        self.asset = asset
        self.kind = kind
        self.resource = resource
        self.originalResource = originalResource
        super.init()
    }
    
    // MARK: Properties
    let kind: Kind
    private let asset: PHAsset
    let resource: PHAssetResource
    private let originalResource: PHAssetResource?
    private lazy var tempURL: TempURL? = {
        resource.sy_privateFileURL?.tempURL(filename: filename)
    }()
    
    enum Kind: Int, Comparable {
        case video = 0, photo = 1, livePhoto = 2

        static func < (lhs: ExportableMedia.Kind, rhs: ExportableMedia.Kind) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    // MARK: Computed properties
    var filename: String {
        if let url = resource.sy_privateFileURL, let originalUrl = originalResource?.sy_privateFileURL {
            return originalUrl.deletingPathExtension().appendingPathExtension(url.pathExtension).lastPathComponent
        }
        return originalResource?.originalFilename ?? resource.originalFilename
    }
    
    var sharingURL: URL? {
        tempURL?.url ?? resource.sy_privateFileURL
    }
}
