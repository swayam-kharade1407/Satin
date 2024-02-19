//
//  RenderList.swift
//
//
//  Created by Reza Ali on 12/12/23.
//

import Foundation

final class RenderList {
    public var isEmpty: Bool {
        renderables.isEmpty
    }

    private var renderables: [Renderable]
    private var sortedRenderables: [Renderable] { renderables.sorted { $0.renderOrder < $1.renderOrder } }

    public init(_ renderable: Renderable) {
        self.renderables = [renderable]
    }

    public func append(_ renderable: Renderable) {
        renderables.append(renderable)
    }

    public func removeAll(keepingCapacity: Bool = true) {
        renderables.removeAll(keepingCapacity: keepingCapacity)
    }

    public func getRenderables(sorted: Bool) -> [Renderable] {
        sorted ? sortedRenderables : renderables
    }
}
