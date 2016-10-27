//
//  LazyLoadingTests.swift
//  BrickKit
//
//  Created by Ruben Cagnie on 10/26/16.
//  Copyright © 2016 Wayfair. All rights reserved.
//

import XCTest
@testable import BrickKit

class LazyLoadingTests: XCTestCase {
    let BrickIdentifier = "Brick"
    var brickView: BrickCollectionView!
    var repeatCountDataSource: FixedRepeatCountDataSource!
    var repeatBrick: Brick!

    var flowLayout: BrickFlowLayout {
        return brickView.layout as! BrickFlowLayout
    }
    
    override func setUp() {
        super.setUp()
        brickView = BrickCollectionView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
    }

    func setupSection(repeatCount: Int = 100, widthRatio: CGFloat = 1, height: CGFloat = 100) {
        brickView.registerBrickClass(DummyBrick.self)

        repeatBrick = DummyBrick(BrickIdentifier, width: .Ratio(ratio: widthRatio), height: .Fixed(size: height))
        let section = BrickSection(bricks: [
            repeatBrick
            ])
        repeatCountDataSource = FixedRepeatCountDataSource(repeatCountHash: [BrickIdentifier: repeatCount])
        section.repeatCountDataSource = repeatCountDataSource

        brickView.setSection(section)
    }

    func testFrameOfInterest() {
        setupSection()

        brickView.collectionViewLayout.layoutAttributesForElementsInRect(CGRect(x: 0, y: 0, width: 320, height: 500))
        XCTAssertEqual(flowLayout.frameOfInterest, CGRect(x: 0, y: 0, width: 320, height: 500))
        brickView.collectionViewLayout.layoutAttributesForElementsInRect(CGRect(x: 0, y: 500, width: 320, height: 500))
        XCTAssertEqual(flowLayout.frameOfInterest, CGRect(x: 0, y: 0, width: 320, height: 1000))
        brickView.collectionViewLayout.layoutAttributesForElementsInRect(CGRect(x: 0, y: 20000, width: 320, height: 500))
        XCTAssertEqual(flowLayout.frameOfInterest, CGRect(x: 0, y: 0, width: 320, height: 20500))
    }
    
    func testThatContentSizeIsSetCorrectly() {
        setupSection()

        brickView.layoutSubviews()

        XCTAssertEqual(brickView.contentSize, CGSize(width: 320, height: 10000))
    }
    
    func testThatOnlyNecessaryAttributesAreCreated() {
        setupSection()

        brickView.collectionViewLayout.layoutAttributesForElementsInRect(CGRect(x: 0, y: 0, width: 320, height: 500))
        XCTAssertEqual(flowLayout.sections![1]!.attributes.count, 5)
        XCTAssertEqual(flowLayout.sections![1]!.frame, CGRect(x: 0, y: 0, width: 320, height: 10000))
    }

    func testThatOnlyNecessaryAttributesAreCreatedTwoBy() {
        setupSection(widthRatio: 1/2)

        brickView.collectionViewLayout.layoutAttributesForElementsInRect(CGRect(x: 0, y: 0, width: 320, height: 500))
        XCTAssertEqual(flowLayout.sections![1]!.attributes.count, 10)
        XCTAssertEqual(flowLayout.sections![1]!.frame, CGRect(x: 0, y: 0, width: 320, height: 5000))
    }

    func testThatOnlyNecessaryAttributesAreCreatedWithInsets() {
        setupSection()
        brickView.section.inset = 10
        brickView.section.edgeInsets = UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0)

