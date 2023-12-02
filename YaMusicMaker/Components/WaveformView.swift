//
//  WaveformView.swift
//  YaMusicMaker
//
//  Created by Vlad Eliseev on 05.11.2023.
//

import UIKit

class WaveformView: UIImageView {
    
    func generateWaveImage2(
        scales: [CGFloat],
        imageSize: CGSize,
        strokeColor: UIColor,
        backgroundColor: UIColor,
        waveSpacing: CGFloat,
        completion: @escaping (_ image: UIImage?) -> Void
    ) {
        UIGraphicsBeginImageContextWithOptions(imageSize, false, 0)
        guard let context: CGContext = UIGraphicsGetCurrentContext() else {
            completion(nil)
            return
        }
        
        let middleY = imageSize.height / 2
        
        let gapsCount = (scales.count - 1)
        let gapsWidth = CGFloat(gapsCount) * waveSpacing
        let waveWidth = (imageSize.width - gapsWidth) / CGFloat(scales.count)
        
        context.setFillColor(backgroundColor.cgColor)
        context.setAlpha(1.0)
        context.fill(CGRect(origin: .zero, size: imageSize))
        context.setLineWidth(waveWidth)
        context.setLineJoin(.round)
        context.setLineCap(.round)
        
        var x: CGFloat = 0.0
        
        for scale in scales {
            let waveHeight = CGFloat(scale)
            
            context.move(to: CGPoint(x: x, y: middleY - waveHeight))
            context.addLine(to: CGPoint(x: x, y: middleY + waveHeight))
            
            x += waveSpacing + waveWidth
        }
        
        context.setStrokeColor(strokeColor.cgColor)
        context.strokePath()
        
        guard let soundWaveImage = UIGraphicsGetImageFromCurrentImageContext() else {
            UIGraphicsEndImageContext()
            completion(nil)
            return
        }
        
        UIGraphicsEndImageContext()
        completion(soundWaveImage)
    }
}
