//
//  BrickLayoutSection.swift
//  BrickKit
//
//  Created by Ruben Cagnie on 9/1/16.
//  Copyright © 2016 Wayfair LLC. All rights reserved.
//

import UIKit

protocol BrickLayoutSectionDelegate: class {
    func brickLayoutSection(section: BrickLayoutSection, didCreateAttributes attributes: BrickLayoutAttributes)
}

protocol BrickLayoutSectionDataSource: class {
    var alignRowHeights: Bool { get }
    var zIndexBehavior: BrickLayoutZIndexBehavior { get }
    var scrollDirection: UICollectionViewScrollDirection { get }
    var widthRatio: CGFloat { get }
    var frameOfInterest: CGRect { get }

    func edgeInsets(in section: BrickLayoutSection) -> UIEdgeInsets
    func inset(in section: BrickLayoutSection) -> CGFloat
    func width(for index: Int, totalWidth: CGFloat, in section: BrickLayoutSection) -> CGFloat
    func prepareForSizeCalculation(for attributes: BrickLayoutAttributes, containedIn width: CGFloat, origin: CGPoint, invalidate: Bool, in section: BrickLayoutSection, updatedAttributes: OnAttributesUpdatedHandler?)
    func size(for attributes: BrickLayoutAttributes, containedIn width: CGFloat, in section: BrickLayoutSection) -> CGSize
    func identifier(for index: Int, in section: BrickLayoutSection) -> String
    func zIndex(for index: Int, in section: BrickLayoutSection) -> Int
    func isEstimate(for attributes: BrickLayoutAttributes, in section: BrickLayoutSection) -> Bool
    func downStreamIndexPaths(in section: BrickLayoutSection) -> [NSIndexPath]

}

/// BrickLayoutSection manages all the attributes that are in one specific section
internal class BrickLayoutSection {
    static let OnlyCalculateFrameOfInterest = true

    /// The BrickLayoutAttributes that represent this section on a level higher
    /// - Optional because the root section will not have this set
    internal var sectionAttributes: BrickLayoutAttributes?

    /// Index of the section
    internal let sectionIndex: Int

    /// Number of Items in this section
    internal private(set) var numberOfItems: Int

    /// Calculated attributes for this section
    internal private(set) var attributes: [Int: BrickLayoutAttributes] = [:]

    /// Frame that contains this whole section
    internal private(set) var frame: CGRect = .zero

    /**
        Width of the section. Can be set by `setSectionWidth`

        This is not a calculated property of the frame because in case of horizontal scrolling, the values will be different
     */
    internal private(set) var sectionWidth: CGFloat

    /// Origin of the frame. Can be set by `setOrigin`
    private var origin: CGPoint {
        return frame.origin
    }

    /// DataSource that is used to calculate the section
    internal weak var dataSource: BrickLayoutSectionDataSource?

    /// Delegate that is used get informed by certain events
    internal weak var delegate: BrickLayoutSectionDelegate?

    /// Default constructor
    ///
    /// - parameter sectionIndex:      Index of the section
    /// - parameter sectionAttributes: Attributes on a higher level that contain this section
    /// - parameter numberOfItems:     Initial number of items in this section
    /// - parameter origin:            Origin of the section
    /// - parameter sectionWidth:      Width of the section
    /// - parameter dataSource:        DataSource
    ///
    /// - returns: instance of the BrickLayoutSection
    init(sectionIndex: Int, sectionAttributes: BrickLayoutAttributes?, numberOfItems: Int, origin: CGPoint, sectionWidth: CGFloat, dataSource: BrickLayoutSectionDataSource, delegate: BrickLayoutSectionDelegate? = nil) {
        self.dataSource = dataSource
        self.delegate = delegate
        self.sectionIndex = sectionIndex
        self.numberOfItems = numberOfItems
        self.sectionAttributes = sectionAttributes
        self.sectionWidth = sectionWidth

        initializeFrameWithOrigin(origin, sectionWidth: sectionWidth)
    }


