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

class ViewController: UIViewController {

    // MARK: ViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Biggest", style: .plain, target: self, action: #selector(scrollToBiggest))
        
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
        if loadResult == nil {
            self.loadGroups()
        }
    }

    // MARK: Properties
    private var loadResult: Result<[Group], AppError>? {
        didSet {
            if case .success(let groups) = loadResult {
                self.groups = groups
            }
            else {
                self.groups = []
            }
        }
    }
    private var groups: [Group] = [] {
        didSet {
            collectionView.reloadData()
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
            self.loadResult = result
            SVProgressHUD.dismiss()
        }.onFailure { error in
            let alert = UIAlertController(title: error.localizedDescription, message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @objc private func scrollToBiggest() {
        guard let biggest = groups.enumerated().max(by: { $0.element.size < $1.element.size })?.offset else { return }
        guard let attributes = collectionViewLayout.layoutAttributesForSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: biggest)) else { return }
        collectionView.setContentOffset(CGPoint(x: 0, y: attributes.frame.origin.y - collectionView.adjustedContentInset.top), animated: true)
    }

    // MARK: Content
}

extension ViewController: GroupCellDelegate {
    func groupCell(_ groupCell: GroupCell, tappedShareOn group: Group) {
        let shareVC = UIActivityViewController(activityItems: group.medias.map(\.asset), applicationActivities: nil)
        present(shareVC, animated: true, completion: nil)
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

