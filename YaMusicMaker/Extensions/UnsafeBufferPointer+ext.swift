//
//  UnsafeBufferPointer+ext.swift
//  YaMusicMaker
//
//  Created by Vlad Eliseev on 05.11.2023.
//

import Foundation

extension UnsafeBufferPointer {
    func item(at index: Int) -> Element? {
        if index >= self.count {
            return nil
        }
        
        return self[index]
    }
}