    /// Initialize the frame with the default origin and width
    ///
    /// - parameter sectionOrigin: origin
    /// - parameter sectionWidth:  width
    ///
    private func initializeFrameWithOrigin(origin: CGPoint, sectionWidth: CGFloat) {
        frame.origin = origin
        frame.size.width = sectionWidth
    }

    func setNumberOfItems(numberOfItems: Int, addedAttributes: OnAttributesUpdatedHandler?, removedAttributes: OnAttributesUpdatedHandler?) {
        guard numberOfItems != self.numberOfItems else {
            return
        }

        let difference = numberOfItems - self.numberOfItems

        if difference > 0 {
            self.numberOfItems = numberOfItems
            createOrUpdateCells(from: attributes.count, invalidate: false, updatedAttributes: addedAttributes)
        } else {
            self.numberOfItems = numberOfItems
            while attributes.count != numberOfItems {
                guard let lastIndex = attributes.keys.maxElement() else {
                    continue
                }
                if let last = attributes[lastIndex] {
                    removedAttributes?(attributes: last, oldFrame: last.frame)
                }
                attributes.removeValueForKey(lastIndex)
            }
            createOrUpdateCells(from: attributes.count, invalidate: true, updatedAttributes: nil)
        }

    }

    func appendItem(updatedAttributes: OnAttributesUpdatedHandler?) {
        numberOfItems += 1
        createOrUpdateCells(from: attributes.count, invalidate: true, updatedAttributes: updatedAttributes)
    }

    func deleteLastItem(updatedAttributes: OnAttributesUpdatedHandler?) {
        guard let lastIndex = attributes.keys.maxElement(), let last = attributes[lastIndex] else {
            return
        }
        numberOfItems -= 1
        attributes.removeValueForKey(lastIndex)
        createOrUpdateCells(from: attributes.count, invalidate: true, updatedAttributes: updatedAttributes)
        updatedAttributes?(attributes: last, oldFrame: last.frame)
    }


    func setOrigin(origin: CGPoint, fromBehaviors: Bool, updatedAttributes: OnAttributesUpdatedHandler?) {
        guard self.origin != origin else {
            return
        }

        let offset = CGSize(width: origin.x - self.origin.x, height: origin.y - self.origin.y)
        self.frame.origin = origin
//        continueCalculatingCells { (attributes, oldFrame) in
//            if fromBehaviors {
//                // We de-compensate the attributes, as they have been calculated with the updated origin...
//                attributes.frame.origin.x -= offset.width
//                attributes.frame.origin.y -= offset.height
//            }
//        }
//        self.frame.origin = origin

        self.offsetFrames(offset, fromBehaviors: fromBehaviors, updatedAttributes: updatedAttributes)
    }

    private func offsetFrames(offset: CGSize, fromBehaviors: Bool, updatedAttributes: OnAttributesUpdatedHandler?) {
        for attribute in attributes.values {
            let oldFrame = attribute.frame
            if !fromBehaviors {
                attribute.originalFrame.origin.x += offset.width
                attribute.originalFrame.origin.y += offset.height
            }
            attribute.frame.origin.x += offset.width
            attribute.frame.origin.y += offset.height

            updatedAttributes?(attributes: attribute, oldFrame: oldFrame)
        }
    }


    func setSectionWidth(sectionWidth: CGFloat, updatedAttributes: OnAttributesUpdatedHandler?) {
        if self.sectionWidth != sectionWidth {
            self.sectionWidth = sectionWidth
            invalidateAttributes(updatedAttributes)
        }
    }

    internal func invalidateAttributes(updatedAttributes: OnAttributesUpdatedHandler?) {
        createOrUpdateCells(from: 0, invalidate: true, updatedAttributes: updatedAttributes)
    }

