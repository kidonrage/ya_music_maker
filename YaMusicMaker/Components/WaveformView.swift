//
//  WaveformView.swift
//  YaMusicMaker
//
//  Created by Vlad Eliseev on 05.11.2023.
//

import UIKit

class WaveformView: UIImageView {

    func generateWaveImage(samples: UnsafeBufferPointer<Float>,
                                   imageSize: CGSize,
                                   strokeColor: UIColor,
                                   backgroundColor: UIColor,
                                   waveWidth: CGFloat,      // Width of each wave
                                   waveSpacing: CGFloat,    // Space between waveform items
                                   completion: @escaping (_ image: UIImage?) -> Void) {
        autoreleasepool {
            UIGraphicsBeginImageContextWithOptions(imageSize, false, 0)
            guard let context: CGContext = UIGraphicsGetCurrentContext() else {
                completion(nil)
                return
            }
            
            let middleY = imageSize.height / 2
            
            context.setFillColor(backgroundColor.cgColor)
            context.setAlpha(1.0)
            context.fill(CGRect(origin: .zero, size: imageSize))
            context.setLineWidth(waveWidth)
            context.setLineJoin(.round)
            context.setLineCap(.round)
            
            let maxAmplitude = samples.max() ?? 0
            let heightNormalizationFactor = Float(imageSize.height) / maxAmplitude / 2
            
            var x: CGFloat = 0.0
            let samplesCount = samples.count
            let sizeWidth = Int(imageSize.width)
            var index = 0
            var sampleAtIndex = samples.item(at: index * samplesCount / sizeWidth)
            while sampleAtIndex != nil {
                
                sampleAtIndex = samples.item(at: index * samplesCount / sizeWidth)
                let normalizedSample = CGFloat(sampleAtIndex ?? 0) * CGFloat(heightNormalizationFactor)
                let waveHeight = normalizedSample * middleY
                
                context.move(to: CGPoint(x: x, y: middleY - waveHeight))
                context.addLine(to: CGPoint(x: x, y: middleY + waveHeight))
                
                x += waveSpacing + waveWidth
                
                index += 1
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
}
