//
//  SelfSizingTableView.swift
//  YaMusicMaker
//
//  Created by Vlad Eliseev on 04.11.2023.
//

import UIKit

final class SelfSizingTableView: UITableView {
    
    override var contentSize: CGSize {
        didSet {
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

    override var intrinsicContentSize: CGSize {
        let height = min(.infinity, contentSize.height + contentInset.top + contentInset.bottom)
        return CGSize(width: contentSize.width  + contentInset.left + contentInset.right, height: height)
    }
}
