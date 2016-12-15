//  ContentViewController.swift
//  PhotoGalleries
//  Created by ncarmine 2016

import UIKit

class ContentViewController: UIViewController, UIScrollViewDelegate {
    
    @IBOutlet var scrollView: UIScrollView!
    
    var imageView: UIImageView!
    
    var pageIndex: Int!
    var imageFile: String!
    var navHidden = false
    var delegate: hideNavDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ContentViewController.rotated), name: UIDeviceOrientationDidChangeNotification, object: nil)
        self.automaticallyAdjustsScrollViewInsets = false

        //Redo constraints at runtime
        scrollView.layoutIfNeeded()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        
        //add image to scrollview as a subview
        let currImage = UIImage(named: self.imageFile)!
        imageView = UIImageView(image: currImage)
        imageView.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: currImage.size)
        scrollView.addSubview(imageView)
        
        //Add the double-tap recognizer: two taps with one finger
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ContentViewController.scrollViewZoomIn(_:)))
        doubleTapRecognizer.numberOfTapsRequired = 2
        doubleTapRecognizer.numberOfTouchesRequired = 1
        scrollView.addGestureRecognizer(doubleTapRecognizer)
        
        //Add single-tap hide navbar tap recognizer
        let navHideRecognizer = UITapGestureRecognizer(target: self, action: #selector(ContentViewController.hideNav(_:)))
        navHideRecognizer.numberOfTapsRequired = 1
        navHideRecognizer.numberOfTouchesRequired = 1
        //Make sure it's not a double tap first
        //This causes a slight delay in the single tap, however
        navHideRecognizer.requireGestureRecognizerToFail(doubleTapRecognizer)
        scrollView.addGestureRecognizer(navHideRecognizer)
    }
    
    func centerScrollViewContents() {
        let contentWidth = scrollView.contentSize.width
        let contentHeight = scrollView.contentSize.height
        let offSetX = max((scrollView.bounds.size.width - contentWidth) * 0.5, 0.0)
        let offSetY = max((scrollView.bounds.size.height - contentHeight) * 0.5, 0.0)
        
        imageView.center = CGPointMake(contentWidth * 0.5 + offSetX, contentHeight * 0.5 + offSetY)
    }

    func scrollViewZoomIn(recognizer: UITapGestureRecognizer) {
        if scrollView.zoomScale == scrollView.minimumZoomScale {
            //Get point where user double-tapped
            let pointInView = recognizer.locationInView(imageView)
            
            //Create the new scale to zoom into
            var newZoomScale = scrollView.zoomScale * 2
            newZoomScale = min(newZoomScale, scrollView.maximumZoomScale)
            
            //If the newZoomScale is smaller than the current zoom scale, don't zoom
            if newZoomScale > scrollView.zoomScale {
                //Create the rectangle to zoom into
                let scrollViewSize = scrollView.bounds.size
                let w = scrollViewSize.width / newZoomScale
                let h = scrollViewSize.height / newZoomScale
                let x = pointInView.x - (w / 2.0)
                let y = pointInView.y - (h / 2.0)
                let rectToZoomTo = CGRectMake(x, y, w, h)
                //Then zoom into it
                scrollView.zoomToRect(rectToZoomTo, animated: true)
            }
        } else {
            //Zoom out on double-tap if image is zoomed in at all
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        }
    }

    func hideNav(recognizer: UITapGestureRecognizer) {
        //Tell the RootVC to hide/show the status bar
        delegate?.navHiddenChanged(!navHidden)
        //Then toggle the nav controller from here
        self.navigationController?.setNavigationBarHidden(!navHidden, animated: true)
        navHidden = !navHidden
    }

    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(scrollView: UIScrollView) {
        centerScrollViewContents()
    }
    
    func rotated() {
        centerScrollViewContents()
    }
    
    override func viewWillLayoutSubviews() {
        //redo constraints after navigation bar has been accounted for
        scrollView.layoutIfNeeded()
        //set the size of the scrollview to the size of the image
        scrollView.contentSize = imageView.image!.size
        //set the zoom scale so the image shows up properly - otherwise it's huge
        let scrollViewFrame = scrollView.frame
        let scaleWidth = scrollViewFrame.width / scrollView.contentSize.width
        let scaleHeight = scrollViewFrame.height / scrollView.contentSize.height
        let minScale = min(scaleWidth, scaleHeight)
        scrollView.minimumZoomScale = minScale
        scrollView.maximumZoomScale = 1.0
        scrollView.zoomScale = minScale
        centerScrollViewContents()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
