//
//  Color.swift
//  YaMusicMaker
//
//  Created by Vlad Eliseev on 03.11.2023.
//

import UIKit

struct Color {
    
    static let white = UIColor(255, 255, 255)
    static let green = UIColor(168, 219, 16, 1)
    static let black = UIColor(0, 0, 0, 1)
    static let blue = UIColor(90, 80, 226)
    static let gray = UIColor(63, 63, 63, 1)
    static let grayDark = UIColor(47, 47, 47, 1)
    static let grayDark2 = UIColor(23, 23, 23, 1)
    static let red = UIColor(243, 75, 75, 0.25)
}

extension UIColor {
    
    convenience init(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1.0) {
        self.init(red: r / 255, green: g / 255, blue: b / 255, alpha: a)
    }
}
