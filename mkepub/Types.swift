//
//  Types.swift
//  mkepub
//
//  Created by Rumpel Stiltskin on 16.09.2024.
//

import Foundation

struct EpubInfo: Codable {
    var id: String?
    var name: String
    var author: String
    var title: String
    var start: String?
    var startTitle: String?
    var cover: String?
    var style: String?
    var fonts: [String]?
    var images: [String]?
    var documents: [String]
}

struct Page {
    var name: String
    var file: String
    var title: String
    var body: String
}
