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
        label.text = "Громкость"
        label.textAlignment = .center
        label.backgroundColor = Color.white
        label.textColor = Color.black
        label.layer.cornerRadius = 4
        label.clipsToBounds = true
        label.font = .systemFont(ofSize: 12)
        return label
    }()
    
    private let speedIndicator: UILabel = {
        let label = UILabel()
        label.text = "Скорость"
        label.font = .systemFont(ofSize: 12)
        label.textAlignment = .center
        label.backgroundColor = Color.white
        label.textColor = Color.black
        label.clipsToBounds = true
        label.layer.cornerRadius = 4
        return label
    }()
    
    private let targetView: UIView = {
        let view = UIView()
        view.backgroundColor = Color.white
        view.layer.cornerRadius = 12
        return view
    }()
    private let targetVerticalAxisView: UIView = {
        let view = UIView()
        view.backgroundColor = Color.black
        return view
    }()
    private let targetHorizontalAxisView: UIView = {
        let view = UIView()
        view.backgroundColor = Color.black
        return view
    }()
    private let horizontalTicksImage = UIImageView()
    private let verticalTicksImage = UIImageView()
    
    private var gradientLayer = CAGradientLayer()
    
    private let indicatorSize: CGSize = CGSize(width: 90, height: 20)
    private let targetViewSize: CGFloat = 24
    
    private var lastTouch: CGPoint = .zero
    private var pointWhenTouchStarted: CGPoint?
    private var initialTouch: CGPoint?
    
    private weak var viewModel: LayerViewModel?
    
    private var bag = DisposeBag()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        gradientLayer.frame = bounds
        
        verticalTicksImage.frame = CGRect(
            origin: CGPoint(x: .zero, y: indicatorSize.width / 2),
            size: CGSize(width: indicatorSize.height, height: frame.height - indicatorSize.width))
        
        generateAxisTicks(
            minValue: CGFloat(minVolume * 10),
            maxValue: CGFloat(maxVolume * 10),
            littleTicksStep: 1,
            bigTicksStep: 10,
            imageSize: CGSize(width: frame.height, height: indicatorSize.height),
            strokeColor: Color.black
        ) { image in
            self.verticalTicksImage.image = image
        }
        
        generateAxisTicks(
            minValue: CGFloat(minTempo),
            maxValue: CGFloat(maxTempo),
            littleTicksStep: 2,
            bigTicksStep: 10,
            imageSize: horizontalTicksImage.frame.size,
            strokeColor: Color.black
        ) { image in
            self.horizontalTicksImage.image = image
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        let location = touch.location(in: self)
        
        let volumeHeight = volumeIndicator.frame.height
        let relativeVolume = (location.y - (volumeHeight / 2)) / (frame.height - volumeHeight)
        let volumeLevel = maxVolume * (1 - relativeVolume)
        let constraintedVolume = max(min(maxVolume, volumeLevel), minVolume)
        
        let speedIndicatorWidth = speedIndicator.frame.width
        let relativeSpeed = (location.x - (speedIndicatorWidth / 2)) / (frame.width - speedIndicatorWidth)
        let speedLevel = minTempo + ((maxTempo - minTempo) * Float(relativeSpeed))
        let constraintedSpeed = max(min(maxTempo, speedLevel), minTempo)
        self.viewModel?.volume.accept(Float(constraintedVolume))
        self.viewModel?.speed.accept(constraintedSpeed)
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
        let height: CGFloat = indicatorSize.height
        let indicatorWidth = indicatorSize.width
        let x = CGFloat(((updatedSpeed - minTempo) / (maxTempo - minTempo))) * (frame.width - indicatorWidth)
        let frame = CGRect(
            x: x,
            y: frame.height - height - height,
            width: indicatorSize.width,
            height: height
        )
        speedIndicator.frame = frame
        
        targetView.frame = CGRect(
            x: x + (indicatorWidth / 2) - targetViewSize / 2,
            y: targetView.frame.origin.y,
            width: targetViewSize,
            height: targetViewSize
        )
        targetVerticalAxisView.frame = CGRect(
            origin: CGPoint(
                x: targetView.frame.origin.x + targetViewSize / 2,
                y: .zero
            ),
            size: CGSize(width: 1, height: self.frame.height)
        )
    }
    
    private func getSampleFrameOnVisualizerCoords(
        targetViewSize: CGSize,
        updatedSpeed: Float,
        updatedVolume: Float
    ) -> CGRect {
        let x = CGFloat(((updatedSpeed - minTempo) / (maxTempo - minTempo))) * frame.width
        let volumeScale = maxVolume - minVolume
        let y = (1 - (Double(updatedVolume) / volumeScale)) * frame.height

        return CGRect(
            x: x - targetViewSize.width / 2,
            y: y - targetViewSize.height / 2,
            width: targetViewSize.width,
            height: targetViewSize.height
        )
    }
        
    private func updateVolumeIndicatorFrame(with updatedVolume: Float) {
        let updatedVolume = Double(updatedVolume)
        let indicatorHeight = indicatorSize.width
        let y = (1 - (updatedVolume / (maxVolume - minVolume))) * (frame.height - indicatorHeight)
        let frame = CGRect(
            x: indicatorSize.height,
            y: y,
            width: indicatorSize.height,
            height: indicatorHeight
        )
        volumeIndicator.frame = frame
        
        targetView.frame = CGRect(
            x: targetView.frame.origin.x,
            y: y + (indicatorHeight / 2) - targetViewSize / 2,
            width: targetViewSize,
            height: targetViewSize
        )
        targetHorizontalAxisView.frame = CGRect(
            origin: CGPoint(
                x: .zero,
                y: targetView.frame.origin.y + targetViewSize / 2
            ),
            size: CGSize(width: self.frame.width, height: 1)
        )
    }
    
    private func generateAxisTicks(
        minValue: CGFloat,
        maxValue: CGFloat,
        littleTicksStep: CGFloat,
        bigTicksStep: CGFloat,
        imageSize: CGSize,
        strokeColor: UIColor,
        completion: @escaping (_ image: UIImage?) -> Void
    ) {
        autoreleasepool {
            UIGraphicsBeginImageContextWithOptions(imageSize, false, 0)
            guard let context: CGContext = UIGraphicsGetCurrentContext() else {
                completion(nil)
                return
            }
            
            let lineWidth: CGFloat = 1
            
            context.setLineWidth(lineWidth)
            context.setLineJoin(.round)
            context.setLineCap(.round)
            context.setStrokeColor(strokeColor.cgColor)
            
            let tickSpacing = imageSize.width / (((maxValue - minValue) / littleTicksStep) - lineWidth)
            
            for index in stride(from: 0, through: maxValue - minValue, by: littleTicksStep) {
                let x = index * tickSpacing
                context.move(to: CGPoint(x: x, y: imageSize.height))
                context.addLine(to: CGPoint(x: x, y: (index * littleTicksStep).truncatingRemainder(dividingBy: bigTicksStep) == .zero ? .zero : imageSize.height / 2))
            }
            
            context.strokePath()
            
            guard let axisTicksImage = UIGraphicsGetImageFromCurrentImageContext() else {
                UIGraphicsEndImageContext()
                completion(nil)
                return
            }
            
            UIGraphicsEndImageContext()
            completion(axisTicksImage)
        }
    }
    
    private func setupViews() {
        gradientLayer.colors = [Color.greenDark.cgColor, Color.green.cgColor]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 1.0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.0)
        
        layer.insertSublayer(gradientLayer, at:0)
        
        layer.cornerRadius = 12
        layer.masksToBounds = true
        
        addSubview(targetHorizontalAxisView)
        addSubview(targetVerticalAxisView)
        addSubview(targetView)
        
        addSubview(speedIndicator)
        
        addSubview(volumeIndicator)
        volumeIndicator.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
        
        addSubview(horizontalTicksImage)
        horizontalTicksImage.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(indicatorSize.width / 2)
            make.height.equalTo(indicatorSize.height)
        }
    
        addSubview(verticalTicksImage)
        verticalTicksImage.transform = CGAffineTransform(scaleX: -1, y: 1).rotated(by: -CGFloat.pi / 2)
    }
}
