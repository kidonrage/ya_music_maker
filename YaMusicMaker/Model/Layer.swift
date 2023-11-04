//
//  Laye.swift
//  YaMusicMaker
//
//  Created by Vlad Eliseev on 04.11.2023.
//

import Foundation

final class Layer {
    
    let sampleUrl: URL
    let name: String
    var isMuted: Bool
    var isPlaying: Bool
    
    init(sampleUrl: URL, name: String, isMuted: Bool = false, isPlaying: Bool = false) {
        self.sampleUrl = sampleUrl
        self.name = name
        self.isMuted = isMuted
        self.isPlaying = isPlaying
    }
}
