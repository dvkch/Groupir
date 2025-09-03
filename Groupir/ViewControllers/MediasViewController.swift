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
    required init(medias: [Media], initialIndex: Int) {
        self.medias = medias
        super.init(nibName: nil, bundle: nil)
        dataSource = self
        delegate = self
        currentPreviewItemIndex = initialIndex
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteCurrentItem))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Properties
    private(set) var medias: [Media] {
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
                        if index == self.medias.count - 1 {
                            self.currentPreviewItemIndex -= 1
                        }
                        self.medias.remove(at: index)
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
