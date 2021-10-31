//
//  MediasViewController.swift
//  Groupir
//
//  Created by Stanislas Chevallier on 24/10/2021.
//

import UIKit
import QuickLook
import Photos

class MediasViewController: QLPreviewController {
    
    // MARK: ViewControllers
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        delegate = self
        currentPreviewItemIndex = initialIndex
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteCurrentItem))
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
    
    private var toolbar: UIToolbar? {
        return view.firstDescendant(of: UIToolbar.self, recursive: true, satisfying: { $0.items?.isNotEmpty == true })
    }
    
    // MARK: Actions
    @objc private func deleteCurrentItem() {
        let index = currentPreviewItemIndex
        guard index != NSNotFound, index < medias.count else { return }

        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets([self.medias[index].asset] as NSArray)
        }, completionHandler: { success, _ in
            DispatchQueue.main.async {
                if success {
                    if self.medias.count == 1 {
                        self.dismiss(animated: true, completion: nil)
                    }
                    else {
                        self.medias.remove(at: index)
                        while self.currentPreviewItemIndex >= self.medias.count {
                            self.currentPreviewItemIndex -= 1
                        }
                        self.reloadData()
                    }
                }
            }
        })
    }
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
