//
//  NSDiffableDataSourceSnapshot+SY.swift
//  Groupir
//
//  Created by Stanislas Chevallier on 28/10/2021.
//

import Foundation
import UIKit

extension NSDiffableDataSourceSnapshot where SectionIdentifierType: Group, ItemIdentifierType == Media {
    init(_ sections: [SectionIdentifierType]) {
        self.init()
        appendSections(sections)
        sections.forEach { appendItems($0.medias, toSection: $0) }
    }
}