        brickView.collectionViewLayout.layoutAttributesForElementsInRect(CGRect(x: 0, y: 0, width: 320, height: 500))
        XCTAssertEqual(flowLayout.sections![1]!.frame, CGRect(x: 0, y: 0, width: 320, height: 11000))
    }

    func testThatOnlyNecessaryAttributesAreCreatedWithInsetsTwoBy() {
        setupSection(widthRatio: 1/2)
        brickView.section.inset = 10
        brickView.section.edgeInsets = UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0)

        brickView.collectionViewLayout.layoutAttributesForElementsInRect(CGRect(x: 0, y: 0, width: 320, height: 500))
        XCTAssertEqual(flowLayout.sections![1]!.frame, CGRect(x: 0, y: 0, width: 320, height: 5500))
    }

    func testThatOnlyNecessaryAttributesAreCreatedWhenScrolling() {
        setupSection()
        
        brickView.collectionViewLayout.layoutAttributesForElementsInRect(CGRect(x: 0, y: 0, width: 320, height: 500))
        brickView.collectionViewLayout.layoutAttributesForElementsInRect(CGRect(x: 0, y: 500, width: 320, height: 500))
        XCTAssertEqual(flowLayout.sections![1]!.attributes.count, 10)
        XCTAssertEqual(flowLayout.sections![1]!.frame, CGRect(x: 0, y: 0, width: 320, height: 10000))
    }

    func _testThatStickyFooterWorksWithLazyLoading() {
        setupSection()
        let stickyFooter = StickyFooterLayoutBehavior(dataSource: FixedStickyLayoutBehaviorDataSource(indexPaths: [NSIndexPath(forItem: 99, inSection: 1)]))
        flowLayout.behaviors.insert(stickyFooter)

        brickView.collectionViewLayout.layoutAttributesForElementsInRect(CGRect(x: 0, y: 0, width: 320, height: 500))
        XCTAssertEqual(flowLayout.sections![1]!.attributes.count, 6)
        XCTAssertEqual(flowLayout.sections![1]!.frame, CGRect(x: 0, y: 0, width: 320, height: 10000))
        XCTAssertNotNil(flowLayout.sections![1]!.attributes[99])
        XCTAssertEqual(flowLayout.sections![1]!.attributes[99].frame, CGRect(x: 0, y: 380, width: 320, height: 100))
        XCTAssertEqual(flowLayout.sections![1]!.attributes[99].originalFrame, CGRect(x: 0, y: 9900, width: 320, height: 100))
    }

    func testThatAlignRowHeightsWorksProperly() {
        setupSection()
        brickView.section.inset = 10

        flowLayout.alignRowHeights = true

        let attributes = brickView.collectionViewLayout.layoutAttributesForElementsInRect(CGRect(x: 0, y: 0, width: 320, height: 500))?.sort({$0.0.indexPath.item < $0.1.indexPath.item})
        print(attributes)
        let lastAttributes = attributes?.last
        print(lastAttributes)
        XCTAssertEqual(lastAttributes?.frame, CGRect(x: 0.0, y: 440.0, width: 320.0, height: 100.0))
    }

    func testThatDynamicHeightsWorksProperly() {
        brickView.registerBrickClass(LabelBrick.self)
        let section = BrickSection(bricks: [
            LabelBrick(BrickIdentifier, text: "", configureCellBlock: { cell in
                var text = ""
                for _ in 0...cell.index {
                    if !text.isEmpty {
                        text += "\n"
                    }
                    text += "BRICK \(cell.index + 1)"
                }
                cell.label.text = text
            })
            ])
        repeatCountDataSource = FixedRepeatCountDataSource(repeatCountHash: [BrickIdentifier: 1000])
        section.repeatCountDataSource = repeatCountDataSource

        brickView.setSection(section)
        brickView.layoutSubviews()

        flowLayout.alignRowHeights = true

//        let attributes = brickView.collectionViewLayout.layoutAttributesForElementsInRect(CGRect(x: 0, y: 0, width: 320, height: 500))?.sort({$0.0.indexPath.item < $0.1.indexPath.item})
//        print(attributes)

        brickView.contentOffset.y = brickView.frame.height
        brickView.layoutIfNeeded()

//        let lastAttributes = attributes?.last
//        print(lastAttributes)
//        XCTAssertEqual(lastAttributes?.frame, CGRect(x: 0.0, y: 440.0, width: 320.0, height: 100.0))

//        print(brickView.visibleCells().map({$0.frame}))
        for cell in brickView.visibleCells() {
            let indexPath = brickView.indexPathForCell(cell)!
            print("\(indexPath.item): \(cell.frame)")
        }
        print("\n\n\n")
        for attributes in flowLayout.sections![1]!.attributes {
            if attributes.indexPath.section == 1 {
                print("\(attributes.indexPath.item): \(attributes.frame.minY)")
            }
        }
    }

}
