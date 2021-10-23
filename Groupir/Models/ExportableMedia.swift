//
//  ExportableMedia.swift
//  Groupir
//
//  Created by Stanislas Chevallier on 23/10/2021.
//

import UIKit
import Photos

class ExportableMedia: NSObject {
    init(asset: PHAsset, resource: PHAssetResource, originalResource: PHAssetResource?) {
        self.asset = asset
        self.resource = resource
        self.originalResource = originalResource
        super.init()
    }
    
    private let asset: PHAsset
    private let resource: PHAssetResource
    private let originalResource: PHAssetResource?
}

extension ExportableMedia: UIActivityItemSource {
    func ExportableMedia(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
        return resource.uniformTypeIdentifier
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        if let url = resource.sy_privateFileURL, let originalUrl = originalResource?.sy_privateFileURL {
            return originalUrl.deletingPathExtension().appendingPathExtension(url.pathExtension).lastPathComponent
        }
        return originalResource?.originalFilename ?? resource.originalFilename
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.resizeMode = .fast
        options.deliveryMode = .fastFormat
        options.isNetworkAccessAllowed = false
        options.version = .current

        var resultImage: UIImage?
        PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: 200, height: 200), contentMode: .aspectFit, options: options) { (image, _) in
            resultImage = image
        }
        return resultImage ?? UIImage()
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        guard let url = resource.sy_privateFileURL else { return nil }
        return try! Data(contentsOf: url, options: .mappedIfSafe)
    }
}