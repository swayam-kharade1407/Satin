//
//  Paths.swift
//  Example
//
//  Created by Reza Ali on 9/3/24.
//  Copyright © 2024 Hi-Rez. All rights reserved.
//

import Foundation

func getResourceAssetsURL() -> URL {
    Bundle.main.resourceURL!.appendingPathComponent("Assets")
}

func getResourceAssetsSharedURL() -> URL {
    getResourceAssetsURL().appendingPathComponent("Shared")
}

func getResourceAssetsSharedPipelinesURL() -> URL {
    getResourceAssetsSharedURL().appendingPathComponent("Pipelines")
}
