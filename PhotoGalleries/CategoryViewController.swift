//  CategoryViewController.swift
//  PhotoGalleries
//  Created by ncarmine 2016

import UIKit

class CategoryViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    let reuseIdentifier = "Category"
    let thumbReuseIdentifier = "ThumbnailCell"

    var thumbCollectSuffix: String?
    var categories = [Category]()
    
    @IBAction func hamburgerButton(sender: AnyObject) {
        revealViewController().revealToggle(nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //Setup sidemenu
        if self.revealViewController() != nil {
            self.navigationController?.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
            self.navigationController?.view.addGestureRecognizer(self.revealViewController().tapGestureRecognizer())
            
            self.revealViewController().rearViewRevealWidth = 250
            self.revealViewController().rearViewRevealOverdraw = 0.0
            self.revealViewController().toggleAnimationDuration = 0.22
        }
    }

    //MARK - UICollectionViewDataSource
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categories.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! CategoryCollectionViewCell
        
        //Set cell title appropriately
        cell.catTitle.text = categories[indexPath.row].catTitle
        
        //If the view already exists, remove it
        if cell.thumbnailCollectionView != nil {
            cell.thumbnailCollectionView?.willMoveToParentViewController(nil)
            cell.thumbnailCollectionView?.view.removeFromSuperview()
            cell.thumbnailCollectionView?.removeFromParentViewController()
        }
    
        //Create a new subclassed CollectionViewController (ThumbnailCollectionViewController) from the storyboard
        let thumbsViewController = self.storyboard?.instantiateViewControllerWithIdentifier("ThumbnailColllection-" + thumbCollectSuffix!) as! ThumbnailCollectionViewController
        //Set the images for that view controler to display
        thumbsViewController.thumbnails = categories[indexPath.row].catImages
        //println(indexPath.row)
        //Add the view controller as a child VC
        self.addChildViewController(thumbsViewController)
        //Setup frame
        let spacing: CGFloat = 5
        let cellY = cell.catTitle.frame.maxY+spacing
        thumbsViewController.view.frame = CGRectMake(spacing, cellY, cell.bounds.width-(spacing*2), cell.bounds.height-cellY-spacing)
        //Add the view of thumbsViewController as a subview
        cell.addSubview(thumbsViewController.view)
        thumbsViewController.didMoveToParentViewController(self)
        cell.thumbnailCollectionView = thumbsViewController
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        //Set frame for each CategoryCollectionViewControllerCell
        let width = collectionView.bounds.width - 20
        var height: CGFloat = 150
        if UIDeviceOrientationIsLandscape(UIDevice.currentDevice().orientation) && collectionView.bounds.height < 700 { UIDevice.currentDevice()
            //Keep height for iPad in landscape
            height = 100
        }
        return CGSizeMake(width, height)
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        //Redo layout and cell data upon rotation
        collectionViewLayout.invalidateLayout()
        collectionView?.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}