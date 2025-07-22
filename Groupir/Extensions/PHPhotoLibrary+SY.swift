//
//  PHPhotoLibrary+SY.swift
//  Groupir
//
//  Created by syan on 18/01/2025.
//

import Photos
import BrightFutures

extension PHPhotoLibrary {
    private func performChangesFuture<T>(_ changes: @escaping () -> T) -> Future<T, Error> {
        return .init { resolver in
            var result: T?
            PHPhotoLibrary.shared().performChanges({
                result = changes()
            }) { success, error in
                if let error {
                    resolver(.failure(error))
                }
                else {
                    resolver(.success(result!))
                }
            }
        }
    }

    func createFolder(_ name: String) -> Future<String, Error> {
        return performChangesFuture {
            let collection = PHCollectionListChangeRequest.creationRequestForCollectionList(withTitle: name)
            return collection.placeholderForCreatedCollectionList.localIdentifier
        }
    }
    
    func createAlbum(_ name: String) -> Future<String, Error> {
        return performChangesFuture {
            let collection = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: name)
            return collection.placeholderForCreatedAssetCollection.localIdentifier
        }
    }
    
    func addAssets(_ assets: [PHAsset], to collection: PHAssetCollection) -> Future<(), Error> {
        return performChangesFuture {
            PHAssetCollectionChangeRequest(for: collection)?.addAssets(assets as NSFastEnumeration)
        }
    }
}
