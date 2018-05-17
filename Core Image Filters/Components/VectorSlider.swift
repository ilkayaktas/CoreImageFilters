//
//  VectorSlider.swift
//  Core Image Filters
//
//  Created by Eugene Bokhan on 5/17/18.
//  Copyright © 2018 Eugene Bokhan. All rights reserved.
//

import UIKit

class VectorSlider: UIControl {
    
    var maximumValue: CGFloat?
    
    let stackView: UIStackView = {
        
        let stackView = UIStackView()
        
        stackView.distribution = UIStackViewDistribution.fillEqually
        stackView.axis = UILayoutConstraintAxis.horizontal
        
        return stackView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(stackView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var vectorWithMaximumValue: (vector: CIVector?, maximumValue: CGFloat?)? {
        didSet {
            maximumValue = vectorWithMaximumValue?.maximumValue
            vector = vectorWithMaximumValue?.vector
        }
    }
    
    private(set) var vector: CIVector? {
        didSet {
            if (vector?.count ?? 0) != oldValue?.count {
                rebuildUI()
            }
            
            guard let vector = vector else {
                return
            }
            
            for (index, slider) in stackView.arrangedSubviews.enumerated() where slider is UISlider {
                if let slider = slider as? UISlider {
                    slider.value = Float(vector.value(at: index))
                }
            }
        }
    }
    
    func rebuildUI() {
        stackView.arrangedSubviews.forEach
            {
                $0.removeFromSuperview()
        }
        
        guard let vector = vector else {
            return
        }
        
        let sliderMax = maximumValue ?? vector.sliderMax
        
        for _ in 0 ..< vector.count {
            
            let slider = UISlider()
            
            slider.maximumValue = Float(sliderMax)
            slider.addTarget(self, action: #selector(VectorSlider.sliderChangeHandler), for: UIControlEvents.valueChanged)
            
            stackView.addArrangedSubview(slider)
        }
    }
    
    @objc
    func sliderChangeHandler() {
        
        let values = stackView.arrangedSubviews
            .filter({ $0 is UISlider })
            .map({ CGFloat(($0 as! UISlider).value) })
        
        vector = CIVector(values: values,
                          count: values.count)
        
        sendActions(for: UIControlEvents.valueChanged)
    }
    
    override func layoutSubviews() {
        stackView.frame = bounds
        stackView.spacing = 5
    }
}


extension CIVector {
    /// If the maximum of any of the vector's values is greater than one,
    /// return double that, otherwise, return 1.
    ///
    /// `CIVector(x: 10, y: 12, z: 9, w: 11).sliderMax` = 24
    /// `CIVector(x: 0, y: 1, z: 1, w: 0).sliderMax` = 1
    
    var sliderMax: CGFloat
    {
        var maxValue: CGFloat = 1
        
        for i in 0 ..< self.count {
            maxValue = max(maxValue,
                           self.value(at: i) > 1 ? self.value(at: i) * 2 : 1)
        }
        
        return maxValue
    }
}

