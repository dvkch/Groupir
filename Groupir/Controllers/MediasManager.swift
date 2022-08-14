//
//  MediasManager.swift
//  Groupir
//
//  Created by Stanislas Chevallier on 21/10/2021.
//

import Photos
import BrightFutures

class MediasManager: NSObject {

    // MARK: Init
    static let shared = MediasManager()
    private override init() {
        events = .init(initial: [])
        albums = .init(initial: UserDefaults.standard.codableValue([Album].self, for: "meta_groups") ?? [])
        albumsMediaIDs = Set(albums.value.map(\.mediaIDs).joined())
        super.init()

        albums.addObserver(ref: self) { old, new in
            self.albumsMediaIDs = Set(new.map(\.mediaIDs).joined())
            UserDefaults.standard.setCodable(new, for: "meta_groups")
        }

        PHPhotoLibrary.shared().register(self)
    }
    
    // MARK: Events
    let events: ObservedObject<[Event]>
    
    private var currentReload: Future<(), AppError>?
    func reloadEvents(progress: ((Float) -> ())?) -> Future<(), AppError> {
        if let currentReload = currentReload {
            return currentReload
        }
        
        let future = eventGroups(progress: progress).andThen { _ in self.currentReload = nil }
        currentReload = future
        return future
    }
    
    // MARK: Albums
    let albums: ObservedObject<[Album]>
    private var albumsMediaIDs: Set<String> = [] {
        didSet {
            guard albumsMediaIDs != oldValue else { return }
            recomputeEvents()
        }
    }
    
    func isInAlbum(media: Media) -> Bool {
        return albumsMediaIDs.contains(media.asset.localIdentifier)
    }
    
    func addMedias(_ medias: [Media], to album: Album) {
        var updatedAlbums = albums.value
        
        if !updatedAlbums.contains(album) {
            updatedAlbums.append(album)
        }
        
        guard let index = updatedAlbums.firstIndex(of: album) else { return }
        updatedAlbums[index].add(medias: medias)
        self.albums.value = updatedAlbums
    }

    func removeMediasFromAlbums(_ medias: [Media]) {
        var updatedAlbums = albums.value
        for i in 0..<updatedAlbums.count {
            updatedAlbums[i].remove(medias: medias)
        }
        updatedAlbums.removeAll { $0.medias.isEmpty }
        self.albums.value = updatedAlbums
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
    
    // MARK: Library properties
    private var assets: [PHAsset] = []
    private(set) var medias: [Media] = [] {
        didSet {
            PrefsManager.shared.cacheFileSizes(from: medias)
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
                let result = PHAsset.fetchAssets(with: nil)

                var assets = [PHAsset]()
                assets.reserveCapacity(result.count)
                result.enumerateObjects { asset, _, _ in assets.append(asset) }
                assets = assets.filter { $0.sourceType == .typeUserLibrary }
                resolver(.success(assets))
            }
        }
    }
    
    private func eventGroups(progress progressClosure: ((Float) -> ())?) -> Future<(), AppError> {
        return askPermission()
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
    }
    
    func medias(in album: Album) -> [Media] {
        return album.mediaIDs.compactMap { mediasDictionary[$0] }
    }
}

extension MediasManager: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        _ = reloadEvents(progress: nil)
    }
}

