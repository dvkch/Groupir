//
//  PHFetchResult+SY.swift
//  Groupir
//
//  Created by syan on 22/07/2025.
//

import Photos

extension Array where Element: AnyObject {
    static func forResults(_ fetchResult: PHFetchResult<Element>, filter: ((Element) -> Bool)? = nil) -> [Element] {
        var elements = Self()
        elements.reserveCapacity(fetchResult.count)
        fetchResult.enumerateObjects { object, _, _ in
            if filter?(object) != false {
                elements.append(object)
            }
        }
        return elements
    }
}
