//
//  DiffableDataSource.swift
//  Groupir
//
//  Created by Stanislas Chevallier on 28/10/2021.
//

import Foundation
import UIKit

protocol CollectionViewIndexable<IndexID> {
    associatedtype IndexID: Hashable
    var collectionViewIndex: (id: IndexID, title: String) { get }
}

class DiffableDataSource<Section: Hashable & CollectionViewIndexable, Item: Hashable>: UICollectionViewDiffableDataSource<Section, Item> {
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
    
    private var uniqueIndices = [(id: Section.IndexID, title: String)]()
    
    override func indexTitles(for collectionView: UICollectionView) -> [String]? {
        uniqueIndices.removeAll()
        
        let snapshot = self.snapshot()
        let nonEmptySections = snapshot.sectionIdentifiers.filter { snapshot.numberOfItems(inSection: $0) > 0 }
        
        for id in nonEmptySections.map(\.collectionViewIndex) {
            if !uniqueIndices.contains(where: { $0.id == id.id }) {
                uniqueIndices.append(id)
            }
        }
        
        return uniqueIndices.map(\.title).nilIfEmpty
    }
    
    override func collectionView(_ collectionView: UICollectionView, indexPathForIndexTitle title: String, at index: Int) -> IndexPath {
        let selectedID = uniqueIndices.element(at: index)!
        let sectionIndex = snapshot().sectionIdentifiers.firstIndex(where: { $0.collectionViewIndex.id == selectedID.id })!
        return IndexPath(item: 0, section: sectionIndex)
    }
}
