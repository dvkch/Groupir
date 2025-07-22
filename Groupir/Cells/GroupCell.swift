//
//  GroupCell.swift
//  Groupir
//
//  Created by Stanislas Chevallier on 21/10/2021.
//

import UIKit

protocol GroupCellDelegate: NSObjectProtocol {
    func groupCell(_ groupCell: GroupCell, tappedShareOn group: Groupable, sender: UIView)
    func groupCell(_ groupCell: GroupCell, tappedMergeWithPreviousOn group: Event)
    func groupCell(_ groupCell: GroupCell, tappedResplitOn group: Event)
    func groupCell(_ groupCell: GroupCell, tappedAddToGroupOn group: Event)
    func groupCell(_ groupCell: GroupCell, tappedRemoveGroup group: Album)
    func groupCell(_ groupCell: GroupCell, tappedDeleteOn group: Groupable)
}

class GroupCell: UICollectionReusableView {
    
    // MARK: Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 8
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        label.textColor = .label
        label.numberOfLines = 0
        addSubview(label)
        label.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(8)
            make.top.equalToSuperview().offset(8)
            make.centerY.equalToSuperview()
        }

        shareButton.setImage(UIImage(systemName: "ellipsis.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .bold)), for: .normal)
        shareButton.contentHorizontalAlignment = .trailing
        shareButton.setContentHuggingPriority(.required, for: .horizontal)
        shareButton.showsMenuAsPrimaryAction = true
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
    var group: Groupable? {
        didSet {
            updateContent()
        }
    }
    
    // MARK: Views
    private let label = UILabel()
    private let shareButton = UIButton(type: .custom)
    
    // MARK: Content
    private func updateContent() {
        guard let group = group else { return }
        label.text = [group.title, group.details].joined(separator: ", ")
        
        let actions = GroupAction.available(for: group).map { action in
            UIAction(title: action.title, image: action.image) { [weak self] _ in
                guard let self = self, let group = self.group else { return }
                switch action {
                case .mergeWithPrevious:    self.delegate?.groupCell(self, tappedMergeWithPreviousOn: group as! Event)
                case .splitByDate:          self.delegate?.groupCell(self, tappedResplitOn: group as! Event)
                case .addToAlbum:           self.delegate?.groupCell(self, tappedAddToGroupOn: group as! Event)
                case .removeAlbum:          self.delegate?.groupCell(self, tappedRemoveGroup: group as! Album)
                case .share:                self.delegate?.groupCell(self, tappedShareOn: group, sender: shareButton)
                case .delete:               self.delegate?.groupCell(self, tappedDeleteOn: group)
                }
            }
        }
        shareButton.menu = UIMenu(children: actions)
    }
}
