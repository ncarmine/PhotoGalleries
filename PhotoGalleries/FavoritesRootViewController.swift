//  FavoritesRootViewController.swift
//  PhotoGalleries
//  Created by ncarmine 2016

import UIKit
import CoreData

class FavoritesRootViewController: RootViewController {
    
    var delegate: imageUnfavoritedDelegate?
    var imageIndexPath: NSIndexPath?

    override func favFunk() {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        
        //Find the index of the photo to be deleted
        if let deletedPhotoIndex = (favImageNames!).indexOf(currentPhoto!.filename) {
            //Get the entity
            let deletedPhoto = favImages![deletedPhotoIndex]
            //Delete the photo from CoreData
            managedContext.deleteObject(deletedPhoto as NSManagedObject)
            var error: NSError?
            do {
                try managedContext.save()
                //Remove the image from the inherited arrays
                favImages?.removeAtIndex(deletedPhotoIndex)
                favImageNames?.removeAtIndex(deletedPhotoIndex)
                updatePhoto(currentPhoto!)
                //Go back to the previous view controller
                navigationController?.popViewControllerAnimated(true)
                //Tell FavoritesCollectionViewController it has one less image
                delegate?.imageUnfavorited(imageIndexPath!)
            } catch let error1 as NSError {
                error = error1
                print("Could not delete \(error), \(error?.userInfo)")
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}