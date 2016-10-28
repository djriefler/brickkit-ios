//
//  BrickUtils.swift
//  BrickKit
//
//  Created by Ruben Cagnie on 9/30/16.
//  Copyright © 2016 Wayfair LLC. All rights reserved.
//

import Foundation

protocol Frameable {
    var frame: CGRect { get }
    var hidden: Bool { get }
}

extension UICollectionViewLayoutAttributes: Frameable {
    
}

enum BrickUtils {

    /// Calculates a width, based on the total width and its inset
    ///
    /// - parameter ratio:      Ratio
    /// - parameter widthRatio: Value that represents 100%
    /// - parameter totalWidth: Total width to calculate from
    /// - parameter inset:      Inset inbetween widths
    ///
    /// - returns: The actual width
    static func calculateWidth(for ratio: CGFloat, widthRatio: CGFloat, totalWidth: CGFloat, inset: CGFloat) -> CGFloat {
        let rowWidth = totalWidth - CGFloat((widthRatio / ratio) - 1) * inset
        let width = rowWidth * (ratio / widthRatio)
        return width
    }

    /// Find the maxY in a row of frames, not including the itemIndex
    ///
    /// - parameter itemIndex: Index to start at
    /// - parameter frames:    Array of frames to search through
    ///
    /// - returns: MaxY in the
    static func findRowMaxY<T: Frameable>(for itemIndex: Int, in frames: [Int: T]) -> T? {
        guard itemIndex <= frames.count else {
            return nil
        }

        if itemIndex == 0 {
            return nil
        }

        guard let frameable = frames[itemIndex-1] else {
            return nil
        }

//        let currentY = frameable.frame.origin.y
        var maxFrameable = frameable
//        var maxY = frameable.frame.maxY
        for index in (itemIndex-1).stride(to: -1, by: -1) {
            guard let nextFrameable = frames[index] where !nextFrameable.hidden else {
                continue
            }
            if maxFrameable.frame.maxY != nextFrameable.frame.origin.y {
                return nextFrameable
            }
            if nextFrameable.frame.maxY > maxFrameable.frame.maxY {
                maxFrameable = nextFrameable
            }
        }
        
        return maxFrameable
    }
}

