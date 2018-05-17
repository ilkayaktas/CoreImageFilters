//
//  MasterViewController.swift
//  Core Image Filters
//
//  Created by Eugene Bokhan on 5/16/18.
//  Copyright © 2018 Eugene Bokhan. All rights reserved.
//

import UIKit

class MasterViewController: UITableViewController {
    
    // MARK: - UI Elements
    
    var detailViewController: DetailViewController? = nil
    
    // MARK: - Properties
    
    var objects = [Any]()
    
    let filterCategories =
        [
            CategoryCustomFilters,
            kCICategoryBlur,
            kCICategoryColorAdjustment,
            kCICategoryColorEffect,
            kCICategoryCompositeOperation,
            kCICategoryDistortionEffect,
            kCICategoryGenerator,
            kCICategoryGeometryAdjustment,
            kCICategoryGradient,
            kCICategoryHalftoneEffect,
            kCICategoryReduction,
            kCICategorySharpen,
            kCICategoryStylize,
            kCICategoryTileEffect,
            kCICategoryTransition,
            ].sorted{ CIFilter.localizedName(forCategory: $0) < CIFilter.localizedName(forCategory: $1)}
    
    let exclusions = ["CIQRCodeGenerator",
                      "CIPDF417BarcodeGenerator",
                      "CICode128BarcodeGenerator",
                      "CIAztecCodeGenerator",
                      "CIColorCubeWithColorSpace",
                      "CIColorCube",
                      "CIAffineTransform",
                      "CIAffineClamp",
                      "CIAffineTile",
                      "CICrop"] // to do: fix CICrop!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
        
        setupTableView()
        
//        if let split = splitViewController {
//            let controllers = split.viewControllers
//            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
//        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupTableView() {
        tableView.register(UITableViewHeaderFooterView.self,
                           forHeaderFooterViewReuseIdentifier: "HeaderRenderer")
        tableView.register(UITableViewCell.self,
                           forCellReuseIdentifier: "ItemRenderer")
    }
    
    func supportedFilterNamesInCategory(_ category: String?) -> [String]
    {
        return CIFilter.filterNames(inCategory: category).filter {
                !exclusions.contains($0)
        }
    }
    
    func supportedFilterNamesInCategories(_ categories: [String]?) -> [String]
    {
        return CIFilter.filterNames(inCategories: categories).filter {
                !exclusions.contains($0)
        }
    }
    
    // MARK: - Segues
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                
                let filterName: String
                
                filterName = supportedFilterNamesInCategory(filterCategories[(indexPath as NSIndexPath).section]).sorted()[(indexPath as NSIndexPath).row]
                
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.filterName = filterName
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }
    
    // MARK: - Table View
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return filterCategories.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return supportedFilterNamesInCategory(filterCategories[section]).count
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        return 40
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: "HeaderRenderer")! as UITableViewHeaderFooterView
        
        cell.textLabel?.text = CIFilter.localizedName(forCategory: filterCategories[section])
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemRenderer",
                                                 for: indexPath)
        
        let filterName = supportedFilterNamesInCategory(filterCategories[(indexPath as NSIndexPath).section]).sorted()[(indexPath as NSIndexPath).row]
        
        print(CIFilter.localizedName(forFilterName: filterName))
        
        cell.textLabel?.text = CIFilter.localizedName(forFilterName: filterName) ?? (CIFilter(name: filterName)?.attributes[kCIAttributeFilterDisplayName] as? String) ?? filterName
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        performSegue(withIdentifier: "showDetail", sender: cell)
        
    }
    
}
