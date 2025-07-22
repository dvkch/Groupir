//
//  MediaPreviewViewController.swift
//  Groupir
//
//  Created by syan on 23/07/2025.
//

import UIKit
import Photos
import SnapKit

class MediaPreviewViewController: UIViewController {
    
    // MARK: ViewController
    init(media: Media) {
        self.media = media
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        view.contentMode = .scaleAspectFit
        view.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        updateImage()
    }

    // MARK: Properties
    let media: Media
    
    // MARK: Views
    private let imageView: UIImageView = UIImageView()
    
    // MARK: Content
    private func updateImage() {
        let options = PHImageRequestOptions()
        options.version = .current
        options.isNetworkAccessAllowed = false
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        
        let size = CGSize(width: imageView.bounds.width * UIScreen.main.scale, height: imageView.bounds.height * UIScreen.main.scale)
        PHImageManager.default().requestImage(for: media.asset, targetSize: size, contentMode: .aspectFit, options: options) { [weak self] (image, _) in
            self?.imageView.contentMode = .scaleAspectFit
            self?.imageView.image = image
        }
    }
}
