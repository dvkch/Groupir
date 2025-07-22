//
//  MediasManager.swift
//  Groupir
//
//  Created by Stanislas Chevallier on 21/10/2021.
//

import Photos
import BrightFutures
import SYKit

class MediasManager: NSObject {

    // MARK: Init
    static let shared = MediasManager()
    private override init() {
        events = .init(initial: [])
        albums = .init(initial: [])
        super.init()
        
        PHPhotoLibrary.shared().register(self)
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
    
    // MARK: Albums
    private func ensureRootAlbum() -> Future<(), AppError> {
        if let rootGroupID = Preferences.shared.rootGroupID, let rootGroup = [PHCollectionList].forResults(
            PHCollectionList.fetchCollectionLists(withLocalIdentifiers: [rootGroupID], options: nil)
        ).unique {
            self.rootAlbum = rootGroup
            return .init(value: ())
        }

        return Future.init { resolver in
            var newRootGroupID: String? = nil
            PHPhotoLibrary.shared().performChanges({
                let request = PHCollectionListChangeRequest.creationRequestForCollectionList(withTitle: "Groupir")
                newRootGroupID = request.placeholderForCreatedCollectionList.localIdentifier
            }) { success, error in
                if success,
                    let newRootGroupID,
                    let newRootGroup = [PHCollectionList].forResults(
                        PHCollectionList.fetchCollectionLists(withLocalIdentifiers: [newRootGroupID], options: nil)
                    ).unique
                {
                    Preferences.shared.rootGroupID = newRootGroupID
                    self.rootAlbum = newRootGroup
                    resolver(.success(()))
                }
                else {
                    resolver(.failure(AppError.noRootGroup))
                }
            }
        }
    }

    // MARK: Events
    let events: ObservedObject<[Event]>
    
    private var currentReload: Future<(), AppError>?
    func reloadEventsAndAlbums(progress: ((Float) -> ())?) -> Future<(), AppError> {
        if let currentReload = currentReload {
            return currentReload
        }
        
        let future = eventGroups(progress: progress).andThen { _ in self.currentReload = nil }
        currentReload = future
        return future
    }
    
    // MARK: Albums
    private(set) var rootAlbum: PHCollectionList?
    let albums: ObservedObject<[Album]>
    
    func isInAlbum(media: Media) -> Bool {
        return albums.value.contains(where: { $0.mediaIDs.contains(media.asset.localIdentifier) })
    }
    
    func createAlbum(title: String, completion: @escaping (Album) -> Void) {
        guard let rootAlbum else {
            print("No root album")
            return
        }

        var newAlbumID: String? = nil
        PHPhotoLibrary.shared().performChanges({
            let creationRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: title)
            newAlbumID = creationRequest.placeholderForCreatedAssetCollection.localIdentifier

            PHCollectionListChangeRequest(for: rootAlbum)?.addChildCollections([creationRequest.placeholderForCreatedAssetCollection] as NSFastEnumeration)
        }) { success, error in
            if let error {
                print("Couldn't add to album:", error)
            }
            let allAlbums = [PHCollection]
                .forResults(PHCollection.fetchCollections(in: rootAlbum, options: nil))
                .compactMap { $0 as? PHAssetCollection }
            
            if let newAlbumID, let newAlbum = allAlbums.first(where: { $0.localIdentifier == newAlbumID }) {
                completion(Album(album: newAlbum, medias: []))
            }
        }
        // the albums list will be updated when a library event triggers a reload
    }
    
