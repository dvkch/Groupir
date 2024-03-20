//
//  ViewController.swift
//  Groupir
//
//  Created by Stanislas Chevallier on 21/10/2021.
//

import UIKit
import Photos
import SnapKit
import BrightFutures
import QuickLook
import SYKit

class ViewController: UIViewController {

    // MARK: ViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        restorationIdentifier = "ViewController"
        
        selectionButtonItem = .init(image: UIImage(systemName: "checkmark.rectangle"), style: .plain, target: self, action: #selector(editButtonTap))
        navigationItem.leftBarButtonItem = selectionButtonItem
        
        selectionActionsButtonItem = .init(image: UIImage(systemName: "arrowshape.turn.up.forward"), primaryAction: nil, menu: nil)
        quickJumpButtonItem = .init(image: UIImage(systemName: "filemenu.and.selection"), primaryAction: nil, menu: nil)

        segmentControl.insertSegment(withTitle: "Events", at: 0, animated: false)
        segmentControl.insertSegment(withTitle: "Albums", at: 1, animated: false)
        segmentControl.selectedSegmentIndex = 0
        segmentControl.addTarget(self, action: #selector(segmentControlChanged), for: .valueChanged)
        view.addSubview(segmentControl)
        segmentControl.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.left.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.right.equalTo(view.safeAreaLayoutGuide).offset(-8)
        }

        for collectionView in [eventsCollectionView, albumsCollectionView] {
            let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
            layout.scrollDirection = .vertical
            layout.sectionInset.bottom = 30
            layout.minimumInteritemSpacing = 0
            layout.minimumLineSpacing = 0
            collectionView.backgroundColor = .systemBackground
            collectionView.register(MediaCell.self, forCellWithReuseIdentifier: "MediaCell")
            collectionView.register(GroupCell.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "GroupCell")
            collectionView.delegate = self
            collectionView.allowsSelectionDuringEditing = true
            collectionView.allowsMultipleSelectionDuringEditing = true
            view.addSubview(collectionView)
            collectionView.snp.makeConstraints { make in
                make.top.equalTo(segmentControl.snp.bottom).offset(8)
                make.left.right.bottom.equalToSuperview()
            }
        }
        
        eventsDataSource = .init(collectionView: eventsCollectionView, cellProvider: { collectionView, indexPath, itemIdentifier in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MediaCell", for: indexPath) as! MediaCell
            cell.media = itemIdentifier
            return cell
        })
        eventsDataSource.setSectionHeaderProvider { collectionView, section, indexPath in
            let cell = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "GroupCell", for: indexPath) as! GroupCell
            cell.group = section
            cell.delegate = self
            return cell
        }
        
