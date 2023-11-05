//
//  UITableViewCell+Ext.swift
//  YaMusicMaker
//
//  Created by Vlad Eliseev on 05.11.2023.
//

import UIKit

extension UITableViewCell {
    
    static var cellId: String {
        return String(describing: Self.self)
    }
}
