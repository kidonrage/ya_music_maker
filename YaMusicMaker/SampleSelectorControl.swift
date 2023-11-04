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
    
    private let iconContainerView = UIView()
    private let iconView = UIImageView()
    private let backgroundView = UIView()
    private let containerView = UIStackView()
    private let optionsView = UIStackView()
    private let gestureRecognizer = UIPanGestureRecognizer()
    private var options: [UIButton] = []
    
    private var isExpanded: Bool = false {
        didSet {
            UIView.animate(withDuration: 0.25) {
                self.backgroundView.backgroundColor = self.isExpanded ? Color.green : Color.white
                self.optionsView.isHidden = !self.isExpanded
            }
        }
    }
    
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
        
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        backgroundView.backgroundColor = .green
        
        backgroundView.addSubview(containerView)
        
        containerView.axis = .vertical
        containerView.addArrangedSubview(iconContainerView)
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        iconContainerView.addSubview(iconView)
        iconContainerView.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(iconContainerView.snp.width)
        }
        
        iconView.image = UIImage(named: "guitar_icon")
        iconView.contentMode = .scaleAspectFit
        iconView.snp.makeConstraints { make in
            make.width.height.equalToSuperview().inset(12)
            make.center.equalToSuperview()
        }
        
        containerView.addArrangedSubview(optionsView)
        
        optionsView.axis = .vertical
        
        options = ["сэмпл1", "сэмпл2", "сэмпл3"].map({ makeOptionButton(title: $0) })
        options.forEach { option in
            optionsView.addArrangedSubview(option)
            option.snp.makeConstraints { make in
                make.height.equalTo(20)
            }
        }
        
        isExpanded = false
        
        isUserInteractionEnabled = true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        isExpanded = true
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isExpanded = false
        
        options.forEach { option in
            option.isHighlighted = false
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        options.forEach { option in
            option.isHighlighted = option == hitTest(touch.location(in: self), with: nil)
        }
    }
    
    private func makeOptionButton(title: String) -> UIButton {
        let button = SampleOptionButton()
        button.setTitle(title, for: .normal)
        return button
    }
}
