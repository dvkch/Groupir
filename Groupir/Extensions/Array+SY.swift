//
//  Array+SY.swift
//  Groupir
//
//  Created by Stanislas Chevallier on 21/10/2021.
//

import Foundation

extension Array {
    func forEachWithPrevious(closure: (Element, Element?) -> ()) {
        let offsetedCollection: [Element?] = [nil] + Array(self.dropLast())
        zip(self, offsetedCollection).forEach {
            closure($0.0, $0.1)
        }
    }
}

extension Collection {
    var isNotEmpty: Bool {
        return !isEmpty
    }
}

extension EnumeratedSequence where Base.Element: Comparable {
    func sorted() -> [Iterator.Element] {
        return sorted(by: { $0.element < $1.element })
    }
    
    func min() -> Iterator.Element? {
        return self.min(by: { $0.element < $1.element })
    }

    func max() -> Iterator.Element? {
        return self.max(by: { $0.element < $1.element })
    }
}
