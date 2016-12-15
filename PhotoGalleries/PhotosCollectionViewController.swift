//  PhotosCollectionViewController.swift
//  PhotoGalleries
//  Created by ncarmine 2016

import UIKit
import CoreData

extension UIImage {
    class func imageWithColor(color: UIColor) -> UIImage {
        //Create a 1x1 pixel context and fill it with given color
        let rect = CGRectMake(0, 0, 1, 1)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        color.setFill()
        UIRectFill(rect)
        //Return the image with the colored pixel context
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

class PhotosCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    let reuseIdentifier = "PhotoCell"
    var jsonPassed: JSON?
    
    var imageArray = [Photo]()
    var selectedPhotos = [String]()
    
    var globalCellSpacing = CGFloat(2)
    var storyboardSuffix: String?
    var viewTitle: String?
    
    var selecting = false {
        didSet {
            //Remove all selected photos when selecting is over
            for indexPath in collectionView!.indexPathsForSelectedItems()! {
                removeSelect(indexPath)
            }
            collectionView?.allowsMultipleSelection = selecting
            collectionView?.selectItemAtIndexPath(nil, animated: true, scrollPosition: .None)
            selectedPhotos.removeAll(keepCapacity: false)
        }
    }
    
    func doneSelecting() {
        selecting = false
        //Set navigation items to non-selection mode
        self.navigationItem.rightBarButtonItem?.title = "Select"
        self.navigationItem.leftBarButtonItem?.title = nil
        self.navigationItem.leftBarButtonItem?.image = UIImage(named: "Triple_bars")
        self.navigationItem.rightBarButtonItem?.enabled = true
        self.navigationItem.title = viewTitle
    }
    
    @IBAction func Select(sender: AnyObject) {
        if !selecting {
            selecting = true
            //Set navigation items to selection mode
            self.navigationItem.leftBarButtonItem?.image = nil
            self.navigationItem.leftBarButtonItem?.title = "Cancel"
            self.navigationItem.rightBarButtonItem?.title = "Favorite"
            self.navigationItem.rightBarButtonItem?.enabled = false
            updateSelectedPhotoCount()
        } else if selecting && !selectedPhotos.isEmpty {
            //Get names of favorited images and setup CoreData
            let favImages = PhotosCollectionViewController.getFavoriteNames(PhotosCollectionViewController.fetchFavorites())
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            let managedContext = appDelegate.managedObjectContext
            let entity = NSEntityDescription.entityForName("FavImages", inManagedObjectContext: managedContext)
            var alertError = false
            
            for sp in 0..<selectedPhotos.count {
                let selectedPhoto = selectedPhotos[sp]
                //First check if selected photo is already favorited to avoid duplicates
                if !favImages.contains(selectedPhoto) {
                    //Get the Photo struct of each selected photo
                    var favPhoto: Photo? = nil
                    for imgIndex in 0..<imageArray.count {
                        if selectedPhoto == imageArray[imgIndex].filename {
                            favPhoto = imageArray[imgIndex]
                            break
                        }
                    }
                    
                    //Assign selected photo to NSManagedObject
                    let favImage = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
                    favImage.setValue(favPhoto!.filename, forKey: "filename")
                    favImage.setValue(favPhoto!.title, forKey: "title")
                    favImage.setValue(favPhoto!.caption, forKey: "caption")
                    
                    //Save it if no errors arise
                    var error: NSError?
                    do {
                        try managedContext.save()
                    } catch let error1 as NSError {
                        error = error1
                        print("Could not save \(error), \(error?.userInfo)")
                        alertError = true
                    }
                }
            }
            doneSelecting()
            //Display alert to confirm to user that images were favorited
            var alertTitle = "Images Favorited"
            if alertError {
                alertTitle = "Error Favoriting Images"
            }
            //Setup and display alert
            let favoritedAlert = UIAlertController(title: alertTitle, message: nil, preferredStyle: .Alert)
            self.presentViewController(favoritedAlert, animated: true, completion: nil)
            //Timer for how long alert should be displayed
            let dismissDelay = 1.5 * Double(NSEC_PER_SEC)
            let time = dispatch_time(DISPATCH_TIME_NOW, Int64(dismissDelay))
            dispatch_after(time, dispatch_get_main_queue(), {
                favoritedAlert.dismissViewControllerAnimated(true, completion: nil)
            })
        }
    }
    
    @IBAction func menuFav(sender: AnyObject) {
        if !selecting && self.revealViewController() != nil {
            //Opens sidemenu
            revealViewController().revealToggle(nil)
        } else {
            doneSelecting()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Create background images for the nav bar (portrait & landscape)
        let gradientImage44 = UIImage.imageWithColor(UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.75))
        let gradientImage32 = UIImage.imageWithColor(UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.75))
        
        //Set the background images of the nav bar, and set it to black so the text is white
        self.navigationController?.navigationBar.setBackgroundImage(gradientImage44, forBarMetrics: .Default)
        self.navigationController?.navigationBar.setBackgroundImage(gradientImage32, forBarMetrics: .Compact)
        self.navigationController?.navigationBar.barStyle = .Black
        
