//  FavoritesCollectionViewController.swift
//  PhotoGalleries
//  Created by ncarmine 2016

import UIKit
import CoreData

//Protocol for FavoritesRootViewController
protocol imageUnfavoritedDelegate {
    func imageUnfavorited(indexPath: NSIndexPath)
}

class FavoritesCollectionViewController: PhotosCollectionViewController, imageUnfavoritedDelegate {

    override func setupImages() {
        //Fill imageArray (inherited) with all images currently favorited
        let favImages = PhotosCollectionViewController.fetchFavorites()
        let favNames = PhotosCollectionViewController.getFavoriteNames(favImages)
        let favTitles = getFavoriteTitles(favImages)
        let favCaptions = getFavoriteCaptions(favImages)
        
        for favIndex in 0..<favImages.count {
            imageArray.append(Photo(filename: favNames[favIndex], title: favTitles[favIndex], caption: favCaptions[favIndex]))
        }
    }
    
    func getFavoriteTitles(favorites: [NSManagedObject]) -> [String] {
        var favNames = [String]()
        for favorite in favorites {
            if let favName = favorite.valueForKey("title") as? String {
                favNames.append(favName)
            }
        }
        return favNames
    }
    
    func getFavoriteCaptions(favorites: [NSManagedObject]) -> [String] {
        var favNames = [String]()
        for favorite in favorites {
            if let favName = favorite.valueForKey("caption") as? String {
                favNames.append(favName)
            }
        }
        return favNames
    }
    
    //Displays text for when no images are favorited
    //Called when view loads and when images are deleted if none are left
    func noImages() {
        self.navigationItem.rightBarButtonItem?.title = nil
        let detailsText = UITextView(frame: CGRect(x: 0, y: 0, width: 300, height: 200))
        detailsText.center = collectionView!.center //Set main text to be in center of collectionView
        detailsText.editable = false
        detailsText.text = "Favorite images in a grid by tapping 'Select' at the top-right, selecting a few images, and tapping 'Favorite' at the top-left.\n\nFavorite an image when viewing it by tapping the star at the top-right."
        detailsText.backgroundColor = UIColor.clearColor()
        detailsText.textColor = UIColor(white: 0.9, alpha: 1.0)
        detailsText.font = UIFont(name: detailsText.font!.fontName, size: 18)
        view.addSubview(detailsText)

        let noFavsLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 20))
        //Set title of text just above main part of text
        noFavsLabel.center = CGPoint(x: collectionView!.center.x, y: detailsText.frame.minY - noFavsLabel.frame.height)
        noFavsLabel.textAlignment = .Center
        noFavsLabel.text = "No Favorited Images"
        noFavsLabel.font = UIFont(name: "Helvetica-Bold", size: 18)
        noFavsLabel.textColor = UIColor(white: 0.9, alpha: 1.0)
        view.addSubview(noFavsLabel)
    }
    
    override func viewWillLayoutSubviews() {
        //Remove "No Favorited Images" message if present up reorientation
        for subview in view.subviews {
            if subview is UILabel || subview is UITextView {
                subview.removeFromSuperview()
            }
        }

        if imageArray.count > 0 {
            self.navigationItem.rightBarButtonItem?.title = "Select"
        } else {
            noImages()
        }
    }
    
    override func doneSelecting() {
        selecting = false
        if imageArray.count > 0 {
            self.navigationItem.rightBarButtonItem?.title = "Select"
            self.navigationItem.rightBarButtonItem?.enabled = true
        } else {
            //Remove "Select" button if there are no images to select
            self.navigationItem.rightBarButtonItem?.title = nil
        }
        self.navigationItem.leftBarButtonItem?.title = nil
        self.navigationItem.leftBarButtonItem?.image = UIImage(named: "Triple_bars")
        self.navigationItem.title = viewTitle
    }
    
    override func Select(sender: AnyObject) {
        if !selecting {
            selecting = true
            self.navigationItem.leftBarButtonItem?.image = nil
            self.navigationItem.leftBarButtonItem?.title = "Cancel"
            self.navigationItem.rightBarButtonItem?.title = "Remove"
            self.navigationItem.rightBarButtonItem?.enabled = false
            updateSelectedPhotoCount()
        } else if selecting && !selectedPhotos.isEmpty {
            //Get entities of favorited images
            let favImages = PhotosCollectionViewController.fetchFavorites()
            let favNames = PhotosCollectionViewController.getFavoriteNames(favImages)
            
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            let managedContext = appDelegate.managedObjectContext
            //let entity = NSEntityDescription.entityForName("FavImages", inManagedObjectContext: managedContext)

            //This time, we know every photo is already in favorites
            //So no need to check first
            for sp in 0..<selectedPhotos.count {
                let selectedPhoto = selectedPhotos[sp]
                //Find index of selected photo filename in CoreData
                let deletedPhotoIndex = favNames.indexOf(selectedPhoto)
                //Get entity at that index
                let deletedPhoto = favImages[deletedPhotoIndex!]
                //Delete the photo from CoreData
                managedContext.deleteObject(deletedPhoto as NSManagedObject)
                
                var error: NSError?
                do {
                    try managedContext.save()
                    print("\"\(selectedPhoto)\" deleted.")
                    
                    //Find the image in the imageArray
                    for imgIndex in 0..<imageArray.count {
                        if selectedPhoto == imageArray[imgIndex].filename {
                            //and remove it
                            imageArray.removeAtIndex(imgIndex)
                            break
                        }
                    }
 
                    
                } catch let error1 as NSError {
                    error = error1
                    print("Could not delete \(error), \(error?.userInfo)")
                }
            }
            //Animate the deletion of the images
            let selectedIndexes = self.collectionView?.indexPathsForSelectedItems()
            self.collectionView?.deleteItemsAtIndexPaths(selectedIndexes!)
            selecting = false
            doneSelecting()
            if imageArray.count <= 0 {
                noImages()
            }
        }
    }
    
    //Called from RootViewController to update this view when image is removed
    func imageUnfavorited(indexPath: NSIndexPath) {
        imageArray.removeAtIndex(indexPath.row)
        self.collectionView?.deleteItemsAtIndexPaths([indexPath])
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        
        let fullView = segue.destinationViewController as! FavoritesRootViewController
        if let indexPath = self.collectionView?.indexPathForCell(sender as! UICollectionViewCell) {
            if segue.identifier == "full_image" {
                fullView.delegate = self
                fullView.imageIndexPath = indexPath
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
