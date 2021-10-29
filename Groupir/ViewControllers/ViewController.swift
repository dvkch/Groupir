//
//  ViewController.swift
//  Groupir
//
//  Created by Stanislas Chevallier on 21/10/2021.
//

import UIKit
import Photos
import SnapKit
import SVProgressHUD
import BrightFutures
import QuickLook

class ViewController: UIViewController {

    // MARK: ViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Biggest", image: nil, primaryAction: nil, menu: nil)

        segmentControl.insertSegment(withTitle: "Events", at: 0, animated: false)
        segmentControl.insertSegment(withTitle: "Groups", at: 1, animated: false)
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
            view.addSubview(collectionView)
            collectionView.snp.makeConstraints { make in
                make.top.equalTo(segmentControl.snp.bottom).offset(8)
                make.left.right.bottom.equalToSuperview()
            }
        }
        
        eventsDataSource = .init(collectionView: eventsCollectionView, cellProvider: { collectionView, indexPath, itemIdentifier in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MediaCell", for: indexPath) as! MediaCell
            cell.media = itemIdentifier
            // TODO: actually hide remove cells if in meta group
            cell.reduceVisibilityIfInMetaGroup = true
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
            cell.reduceVisibilityIfInMetaGroup = false
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

        PHPhotoLibrary.shared().register(self)
        segmentControlChanged()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if eventsDataSource.snapshot().sectionIdentifiers.isEmpty {
            loadGroups()
        }
    }

    // MARK: Properties
    private var ignoreLibraryChanges: Bool = false
    private var eventsDataSource: UICollectionViewDiffableDataSource<Event, Media>!
    private var albumsDataSource: UICollectionViewDiffableDataSource<Album, Media>!

    // MARK: Views
    private let segmentControl = UISegmentedControl()
    private let eventsCollectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    private let albumsCollectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    private var visibleCollectionView: UICollectionView {
        return segmentControl.selectedSegmentIndex == 0 ? eventsCollectionView : albumsCollectionView
    }

    // MARK: Actions
    private func loadGroups() {
        SVProgressHUD.show()
        MediasManager.shared.reloadEvents(progress: { progress in
            SVProgressHUD.showProgress(progress)
        }).andThen { result in
            SVProgressHUD.dismiss()
        }.onFailure { error in
            let alert = UIAlertController(title: error.localizedDescription, message: nil, preferredStyle: .alert)
            error.recoveryOptions.enumerated().forEach { option in
                alert.addAction(UIAlertAction(title: option.element, style: .default, handler: { _ in _ = error.attemptRecovery(optionIndex: option.offset) }))
            }
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }

    @objc private func segmentControlChanged() {
        eventsCollectionView.isHidden = segmentControl.selectedSegmentIndex != 0
        albumsCollectionView.isHidden = segmentControl.selectedSegmentIndex != 1
    }

    private func scrollToEventGroup(_ group: Groupable) {
        let scrollFunction = { (collectionView: UICollectionView, section: Int) in
            let indexPath = IndexPath(item: 0, section: section)
            guard let attributes = collectionView.collectionViewLayout.layoutAttributesForSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, at: indexPath) else { return }
            collectionView.setContentOffset(CGPoint(x: 0, y: attributes.frame.origin.y - collectionView.adjustedContentInset.top), animated: true)
        }
        
        if let group = group as? Event, segmentControl.selectedSegmentIndex == 0, let index = eventsDataSource.snapshot().indexOfSection(group) {
            scrollFunction(eventsCollectionView, index)
        }
        if let group = group as? Album, segmentControl.selectedSegmentIndex == 1, let index = albumsDataSource.snapshot().indexOfSection(group) {
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
    
    private func add(medias: [Media], to group: Album) {
        guard let groupIndex = MediasManager.shared.albums.value.firstIndex(of: group) else {
            MediasManager.shared.albums.value.append(group)
            add(medias: medias, to: group)
            return
        }

        let mediasToAdd = medias.filter { !MediasManager.shared.isInMetaGroup(media: $0) }
        guard mediasToAdd.isNotEmpty else { return }
        
        MediasManager.shared.albums.value[groupIndex].add(medias: mediasToAdd)
    }
    
    private func share(medias: [Media]) {
        SVProgressHUD.show()
        
        medias
            .map { $0.obtainExportURL() }
            .sequence()
            .onSuccess { items in
                SVProgressHUD.dismiss()
                let shareVC = UIActivityViewController(activityItems: Array(items.joined()), applicationActivities: nil)
                self.present(shareVC, animated: true, completion: {  SVProgressHUD.dismiss() })
            }
    }
    
    private func delete(medias: [Media]) {
        ignoreLibraryChanges = true
        PHPhotoLibrary.shared().performChanges {
            let assets = medias.map(\.asset)
            PHAssetChangeRequest.deleteAssets(assets as NSArray)
        } completionHandler: { success, error in
            DispatchQueue.main.async {
                if success {
                    self.loadGroups()
                }
                else {
                    self.ignoreLibraryChanges = false
                }
            }
        }
    }
    
    // MARK: Content
    private func updateNavBar() {
        let groups: [Groupable]
        let biggestGroups: [Groupable]
        if segmentControl.selectedSegmentIndex == 0 {
            groups = eventsDataSource.snapshot().sectionIdentifiers
            biggestGroups = Array(eventsDataSource.snapshot().sectionIdentifiers.sorted().reversed().prefix(20))
        }
        else {
            groups = albumsDataSource.snapshot().sectionIdentifiers
            biggestGroups = Array(albumsDataSource.snapshot().sectionIdentifiers.sorted().reversed().prefix(20))
        }

        let actions: [UIMenuElement] = biggestGroups.map { group in
            UIAction(title: [group.title, group.details].joined(separator: "\n")) { [weak self] _ in
                self?.scrollToEventGroup(group)
            }
        }
        navigationItem.rightBarButtonItem?.menu = UIMenu(children: actions)
        title = Event(medias: Array(groups.map(\.medias).joined())).details
    }
}

extension ViewController: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        if !ignoreLibraryChanges {
            DispatchQueue.main.async {
                self.loadGroups()
            }
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

        // TODO: fix this
        print("GROUP", group)
        PrefsManager.shared.unlink(group: group)
        
        updatedGroups.remove(at: index)
        Event.group(medias: group.medias).reversed().forEach {
            print("ADDING NEW GROUP")
            updatedGroups.insert($0, at: index)
        }
        print("finished new groups")
        MediasManager.shared.events.value = updatedGroups
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
        return CGSize(width: availableWidth, height: 60)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
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
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let cell = collectionView.cellForItem(at: indexPath) as? MediaCell, let media = cell.media else { return nil }
        
        let actions = MediaAction.available(for: media).map { action in
            return UIAction(title: action.title, image: action.image) { [weak self] _ in
                switch action {
                case .addToAlbum:   self?.addMediasToGroup([media])
                case .share:        self?.share(medias: [media])
                case .delete:       self?.delete(medias: [media])
                }
            }
        }

        let actionProvider: UIContextMenuActionProvider = { _ in
            return UIMenu(title: media.filename, children: actions)
        }
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: actionProvider)
    }
}

