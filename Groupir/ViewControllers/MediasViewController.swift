//
//  MediasViewController.swift
//  Groupir
//
//  Created by Stanislas Chevallier on 24/10/2021.
//

import UIKit
import QuickLook

class MediasViewController: QLPreviewController {
    
    // MARK: ViewControllers
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        delegate = self
        currentPreviewItemIndex = initialIndex
    }
    
    // MARK: Properties
    var initialIndex: Int = 0
    var medias: [Media] = [] {
        didSet {
            reloadData()
        }
    }
    var animationViews: [Media: UIView] = [:]
    private var previewItems: [Media: MediaPreviewItem] = [:]
}

extension MediasViewController: QLPreviewControllerDataSource {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return medias.count
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        let media = medias[index]
        let previewItem = previewItems[media] ?? media.mediaPreviewItem
        previewItems[media] = previewItem
        return previewItem
    }
}

extension MediasViewController: QLPreviewControllerDelegate {
    func previewController(_ controller: QLPreviewController, transitionViewFor item: QLPreviewItem) -> UIView? {
        return animationViews[(item as! MediaPreviewItem).media]
    }
}
