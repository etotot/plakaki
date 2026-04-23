//
//  LayoutEngine.swift
//  FlightDeck
//
//  Created by Andrey Marshak on 22/04/2026.
//

import CoreGraphics
import Foundation
import GroundControl

public struct SpaceGeometry {
    let spaceFrames: [GroundControl.Space.ID: CGRect]
}

public enum LayoutEngine {
    public static func computeLayout(for root: LayoutRoot,
                                     spaceGeometry: [GroundControl.Space.ID: CGRect]) -> LayoutPlan
    {
        var result = [Window.ID: WindowLayout]()
        for space in root.displays.compactMap(\.focusedSpace) {
            guard let rect = spaceGeometry[space.id] else { continue }
            result.merge(computeLayout(for: space, geometry: rect).windows, uniquingKeysWith: { _, new in new })
        }

        return .init(windows: result)
    }

    private static func computeLayout(for space: LayoutSpace, geometry: CGRect) -> LayoutPlan {
        guard let root = space.tiledRoot else {
            return .empty
        }

        return computeLayout(for: root, geometry: geometry, focusedWindowId: space.focusedWindow)
    }

    private static func computeLayout(for container: Container, geometry: CGRect,
                                      focusedWindowId: Window.ID?) -> LayoutPlan
    {
        let gap = 8.0

        switch container {
        case let .leaf(windowId):
            return .init(windows: [
                windowId: .init(frame: geometry, zIndex: windowId == focusedWindowId ? 1 : 0)
            ])

        case let .stack(_, children):
            var result = [Window.ID: WindowLayout]()

            let windowWidth = (geometry.width - CGFloat(children.count - 1) * gap) / CGFloat(children.count)
            for childIndex in children.indices {
                let rect = CGRect(
                    x: geometry.origin.x + CGFloat(childIndex) * (gap + windowWidth),
                    y: geometry.origin.y,
                    width: windowWidth,
                    height: geometry.height
                )

                let childLayout = computeLayout(
                    for: children[childIndex],
                    geometry: rect,
                    focusedWindowId: focusedWindowId
                )
                result.merge(childLayout.windows, uniquingKeysWith: { _, new in new })
            }

            // let windowWidth = geometry.width - CGFloat(children.count - 1) * stride
            //
            // for i in children.indices {
            //     let rect = CGRect(x: CGFloat(i) * stride, y: 0, width: windowWidth, height: geometry.height)
            //     switch children[i] {
            //     case let .leaf(windowId):
            //         result[windowId] = .init(frame: rect, zIndex: 1)
            //     default:
            //         let childLayout = computeLayout(for: children[i], geometry: rect)
            //         result.merge(childLayout.windows, uniquingKeysWith: { _, new in new })
            //     }
            // }

            return .init(windows: result)
        }
    }
}
