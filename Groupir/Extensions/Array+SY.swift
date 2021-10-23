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
