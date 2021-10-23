//
//  MediasManager.swift
//  Groupir
//
//  Created by Stanislas Chevallier on 21/10/2021.
//

import Photos
import BrightFutures

class MediasManager {

    // MARK: Init
    static let shared = MediasManager()
    private init() { }
    
    // MARK: Permissions
    private func askPermission() -> Future<(), AppError> {
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .authorized {
            return .init(value: ())
        }
        
        return Future.init { resolver in
            PHPhotoLibrary.requestAuthorization { (newStatus) in
                if (newStatus == PHAuthorizationStatus.authorized) {
                    resolver(.success(()))
                } else {
                    resolver(.failure((AppError.noPhotosAccess)))
                }
            }
        }
    }
    
    // MARK: Content
    private func obtainImages() -> Future<[PHAsset], AppError> {
        return Future.init { resolver in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = PHAsset.fetchAssets(with: nil)

                var assets = [PHAsset]()
                assets.reserveCapacity(result.count)
                result.enumerateObjects { asset, _, _ in assets.append(asset) }
                assets = assets.filter { $0.sourceType == .typeUserLibrary }
                resolver(.success(assets))
            }
        }
    }
    
    func groupedImages(progress progressClosure: ((Float) -> ())?) -> Future<[Group], AppError> {
        return askPermission()
            .flatMap { self.obtainImages() }
            .flatMap { (assets: [PHAsset]) -> Future<[Group], AppError> in
                Future.init { resolver in
                    DispatchQueue.global(qos: .userInitiated).async {
                        var progress: Float = 0 {
                            didSet {
                                if (progress * 100).rounded(.down) != (oldValue * 100).rounded(.down) {
                                    DispatchQueue.main.async {
                                        progressClosure?(progress)
                                    }
                                }
                            }
                        }

                        let medias: [Media] = assets.enumerated().compactMap {
                            progress = Float($0.offset) / Float(assets.count)
                            return Media(asset: $0.element)
                        }
                        CacheManager.shared.cacheFileSizes(from: medias)

                        let groups = Group.group(medias: medias)
                        resolver(.success(groups))
                    }
                }
            }
    }
}
