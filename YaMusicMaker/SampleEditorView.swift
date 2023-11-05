//
//  SampleEditorView.swift
//  YaMusicMaker
//
//  Created by Vlad Eliseev on 03.11.2023.
//

import UIKit
import RxSwift

final class SampleEditorView: UIControl {
    
    private var minVolume: Double = 0.0
    private var maxVolume: Double = 4.0
    
    private var minTempo = Float(Constants.minTempo)
    private var maxTempo = Float(Constants.maxTempo)
    
    private let volumeIndicator: UILabel = {
        let label = UILabel()
        label.text = "громкость"
        label.textAlignment = .center
        label.backgroundColor = Color.green
        return label
    }()
    
    private let speedIndicator: UILabel = {
        let label = UILabel()
        label.text = "скорость"
        label.textAlignment = .center
        label.backgroundColor = Color.green
        return label
    }()
    
    private weak var viewModel: LayerViewModel?
    
    private var bag = DisposeBag()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        let relativeVolume = location.y / frame.height
        let volumeLevel = maxVolume * (1 - relativeVolume)
        let constraintedVolume = max(min(maxVolume, volumeLevel), minVolume)
        
        let relativeSpeed = location.x / frame.width
        let speedLevel = maxTempo * Float(relativeSpeed)
        let constraintedSpeed = max(min(maxTempo, speedLevel), minTempo)
        
//        print(relativeVolume, volumeLevel, relativeSpeed, speedLevel)

        self.viewModel?.volume.onNext(Float(constraintedVolume))
        self.viewModel?.speed.onNext(constraintedSpeed)
    }
    
    func configure(with layerModel: LayerViewModel?) {
        bag = DisposeBag()
        
        self.viewModel = layerModel
        
        guard let layerModel else {
            return
        }
        
        layerModel.speed
            .bind(onNext: { [weak self] updatedTempo in
                self?.updateSpeedIndicatorFrame(with: updatedTempo)
            })
            .disposed(by: bag)
        
        layerModel.volume
            .bind { [weak self] updatedVolume in
                self?.updateVolumeIndicatorFrame(with: updatedVolume)
            }
            .disposed(by: bag)
    }
    
    private func updateSpeedIndicatorFrame(with updatedSpeed: Float) {
        let height: CGFloat = 20
        let indicatorWidth = speedIndicator.frame.width
        let frame = CGRect(
            x: CGFloat(((updatedSpeed - minTempo) / (self.maxTempo - self.minTempo))) * (frame.width - indicatorWidth),
            y: frame.height - height,
            width: 90,
            height: height
        )
        self.speedIndicator.frame = frame
    }
        
    private func updateVolumeIndicatorFrame(with updatedVolume: Float) {
        let updatedVolume = Double(updatedVolume)
        let indicatorHeight = volumeIndicator.frame.height
        let frame = CGRect(
            x: .zero,
            y: (1 - (updatedVolume / (maxVolume - minVolume))) * (frame.height - indicatorHeight),
            width: 20,
            height: 90
        )
        volumeIndicator.frame = frame
    }
    
    private func setupViews() {
        backgroundColor = Color.blue
        
        addSubview(speedIndicator)
        
        addSubview(volumeIndicator)
        volumeIndicator.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
    }
}
