//
//  CarnivalMirror.swift
//  Core Image Filters
//
//  Created by Eugene Bokhan on 5/17/18.
//  Copyright © 2018 Eugene Bokhan. All rights reserved.
//

import CoreImage

class CarnivalMirror: CIFilter
{
    var inputImage : CIImage?
    
    var inputHorizontalWavelength: CGFloat = 10
    var inputHorizontalAmount: CGFloat = 20
    
    var inputVerticalWavelength: CGFloat = 10
    var inputVerticalAmount: CGFloat = 20
    
    override func setDefaults()
    {
        inputHorizontalWavelength = 10
        inputHorizontalAmount = 20
        
        inputVerticalWavelength = 10
        inputVerticalAmount = 20
    }
    
    override var attributes: [String : Any]
    {
        return [
            kCIAttributeFilterDisplayName: "Carnival Mirror",
            
            "inputImage": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "CIImage",
                kCIAttributeDisplayName: "Image",
                kCIAttributeType: kCIAttributeTypeImage],
            
            "inputHorizontalWavelength": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "NSNumber",
                kCIAttributeDefault: 10,
                kCIAttributeDisplayName: "Horizontal Wavelength",
                kCIAttributeMin: 0,
                kCIAttributeSliderMin: 0,
                kCIAttributeSliderMax: 100,
                kCIAttributeType: kCIAttributeTypeScalar],
            
            "inputHorizontalAmount": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "NSNumber",
                kCIAttributeDefault: 20,
                kCIAttributeDisplayName: "Horizontal Amount",
                kCIAttributeMin: 0,
                kCIAttributeSliderMin: 0,
                kCIAttributeSliderMax: 100,
                kCIAttributeType: kCIAttributeTypeScalar],
            
            "inputVerticalWavelength": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "NSNumber",
                kCIAttributeDefault: 10,
                kCIAttributeDisplayName: "Vertical Wavelength",
                kCIAttributeMin: 0,
                kCIAttributeSliderMin: 0,
                kCIAttributeSliderMax: 100,
                kCIAttributeType: kCIAttributeTypeScalar],
            
            "inputVerticalAmount": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "NSNumber",
                kCIAttributeDefault: 20,
                kCIAttributeDisplayName: "Vertical Amount",
                kCIAttributeMin: 0,
                kCIAttributeSliderMin: 0,
                kCIAttributeSliderMax: 100,
                kCIAttributeType: kCIAttributeTypeScalar]
        ]
        
        
    }
    
    let carnivalMirrorKernel = CIWarpKernel(source:
        "kernel vec2 carnivalMirror(float xWavelength, float xAmount, float yWavelength, float yAmount)" +
        "{" +
        "   float y = destCoord().y + sin(destCoord().y / yWavelength) * yAmount; " +
        "   float x = destCoord().x + sin(destCoord().x / xWavelength) * xAmount; " +
        "   return vec2(x, y); " +
        "}"
    )
    
    override var outputImage : CIImage!
    {
        if let inputImage = inputImage,
            let kernel = carnivalMirrorKernel
        {
            let arguments = [
                inputHorizontalWavelength, inputHorizontalAmount,
                inputVerticalWavelength, inputVerticalAmount]
            
            let extent = inputImage.extent
            
            return kernel.apply(extent: extent,
                roiCallback:
                {
                    (index, rect) in
                    return rect
                },
                image: inputImage,
                arguments: arguments)
        }
        return nil
    }
}
