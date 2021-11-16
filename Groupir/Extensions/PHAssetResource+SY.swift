//
//  PHAssetResource+SY.swift
//  Groupir
//
//  Created by Stanislas Chevallier on 23/10/2021.
//

import Photos

extension PHAssetResource {
    // privateFileURL
    private static let fileUrlKey = ["priva", String("LRUeliFet".reversed())].joined()
    var sy_privateFileURL: URL? {
        return value(forKey: PHAssetResource.fileUrlKey) as? URL
    }
    
    // fileSize
    private static let fileSizeKey = ["fileS", String("ezi".reversed())].joined()
    var sy_fileSize: UInt64 {
        guard let size = value(forKey: PHAssetResource.fileSizeKey) as? CLong else { return 0 }
        return UInt64(size)
    }
}

