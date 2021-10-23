//
//  GroupCell.swift
//  Groupir
//
//  Created by Stanislas Chevallier on 21/10/2021.
//

import UIKit

protocol GroupCellDelegate: NSObjectProtocol {
    func groupCell(_ groupCell: GroupCell, tappedShareOn group: Group)
}

class GroupCell: UICollectionReusableView {
    
    // MARK: Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        label.textColor = .label
        addSubview(label)
        label.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(8)
            make.top.equalToSuperview().offset(8)
            make.centerY.equalToSuperview()
        }

        shareButton.setImage(UIImage(systemName: "ellipsis.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .bold)), for: .normal)
        shareButton.contentHorizontalAlignment = .trailing
        shareButton.addTarget(self, action: #selector(shareButtonTap), for: .primaryActionTriggered)
        shareButton.setContentHuggingPriority(.required, for: .horizontal)
        addSubview(shareButton)
        shareButton.snp.makeConstraints { make in
            make.left.equalTo(label.snp.right).offset(8)
            make.right.equalToSuperview().offset(-8)
            make.top.bottom.equalToSuperview()
            make.width.equalTo(shareButton.snp.height)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Properties
    weak var delegate: GroupCellDelegate?
    var group: Group? {
        didSet {
            updateContent()
        }
    }
    
    // MARK: Views
    private let label = UILabel()
    private let shareButton = UIButton(type: .custom)
    private let sizeFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter
    }()
    
    // MARK: Actions
    @objc private func shareButtonTap() {
        guard let group = group else { return }
        delegate?.groupCell(self, tappedShareOn: group)
    }
    
    // MARK: Content
    private func updateContent() {
        guard let group = group else { return }
        label.text = "\(group.medias.count) medias, \(sizeFormatter.string(fromByteCount: Int64(group.size)))"
    }
}
