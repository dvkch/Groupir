//
//  MediaViewController.swift
//  Groupir
//
//  Created by Stanislas Chevallier on 22/10/2021.
//

import UIKit
import Photos
import AVKit
import SVProgressHUD

class MediaViewController: UIViewController {
    
    // MARK: ViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(weight: .bold)),
            style: .plain, target: self, action: #selector(closeButtonTap)
        )
        
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        view.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        playerView.allowsPictureInPicturePlayback = false
        playerView.entersFullScreenWhenPlaybackBegins = false
        playerView.view.isHidden = true
        playerView.willMove(toParent: self)
        view.addSubview(playerView.view)
        playerView.view.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        playerView.didMove(toParent: self)
        
        updateContent()
    }
    
    // MARK: Properties
    var media: Media?
    
    // MARK: Views
    private let imageView = UIImageView()
    private let playerView = AVPlayerViewController()
    
    // MARK: Actions
    @objc private func closeButtonTap() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: Content
    private func updateContent(forceImage: Bool = false) {
        guard let media = media else { return }
        
        title = PHAssetResource.assetResources(for: media.asset).first?.originalFilename

        SVProgressHUD.show()

        if !forceImage && [.video, .audio].contains(media.asset.mediaType) {
            let options = PHVideoRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            PHImageManager.default().requestAVAsset(forVideo: media.asset, options: options) { [weak self] (asset, audioMix, info) in
                DispatchQueue.main.async {
                    SVProgressHUD.dismiss()
                    if let asset = asset {
                        self?.playerView.view.isHidden = false
                        self?.playerView.player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
                    }
                    else {
                        self?.updateContent(forceImage: true)
                    }
                }
            }
        }
        else {
            PHImageManager.default().requestImage(for: media.asset, targetSize: view.bounds.size, contentMode: .aspectFit, options: nil) { [weak self] (image, _) in
                SVProgressHUD.dismiss()
                guard self?.media == media else { return }
                self?.imageView.isHidden = false
                self?.imageView.image = image
            }
        }
    }
}
