//  ThumbnailCollectionViewController.swift
//  PhotoGalleries
//  Created by ncarmine 2016

import UIKit

class ThumbnailCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    let reuseIdentifier = "ThumbCell"
    var thumbnails = [String]()
    var bounce = true
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        //Get total size of all the images with the spacing
        let totalContentWidth = (self.view.bounds.height * CGFloat(thumbnails.count)) + (5.0 *  CGFloat(thumbnails.count-1))
        
        //If the view is showing all the images, don't bounce
        if self.view.bounds.width >= totalContentWidth {
            bounce = false
        }
        collectionView?.bounces = bounce
    }

    //MARK - UICollectionViewDataSource
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return thumbnails.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! ThumbnailCollectionViewCell
        let cellImage = UIImage(named: thumbnails[indexPath.row])
        cell.thumbnailImageView.image = cellImage
    
        return cell
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 5.0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 5.0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let imgSize = self.view.bounds.height
        let size = CGSizeMake(imgSize, imgSize)
        return size
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