    func update(height height: CGFloat, at index: Int, updatedAttributes: OnAttributesUpdatedHandler?) {
        guard let brickAttributes = attributes[index] else {
            return
        }
//        if sectionIndex == 1 && index < 2 {
            print("Update Height \(index): \(height)")
//        }
        brickAttributes.isEstimateSize = false

        guard brickAttributes.originalFrame.height != height else {
            return
        }

        brickAttributes.originalFrame.size.height = height
        createOrUpdateCells(from: index, invalidate: false, updatedAttributes: updatedAttributes, customHeightProvider:{ attributes -> CGFloat? in
            guard attributes.isEstimateSize else {
                return nil
            }

            if attributes.identifier == self.attributes[index]?.identifier {
                return brickAttributes.originalFrame.height
            }

            return nil
        })
    }

    private func invalidateAttributes(attributes: BrickLayoutAttributes) {
        attributes.isEstimateSize = true
        attributes.originalFrame = .zero
        attributes.frame = .zero
    }

    func invalidate(at index: Int, updatedAttributes: OnAttributesUpdatedHandler?) {
        guard let dataSource = dataSource, let brickAttributes = attributes[index] else {
            fatalError("Invalidate can't be called without dataSource")
        }

        invalidateAttributes(brickAttributes)

        let width = widthAtIndex(index, dataSource: dataSource)
        let size = dataSource.size(for: brickAttributes, containedIn: width, in: self)
        brickAttributes.originalFrame.size = size
        brickAttributes.frame.size = size

        createOrUpdateCells(from: index, invalidate: false, updatedAttributes: updatedAttributes, customHeightProvider: nil)
    }

    func changeVisibility(visibility: Bool, at index: Int, updatedAttributes: OnAttributesUpdatedHandler?) {
        guard let brickAttributes = attributes[index] else {
            return
        }
        brickAttributes.hidden = visibility
        
        createOrUpdateCells(from: index, invalidate: false, updatedAttributes: updatedAttributes, customHeightProvider: nil)
    }

    private func widthAtIndex(index: Int, dataSource: BrickLayoutSectionDataSource) -> CGFloat {
        let edgeInsets = dataSource.edgeInsets(in: self)
        let totalWidth = sectionWidth - edgeInsets.left - edgeInsets.right

        return dataSource.width(for: index, totalWidth: totalWidth, in: self)
    }

    func continueCalculatingCells(updatedAttributes: OnAttributesUpdatedHandler?) {
        guard attributes.count != numberOfItems else {
            return
        }
        guard let dataSource = dataSource else {
            return
        }
        let downStreamIndexPaths = dataSource.downStreamIndexPaths(in: self)
        let nextIndex = attributes.count - downStreamIndexPaths.count

        createOrUpdateCells(from: nextIndex, invalidate: false, updatedAttributes: updatedAttributes, customHeightProvider: nil)
    }

