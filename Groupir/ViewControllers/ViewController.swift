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

class ViewController: UIViewController {

    // MARK: ViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Biggest", image: nil, primaryAction: nil, menu: nil)

        collectionViewLayout.scrollDirection = .vertical
        collectionViewLayout.itemSize = .init(width: 100, height: 100)
        collectionViewLayout.sectionInset.bottom = 50
        collectionViewLayout.minimumInteritemSpacing = 0
        collectionViewLayout.minimumLineSpacing = 0
        collectionView.backgroundColor = .systemBackground
        collectionView.register(MediaCell.self, forCellWithReuseIdentifier: "MediaCell")
        collectionView.register(GroupCell.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "GroupCell")
        collectionView.dataSource = self
        collectionView.delegate = self
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if groups.isEmpty {
            loadGroups()
        }
    }

    // MARK: Properties
    private var groups: [Group] = [] {
        didSet {
            let biggestGroups = groups.sorted().reversed().prefix(10)
            let actions: [UIMenuElement] = biggestGroups.map { group in
                UIAction(title: group.description) { [weak self] _ in
                    self?.scrollToGroup(group)
                }
            }
            navigationItem.rightBarButtonItem?.menu = UIMenu(children: actions)
        }
    }

    // MARK: Views
    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    private var collectionViewLayout: UICollectionViewFlowLayout {
        return collectionView.collectionViewLayout as! UICollectionViewFlowLayout
    }
    
    // MARK: Actions
    private func loadGroups() {
        SVProgressHUD.show()
        MediasManager.shared.groupedImages(progress: { progress in
            SVProgressHUD.showProgress(progress)
        }).andThen { result in
            SVProgressHUD.dismiss()
        }.onSuccess { groups in
            self.groups = groups
            self.collectionView.reloadData()
        }.onFailure { error in
            let alert = UIAlertController(title: error.localizedDescription, message: nil, preferredStyle: .alert)
            error.recoveryOptions.enumerated().forEach { option in
                alert.addAction(UIAlertAction(title: option.element, style: .default, handler: { _ in _ = error.attemptRecovery(optionIndex: option.offset) }))
            }
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    private func scrollToGroup(_ group: Group) {
        guard let index = groups.firstIndex(of: group) else { return }
        let indexPath = IndexPath(item: 0, section: index)
        guard let attributes = collectionViewLayout.layoutAttributesForSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, at: indexPath) else { return }
        collectionView.setContentOffset(CGPoint(x: 0, y: attributes.frame.origin.y - collectionView.adjustedContentInset.top), animated: true)
    }
}

extension ViewController: GroupCellDelegate {
    func groupCell(_ groupCell: GroupCell, tappedShareOn group: Group) {
        SVProgressHUD.show()
        
        group.medias
            .map { $0.obtainExportURL() }
            .sequence()
            .onSuccess { items in
                SVProgressHUD.dismiss()
                let shareVC = UIActivityViewController(activityItems: Array(items.joined()), applicationActivities: nil)
                shareVC.completionWithItemsHandler = { activityType, completed, _, activityError in
                    if let activityError = activityError {
                        print("Error:", activityError)
                    }
                }
                self.present(shareVC, animated: true, completion: {  SVProgressHUD.dismiss() })
            }
    }
    
    func groupCell(_ groupCell: GroupCell, tappedMergeWithPreviousOn group: Group) {
        guard let index = groups.firstIndex(of: group), index > 0 else { return }
        let prevGroup = groups[index - 1]

        collectionView.performBatchUpdates({
            let newGroup = Group(medias: prevGroup.medias + group.medias)
            groups.remove(at: index)
            groups.remove(at: index - 1)
            groups.insert(newGroup, at: index - 1)
            collectionView.reloadSections(IndexSet(integer: index - 1))
            collectionView.deleteSections(IndexSet(integer: index))
        }, completion: nil)
    }
    
    func groupCell(_ groupCell: GroupCell, tappedDeleteOn group: Group) {
        guard let index = groups.firstIndex(of: group) else { return }

        PHPhotoLibrary.shared().performChanges {
            let assets = group.medias.map(\.asset)
            PHAssetChangeRequest.deleteAssets(assets as NSArray)
        } completionHandler: { success, error in
            DispatchQueue.main.async {
                if success {
                    self.collectionView.performBatchUpdates({
                        self.groups.remove(at: index)
                        self.collectionView.deleteSections(IndexSet(integer: index))
                    }, completion: nil)
                }
            }
        }
    }
}

extension ViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return groups.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return groups[section].medias.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MediaCell", for: indexPath) as! MediaCell
        cell.media = groups[indexPath.section].medias[indexPath.item]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let cell = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "GroupCell", for: indexPath) as! GroupCell
        cell.group = groups[indexPath.section]
        cell.delegate = self
        return cell
    }
}

extension ViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let availableWidth = collectionView.bounds.inset(by: collectionView.adjustedContentInset).width
        let width = (availableWidth / CGFloat(5)).rounded(.down)
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let availableWidth = collectionView.bounds.inset(by: collectionView.adjustedContentInset).width
        return CGSize(width: availableWidth, height: 50)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let vc = MediaViewController()
        vc.media = groups[indexPath.section].medias[indexPath.item]
        present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
    }
}

