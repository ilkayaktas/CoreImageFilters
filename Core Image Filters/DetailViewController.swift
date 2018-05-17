//
//  DetailViewController.swift
//  Core Image Filters
//
//  Created by Eugene Bokhan on 5/16/18.
//  Copyright © 2018 Eugene Bokhan. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {
    
    // MARK: - UI Elements
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewHeightConstraint: NSLayoutConstraint!
    
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
    
    // MARK: - Properties
    
    #if !arch(i386) && !arch(x86_64)
    let ciMetalContext = CIContext(mtlDevice: MTLCreateSystemDefaultDevice()!)
    #else
    let ciMetalContext = CIContext()
    #endif
    
    let ciOpenGLESContext = CIContext()
    
    let rect640x640 = CGRect(x: 0, y: 0, width: 640, height: 640)
    let compositeOverBlackFilter = CompositeOverBlackFilter()
    
    /// Whether the user has changed the filter whilst it's
    /// running in the background.
    var pending = false
    
    /// Whether a filter is currently running in the background
    var busy = false {
        didSet {
            if busy {
                activityIndicator.startAnimating()
            }
            else {
                activityIndicator.stopAnimating()
            }
        }
    }
    
    var filterName: String?
    
    public var currentFilter: CIFilter?
    
    /// User defined filter parameter values
    public var filterParameterValues: [String: AnyObject] = [kCIInputImageKey: assets.first!.ciImage]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupImageView()
        setupTableView()
        
        updateFromFilterName()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupImageViewConstraints()
        setupTableViewConstraints()
        
        tableView.separatorStyle = UITableViewCellSeparatorStyle.none
        
        activityIndicator.frame = imageView.bounds
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Setup UI
    
    func setupImageView() {
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.addSubview(activityIndicator)
    }
    
    func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(FilterInputItemRenderer.self, forCellReuseIdentifier: "FilterInputItemRenderer")
        tableView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    // MARK: - Layout
    
    func setupImageViewConstraints() {
        
        switch UIApplication.shared.statusBarOrientation {
        case .portrait, .portraitUpsideDown:
            imageViewWidthConstraint.constant = view.bounds.width
            imageViewHeightConstraint.constant = view.bounds.height / 2
        case .landscapeLeft, .landscapeRight:
            imageViewWidthConstraint.constant = view.bounds.width / 2
            imageViewHeightConstraint.constant = view.bounds.height
        case .unknown:
            break
        }
    }
    
    func setupTableViewConstraints() {
        
        switch UIApplication.shared.statusBarOrientation {
        case .portrait, .portraitUpsideDown:
            tableViewWidthConstraint.constant = view.bounds.width
            tableViewHeightConstraint.constant = view.bounds.height / 2
        case .landscapeLeft, .landscapeRight:
            tableViewWidthConstraint.constant = view.bounds.width / 2
            tableViewHeightConstraint.constant = view.bounds.height
        case .unknown:
            break
        }
    }
    
    func updateFromFilterName() {
        guard let filterName = filterName, let filter = CIFilter(name: filterName) else { return }
        
        imageView.subviews
            .filter({ $0 is FilterAttributesDisplayable})
            .forEach({ $0.removeFromSuperview() })
        
        if let widget = OverlayWidgets.getOverlayWidgetForFilter(filterName) as? UIView {
            imageView.addSubview(widget)
            widget.frame = imageView.bounds
        }
        
        currentFilter = filter
        fixFilterParameterValues()
        
        tableView.reloadData()
        
        applyFilter()
    }
    
    /// Assign a default image if required and ensure existing
    /// filterParameterValues won't break the new filter.
    func fixFilterParameterValues() {
        guard let currentFilter = currentFilter else { return }
        
        let attributes = currentFilter.attributes
        
        for inputKey in currentFilter.inputKeys {
            if let attribute = attributes[inputKey] as? [String : Any] {
                // default image
                if let className = attribute[kCIAttributeClass] as? String
                    , className == "CIImage" && filterParameterValues[inputKey] == nil {
                    filterParameterValues[inputKey] = assets.first!.ciImage
                }
                
                // ensure previous values don't exceed kCIAttributeSliderMax for this filter
                if let maxValue = attribute[kCIAttributeSliderMax] as? Float,
                    let filterParameterValue = filterParameterValues[inputKey] as? Float
                    , filterParameterValue > maxValue {
                    filterParameterValues[inputKey] = maxValue as AnyObject?
                }
                
                // ensure vector is correct length
                if let defaultVector = attribute[kCIAttributeDefault] as? CIVector,
                    let filterParameterValue = filterParameterValues[inputKey] as? CIVector
                    , defaultVector.count != filterParameterValue.count {
                    filterParameterValues[inputKey] = defaultVector
                }
            }
        }
    }
    
    func applyFilter()
    {
        guard !busy else  {
            pending = true
            return
        }
        
        guard let currentFilter = self.currentFilter else {
            return
        }
        
        busy = true
        
        imageView.subviews
            .filter({ $0 is FilterAttributesDisplayable})
            .forEach({ ($0 as? FilterAttributesDisplayable)?.setFilter(currentFilter) })
        
        let queue = currentFilter is VImageFilter ?
            DispatchQueue.main :
            DispatchQueue.global(qos: DispatchQoS.QoSClass.default)
        
        queue.async {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            for (key, value) in self.filterParameterValues where currentFilter.inputKeys.contains(key) {
                currentFilter.setValue(value, forKey: key)
            }
            
            let outputImage = currentFilter.outputImage!
            let finalImage: CGImage
            
            let context = (currentFilter is MetalRenderable) ? self.ciMetalContext : self.ciOpenGLESContext
            
            if outputImage.extent.width == 1 || outputImage.extent.height == 1 {
                // if a filter's output image height or width is 1,
                // (e.g. a reduction filter) stretch to 640x640
                
                let stretch = CIFilter(name: "CIStretchCrop", withInputParameters: ["inputSize": CIVector(x: 640, y: 640), "inputCropAmount": 0, "inputCenterStretchAmount": 1, kCIInputImageKey: outputImage])!
                
                finalImage = context.createCGImage(stretch.outputImage!, from: self.rect640x640)!
            }
            else if outputImage.extent.width < 640 || outputImage.extent.height < 640 {
                // if a filter's output image is smaller than 640x640 (e.g. circular wrap or lenticular
                // halo), composite the output over a black background)
                
                self.compositeOverBlackFilter.setValue(outputImage, forKey: kCIInputImageKey)
                
                finalImage = context.createCGImage(self.compositeOverBlackFilter.outputImage!, from: self.rect640x640)!
            } else { finalImage = context.createCGImage(outputImage, from: self.rect640x640)! }
            
            let endTime = (CFAbsoluteTimeGetCurrent() - startTime)
            
            DispatchQueue.main.async {
                
                self.imageView.image = UIImage(cgImage: finalImage)
                self.busy = false
                
                if self.pending {
                    self.pending = false
                    self.applyFilter()
                }
            }
        }
    }
    
}

// MARK: UITableViewDelegate extension

extension DetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 85
    }
}

// MARK: UITableViewDataSource extension

extension DetailViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentFilter?.inputKeys.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FilterInputItemRenderer",
                                                 for: indexPath) as! FilterInputItemRenderer
        
        if let inputKey = currentFilter?.inputKeys[(indexPath as NSIndexPath).row],
            let attribute = currentFilter?.attributes[inputKey] as? [String : Any] {
            cell.detail = (inputKey: inputKey,
                           attribute: attribute,
                           filterParameterValues: filterParameterValues)
        }
        
        cell.delegate = self
        
        return cell
    }
}

// MARK: FilterInputItemRendererDelegate extension

extension DetailViewController: FilterInputItemRendererDelegate {
    func filterInputItemRenderer(_ filterInputItemRenderer: FilterInputItemRenderer, didChangeValue: AnyObject?, forKey: String?) {
        if let key = forKey, let value = didChangeValue {
            filterParameterValues[key] = value
            applyFilter()
        }
    }
    
    @objc(tableView:shouldHighlightRowAtIndexPath:) func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}