    private func createOrUpdateCells(from firstIndex: Int, invalidate: Bool, updatedAttributes: OnAttributesUpdatedHandler?, customHeightProvider: ((attributes: BrickLayoutAttributes) -> CGFloat?)? = nil) {
        guard let dataSource = dataSource else {
            return
        }

        let create = attributes.isEmpty
        let zIndexBehavior = dataSource.zIndexBehavior

        let edgeInsets = dataSource.edgeInsets(in: self)
        let inset = dataSource.inset(in: self)

        var startOrigin: CGPoint
        var maxY: CGFloat

        let startFrame = sectionAttributes?.originalFrame ?? frame
        startOrigin = CGPoint(x: startFrame.origin.x + edgeInsets.left, y: startFrame.origin.y + edgeInsets.top)
        maxY = startFrame.origin.y
        if !create {
//            let visibleAttributes = attributes.values.filter({ !$0.hidden })







            if firstIndex > 0 {
                if firstIndex == 2 {
                    print("Y")
                }

                var originY: CGFloat?
                if let currentAttribute = attributes[firstIndex] {
                    originY = currentAttribute.originalFrame.minY
                }

                var startOriginFound = false
                for index in (firstIndex-1).stride(to: -1, by: -1) {
                    if let nextAttribute = attributes[index] where !nextAttribute.hidden {
                        if originY == nil {
                            originY = nextAttribute.originalFrame.minY
                        }
                        if !startOriginFound {
                            startOrigin = CGPoint(x: nextAttribute.originalFrame.maxX + inset, y: nextAttribute.originalFrame.origin.y)
                            startOriginFound = true
                        }

                        maxY = max(maxY, nextAttribute.originalFrame.maxY)
                        if originY != nextAttribute.originalFrame.minY {
                            break
                        }
                    }
                }

                if let maxFrame = BrickUtils.findRowMaxY(for: firstIndex, in: attributes){
                    let xmaxY = maxFrame.frame.maxY
                    if xmaxY != maxY {
                        print("Que?")
                    }
                }
            } else {
                // Check the first visible attribute
                for index in 0..<firstIndex {
                    if let first = attributes[index] where !first.hidden  {
                        maxY = first.originalFrame.maxY
                        startOrigin = first.originalFrame.origin
                    }
                }
            }
        }

        var x: CGFloat = startOrigin.x
        var y: CGFloat = startOrigin.y

        let frameOfInterest = dataSource.frameOfInterest

        let numberOfItems = self.numberOfItems

        for index in firstIndex..<numberOfItems {
            if !createOrUpdateAttribute(at: index, with: dataSource, x: &x, y: &y, maxY: &maxY, edgeInsets: edgeInsets, inset: inset, zIndexBehavior: zIndexBehavior, force: false, invalidate: invalidate, frameOfInterest: frameOfInterest, updatedAttributes: updatedAttributes, customHeightProvider: customHeightProvider) {
                break
            }
        }

        if dataSource.alignRowHeights {
            let maxHeight = maxY - y
            updateHeightForRowsFromIndex(attributes.count - 1, maxHeight: maxHeight, updatedAttributes: updatedAttributes)
        }

        // Downstream IndexPaths
        if BrickLayoutSection.OnlyCalculateFrameOfInterest {
            let downStreamIndexPaths = dataSource.downStreamIndexPaths(in: self)
            for indexPath in downStreamIndexPaths {
                guard self.attributes[indexPath.item] == nil else {
                    // If the attribute already exists, don't do anything with it
                    break
                }
                createOrUpdateAttribute(at: indexPath.item, with: dataSource, x: &x, y: &y, maxY: &maxY, edgeInsets: edgeInsets, inset: inset, zIndexBehavior: zIndexBehavior, force: true, invalidate: invalidate, frameOfInterest: frameOfInterest, updatedAttributes: updatedAttributes, customHeightProvider: customHeightProvider)
            }
        }

        // Frame Height

        var frameHeight: CGFloat = 0
        if let first = attributes[0] {
            if numberOfItems != attributes.count {
                // If not all attributes are calculated, we need to estimate how big the section will be
                let height = (maxY - first.originalFrame.origin.y) + inset
                let percentageDone = CGFloat(attributes.count) / CGFloat(numberOfItems)
                frameHeight = (height / percentageDone)// + edgeInsets.bottom + edgeInsets.top
            } else {
                frameHeight = (maxY - first.originalFrame.origin.y) + edgeInsets.bottom + edgeInsets.top
            }

            let originY = first.originalFrame.origin.y - edgeInsets.top

            if frame.origin.y != originY {
                let originDiff = frame.origin.y - originY
                frame.origin.y = originY

                // The origin for the frame is changed. This means that previously calculated frames need to be compensated back up
                // Only update the attributes below the firstIndex (as the ones after are already correct)
                for index in 0..<firstIndex {
                    attributes[index]?.frame.origin.y -= originDiff
                }
            }
        }

        if frameHeight <= edgeInsets.bottom + edgeInsets.top {
            frameHeight = 0
        }
        frame.size.height = frameHeight

        switch dataSource.scrollDirection {
        case .Vertical: frame.size.width = sectionWidth
        case .Horizontal:
            x -= inset // Take off the inset as this is added to the end
            frame.size.width = x + edgeInsets.right
        }

        print("\n")
        print("Attributes")
        let keys = attributes.keys.sort(<)
        for key in keys {
            print("\(key): \(attributes[key]!.frame)")
        }
    }

