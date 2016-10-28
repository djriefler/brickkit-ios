//
//  BrickLayoutSectionBinarySearchTests.swift
//  BrickKit
//
//  Created by Ruben Cagnie on 10/27/16.
//  Copyright © 2016 Wayfair. All rights reserved.
//

import XCTest
@testable import BrickKit

private let mapAttributesToItemIndex: (UICollectionViewLayoutAttributes) -> Int = {$0.indexPath.item}
private let sortByNumber: (Int, Int) -> Bool = {$0 < $1}


class BrickLayoutSectionBinarySearchTests: XCTestCase {

    var layout: BrickFlowLayout {
        return brickView.layout as! BrickFlowLayout
    }

    var brickView: BrickCollectionView!

    var dataSource:FixedBrickLayoutSectionDataSource!
    override func setUp() {
        super.setUp()

        brickView = BrickCollectionView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        dataSource = nil
        continueAfterFailure = false
    }

    private func createSection(widthRatios: [CGFloat], heights: [CGFloat], edgeInsets: UIEdgeInsets, inset: CGFloat, sectionWidth: CGFloat, updatedAttributes: OnAttributesUpdatedHandler? = nil) -> BrickLayoutSection {
        dataSource = FixedBrickLayoutSectionDataSource(widthRatios: widthRatios, heights: heights, edgeInsets: edgeInsets, inset: inset)
        let section = BrickLayoutSection(
            sectionIndex: 0,
            sectionAttributes: nil,
            numberOfItems: widthRatios.count,
            origin: CGPoint.zero,
            sectionWidth: sectionWidth,
            dataSource: dataSource)
        section.invalidateAttributes(updatedAttributes)
        return section
    }
    
    func testThatSectionReturnsAttributesForRect() {
        let totalNumber = 20
        let section = createSection(Array<CGFloat>(count: totalNumber, repeatedValue: 1), heights: Array<CGFloat>(count: totalNumber, repeatedValue: 50), edgeInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0), inset: 0, sectionWidth: 320)

        var attributes: [Int]!

        attributes = section.layoutAttributesForElementsInRect(CGRect(x: 0, y: 0, width: 320, height: 480)).map(mapAttributesToItemIndex).sort(sortByNumber)
        XCTAssertEqual(attributes.count, 10)
        XCTAssertEqual(attributes,Array<Int>(0...9))

        attributes = section.layoutAttributesForElementsInRect(CGRect(x: 0, y: 25, width: 320, height: 480)).map(mapAttributesToItemIndex).sort(sortByNumber)
        XCTAssertEqual(attributes.count, 11)
        XCTAssertEqual(attributes,Array<Int>(0...10))

        attributes = section.layoutAttributesForElementsInRect(CGRect(x: 0, y: 480, width: 320, height: 480)).map(mapAttributesToItemIndex).sort(sortByNumber)
        XCTAssertEqual(attributes.count, 11)
        XCTAssertEqual(attributes,Array<Int>(9...19))

    }

    func testThatSectionReturnsAttributesForRectWithInset() {
        let totalNumber = 20
        let section = createSection(Array<CGFloat>(count: totalNumber, repeatedValue: 1), heights: Array<CGFloat>(count: totalNumber, repeatedValue: 50), edgeInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0), inset: 10, sectionWidth: 320)

        var attributes: [Int]!

        attributes = section.layoutAttributesForElementsInRect(CGRect(x: 0, y: 55, width: 320, height: 480)).map(mapAttributesToItemIndex).sort(sortByNumber)
        XCTAssertEqual(attributes.count, 8)
        XCTAssertEqual(attributes,Array<Int>(1...8))

    }

    func testThatSectionReturnsAttributesForRectWith2By() {
        let totalNumber = 50
        let section = createSection(Array<CGFloat>(count: totalNumber, repeatedValue: 1/2), heights: Array<CGFloat>(count: totalNumber, repeatedValue: 50), edgeInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0), inset: 0, sectionWidth: 320)

        var attributes: [Int]!

        attributes = section.layoutAttributesForElementsInRect(CGRect(x: 0, y: 55, width: 320, height: 480)).map(mapAttributesToItemIndex).sort(sortByNumber)
        XCTAssertEqual(attributes.count, 20)
        XCTAssertEqual(attributes,Array<Int>(2...21))
        
    }

    func testThatSectionReturnsAttributesForRectWith2ByHuge() {
        let totalNumber = 50000
        let section = createSection(Array<CGFloat>(count: totalNumber, repeatedValue: 1/2), heights: Array<CGFloat>(count: totalNumber, repeatedValue: 50), edgeInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0), inset: 0, sectionWidth: 320)

        var attributes: [Int]!

        attributes = section.layoutAttributesForElementsInRect(CGRect(x: 0, y: 55, width: 320, height: 480)).map(mapAttributesToItemIndex).sort(sortByNumber)
        XCTAssertEqual(attributes.count, 20)
        XCTAssertEqual(attributes,Array<Int>(2...21))
        
    }
    
}
