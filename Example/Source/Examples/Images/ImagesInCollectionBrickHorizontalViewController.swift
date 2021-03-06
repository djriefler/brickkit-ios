//
//  ImagesInCollectionBrickHorizontalViewController.swift
//  BrickKit-Example
//
//  Created by Ruben Cagnie on 10/19/16.
//  Copyright © 2016 Wayfair LLC. All rights reserved.
//

import UIKit
import BrickKit

class ImagesInCollectionBrickHorizontalViewController: BrickViewController {

    override class var title: String {
        return "Horizontal Images in CollectionBrick"
    }
    override class var subTitle: String {
        return "Shows how to use images in a CollectionBrick"
    }

    let numberOfImages = 9

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .brickBackground

        registerBrickClass(CollectionBrick.self)

        let collectionSection = BrickSection(backgroundColor: .brickGray1, bricks: [
            ImageBrick(BrickIdentifiers.repeatLabel, dataSource: self),
            ], inset: 10, edgeInsets: UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5))
        collectionSection.repeatCountDataSource = self

        let section = BrickSection(bricks: [
            CollectionBrick(scrollDirection: .Horizontal, dataSource: CollectionBrickCellModel(section: collectionSection, configureHandler: { (cell) in
                cell.brickCollectionView.registerBrickClass(ImageBrick.self)
            }))
            ])

        self.setSection(section)
    }

}

extension ImagesInCollectionBrickHorizontalViewController: BrickRepeatCountDataSource {

    func repeatCount(for identifier: String, with collectionIndex: Int, collectionIdentifier: String) -> Int {
        if identifier == BrickIdentifiers.repeatLabel {
            return numberOfImages
        } else {
            return 1
        }
    }

}

extension ImagesInCollectionBrickHorizontalViewController: ImageBrickDataSource {
    func imageForImageBrickCell(cell: ImageBrickCell) -> UIImage? {
        return UIImage(named: "image\(cell.index)")
    }

    func contentModeForImageBrickCell(imageBrickCell: ImageBrickCell) -> UIViewContentMode {
        return .ScaleAspectFill
    }
}
