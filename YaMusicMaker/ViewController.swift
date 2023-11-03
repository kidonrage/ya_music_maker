//
//  ViewController.swift
//  YaMusicMaker
//
//  Created by Vlad Eliseev on 03.11.2023.
//

import UIKit

class ViewController: UIViewController {
    
    private let control = SampleSelectorControl()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        view.addSubview(control)
        
        
    }
}

