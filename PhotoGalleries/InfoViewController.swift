//  InfoViewController.swift
//  PhotoGalleries
//  Created by ncarmine 2016

import UIKit

class InfoViewController: UIViewController, UINavigationBarDelegate {

    var delegate: favoriteChangedDelegate?
    
    var currentPhoto: Photo?
    var favorited: Bool?
    
    func favorite() {
        favorited! = !favorited! //Not Spanish, just unpacking
        delegate?.favoriteChanged() //Setup delegate for favoriteChanged() protocol
        
        //Update nav bar to reflect star button changes
        var navBar: UINavigationBar?
        for subView in view.subviews {
            if subView is UINavigationBar {
                navBar = subView as? UINavigationBar
            }
        }
        navBar?.items = setNavItems()
    }
    
    func dismiss() {
        //Go back to previous view controller
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func setNavItems() -> [UINavigationItem] {
        //Set star item appropriately
        var starImage = UIImage(named: "Star_empty")
        if favorited! {
            starImage = UIImage(named: "Star_filled")
        }
        
        let navItem = UINavigationItem() //Setup new blank nav bar item array
        navItem.title = "Image Description" //Set title

        //Set other buttons accordingly and add them to navItem
        let favButton = UIBarButtonItem(image: starImage, style: .Plain, target: self, action: #selector(InfoViewController.favorite))
        let dismissButton = UIBarButtonItem(title: "Done", style: .Plain, target: self, action: #selector(InfoViewController.dismiss))
        navItem.rightBarButtonItem = favButton
        navItem.leftBarButtonItem = dismissButton
        
        return [navItem]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Setup nav bar at runtime to allow for star button changes
        self.setNeedsStatusBarAppearanceUpdate()
        
        let navBar = UINavigationBar(frame: CGRect(x: 0, y: 20, width: view.frame.width, height: 44))
        navBar.opaque = true
        navBar.translucent = false
        navBar.barStyle = UIBarStyle.Black
        navBar.delegate = self

        navBar.items = setNavItems()
        view.addSubview(navBar)
        
        //When the nav bar is setup at runtime, the text view also has to be setup
        //Otherwise part of it will be under the nav bar
        let textOrigin = topLayoutGuide.length + navBar.frame.height
        let detailsText = UITextView(frame: CGRect(x: 0, y: textOrigin, width: view.frame.width, height: view.frame.height - textOrigin))
        detailsText.editable = false
        detailsText.text = currentPhoto!.caption
        detailsText.backgroundColor = UIColor(white: 0.1, alpha: 1.0)
        detailsText.textColor = UIColor(white: 0.9, alpha: 1.0)
        detailsText.font = UIFont(name: detailsText.font!.fontName, size: 18)
        
        view.addSubview(detailsText)
    }

    override func viewWillLayoutSubviews() {
        //Get current nav bar and text view
        var navBar: UINavigationBar?
        var textView: UITextView?
        for subView in view.subviews {
            if subView is UINavigationBar {
                navBar = subView as? UINavigationBar
            } else if subView is UITextView {
                textView = subView as? UITextView
            }
        }
        
        //Resize them and move them as needed for orientation
        navBar?.frame = CGRect(x: 0, y: topLayoutGuide.length, width: view.frame.width, height: 44)
        
        //Same for text view
        let textOrigin = topLayoutGuide.length + navBar!.frame.height
        textView!.frame = CGRect(x: 0, y: textOrigin, width: view.frame.width, height: view.frame.height - textOrigin)
    }
    
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return UIBarPosition.Top
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}