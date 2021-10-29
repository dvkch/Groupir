//
//  GroupCell.swift
//  Groupir
//
//  Created by Stanislas Chevallier on 21/10/2021.
//

import UIKit

protocol GroupCellDelegate: NSObjectProtocol {
    func groupCell(_ groupCell: GroupCell, tappedShareOn group: Groupable)
    func groupCell(_ groupCell: GroupCell, tappedMergeWithPreviousOn group: Event)
    func groupCell(_ groupCell: GroupCell, tappedResplitOn group: Event)
    func groupCell(_ groupCell: GroupCell, tappedAddToGroupOn group: Event)
    func groupCell(_ groupCell: GroupCell, tappedDeleteOn group: Groupable)
}

class GroupCell: UICollectionReusableView {
    
    // MARK: Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        
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
        
        var actions = [UIAction]()
        actions.append(UIAction(title: "Share", image: UIImage(systemName: "square.and.arrow.up")) { [weak self] _ in
            guard let self = self, let group = self.group else { return }
            self.delegate?.groupCell(self, tappedShareOn: group)
        })
        
        if let eventGroup = group as? Event {
            actions.append(UIAction(title: "Merge with previous group", image: UIImage(systemName: "arrow.triangle.merge")) { [weak self] _ in
                guard let self = self else { return }
                self.delegate?.groupCell(self, tappedMergeWithPreviousOn: eventGroup)
            })
            actions.append(UIAction(title: "Split by date", image: UIImage(systemName: "arrow.triangle.branch")) { [weak self] _ in
                guard let self = self else { return }
                self.delegate?.groupCell(self, tappedResplitOn: eventGroup)
            })
            actions.append(UIAction(title: "Add all to group", image: UIImage(systemName: "folder")) { [weak self] _ in
                guard let self = self else { return }
                self.delegate?.groupCell(self, tappedAddToGroupOn: eventGroup)
            })
        }
        
        actions.append(UIAction(title: "Delete", image: UIImage(systemName: "trash")) { [weak self] _ in
            guard let self = self, let group = self.group else { return }
            self.delegate?.groupCell(self, tappedDeleteOn: group)
        })
        shareButton.menu = UIMenu(children: actions)
    }
}
