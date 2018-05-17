//
//  CompositeOverBlackFilter.swift
//  Core Image Filters
//
//  Created by Eugene Bokhan on 5/17/18.
//  Copyright © 2018 Eugene Bokhan. All rights reserved.
//

import UIKit
import CoreImage

class CompositeOverBlackFilter: CIFilter {
    
    let black: CIFilter
    let composite: CIFilter
    
    var inputImage : CIImage?
    
    override init() {
        
        black = CIFilter(name: "CIConstantColorGenerator", withInputParameters: [kCIInputColorKey: CIColor(color: UIColor.black)])!
        
        composite = CIFilter(name: "CISourceAtopCompositing", withInputParameters: [kCIInputBackgroundImageKey: black.outputImage!])!
        
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var outputImage: CIImage! {
        
        guard let inputImage = inputImage else { return nil }
        
        composite.setValue(inputImage, forKey: kCIInputImageKey)
        
        return composite.outputImage
    }
}

