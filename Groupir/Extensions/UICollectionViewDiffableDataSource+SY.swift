//
//  UICollectionViewDiffableDataSource+SY.swift
//  Groupir
//
//  Created by Stanislas Chevallier on 28/10/2021.
//

import Foundation
import UIKit

extension UICollectionViewDiffableDataSource {
    func refreshItems(_ items: [ItemIdentifierType]) {
        var snapshot = self.snapshot()
        snapshot.reloadItems(items)
        apply(snapshot, animatingDifferences: true)
    }
}