        albumsDataSource = .init(collectionView: albumsCollectionView, cellProvider: { collectionView, indexPath, itemIdentifier in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MediaCell", for: indexPath) as! MediaCell
            cell.media = itemIdentifier
            return cell
        })
        albumsDataSource.setSectionHeaderProvider { collectionView, section, indexPath in
            let cell = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "GroupCell", for: indexPath) as! GroupCell
            cell.group = section
            cell.delegate = self
            return cell
        }

        MediasManager.shared.events.addObserver(ref: self, callNow: true) { _, new in
            self.eventsDataSource.apply(.init(new))
            self.updateNavBar()
        }
        MediasManager.shared.albums.addObserver(ref: self, callNow: true) { _, new in
            self.albumsDataSource.apply(.init(new))
            self.updateNavBar()
        }

        segmentControlChanged()
        isEditing = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if eventsDataSource.snapshot().sectionIdentifiers.isEmpty {
            loadGroups()
        }
    }
    
    // MARK: Restoration
    func updateUserActivity() {
        let currentUserActivity = view.window?.windowScene?.userActivity ?? NSUserActivity(activityType: SceneDelegate.defaultActivityType)
        currentUserActivity.addUserInfoEntries(from: ["selected_segment": segmentControl.selectedSegmentIndex])

        if let topVisibleEventMedia = eventsCollectionView.visibleCells.compactMap({ ($0 as? MediaCell)?.media }).sorted().first {
            currentUserActivity.addUserInfoEntries(from: ["top_event_media_date": topVisibleEventMedia.date])
        }
        if let topVisibleAlbumMedia = albumsCollectionView.visibleCells.compactMap({ ($0 as? MediaCell)?.media }).first,
           let section = albumsDataSource.snapshot().sectionIdentifier(containingItem: topVisibleAlbumMedia)
        {
            currentUserActivity.addUserInfoEntries(from: ["top_album_unique_id": section.uniqueID])
        }
        view.window?.windowScene?.userActivity = currentUserActivity
    }

    func continueFrom(activity: NSUserActivity) {
        segmentControl.selectedSegmentIndex = (activity.userInfo?["selected_segment"] as? Int) ?? 0
        let topVisibleEventDate = (activity.userInfo?["top_event_media_date"] as? Date)
        let topVisibleAlbumUniqueID = (activity.userInfo?["top_album_unique_id"] as? String)

        loadGroups {
            if let date = topVisibleEventDate,
                let media = MediasManager.shared.medias.first(where: { $0.date >= date }),
               let section = self.eventsDataSource.snapshot().sectionIdentifier(containingItem: media)
            {
                self.scrollTo(section, animated: false)
            }
            if let uniqueID = topVisibleAlbumUniqueID, let album = MediasManager.shared.albums.value.first(where: { $0.uniqueID == uniqueID }) {
                self.scrollTo(album, animated: false)
            }
        }
    }
    
    // MARK: Properties
    private var eventsDataSource: UICollectionViewDiffableDataSource<Event, Media>!
    private var albumsDataSource: UICollectionViewDiffableDataSource<Album, Media>!

    // MARK: Views
    private var selectionButtonItem = UIBarButtonItem()
    private var selectionActionsButtonItem = UIBarButtonItem()
    private var quickJumpButtonItem = UIBarButtonItem()
    private let segmentControl = UISegmentedControl()
    private let eventsCollectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    private let albumsCollectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    private var visibleCollectionView: UICollectionView {
        return segmentControl.selectedSegmentIndex == 0 ? eventsCollectionView : albumsCollectionView
    }

    // MARK: Actions
    override var isEditing: Bool {
        didSet {
            [eventsCollectionView, albumsCollectionView].forEach { $0.isEditing = isEditing }
            updateNavBar()
        }
    }

    @objc func editButtonTap() {
        isEditing = !isEditing
    }
    
    private func loadGroups(_ success: (() -> ())? = nil) {
        let hud = HUDAlertController.show(in: self)
        MediasManager.shared
            .reloadEvents(progress: { progress in 
                hud.progress = progress
            })
            .onSuccess { _ in 
                hud.dismiss(animated: true)
                success?()
            }
            .onFailure { error in
                let alert = UIAlertController(title: error.localizedDescription, message: nil, preferredStyle: .alert)
                error.recoveryOptions.enumerated().forEach { option in
                    alert.addAction(UIAlertAction(title: option.element, style: .default, handler: { _ in _ = error.attemptRecovery(optionIndex: option.offset) }))
                }
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, afterDismissing: hud, animated: true, completion: nil)
            }
    }

    @objc private func segmentControlChanged() {
        isEditing = false
        eventsCollectionView.isHidden = segmentControl.selectedSegmentIndex != 0
        albumsCollectionView.isHidden = segmentControl.selectedSegmentIndex != 1
    }

    private func scrollTo(_ group: Groupable, animated: Bool) {
        let scrollFunction = { (collectionView: UICollectionView, section: Int) in
            let indexPath = IndexPath(item: 0, section: section)
            guard let attributes = collectionView.collectionViewLayout.layoutAttributesForSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, at: indexPath) else { return }
            collectionView.setContentOffset(CGPoint(x: 0, y: attributes.frame.origin.y - collectionView.adjustedContentInset.top), animated: animated)
        }
        
        if let group = group as? Event, let index = eventsDataSource.snapshot().indexOfSection(group) {
            scrollFunction(eventsCollectionView, index)
        }
        if let group = group as? Album, let index = albumsDataSource.snapshot().indexOfSection(group) {
            scrollFunction(albumsCollectionView, index)
        }
    }
    
    private func addMediasToGroup(_ medias: [Media]) {
        let vc = UIAlertController(title: "Which group?", message: nil, preferredStyle: .actionSheet)
        MediasManager.shared.albums.value.forEach { group in
            vc.addAction(UIAlertAction(title: group.title, style: .default, handler: { _ in
                self.add(medias: medias, to: group)
            }))
        }
        vc.addAction(UIAlertAction(title: "New group...", style: .default, handler: { _ in
            let newGroupVC = UIAlertController(title: "Enter a group name", message: nil, preferredStyle: .alert)
            newGroupVC.addTextField { field in
                field.placeholder = "Name"
            }
            newGroupVC.addAction(UIAlertAction(title: "Create", style: .default, handler: { _ in
                let group = Album(title: newGroupVC.textFields?.first?.text ?? "Group")
                self.add(medias: medias, to: group)
            }))
            newGroupVC.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(newGroupVC, animated: true, completion: nil)
        }))
        vc.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(vc, animated: true, completion: nil)
    }
    
    private func add(medias: [Media], to album: Album) {
        MediasManager.shared.addMedias(medias, to: album)
    }
    
    private func removeMediasFromAlbums(_ medias: [Media]) {
        MediasManager.shared.removeMediasFromAlbums(medias)
    }
    
    private func share(medias: [Media]) {
        let hud = HUDAlertController.show(in: self)

        medias
            .map { $0.obtainExportURL() }
            .sequence()
            .onSuccess { items in
                let shareVC = UIActivityViewController(
                    activityItems: Array(items.joined()).compactMap(\.sharingURL),
                    applicationActivities: nil
                )
                shareVC.completionWithItemsHandler = { _, _, _, _ in
                    _ = items // let's keep a ref around around until sharing is done, or the files will disappear
                }
                self.present(shareVC, afterDismissing: hud, animated: true)
            }
    }
    
    private func delete(medias: [Media]) {
        var hud: HUDAlertController? = nil
        if medias.count > 10 {
            hud = HUDAlertController.show(in: self)
        }

        PHPhotoLibrary.shared().performChanges({
            let assets = medias.map(\.asset)
            PHAssetChangeRequest.deleteAssets(assets as NSArray)
        }, completionHandler: { _, _ in
            DispatchQueue.main.async {
                HUDAlertController.dismiss(hud)
            }
        })
    }
    
    // MARK: Content
    private var visibleGroups: [Groupable] {
        let groups: [Groupable]
        if segmentControl.selectedSegmentIndex == 0 {
            let snapshot = eventsDataSource.snapshot()
            groups = snapshot.sectionIdentifiers
        }
        else {
            let snapshot = albumsDataSource.snapshot()
            groups = snapshot.sectionIdentifiers
        }
        return groups
    }
    
    private var selectedMedias: [Media] {
        let selectedMedias: [Media]
        if segmentControl.selectedSegmentIndex == 0 {
            let snapshot = eventsDataSource.snapshot()
            selectedMedias = eventsCollectionView.indexPathsForSelectedItems?.map {
                let section = snapshot.sectionIdentifiers[$0.section]
                return snapshot.itemIdentifiers(inSection: section)[$0.item]
            } ?? []
        }
        else {
            let snapshot = albumsDataSource.snapshot()
            selectedMedias = albumsCollectionView.indexPathsForSelectedItems?.map {
                let section = snapshot.sectionIdentifiers[$0.section]
                return snapshot.itemIdentifiers(inSection: section)[$0.item]
            } ?? []
        }
        return selectedMedias
    }

    private func updateNavBar() {
        if isEditing {
            let selectedMedias = self.selectedMedias
            title = Event(medias: selectedMedias).details
            selectionButtonItem.image = UIImage(systemName: "checkmark.rectangle")
            navigationItem.rightBarButtonItem = selectionActionsButtonItem
            let actions = MediaAction.available(for: selectedMedias).map { action in
                return UIAction(title: action.title, image: action.image) { [weak self] _ in
                    switch action {
                    case .addToAlbum:       self?.addMediasToGroup(selectedMedias)
                    case .removeFromAlbum:  self?.removeMediasFromAlbums(selectedMedias)
                    case .share:            self?.share(medias: selectedMedias)
                    case .delete:           self?.delete(medias: selectedMedias)
                    }
                    self?.isEditing = false
                }
            }
            selectionActionsButtonItem.menu = UIMenu(children: actions)
        }
        else {
            let groups = self.visibleGroups
            let biggestGroups = Array(groups.sorted(by: { $0.size > $1.size }).prefix(20))

            title = Event(medias: Array(groups.map(\.medias).joined())).details
            selectionButtonItem.image = UIImage(systemName: "rectangle")
            navigationItem.rightBarButtonItem = quickJumpButtonItem
            let actions: [UIMenuElement] = biggestGroups.map { group in
                UIAction(title: [group.title, group.details].joined(separator: "\n")) { [weak self] _ in
                    self?.scrollTo(group, animated: true)
                }
            }
            quickJumpButtonItem.menu = UIMenu(children: actions)
        }
    }
}

