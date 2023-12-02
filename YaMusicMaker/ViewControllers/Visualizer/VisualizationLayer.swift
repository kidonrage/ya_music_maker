//
//  VisualizationLayer.swift
//  YaMusicMaker
//
//  Created by Vlad Eliseev on 02.12.2023.
//

import UIKit
import AVFoundation

final class VisualizationLayer: CALayer {
    
    private var minVolume: Double = 0.0
    private var maxVolume: Double = 4.0
    
    private var minTempo = Float(Constants.minTempo)
    private var maxTempo = Float(Constants.maxTempo)
    
    private let layers: [VisualizationEntity]
    
    init(layers: [VisualizationEntity]) {
        self.layers = layers
        
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update() {
        sublayers?.removeAll()
        
        let videoSize: CGSize = frame.size
        
        let outputLayer = CALayer()
        outputLayer.frame = CGRect(origin: .zero, size: videoSize)
        
        for layer in layers {
            guard !layer.isMuted else { continue }
            
            let animationDuration = 60.0 / layer.speed
            
            let sampleLayer: CALayer
            let visualizationEntityType = VisualizationLayerType.allCases.randomElement()
            switch visualizationEntityType {
            case .filledCircle:
                sampleLayer = makeFilledCircleLayer(animationDuration: TimeInterval(animationDuration))
            case .outlinedCircle:
                sampleLayer = makeOutlineCircleLayer(animationDuration: TimeInterval(animationDuration))
            case .spiral:
                sampleLayer = makeSpiralLayer(animationDuration: TimeInterval(animationDuration))
            default:
                continue
            }
            sampleLayer.frame = getSampleFrameOnVisualizerCoords(
                targetViewSize: CGSize(width: 50, height: 50),
                containerSize: outputLayer.frame.size,
                updatedSpeed: layer.speed,
                updatedVolume: layer.volume
            )
            
            outputLayer.addSublayer(sampleLayer)
        }
        
        addSublayer(outputLayer)
    }
    
    private func makeOutlineCircleLayer(animationDuration: TimeInterval) -> CALayer {
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 0.8
        scaleAnimation.toValue = 1.2
        scaleAnimation.duration = animationDuration
        scaleAnimation.repeatCount = .greatestFiniteMagnitude
        scaleAnimation.autoreverses = true
        scaleAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        scaleAnimation.beginTime = AVCoreAnimationBeginTimeAtZero
        scaleAnimation.isRemovedOnCompletion = false
        
        let circleLayer = CAShapeLayer()
        let radius: CGFloat = 150.0
        circleLayer.path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 2.0 * radius, height: 2.0 * radius), cornerRadius: radius).cgPath
        circleLayer.strokeColor = Color.green.cgColor
        circleLayer.fillColor = nil
        circleLayer.lineWidth = 2
        circleLayer.add(scaleAnimation, forKey: "scale")
        return circleLayer
    }
    
    private func makeFilledCircleLayer(animationDuration: TimeInterval) -> CALayer {
        let scaleAnimation = CABasicAnimation(keyPath: "opacity")
        scaleAnimation.fromValue = 1
        scaleAnimation.toValue = 0.0
        scaleAnimation.duration = animationDuration
        scaleAnimation.repeatCount = .greatestFiniteMagnitude
        scaleAnimation.autoreverses = true
        scaleAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        scaleAnimation.beginTime = AVCoreAnimationBeginTimeAtZero
        scaleAnimation.isRemovedOnCompletion = false
        
        let circleLayer = CAShapeLayer()
        let radius: CGFloat = 150.0
        circleLayer.path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 2.0 * radius, height: 2.0 * radius), cornerRadius: radius).cgPath
        circleLayer.fillColor = UIColor.blue.cgColor
        circleLayer.add(scaleAnimation, forKey: "scale")
        return circleLayer
    }
    
    private func makeSpiralLayer(animationDuration: TimeInterval) -> CALayer {
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationAnimation.toValue = 2 * CGFloat.pi
        rotationAnimation.duration = animationDuration
        rotationAnimation.repeatCount = .greatestFiniteMagnitude
        rotationAnimation.fillMode = .forwards
        rotationAnimation.isRemovedOnCompletion = false
        
        let layer = CALayer()
        let spiralImage = UIImage(named: "spiral")
        layer.contents = spiralImage?.cgImage
        
        layer.add(rotationAnimation, forKey: nil)
        
        return layer
    }
    
    private func getSampleFrameOnVisualizerCoords(
        targetViewSize: CGSize,
        containerSize: CGSize,
        updatedSpeed: Float,
        updatedVolume: Float
    ) -> CGRect {
        let x = CGFloat(((updatedSpeed - minTempo) / (maxTempo - minTempo))) * containerSize.width
        let volumeScale = maxVolume - minVolume
        let y = (1 - (Double(updatedVolume) / volumeScale)) * containerSize.height

        return CGRect(
            x: x - targetViewSize.width / 2,
            y: y - targetViewSize.height / 2,
            width: targetViewSize.width,
            height: targetViewSize.height
        )
    }
}
