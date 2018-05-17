//
//  Scatter.swift
//  Core Image Filters
//
//  Created by Eugene Bokhan on 5/17/18.
//  Copyright © 2018 Eugene Bokhan. All rights reserved.
//
import CoreImage

// An alternative version of the scatter filter using a pseudo random number generator
// inside a warp kernel.
class ScatterWarp: CIFilter {
    var inputImage: CIImage?
    var inputScatterRadius: CGFloat = 25
    
    override var attributes: [String : Any] {
        return [
            kCIAttributeFilterDisplayName: "Scatter (Warp Kernel)",
            
            "inputImage": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "CIImage",
                kCIAttributeDisplayName: "Image",
                kCIAttributeType: kCIAttributeTypeImage],
            
            "inputScatterRadius": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "NSNumber",
                kCIAttributeDefault: 25,
                kCIAttributeDisplayName: "Scatter Radius",
                kCIAttributeMin: 1,
                kCIAttributeSliderMin: 1,
                kCIAttributeSliderMax: 150,
                kCIAttributeType: kCIAttributeTypeScalar],
        ]
    }
    
    let kernel = CIWarpKernel(source:
        // based on https://www.shadertoy.com/view/ltB3zD - the additional seed
        // calculation prevents repetition when using destCoord() as the seed.
        "float noise(vec2 co)" +
            "{ " +
            "    vec2 seed = vec2(sin(co.x), cos(co.y)); " +
            "    return fract(sin(dot(seed ,vec2(12.9898,78.233))) * 43758.5453); " +
            "} " +
            
            "kernel vec2 scatter(float radius)" +
            "{" +
            "   float offsetX = radius * (-1.0 + noise(destCoord()) * 2.0); " +
            "   float offsetY = radius * (-1.0 + noise(destCoord().yx) * 2.0); " +
            "   return vec2(destCoord().x + offsetX, destCoord().y + offsetY); " +
        "}"
    )
    
    override var outputImage: CIImage? {
        guard let kernel = kernel, let inputImage = inputImage else { return nil }
        
        return  kernel.apply( extent: inputImage.extent, roiCallback: { (index, rect) in
                return rect
            }, image: inputImage, arguments: [inputScatterRadius])
    }
}

// Pixel scattering filter using CIRandomGenerator as its source. The output of the
// random generator can be blurred allowing for a smoothness attribute.
class Scatter: CIFilter {
    var inputImage: CIImage?
    var inputScatterRadius: CGFloat = 25
    var inputScatterSmoothness: CGFloat = 1.0
    
    override var attributes: [String : Any] {
        return [
            kCIAttributeFilterDisplayName: "Scatter",
            
            "inputImage": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "CIImage",
                kCIAttributeDisplayName: "Image",
                kCIAttributeType: kCIAttributeTypeImage],
        
            "inputScatterRadius": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "NSNumber",
                kCIAttributeDefault: 25,
                kCIAttributeDisplayName: "Scatter Radius",
                kCIAttributeMin: 1,
                kCIAttributeSliderMin: 1,
                kCIAttributeSliderMax: 150,
                kCIAttributeType: kCIAttributeTypeScalar],
        
            "inputScatterSmoothness": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "NSNumber",
                kCIAttributeDefault: 1,
                kCIAttributeDisplayName: "Scatter Smoothness",
                kCIAttributeMin: 0,
                kCIAttributeSliderMin: 0,
                kCIAttributeSliderMax: 4,
                kCIAttributeType: kCIAttributeTypeScalar]
        ]
    }
    
    let kernel = CIKernel(source:
        "kernel vec4 scatter(sampler image, sampler noise, float radius)" +
        "{" +
        "   vec2 workingSpaceCoord = destCoord() + -radius + sample(noise, samplerCoord(noise)).xy * radius * 2.0; " +
        "   vec2 imageSpaceCoord = samplerTransform(image, workingSpaceCoord); " +
        "   return sample(image, imageSpaceCoord);" +
        "}")
    
    override var outputImage: CIImage? {
        guard let kernel = kernel, let inputImage = inputImage else { return nil }
        
        let noise = CIFilter(name: "CIRandomGenerator")!.outputImage!
            .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: inputScatterSmoothness])
            .cropped(to: inputImage.extent)
        
        let arguments = [inputImage, noise, inputScatterRadius] as [Any]

        return kernel.apply(extent: inputImage.extent, roiCallback: { (index, rect) in
                return rect }, arguments: arguments)

    }
}