extension ViewController: GroupCellDelegate {
    func groupCell(_ groupCell: GroupCell, tappedShareOn group: Groupable) {
        share(medias: group.medias)
    }
    
    func groupCell(_ groupCell: GroupCell, tappedMergeWithPreviousOn group: Event) {
        var updatedGroups = MediasManager.shared.events.value
        guard let index = updatedGroups.firstIndex(of: group), index > 0 else { return }

        updatedGroups[index - 1].merge(withNextGroup: updatedGroups[index])
        updatedGroups.remove(at: index)
        MediasManager.shared.events.value = updatedGroups
    }
    
    func groupCell(_ groupCell: GroupCell, tappedResplitOn group: Event) {
        var updatedGroups = MediasManager.shared.events.value
        guard let index = updatedGroups.firstIndex(of: group) else { return }

        PrefsManager.shared.unlink(group: updatedGroups[index])
        
        let mediasToRegroup = updatedGroups[index].medias
        updatedGroups.remove(at: index)
        Event.group(medias: mediasToRegroup).reversed().forEach {
            updatedGroups.insert($0, at: index)
        }
        MediasManager.shared.events.value = updatedGroups
    }
    
    func groupCell(_ groupCell: GroupCell, tappedRemoveGroup group: Album) {
        removeMediasFromAlbums(group.medias)
    }
    
