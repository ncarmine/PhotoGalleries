//  Structs.swift
//  PhotoGalleries
//  Created by ncarmine 2016

import Foundation

struct Photo {
    var filename: String
    var title: String
    var caption: String
}

struct Category {
    var catTitle: String
    var catImages: [String]
}