    func addMedias(_ medias: [Media], to album: Album) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetCollectionChangeRequest(for: album.album)?.addAssets(medias.map(\.asset) as NSFastEnumeration)
        }) { success, error in
            if let error {
                print("Couldn't add to album:", error)
            }
        }
        // the albums list will be updated when a library event triggers a reload
    }

    func removeMediasFromAlbums(_ medias: [Media]) {
        let affectedAlbums = albums.value.filter { $0.contains(anyMediaIn: medias) }

        PHPhotoLibrary.shared().performChanges({
            for album in affectedAlbums {
                PHAssetCollectionChangeRequest(for: album.album)?.removeAssets(medias.map(\.asset) as NSFastEnumeration)
            }
        }) { success, error in
            if let error {
                print("Couldn't remove from album:", error)
            }
            else if success {
                self.cleanupEmptyAlbums(in: affectedAlbums)
            }
        }
        // the albums list will be updated when a library event triggers a reload
    }
    
    private func cleanupEmptyAlbums(in albums: [Album]) {
        let emptyAlbums = albums.filter { PHAsset.fetchAssets(in: $0.album, options: nil).count == 0 }
        PHPhotoLibrary.shared().performChanges({
            PHAssetCollectionChangeRequest.deleteAssetCollections(emptyAlbums.map(\.album) as NSFastEnumeration)
        }) { success, error in
            if let error {
                print("Couldn't delete empty albums", error)
            }
        }
        // the albums list will be updated when a library event triggers a reload
    }

    // MARK: Library properties
    private var assets: [PHAsset] = []
    private(set) var medias: [Media] = [] {
        didSet {
            Preferences.shared.cacheFileSizes(from: medias)
            recomputeEvents()
            reloadAlbums()
            
            mediasDictionary = medias.reduce(into: .init(minimumCapacity: medias.count), { $0[$1.asset.localIdentifier] = $1 })
        }
    }
    private var mediasDictionary: [String: Media] = [:]

    private func recomputeEvents() {
        let visibleMedias = medias.filter { !isInAlbum(media: $0) }
        events.value = Event.group(medias: visibleMedias)
    }
    
    private func reloadAlbums() {
        self.albums.value += [] // this will trigger a refresh
    }

    // MARK: Library methods
    private func obtainImages() -> Future<[PHAsset], AppError> {
        return Future.init { resolver in
            DispatchQueue.global(qos: .userInitiated).async {
                let assets = [PHAsset].forResults(PHAsset.fetchAssets(with: nil)) {
                    $0.sourceType == .typeUserLibrary
                }
                resolver(.success(assets))
            }
        }
    }
    
    private func obtainAlbums() -> Future<[PHAssetCollection], AppError> {
        guard let rootAlbum else {
            return .init(error: .noRootGroup)
        }

        return Future.init { resolver in
            DispatchQueue.global(qos: .userInitiated).async {
                let collections = [PHCollection]
                    .forResults(PHCollection.fetchCollections(in: rootAlbum, options: nil))
                    .compactMap { $0 as? PHAssetCollection }
                resolver(.success(collections))
            }
        }
    }
    
    private func eventGroups(progress progressClosure: ((Float) -> ())?) -> Future<(), AppError> {
        return askPermission()
            .flatMap { self.ensureRootAlbum() }
            .flatMap { self.obtainImages() }
            .flatMap { (assets: [PHAsset]) -> Future<(), AppError> in
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

                        self.medias = assets.enumerated().compactMap {
                            progress = Float($0.offset) / Float(assets.count)
                            return Media(asset: $0.element)
                        }.sorted()
                        resolver(.success(()))
                    }
                }
            }
            .flatMap { self.obtainAlbums() }
            .flatMap { (collections: [PHAssetCollection]) -> Future<(), AppError> in
                Future.init { resolver in
                    DispatchQueue.global(qos: .userInitiated).async {
                        self.albums.value = collections.map {
                            let medias = [PHAsset]
                                .forResults(PHAsset.fetchAssets(in: $0, options: nil))
                                .compactMap { Media(asset: $0) }
                            return Album(album: $0, medias: medias)
                        }.sorted()
                        resolver(.success(()))
                    }
                }
            }
    }
}

extension MediasManager: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        _ = reloadEventsAndAlbums(progress: nil)
    }
}

