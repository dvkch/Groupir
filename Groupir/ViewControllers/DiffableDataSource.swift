//
//  DiffableDataSource.swift
//  Groupir
//
//  Created by Stanislas Chevallier on 28/10/2021.
//

import Foundation
import UIKit

class DiffableDataSource<Section: Hashable, Item: Hashable>: UICollectionViewDiffableDataSource<Section, Item> {
    func refreshItems(_ items: [Item]) {
        var snapshot = self.snapshot()
        snapshot.reloadItems(items)
        apply(snapshot, animatingDifferences: true)
    }
    
    func setSectionHeaderProvider(_ provider: @escaping (UICollectionView, Section, IndexPath) -> (UICollectionReusableView?)) {
        self.supplementaryViewProvider = { collectionView, kind, indexPath in
            guard kind == UICollectionView.elementKindSectionHeader else { return nil }
            return provider(collectionView, self.snapshot().sectionIdentifiers[indexPath.section], indexPath)
        }
    }
}
