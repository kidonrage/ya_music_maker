//
//  LayerTableViewCell.swift
//  YaMusicMaker
//
//  Created by Vlad Eliseev on 04.11.2023.
//

import UIKit

extension UITableViewCell {
    
    static var cellId: String {
        return String(describing: Self.self)
    }
}

final class LayerTableViewCell: UITableViewCell {
    
    private let iconView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    private let nameLabel: UILabel = {
        let label = UILabel()
        return label
    }()
    private let toggleMuteButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "speaker.slash"), for: .normal)
        button.tintColor = Color.white
        button.backgroundColor = Color.grayDark
        return button
    }()
    private let deleteButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "trash.fill"), for: .normal)
        button.tintColor = Color.red
        button.backgroundColor = Color.red.withAlphaComponent(0.25)
        return button
    }()
    private lazy var layerMainControlsContainer: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [iconView, nameLabel, toggleMuteButton])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 8
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = .init(top: .zero, left: 10, bottom: .zero, right: .zero)
        stackView.layer.borderWidth = 2.0
        stackView.layer.borderColor = Color.gray.cgColor
        stackView.clipsToBounds = true
        return stackView
    }()
    private lazy var containerView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [layerMainControlsContainer, deleteButton])
        stackView.axis = .horizontal
        stackView.spacing = 10
        return stackView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure() {
        iconView.image = UIImage(systemName: "mic.fill")
        nameLabel.text = "Test Layer"
    }
    
    private func setupUI() {
        self.selectionStyle = .none
        
        let cornerRadius: CGFloat = 12
        let iconSize: CGFloat = 24
        
        layerMainControlsContainer.layer.cornerRadius = cornerRadius
        
        contentView.addSubview(containerView)
        
        containerView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(5)
            make.leading.trailing.equalToSuperview().inset(10)
        }
        
        deleteButton.layer.cornerRadius = cornerRadius
        deleteButton.snp.makeConstraints { make in
            make.width.equalTo(deleteButton.snp.height)
        }
        
        toggleMuteButton.snp.makeConstraints { make in
            make.height.width.equalTo(deleteButton.snp.height)
        }
        
        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(iconSize)
        }
    }
}