    func createOrUpdateAttribute(at index: Int, with dataSource: BrickLayoutSectionDataSource, inout x: CGFloat, inout y: CGFloat, inout maxY: CGFloat, edgeInsets: UIEdgeInsets, inset: CGFloat, zIndexBehavior: BrickLayoutZIndexBehavior, force: Bool, invalidate: Bool, frameOfInterest: CGRect, updatedAttributes: OnAttributesUpdatedHandler?, customHeightProvider: ((attributes: BrickLayoutAttributes) -> CGFloat?)?) -> Bool {
        print("createOrUpdateAttribute(\(index))")
        let indexPath = NSIndexPath(forItem: index, inSection: sectionIndex)

        var width = widthAtIndex(index, dataSource: dataSource)

        var brickAttributes: BrickLayoutAttributes! = attributes[index]
        let existingAttribute: Bool = brickAttributes != nil

        let shouldBeOnNextRow: Bool
        switch dataSource.scrollDirection {
        case .Horizontal: shouldBeOnNextRow = false
        case .Vertical: shouldBeOnNextRow = (x + width - origin.x) > (sectionWidth - edgeInsets.right)
        }

        var nextY: CGFloat = y
        var nextX: CGFloat = x
        if shouldBeOnNextRow {
            if dataSource.alignRowHeights {
                let maxHeight = maxY - nextY
                updateHeightForRowsFromIndex(index - 1, maxHeight: maxHeight, updatedAttributes: updatedAttributes)
            }

            if maxY > nextY  {
                nextY = maxY + inset
            }
            nextX = origin.x + edgeInsets.left
        }

        let offsetX: CGFloat
        let offsetY: CGFloat
        if let sectionAttributes = sectionAttributes where sectionAttributes.originalFrame != nil {
            offsetX = frame.origin.x - sectionAttributes.originalFrame.origin.x
            offsetY = frame.origin.y - sectionAttributes.originalFrame.origin.y
        } else {
            offsetX = 0
            offsetY = 0
        }

        nextX += offsetX
        nextY += offsetY

        let nextOrigin = CGPoint(x: nextX, y: nextY)

        if BrickLayoutSection.OnlyCalculateFrameOfInterest && !existingAttribute && !frameOfInterest.contains(nextOrigin) && !force {
            return false
        }

//        numberOfItemsAdded += 1

        nextX -= offsetX
        nextY -= offsetY

        x = nextX
        y = nextY

        let cellOrigin = nextOrigin

        let oldFrame:CGRect?
        let oldOriginalFrame: CGRect?

        let recalculateZIndex = !existingAttribute || invalidate
        if existingAttribute {
            brickAttributes = attributes[index]
            oldFrame = brickAttributes.frame
            oldOriginalFrame = brickAttributes.originalFrame

            if invalidate {
                invalidateAttributes(brickAttributes)
                brickAttributes.isEstimateSize = dataSource.isEstimate(for: brickAttributes, in: self)
            }
        } else {
            brickAttributes = createAttribute(at: indexPath, with: dataSource)
            oldFrame = nil
            oldOriginalFrame = nil
        }


        if recalculateZIndex && zIndexBehavior == .BottomUp {
            brickAttributes.zIndex = dataSource.zIndex(for: index, in: self)
        }

        let height: CGFloat

        // Prepare the datasource that size calculation will happen
        dataSource.prepareForSizeCalculation(for: brickAttributes, containedIn: width, origin: cellOrigin, invalidate: invalidate, in: self, updatedAttributes: updatedAttributes)

        if let brickFrame = oldOriginalFrame where brickFrame.width == width && !invalidate {
            if let customHeight = customHeightProvider?(attributes: brickAttributes) {
                height = customHeight
            } else {
                height = brickFrame.height
            }
        } else {
            let size = dataSource.size(for: brickAttributes, containedIn: width, in: self)
            height = size.height
            width = size.width
        }

        var brickFrame = CGRect(origin: cellOrigin, size: CGSize(width: width, height: height))
        brickAttributes.frame = brickFrame
        brickFrame.origin.x -= offsetX
        brickFrame.origin.y -= offsetY
        brickAttributes.originalFrame = brickFrame

        if recalculateZIndex && zIndexBehavior == .TopDown {
            brickAttributes.zIndex = dataSource.zIndex(for: index, in: self)
        }

        if !existingAttribute {
            delegate?.brickLayoutSection(self, didCreateAttributes: brickAttributes)
        }

        updatedAttributes?(attributes: brickAttributes, oldFrame: oldFrame)

        let sectionIsHidden = sectionAttributes?.hidden ?? false
        let brickIsHiddenOrHasNoHeight = height <= 0 || brickAttributes.hidden

        if sectionIsHidden || !brickIsHiddenOrHasNoHeight {
            x = brickFrame.maxX + inset
            maxY = max(brickFrame.maxY, maxY)
            if maxY == 331.0 && index == 1 {
                print("Que?")
            }
        }

        brickAttributes.alpha = brickAttributes.hidden ? 0 : 1

        return true
    }

