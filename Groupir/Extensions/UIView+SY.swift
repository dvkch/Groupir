//
//  UIView+SY.swift
//  Groupir
//
//  Created by Stanislas Chevallier on 31/10/2021.
//

import UIKit

extension UIView {
    func firstDescendant<T: UIView>(of kind: T.Type, recursive: Bool, satisfying filter: ((T) -> Bool)? = nil) -> T? {
        var subviews = self.subviews.compactMap({ $0 as? T })
        if let filter = filter {
            subviews = subviews.filter(filter)
        }
        if let subview = subviews.first {
            return subview
        }

        if recursive {
            return self.subviews.compactMap { $0.firstDescendant(of: T.self, recursive: recursive, satisfying: filter) }.first
        }
        return nil
    }
}
