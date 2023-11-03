//
//  SampleSelectorControl.swift
//  YaMusicMaker
//
//  Created by Vlad Eliseev on 03.11.2023.
//

import UIKit

final class SampleOptionButton: UIButton {
    
    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? .white : nil
        }
    }
}

final class SampleSelectorControl: UIControl {
    
    private let iconView = UIImageView()
    private let backgroundView = UIView()
    private let containerView = UIStackView()
    private let optionsView = UIStackView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    
        setupViews()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        backgroundView.layer.cornerRadius = frame.width / 2
        
    }
    
    private func setupViews() {
        addSubview(backgroundView)
        
        backgroundView.backgroundColor = .white
        
        backgroundView.addSubview(containerView)
        
        containerView.axis = .vertical
        containerView.addArrangedSubview(iconView)
        containerView.addArrangedSubview(optionsView)
        
        optionsView.isHidden = false
        ["сэмпл1", "сэмпл2", "сэмпл3"].forEach { name in
            optionsView.addArrangedSubview(makeOptionButton(title: name))
        }
    }
    
    private func makeOptionButton(title: String) -> UIButton {
        let button = SampleOptionButton()
        button.setTitle(title, for: .normal)
        return button
    }
}
