//
//  Utils.swift
//  ARPointCloudRenderer
//
//  Created by Florian Bruggisser on 17.11.18.
//  Copyright © 2018 Florian Bruggisser. All rights reserved.
//

import Foundation
import QuartzCore

@discardableResult
func measure<A>(name: String = "", _ block: () -> A) -> A {
    let startTime = CACurrentMediaTime()
    let result = block()
    let timeElapsed = CACurrentMediaTime() - startTime
    print("Time: \(name) - \(timeElapsed) seconds")
    return result
}
