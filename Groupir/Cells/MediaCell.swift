//
//  MediaCell.swift
//  Groupir
//
//  Created by Stanislas Chevallier on 21/10/2021.
//

import UIKit
import Photos

class MediaCell: UICollectionViewCell {
    
    // MARK: Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.minificationFilter = .trilinear
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        kindImageView.tintColor = .label
        kindImageView.contentMode = .scaleAspectFit
        kindImageView.layer.shadowColor = UIColor.systemBackground.cgColor
        kindImageView.layer.shadowOffset = .zero
        kindImageView.layer.shadowOpacity = 0.8
        kindImageView.layer.shadowRadius = 1
        contentView.addSubview(kindImageView)
        kindImageView.snp.makeConstraints { make in
            make.size.equalToSuperview().multipliedBy(0.3)
            make.bottom.left.equalToSuperview().offset(4)
        }
        
        selectionOverlayView.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.4)
        contentView.addSubview(selectionOverlayView)
        selectionOverlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        selectionImageView.image = UIImage(systemName: "checkmark.circle", withConfiguration: UIImage.SymbolConfiguration(weight: UIImage.SymbolWeight.bold))
        selectionImageView.backgroundColor = .systemPurple
        selectionImageView.tintColor = .white
        contentView.addSubview(selectionImageView)
        selectionImageView.snp.makeConstraints { make in
            make.size.equalToSuperview().multipliedBy(0.3)
            make.bottom.right.equalToSuperview().offset(-4)
        }
        
        updateSelection()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Properties
    var media: Media? {
        didSet {
            updateContent()
        }
    }
    private var mediaRequestID: PHImageRequestID?
    
    override var isSelected: Bool {
        didSet {
            updateSelection()
        }
    }
    
    // MARK: Views
    private let imageView = UIImageView()
    private let kindImageView = UIImageView()
    private let selectionOverlayView = UIView()
    private let selectionImageView = UIImageView()
    
    // MARK: Content
    override func prepareForReuse() {
        super.prepareForReuse()
        media = nil
        if let mediaRequestID = mediaRequestID {
            PHImageManager.default().cancelImageRequest(mediaRequestID)
        }
        mediaRequestID = nil
        updateSelection()
    }
    
    private func updateContent() {
        guard let media = media else { return }

        switch media.asset.mediaType {
        case .image:
            kindImageView.image = nil
            kindImageView.layer.shadowColor = nil
        case .video:
            kindImageView.image = UIImage(systemName: "play.rectangle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: UIImage.SymbolWeight.bold))
            kindImageView.layer.shadowColor = UIColor.systemBackground.cgColor
        case .audio:
            kindImageView.image = UIImage(systemName: "waveform", withConfiguration: UIImage.SymbolConfiguration(weight: UIImage.SymbolWeight.bold))
            kindImageView.layer.shadowColor = UIColor.systemBackground.cgColor
        case .unknown:
            kindImageView.image = UIImage(systemName: "questionmark.folder", withConfiguration: UIImage.SymbolConfiguration(weight: UIImage.SymbolWeight.bold))
            kindImageView.layer.shadowColor = UIColor.systemBackground.cgColor
        @unknown default:
            kindImageView.image = UIImage(systemName: "questionmark.folder", withConfiguration: UIImage.SymbolConfiguration(weight: UIImage.SymbolWeight.bold))
            kindImageView.layer.shadowColor = UIColor.systemBackground.cgColor
        }
        updateImage()
    }
    
    private func updateImage() {
        guard let media = media else {
            imageView.image = nil
            return
        }
       
        let options = PHImageRequestOptions()
        options.version = .current
        options.isNetworkAccessAllowed = false
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        
        let size = CGSize(width: imageView.bounds.width * UIScreen.main.scale, height: imageView.bounds.height * UIScreen.main.scale)
        mediaRequestID = PHImageManager.default().requestImage(for: media.asset, targetSize: size, contentMode: .aspectFill, options: options) { [weak self] (image, _) in
            guard self?.media == media else { return }
            self?.imageView.image = image
        }
    }
    
    private var previousSize: CGSize = .zero
    override func layoutSubviews() {
        super.layoutSubviews()
        if previousSize != bounds.size {
            previousSize = bounds.size
            updateImage()
        }
        
        contentView.layoutIfNeeded()
        selectionImageView.layer.cornerRadius = selectionImageView.bounds.width / 2
    }
    
    private func updateSelection() {
        selectionImageView.isHidden = !isSelected
        selectionOverlayView.isHidden = !isSelected
    }
}