    func groupCell(_ groupCell: GroupCell, tappedAddToGroupOn group: Event) {
        addMediasToGroup(group.medias)
    }
    
    func groupCell(_ groupCell: GroupCell, tappedDeleteOn group: Groupable) {
        delete(medias: group.medias)
    }
}

extension ViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let availableWidth = collectionView.bounds.inset(by: collectionView.adjustedContentInset).width
        let itemsCount = (availableWidth / 70).rounded(.down)
        let width = (availableWidth / itemsCount).rounded(.down)
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let availableWidth = collectionView.bounds.inset(by: collectionView.adjustedContentInset).width
        return CGSize(width: availableWidth, height: 50)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard !isEditing else {
            updateNavBar()
            return
        }
        
        collectionView.deselectItem(at: indexPath, animated: false)
        
        let medias: [Media]
        if segmentControl.selectedSegmentIndex == 0 {
            let section = eventsDataSource.snapshot().sectionIdentifiers[indexPath.section]
            medias = section.medias
        }
        else {
            let section = albumsDataSource.snapshot().sectionIdentifiers[indexPath.section]
            medias = section.medias
        }
        guard medias.isNotEmpty else { return }

        let vc = MediasViewController()
        vc.medias = medias
        vc.initialIndex = indexPath.item
        vc.animationViews = collectionView.visibleCells
            .compactMap { $0 as? MediaCell }
            .filter { $0.media != nil }
            .reduce(into: [:], { $0[$1.media!] = $1 })
        present(vc, animated: true, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if isEditing {
            updateNavBar()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let cell = collectionView.cellForItem(at: indexPath) as? MediaCell, let media = cell.media else { return nil }
        
        let actions = MediaAction.available(for: media).map { action in
            return UIAction(title: action.title, image: action.image) { [weak self] _ in
                switch action {
                case .addToAlbum:       self?.addMediasToGroup([media])
                case .removeFromAlbum:  self?.removeMediasFromAlbums([media])
                case .share:            self?.share(medias: [media])
                case .delete:           self?.delete(medias: [media])
                }
            }
        }

        let actionProvider: UIContextMenuActionProvider = { _ in
            return UIMenu(title: media.filename, children: actions)
        }
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: actionProvider)
    }
}
