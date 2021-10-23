//
//  PHAssetResource+SY.swift
//  Groupir
//
//  Created by Stanislas Chevallier on 23/10/2021.
//

import Photos

extension PHAssetResource {
    var sy_privateFileURL: URL? {
        return value(forKey: "privateFileURL") as? URL
    }
}

