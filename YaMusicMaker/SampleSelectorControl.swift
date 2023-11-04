//
//  SampleSelectorControl.swift
//  YaMusicMaker
//
//  Created by Vlad Eliseev on 03.11.2023.
//

import UIKit
import RxSwift
import RxRelay

final class SampleOptionButton: UIButton {
    
    let sample: Sample
    
    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? Color.green : nil
            setTitleColor(isHighlighted ? Color.black : Color.white, for: .normal)
        }
    }
    
    init(sample: Sample) {
        self.sample = sample
        
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class SampleSelectorViewModel {
    
    let name: String
    let icon: UIImage
    let samples: [Sample]
    
    let sampleSelectedHandler: AnyObserver<Sample>
    
    init(name: String, icon: UIImage, samples: [Sample], sampleSelectedHandler: AnyObserver<Sample>) {
        self.name = name
        self.icon = icon
        self.samples = samples
        self.sampleSelectedHandler = sampleSelectedHandler
    }
}

final class SampleSelectorControl: UIControl {
    
    private let iconContainerView = UIView()
    private let iconView = UIImageView()
    private let optionsContainerView = UIStackView()
    private let optionsView = UIStackView()
    private let gestureRecognizer = UIPanGestureRecognizer()
    private let nameLabel = UILabel()
    
    private var options: [SampleOptionButton] = []
    
    private let focusedSample = BehaviorRelay<Sample?>(value: nil)
    
    private var isExpanded: Bool = false {
        didSet {
            UIView.animate(withDuration: 0.25) {
                self.optionsContainerView.alpha = self.isExpanded ? 1 : 0.001
                if self.isExpanded {
                    self.optionsContainerView.snp.remakeConstraints { make in
                        make.top.leading.trailing.equalToSuperview()
                        make.bottom.equalToSuperview()
                    }
                } else {
                    self.optionsContainerView.snp.remakeConstraints { make in
                        make.top.leading.trailing.equalToSuperview()
                        make.bottom.equalTo(self.snp.top)
                    }
                }
            }
        }
    }
    
    private let viewModel: SampleSelectorViewModel
    
    private var bag = DisposeBag()
    
    init(viewModel: SampleSelectorViewModel) {
        self.viewModel = viewModel
        
        super.init(frame: .zero)
        
        setupViews()
        setupBindings()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        iconContainerView.layer.cornerRadius = frame.width / 2
        optionsContainerView.layer.cornerRadius = frame.width / 2
    }
    
    private func setupBindings() {
        let focusedSample = focusedSample
            .share()
            .distinctUntilChanged()
        
        focusedSample
            .bind { [weak self] focusedSample in
                self?.options.forEach { option in
                    option.isHighlighted = option.sample == focusedSample
                }
            }
            .disposed(by: bag)
        
        focusedSample
            .compactMap { $0 }
            .bind(to: AudioService.shared.sampleToPreplay)
            .disposed(by: bag)
    }
    
    private func setupViews() {
        addSubview(iconContainerView)
        iconContainerView.backgroundColor = Color.grayDark2
        iconContainerView.layer.borderWidth = 2
        iconContainerView.layer.borderColor = Color.gray.cgColor
        iconContainerView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(iconContainerView.snp.width)
        }
        
        addSubview(nameLabel)
        nameLabel.text = viewModel.name
        nameLabel.textAlignment = .center
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(iconContainerView.snp.bottom).inset(-8)
            make.leading.trailing.equalToSuperview()
        }
        
        addSubview(optionsContainerView)
        addSubview(iconView)
        
        optionsContainerView.backgroundColor = Color.gray
        optionsContainerView.layer.borderWidth = 2
        optionsContainerView.layer.borderColor = Color.green.cgColor
        optionsContainerView.clipsToBounds = true
    
        optionsContainerView.addSubview(optionsView)
        optionsView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().inset(24)
            make.top.equalTo(iconView.snp.bottom).inset(-8)
        }
        optionsView.axis = .vertical
        options = viewModel.samples.map({ makeOptionButton(sample: $0) })
        options.forEach { option in
            optionsView.addArrangedSubview(option)
        }
        
        iconView.image = viewModel.icon.withTintColor(Color.white)
        iconView.contentMode = .scaleAspectFit
        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(iconContainerView).inset(12)
            make.center.equalTo(iconContainerView)
        }
        
        isExpanded = false
        
        isUserInteractionEnabled = true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        isExpanded = true
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isExpanded = false
        
        if let focusedSample = focusedSample.value {
            viewModel.sampleSelectedHandler.onNext(focusedSample)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let focusedOption = hitTest(touch.location(in: self), with: nil) as? SampleOptionButton
        self.focusedSample.accept(focusedOption?.sample)
    }
    
    private func makeOptionButton(sample: Sample) -> SampleOptionButton {
        let button = SampleOptionButton(sample: sample)
        button.setTitle(sample.name, for: .normal)
        return button
    }
}