        if storyboardSuffix != nil {
            switch storyboardSuffix! {
            case "Gal":
                viewTitle = "Featured"
            case "Fav":
                viewTitle = "Favorites"
            case "Gal2":
                viewTitle = "Gallery Two"
            default:
                viewTitle = nil
            }
        } else {
            //On startup, no segue to this view, so no storyboardSuffix
            //App starts up to Gallery view, so assign values manually
            viewTitle = "Featured"
            storyboardSuffix = "Gal"
        }
        
        //self.navigationController?.navigationBar.barStyle = .Black
        self.navigationItem.title = viewTitle
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PhotosCollectionViewController.rotated), name: UIDeviceOrientationDidChangeNotification, object: nil)
        
        globalCellSpacing = findCellSpacing()
        
        //Setup sidemenu
        if self.revealViewController() != nil {
            self.navigationController?.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
            self.navigationController?.view.addGestureRecognizer(self.revealViewController().tapGestureRecognizer())

            self.revealViewController().rearViewRevealWidth = 250
            self.revealViewController().rearViewRevealOverdraw = 0.0
            self.revealViewController().toggleAnimationDuration = 0.22
        }
        
        setupImages()
    }
    
    func setupImages() {
        //Load "PhotoGalleries.json" file into json variable
        var json: JSON?
        
        if jsonPassed == nil {
            json = JSONInfo().json
        } else {
            json = jsonPassed!
        }
        
        
//        let defaults = NSUserDefaults.standardUserDefaults()
//        
//        
//        if let storedJSON = defaults.objectForKey("stored_json_data") as? NSData {
//            jsonInfo = NSKeyedUnarchiver.unarchiveObjectWithData(storedJSON) as? JSONInfo
//        }
//        if jsonInfo?.json == nil {
//            jsonInfo = JSONInfo()
//            let data = NSKeyedArchiver.archivedDataWithRootObject(jsonInfo!)
//            defaults.setObject(data,forKey: "stored_json_data")
//            defaults.synchronize()
//        }
        

        //For each gallery, load in the photos from the json data
        if storyboardSuffix != nil {
            switch storyboardSuffix! {
            case "Gal":
                imageArray = getImageArray(json!, arrayName: "colors")
            case "Gal2":
                imageArray = getImageArray(json!, arrayName: "hiking")
            default:
                imageArray = getImageArray(json!, arrayName: "default")
            }
        }
    }
    
    func getImageArray(json: JSON, arrayName: String) -> [Photo] {
        var imageArray = [Photo]()
        let jsonArray = json[arrayName]
        
        //Load json data for each image dict into imageArray
        for (_, image):(String, JSON) in jsonArray {
            imageArray.append(Photo(filename: image["filename"].string!,
                title: image["title"].string!,
                caption: image["caption"].string!))
        }
        
        //returns empty Photo array if json[arrayName] is not found
        return imageArray
    }

    //MARK - UICollectionViewDataSource
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageArray.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! PhotoCollectionViewCell
    
        //Configure the cell
        let image = UIImage(named: imageArray[indexPath.row].filename)
        cell.imageView.image = image
        cell.imageView.tag = 303

        return cell
    }
    
    //MARK - Cell Spacing and Layout
    func findItemsPerRow(screenWidth: CGFloat) -> CGFloat {
        //iPhone 4S, 5, 5s
        if screenWidth < 600 {
            return floor(screenWidth/100)
        //iPads in landscape
        } else if screenWidth > 1000 {
            return ceil(screenWidth/150)
        //All other iPhones, and iPads in portrait
        } else {
            return round(screenWidth/125)
        }
    }
    
    func findCellSpacing() -> CGFloat {
        let screenWidth = collectionView!.bounds.size.width
        let numColumns = findItemsPerRow(screenWidth)
        var cellSpacing = 2
        
        //Ensure the cell spacing is an integer
        //Horizontal spacing gets messy with non-ints
        while (screenWidth - (CGFloat(cellSpacing) * (numColumns-1))) % numColumns != 0 {
            cellSpacing += 1
        }

        return CGFloat(cellSpacing)
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let screenWidth = collectionView.bounds.size.width
        let numColumns = findItemsPerRow(screenWidth)
        let cellSpacing = globalCellSpacing
        
        let totalSpace = CGFloat(cellSpacing) * (numColumns-1)
        let cellSize = (screenWidth - totalSpace) / numColumns
        return CGSizeMake(cellSize, cellSize)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return globalCellSpacing
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return globalCellSpacing
    }

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        //Redo layout upon rotation
        collectionViewLayout.invalidateLayout()
        globalCellSpacing = findCellSpacing()
    }
    
    func rotated() {
        //Redo sizing of selection subviews upon rotation
        //viewWillTransitionToSize will get called first
        //invalidateLayout() neeeds time to work, thus new function
        if selecting {
            for indexPath in collectionView!.indexPathsForSelectedItems()! {
                removeSelect(indexPath)
                addSelect(indexPath)
            }
        }
    }
    
    //MARK - Selection
    func updateSelectedPhotoCount() {
        self.navigationItem.title = "\(selectedPhotos.count) photos selected"
        if selectedPhotos.count > 0 {
            self.navigationItem.rightBarButtonItem?.enabled = true
        } else {
            self.navigationItem.rightBarButtonItem?.enabled = false
        }
    }
    
    func addSelect(indexPath: NSIndexPath) {
        //Get cell image
        let cell = collectionView!.cellForItemAtIndexPath(indexPath)
        let cellImageView: UIImageView = cell?.viewWithTag(303) as! UIImageView
        let cellImage = cellImageView.image
        
        //Subtract 50% opacity with this image
        let selectBg = UIImage(named: "Selected_background")
        let selectBgView = UIImageView(image: selectBg)
        
        //Setup for a square image first
        var BgOriginX = CGFloat(0)
        var BgOriginY = CGFloat(0)
        var BgViewWidth = cell!.frame.width
        var BgViewHeight = cell!.frame.height
        
        //Get the appropriate size for the shaded area
        if cellImage?.size.width > cellImage?.size.height {
            //Divide cell height by image aspect ratio to get the height of the image
            BgViewHeight /= (cellImage!.size.width / cellImage!.size.height)
            //Set the shaded area so it's 50% down the cell, lining up with the image
            BgOriginY = (cell!.frame.height - BgViewHeight) / 2.0
        //Same thing for if it's taller than it is wide
        } else if cellImage?.size.height > cellImage?.size.width {
            BgViewWidth /= (cellImage!.size.height / cellImage!.size.width)
            BgOriginX = (cell!.frame.width - BgViewWidth) / 2.0
        } //If the image is a perfect square, no need for calculations
        
        selectBgView.frame = CGRectMake(BgOriginX, BgOriginY, BgViewWidth, BgViewHeight)
        cell?.addSubview(selectBgView)
        
        //Check mark in a circle image
        let selectChk = UIImage(named: "Selected_check")
        let selectChkView = UIImageView(image: selectChk)
        
        //Bring it over the origin amount
        //Then add the width/height of cell image
        //Subtract by (check image size (25x25) + 5) for alignment and spacing
        let selectChkOriginX = BgOriginX + BgViewWidth - 30
        let selectChkOriginY = BgOriginY + BgViewHeight - 30
        
        selectChkView.frame = CGRectMake(selectChkOriginX, selectChkOriginY, 25, 25)
        cell?.addSubview(selectChkView)
    }
    
    func removeSelect(indexPath: NSIndexPath) {
        let cell = collectionView!.cellForItemAtIndexPath(indexPath)
        //Remove all images made above - does not remove cell image
        if let subViews = cell?.subviews {
            for subView in subViews {
                if subView is UIImageView {
                    subView.removeFromSuperview()
                }
            }
        }
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if selecting {
            if !selectedPhotos.contains(imageArray[indexPath.row].filename) {
                collectionView.cellForItemAtIndexPath(indexPath)?.selected = true
                addSelect(indexPath)
                selectedPhotos.append(imageArray[indexPath.row].filename)
                updateSelectedPhotoCount()
            }
        }
    }
    
    override func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        if selecting {
            if let foundPhoto = selectedPhotos.indexOf(imageArray[indexPath.row].filename) {
                collectionView.cellForItemAtIndexPath(indexPath)?.selected = false
                removeSelect(indexPath)
                selectedPhotos.removeAtIndex(foundPhoto)
                updateSelectedPhotoCount()
            }
        }
    }
    
    //MARK - Fetching Favorites
    class func fetchFavorites() -> [NSManagedObject] {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        
        let fetchRequest = NSFetchRequest(entityName: "FavImages")
        do {
            let result = try managedContext.executeFetchRequest(fetchRequest) as? [NSManagedObject]
            return result!
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        return []
    }
    
    class func getFavoriteNames(favorites: [NSManagedObject]) -> [String] {
        var favNames = [String]()
        for favorite in favorites {
            if let favName = favorite.valueForKey("filename") as? String {
                favNames.append(favName)
            }
        }
        return favNames
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //MARK - Navigation
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if identifier == "full_image" {
            return !selecting
        }
        return true
    }
    
    override func viewDidAppear(animated: Bool) {
        //Reset title when going back to this view
        self.title = viewTitle
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        self.title = nil //Make back button say "Back"
        
        let fullView = segue.destinationViewController as! RootViewController
        if let indexPath = self.collectionView?.indexPathForCell(sender as! UICollectionViewCell) {
            if segue.identifier == "full_image" {
                fullView.photoArray = imageArray
                fullView.currentPhoto = imageArray[indexPath.row]
                fullView.favImages = PhotosCollectionViewController.fetchFavorites()
                fullView.favImageNames = PhotosCollectionViewController.getFavoriteNames(PhotosCollectionViewController.fetchFavorites())
                
                fullView.imageIndex = indexPath.row
                fullView.PVCStoryboardID = "PageViewController" + storyboardSuffix!
                fullView.CVCStoryboardID = "ContentViewController" + storyboardSuffix!
                fullView.infoSegue = "info_segue-" + storyboardSuffix!
            }
        }
    }
}