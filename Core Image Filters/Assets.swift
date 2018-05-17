//
//  Assets.swift
//  Core Image Filters
//
//  Created by Eugene Bokhan on 5/17/18.
//  Copyright © 2018 Eugene Bokhan. All rights reserved.
//

import CoreImage
import UIKit

typealias NamedImage = (name: String, ciImage: CIImage)

let gradientImage = CIFilter( name: "CIRadialGradient", withInputParameters: [
        kCIInputCenterKey:
            CIVector(x: 320, y: 320),
        "inputRadius0": 200,
        "inputRadius1": 400,
        "inputColor0":
            CIColor(red: 0, green: 0, blue: 0),
        "inputColor1":
            CIColor(red: 1, green: 1, blue: 1)
    ])?
    .outputImage?
    .cropped(to: CGRect(x: 0, y: 0, width: 640, height: 640))

let assets = [
    NamedImage(name: "New York", ciImage: CIImage(image:#imageLiteral(resourceName: "new york"))!),
    NamedImage(name: "Lake", ciImage: CIImage(image: #imageLiteral(resourceName: "Lake"))!),
    NamedImage(name: "Sunset", ciImage: CIImage(image: #imageLiteral(resourceName: "sunset"))!),
    NamedImage(name: "Gradient", ciImage: gradientImage!)
]

let assetLabels = assets.map({ $0.name })

