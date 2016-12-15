//
//  JSONInfo.swift
//  PhotoGalleries
//
//  Created by Nathan Carmine on 6/11/16.
//  Copyright © 2016 ncarmine. All rights reserved.
//

import Foundation

class JSONInfo: NSObject, NSCoding {
    private(set) var json: JSON?
    
    override init() {
        super.init()
        setJSON()
        //print("JSON RETRIEVED")
    }
    
    required init?(coder aDecoder: NSCoder) {
        if let setJSON = aDecoder.decodeObjectForKey("json") as? JSON {
            json = setJSON
        }
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(json as? AnyObject, forKey: "json")
    }
    
    func setJSON() {
        if let JSONfile = NSBundle.mainBundle().pathForResource("PhotoGalleries", ofType: "json") {
            do {
                let dataFromFile = try NSData(contentsOfFile: JSONfile, options: NSDataReadingOptions.DataReadingMappedIfSafe)
                json = JSON(data: dataFromFile)
            } catch let error {
                print(error)
                print("nil json 01")
                json = nil
            }
        }
        else {
            print("nil json 02")
            json = nil
        }
    }
}