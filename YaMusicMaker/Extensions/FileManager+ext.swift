//
//  FileManager+ext.swift
//  YaMusicMaker
//
//  Created by Vlad Eliseev on 05.11.2023.
//

import Foundation

extension FileManager {
    
    func getDocumentsDirectory() -> URL {
        let paths = urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
}
