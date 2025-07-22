//
//  PHAssetResourceType+SY.swift
//  Groupir
//
//  Created by Stanislas Chevallier on 23/10/2021.
//

import Photos

extension PHAssetResourceType: @retroactive Comparable {
    public static func < (lhs: PHAssetResourceType, rhs: PHAssetResourceType) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

extension PHAssetResourceType: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case .photo:                        return "photo"
        case .video:                        return "video"
        case .audio:                        return "audio"
        case .alternatePhoto:               return "alternatePhoto"
        case .fullSizePhoto:                return "fullSizePhoto"
        case .fullSizeVideo:                return "fullSizeVideo"
        case .adjustmentData:               return "adjustmentData"
        case .adjustmentBasePhoto:          return "adjustmentBasePhoto"
        case .pairedVideo:                  return "pairedVideo"
        case .fullSizePairedVideo:          return "fullSizePairedVideo"
        case .adjustmentBasePairedVideo:    return "adjustmentBasePairedVideo"
        case .adjustmentBaseVideo:          return "adjustmentBaseVideo"
        case .photoProxy:                   return "photoProxy"
        @unknown default:                   return "unknown"
        }
    }
    
    var isUnknown: Bool {
        switch self {
        case .photo:                        return false
        case .video:                        return false
        case .audio:                        return false
        case .alternatePhoto:               return false
        case .fullSizePhoto:                return false
        case .fullSizeVideo:                return false
        case .adjustmentData:               return false
        case .adjustmentBasePhoto:          return false
        case .pairedVideo:                  return false
        case .fullSizePairedVideo:          return false
        case .adjustmentBasePairedVideo:    return false
        case .adjustmentBaseVideo:          return false
        case .photoProxy:                   return false
        @unknown default:                   return true
        }
    }
}

