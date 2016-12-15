//  SidemenuViewController.swift
//  PhotoGalleries
//  Created by ncarmine 2016

import UIKit

class SidemenuViewController: UITableViewController {
    
    let menuItems = ["Gallery", "Favorites", "Gal2", "Cat1", "Cat2", "About", "Packs", "Ads"]
    var isFirst = true
    typealias dict = [String: AnyObject]
    let json = JSONInfo().json
    
    override func viewDidLoad() {
        //Hides lines for unused cell
        let hideLinesView = UIView(frame: CGRectZero)
        self.tableView.tableFooterView = hideLinesView
        setRowHeight(view.frame.size)
    }
    
    override func viewWillAppear(animated: Bool) {
        if isFirst {
            //Set first row as selected
            let firstIndexPath = NSIndexPath(forRow: 0, inSection: 0)
            self.tableView.selectRowAtIndexPath(firstIndexPath, animated: true, scrollPosition: .Top)
            tableView(tableView, didSelectRowAtIndexPath: firstIndexPath)
            isFirst = false
        }
    }
    
    override func viewWillLayoutSubviews() {
        //Safeguard against toplayoutguide being 0 in portrait
        let statusBarHeight = UIApplication.sharedApplication().statusBarFrame.height
        if statusBarHeight < 40 {
            tableView.contentInset = UIEdgeInsetsMake(statusBarHeight, 0, 0, 0)
        } else if statusBarHeight == 40 {
            tableView.contentInset = UIEdgeInsetsMake(20, 0, 0, 0)
        }
        
        //Add black background view underneath status bar
        view.viewWithTag(808)?.removeFromSuperview()
        if statusBarHeight == 20 {
            let blackView = UIView()
            blackView.tag = 808
            blackView.backgroundColor = UIColor.blackColor()
            blackView.frame = CGRectMake(0, -statusBarHeight, view.frame.width, statusBarHeight)
            view.addSubview(blackView)
        }
        
    }
    
    //MARK - TableViewDelegate
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        //Background color sets line color between rows
        cell.backgroundColor = UIColor.blackColor()
        //ContentView bg color sets color below text
        cell.contentView.backgroundColor = UIColor(white: 0.9, alpha: 1.0)
        
        //Makes separator go (mostly) to left edge
        tableView.separatorInset.left = 0
        tableView.separatorInset = UIEdgeInsetsZero
        tableView.layoutMargins = UIEdgeInsetsZero
        tableView.preservesSuperviewLayoutMargins = false
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //Setup view for selected items
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        cell!.backgroundColor = UIColor.blackColor()
        cell!.contentView.backgroundColor = UIColor(white: 0.7, alpha: 1.0)
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        //Redo sizing upon rotation
        setRowHeight(size)
    }
    
    func setRowHeight(size: CGSize) {
        tableView.beginUpdates()
        if size.height > 500 { //iPhones other than 4S in portrait, iPads
            tableView.rowHeight = 64
        } else { // iPhone 4S in both orientations, other iPhones in landscape
            tableView.rowHeight = 44
        }
        tableView.endUpdates()
    }
    
    func getImageArray(json: dict, arrayName: String) -> [Photo] {
        var imageArray = [Photo]()
        //Each image is its own dictionary with image data
        guard let imageDicts = json[arrayName] as? [dict] else {
            return imageArray //return the empty imageArray if the gallery name is not found
        }
        //If gallery name is found, load in the corresponding Photo for each image json data
        for imageDict in imageDicts {
            imageArray.append(Photo(filename: imageDict["filename"]! as! String,
                title: imageDict["title"]! as! String,
                caption: imageDict["caption"]! as! String))
        }
        return imageArray
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
//    func getImageArray(json: JSON, arrayName: String) -> [Photo] {
//        var imageArray = [Photo]()
//        let jsonArray = json[arrayName]
//        
//        //Load json data for each image dict into imageArray
//        for (_, image):(String, JSON) in jsonArray {
//            imageArray.append(Photo(filename: image["filename"].string!,
//                title: image["title"].string!,
//                caption: image["caption"].string!))
//        }
//        
//        //returns empty Photo array if json[arrayName] is not found
//        return imageArray
//    }
    
    func getCategories(json: JSON) -> [Category] {
        var categories = [Category]()
        
        //Load json data for each image dict into imageArray
        for (cat, colors):(String, JSON) in json {
            var imageFilenames = [String]()
            for (_, color):(String, JSON) in colors {
                imageFilenames.append(color["filename"].string!)
            }
            categories.append(Category(catTitle: cat, catImages: imageFilenames))
        }
        
        //returns empty Photo array if json[arrayName] is not found
        return categories
    }
    
    //MARK - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let navController = segue.destinationViewController as! UINavigationController
        
        let gridSegue = navController.topViewController as? PhotosCollectionViewController
        let catSegue = navController.topViewController as? CategoryViewController
        
        //Pass along the segueID to identify which image set to load in future views
        if self.tableView?.indexPathForCell(sender as! UITableViewCell) != nil {
            let segueID = segue.identifier!
            switch segueID {
            case "Gal", "Fav", "Gal2":
                gridSegue!.storyboardSuffix = segueID
            case "Cat1":
                catSegue!.categories = getCategories(json!["colorsCat"])
                catSegue?.thumbCollectSuffix = segueID
            case "Cat2":
                catSegue!.categories = getCategories(json!["colorsCat"])
                catSegue?.thumbCollectSuffix = segueID
            default:
                break
            }
        }
    }
}