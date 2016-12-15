//  RootViewController.swift
//  PhotoGalleries
//  Created by ncarmine 2016

import UIKit
import CoreData

//Allows InfoViewController to talk to this view
protocol favoriteChangedDelegate {
    func favoriteChanged()
}

//The status bar has to be hidden from the RootVC
protocol hideNavDelegate {
    func navHiddenChanged(changedNavHidden: Bool)
}

class RootViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, favoriteChangedDelegate, hideNavDelegate {
    
    var pageViewController: UIPageViewController!
    
    var photoArray = [Photo]()
    var currentPhoto: Photo?
    var currentPhotoFavorite: Bool?
    var favImages: [NSManagedObject]?
    var favImageNames: [String]?
    
    var imageIndex = 0
    var layoutsubs = false
    
    var PVCStoryboardID: String?
    var CVCStoryboardID: String?
    var infoSegue: String?
    
    var navHidden = false
    
    func updatePhoto(newPhoto: Photo) {
        self.title = newPhoto.title
        currentPhoto = newPhoto
        
        currentPhotoFavorite = (favImageNames!).contains(currentPhoto!.filename)
        
        var starImage = UIImage(named: "Star_empty")
        if currentPhotoFavorite! {
            starImage = UIImage(named: "Star_filled")
        }
        
        let favButton = UIBarButtonItem(image: starImage, style: .Plain, target: self, action: #selector(RootViewController.favFunk))
        self.navigationController?.topViewController!.navigationItem.rightBarButtonItem = favButton
    }

    func showInfo(sender: UIButton!) {
        performSegueWithIdentifier(infoSegue!, sender: nil)
    }
    
    func favFunk() {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        
        let entity = NSEntityDescription.entityForName("FavImages", inManagedObjectContext: managedContext)
        
        if !currentPhotoFavorite! {
            let favImage = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
            favImage.setValue(currentPhoto!.filename, forKey: "filename")
            favImage.setValue(currentPhoto!.title, forKey: "title")
            favImage.setValue(currentPhoto!.caption, forKey: "caption")
            var error: NSError?
            do {
                try managedContext.save()
                favImages?.append(favImage)
                favImageNames?.append(currentPhoto!.filename)
                updatePhoto(currentPhoto!)
            } catch let error1 as NSError {
                error = error1
                print("Could not save \(error), \(error?.userInfo)")
            }
        } else {
            if let deletedPhotoIndex = (favImageNames!).indexOf(currentPhoto!.filename) {
                let deletedPhoto = favImages![deletedPhotoIndex]
                managedContext.deleteObject(deletedPhoto as NSManagedObject)
                var error: NSError?
                do {
                    try managedContext.save()
                    favImages?.removeAtIndex(deletedPhotoIndex)
                    favImageNames?.removeAtIndex(deletedPhotoIndex)
                    updatePhoto(currentPhoto!)
                } catch let error1 as NSError {
                    error = error1
                    print("Could not delete \(error), \(error?.userInfo)")
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.setNeedsDisplay()
        
        self.automaticallyAdjustsScrollViewInsets = false
        updatePhoto(currentPhoto!)
        
        //Setup pageViewController
        pageViewController = self.storyboard?.instantiateViewControllerWithIdentifier(PVCStoryboardID!) as! UIPageViewController
        pageViewController.dataSource = self
        pageViewController.delegate = self
        
        //Create the starting view controller at index selected and the one after it
        let startingVC = self.viewControllerAtIndex(imageIndex) as ContentViewController
        let afterVC = pageViewController(pageViewController, viewControllerAfterViewController: startingVC) as! ContentViewController

        //Add pageViewController to main view
        self.addChildViewController(pageViewController)
        self.view.addSubview(pageViewController.view)
        pageViewController.didMoveToParentViewController(self)
        
        //Go to VC after the starting one and go back to the starting one to load the afterVC
        var viewControllers = [afterVC]
        pageViewController.setViewControllers(viewControllers, direction: .Forward, animated: true, completion: nil)
        viewControllers = [startingVC]
        pageViewController.setViewControllers(viewControllers, direction: .Reverse, animated: true, completion: nil)

        //Setup the info button at runtime (vs on storyboard) so it's on top of pageViewController
        let infoButton: UIButton = UIButton(type: UIButtonType.DetailDisclosure)
        infoButton.addTarget(self, action: #selector(RootViewController.showInfo(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        infoButton.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(infoButton)
        
        //Add info button constraints and size.
        let btnConstraintTop = NSLayoutConstraint(item: infoButton, attribute: .Top, relatedBy: .Equal, toItem: topLayoutGuide, attribute: .Bottom, multiplier: 1.0, constant: 8)
        let btnConstraintRight = NSLayoutConstraint(item: infoButton, attribute: .Trailing, relatedBy: .Equal, toItem: view, attribute: .Trailing, multiplier: 1.0, constant: -8)
        let btnWidthConstraint = NSLayoutConstraint(item: infoButton, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 22)
        let btnHeightConstraint = NSLayoutConstraint(item: infoButton, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 22)
        view.addConstraint(btnConstraintTop)
        view.addConstraint(btnConstraintRight)
        view.addConstraint(btnWidthConstraint)
        view.addConstraint(btnHeightConstraint)
    }

    override func viewWillLayoutSubviews() {
        //Go to VC before the starting VC and go back to the starting VC to load the beforeVC
        //viewWillLayoutSubviews() is called multiple times, so do this only once
        if !layoutsubs {
            let startingVC = self.viewControllerAtIndex(imageIndex) as ContentViewController
            let beforeVC = pageViewController(pageViewController, viewControllerBeforeViewController: startingVC) as! ContentViewController
            
            startingVC.delegate = self //set the first VC's delegate to the root
            
            var viewControllers = [beforeVC]
            pageViewController.setViewControllers(viewControllers, direction: .Reverse, animated: true, completion: nil)
            viewControllers = [startingVC]
            pageViewController.setViewControllers(viewControllers, direction: .Forward, animated: true, completion: nil)
            //self.navigationController?.navigationBar.alpha = 0.5
            layoutsubs = true
        }
    }

    func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        //Update title when user swipes through images
        for eachVC in pageViewController.viewControllers! {
            if let currentIndex = eachVC as? ContentViewController {
                currentIndex.delegate = self //set every other VC's delegate to the root
                updatePhoto(photoArray[currentIndex.pageIndex])
            }
        }
    }
    
    func viewControllerAtIndex(index: Int) -> ContentViewController {
        let contentView = self.storyboard?.instantiateViewControllerWithIdentifier(CVCStoryboardID!) as! ContentViewController
        contentView.imageFile = self.photoArray[index].filename as String
        contentView.pageIndex = index
        return contentView
    }
    
    //MARK - Page View Controller Data Source
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {

        let vc = viewController as! ContentViewController
        guard let index = vc.pageIndex else {
            return nil
        }
        
        guard index > 0 else {
            return viewControllerAtIndex(photoArray.count-1)
        }

        return viewControllerAtIndex(index-1)
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {

        let vc = viewController as! ContentViewController
        guard let index = vc.pageIndex else {
            return nil
        }

        guard index < photoArray.count-1 else {
            return viewControllerAtIndex(0)
        }

        return viewControllerAtIndex(index+1)
    }
    
    //Called from InfoViewControler
    func favoriteChanged() {
        //When user taps star in InfoViewController, update this view
        favFunk()
    }
    
    //Called from the ContentVC
    func navHiddenChanged(changedNavHidden: Bool) {
        navHidden = changedNavHidden
        //Toggles the status bar based off single-tap gesture
        prefersStatusBarHidden()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        if navHidden {
            return true
        }
        return super.prefersStatusBarHidden()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //MARK - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let detailsView = segue.destinationViewController as! InfoViewController
        detailsView.delegate = self
        
        detailsView.currentPhoto = currentPhoto
        detailsView.favorited = currentPhotoFavorite!
    }

}