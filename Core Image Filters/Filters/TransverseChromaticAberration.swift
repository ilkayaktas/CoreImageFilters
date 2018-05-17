//
//  TransverseChromaticAberration.swift
//  Core Image Filters
//
//  Created by Eugene Bokhan on 5/17/18.
//  Copyright © 2018 Eugene Bokhan. All rights reserved.
//

import CoreImage

class TransverseChromaticAberration: CIFilter {
    var inputImage: CIImage?
    var inputBlur: CGFloat = 10
    var inputFalloff: CGFloat = 0.2
    var inputSamples: CGFloat = 10
    
    override var attributes: [String : Any] {
        return [
            kCIAttributeFilterDisplayName: "Transverse Chromatic Aberration",
            
            "inputImage": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "CIImage",
                kCIAttributeDisplayName: "Image",
                kCIAttributeType: kCIAttributeTypeImage],
            
            "inputBlur": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "NSNumber",
                kCIAttributeDefault: 10,
                kCIAttributeDisplayName: "Blur",
                kCIAttributeMin: 0,
                kCIAttributeSliderMin: 0,
                kCIAttributeSliderMax: 40,
                kCIAttributeType: kCIAttributeTypeScalar],
            
            "inputFalloff": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "NSNumber",
                kCIAttributeDefault: 0.2,
                kCIAttributeDisplayName: "Falloff",
                kCIAttributeMin: 0,
                kCIAttributeSliderMin: 0,
                kCIAttributeSliderMax: 0.5,
                kCIAttributeType: kCIAttributeTypeScalar],
            
            "inputSamples": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "NSNumber",
                kCIAttributeDefault: 10,
                kCIAttributeDisplayName: "Samples",
                kCIAttributeMin: 5,
                kCIAttributeSliderMin: 5,
                kCIAttributeSliderMax: 40,
                kCIAttributeType: kCIAttributeTypeScalar],
        ]
    }
    
    let transverseChromaticAberrationKernel = CIKernel(source:
        "kernel vec4 motionBlur(sampler image, vec2 size, float sampleCount, float start, float blur) {" +
        "  int sampleCountInt = int(floor(sampleCount));" +
        "  vec4 accumulator = vec4(0.0);" +
        "  vec2 dc = destCoord(); " +
        "  float normalisedValue = length(((dc / size) - 0.5) * 2.0);" +
        "  float strength = clamp((normalisedValue - start) * (1.0 / (1.0 - start)), 0.0, 1.0); " +
        
        "  vec2 vector = normalize((dc - (size / 2.0)) / size);" +
        "  vec2 velocity = vector * strength * blur; " +
        
        "  vec2 redOffset = -vector * strength * (blur * 1.0); " +
        "  vec2 greenOffset = -vector * strength * (blur * 1.5); " +
        "  vec2 blueOffset = -vector * strength * (blur * 2.0); " +
        
        "  for (int i=0; i < sampleCountInt; i++) { " +
        "      accumulator.r += sample(image, samplerTransform (image, dc + redOffset)).r; " +
        "      redOffset -= velocity / sampleCount; " +
        
        "      accumulator.g += sample(image, samplerTransform (image, dc + greenOffset)).g; " +
        "      greenOffset -= velocity / sampleCount; " +
        
        "      accumulator.b += sample(image, samplerTransform (image, dc + blueOffset)).b; " +
        "      blueOffset -= velocity / sampleCount; " +
        "  } " +
        "  return vec4(vec3(accumulator / float(sampleCountInt)), 1.0); " +
        "}")
    
    override var outputImage: CIImage? {
        guard let inputImage = inputImage,
            let kernel = transverseChromaticAberrationKernel else { return nil }
        
        let args = [inputImage,
                    CIVector(x: inputImage.extent.width, y: inputImage.extent.height),
                    inputSamples,
                    inputFalloff,
                    inputBlur] as [Any]
        
        return kernel.apply(
            extent: inputImage.extent,
            roiCallback: {
                (index, rect) in
                return rect.insetBy(dx: -1, dy: -1)
            },
            arguments: args)
        
        
    }
}
