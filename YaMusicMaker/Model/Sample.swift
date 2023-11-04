//
//  Sample.swift
//  YaMusicMaker
//
//  Created by Vlad Eliseev on 04.11.2023.
//

import Foundation

struct Sample: Hashable, Equatable {
    
    let name: String
    let urlToFile: URL
    
    init(name: String, urlToFile: URL) {
        self.name = name
        self.urlToFile = urlToFile
    }
}
