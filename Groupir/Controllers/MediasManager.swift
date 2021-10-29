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
    private init() {
        events = .init(initial: [])
        metaGroups = .init(initial: UserDefaults.standard.codableValue([MetaGroup].self, for: "meta_groups") ?? [])
        metaGroupsMediaIDs = Set(metaGroups.value.map(\.mediaIDs).joined())
    }
    
    // MARK: Events
    var events: ObservedObject<[EventGroup]>
    
    private var currentReload: Future<(), AppError>?
    func reloadEvents(progress: ((Float) -> ())?) -> Future<(), AppError> {
        if let currentReload = currentReload {
            return currentReload
        }
        
        let future = eventGroups(progress: progress)
            .andThen { _ in self.currentReload = nil }
            .map { (groups: [EventGroup]) -> () in self.events.value = groups }
        currentReload = future
        return future
    }
    
    // MARK: MetaGroups
    var metaGroups: ObservedObject<[MetaGroup]> {
        didSet {
            metaGroupsMediaIDs = Set(metaGroups.value.map(\.mediaIDs).joined())
            UserDefaults.standard.setCodable(metaGroups.value, for: "meta_groups")
        }
    }
    private var metaGroupsMediaIDs: Set<String> = []
    
    func isInMetaGroup(media: Media) -> Bool {
        return metaGroupsMediaIDs.contains(media.asset.localIdentifier)
    }

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
    
    // MARK: Internal Library
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
    
    private func eventGroups(progress progressClosure: ((Float) -> ())?) -> Future<[EventGroup], AppError> {
        return askPermission()
            .flatMap { self.obtainImages() }
            .flatMap { (assets: [PHAsset]) -> Future<[EventGroup], AppError> in
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
                        PrefsManager.shared.cacheFileSizes(from: medias)
                        
                        let groups = EventGroup.group(medias: medias)
                        resolver(.success(groups))
                    }
                }
            }
    }
    
    func medias(in group: MetaGroup) -> [Media] {
        let result = PHAsset.fetchAssets(withLocalIdentifiers: group.mediaIDs, options: nil)

        var assets = [PHAsset]()
        assets.reserveCapacity(result.count)
        result.enumerateObjects { asset, _, _ in assets.append(asset) }
        return assets.compactMap { Media(asset: $0) }
    }
}
