//  FavoritesInfoViewController.swift
//  PhotoGalleries
//  Created by ncarmine 2016

import UIKit

class FavoritesInfoViewController: InfoViewController {
    
    override func favorite() {
        //Setup alrt to confirm user actions
        //Without alert, the user could accidentally end up two view back
        let alert = UIAlertController(title: "Remove Image From Favorites?", message: nil, preferredStyle: .Alert)
        let keep = UIAlertAction(title: "Keep", style: .Default, handler: nil)
        let remove = UIAlertAction(title: "Remove", style: .Destructive, handler: { (alert) in
            //Still calls favFunk(), just the subclassed version
            self.delegate?.favoriteChanged()
            //Goes back two views
            self.dismiss()
        })
        
        alert.addAction(keep)
        alert.addAction(remove)
        
        self.presentViewController(alert, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}