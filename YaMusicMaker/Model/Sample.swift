//
//  Sample.swift
//  YaMusicMaker
//
//  Created by Vlad Eliseev on 04.11.2023.
//

import Foundation
import UIKit

struct Sample: Hashable, Equatable {
    
    let name: String
    let urlToFile: URL
    let icon: UIImage
    
    init(name: String, urlToFile: URL, icon: UIImage) {
        self.name = name
        self.urlToFile = urlToFile
        self.icon = icon
    }
}