    func createAttribute(at indexPath: NSIndexPath, with dataSource: BrickLayoutSectionDataSource) -> BrickLayoutAttributes {
        let brickAttributes = BrickLayoutAttributes(forCellWithIndexPath: indexPath)

        brickAttributes.identifier = dataSource.identifier(for: indexPath.item, in: self)
        attributes[indexPath.item] = brickAttributes
        brickAttributes.isEstimateSize = dataSource.isEstimate(for: brickAttributes, in: self)
        return brickAttributes
    }

    func updateHeightForRowsFromIndex(index: Int, maxHeight: CGFloat, updatedAttributes: OnAttributesUpdatedHandler?) {
        guard index >= 0, let brickAttributes = self.attributes[index] else {
            return
        }
        var currentIndex = index
        let y = brickAttributes.originalFrame.origin.y
        while currentIndex >= 0 {
            guard let brickAttributes = attributes[currentIndex] else {
                continue
            }
            if brickAttributes.originalFrame.origin.y != y {
                return
            }
            let oldFrame = brickAttributes.frame
            var newFrame = oldFrame
            newFrame.size.height = maxHeight
            if newFrame != oldFrame {
                print("Update \(currentIndex): \(brickAttributes.frame) to \(newFrame)")
                brickAttributes.frame = newFrame
                updatedAttributes?(attributes: brickAttributes, oldFrame: oldFrame)
            }
            currentIndex -= 1
        }
    }

}

// MARK: - Binary search for elements
extension BrickLayoutSection {

    func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes] {
        var attributes = [UICollectionViewLayoutAttributes]()

        if self.attributes.isEmpty {
            return attributes
        }

        // Find an index that is pretty close to the top of the rect
        let closestIndex = findEstimatedClosestIndex(in: rect)

        // Closure that checks if an attribute is within the rect and adds it to the attributes to return
        // Returns true if the frame is within the rect
        let frameCheck: (index: Int) -> Bool = { index in
            guard let brickAttributes = self.attributes[index] else {
                return false
            }
            if rect.intersects(brickAttributes.frame) {
                attributes.append(brickAttributes)
                return true
            } else {
                return false
            }

        }

        // Go back to see if previous attributes are not closer
        for index in (closestIndex - 1).stride(to: -1, by: -1) {
            if !frameCheck(index: index) {
                break
            }
        }

        // Go forward until an attribute is outside or the rect
        for index in closestIndex..<self.attributes.count {
            if !frameCheck(index: index) {
                break
            }
        }

        return attributes
    }

    func findEstimatedClosestIndex(in rect: CGRect) -> Int {
        let minY = rect.minY

        var complexity = 0
        var lowerBound = 0
        var upperBound = attributes.count
        while lowerBound < upperBound {
            complexity += 1
            let midIndex = lowerBound + (upperBound - lowerBound) / 2
            guard let frame = attributes[midIndex]?.frame else {
                break
            }
            if frame.minY < minY {
                lowerBound = midIndex + 1
            } else {
                upperBound = midIndex
            }
        }
        return lowerBound
    }
}
