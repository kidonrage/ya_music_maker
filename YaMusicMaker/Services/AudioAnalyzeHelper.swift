//
//  AudioAnalyzeHelper.swift
//  YaMusicMaker
//
//  Created by Vlad Eliseev on 01.12.2023.
//

import AVFoundation

final class AudioAnalyzeHelper {
    
    func getScaleFromSamples(buffer: AVAudioPCMBuffer) -> CGFloat? {
        guard let channelData = buffer.floatChannelData?[0] else { return nil }
        let frameLength = Int(buffer.frameLength)
        let indicies = Array(0 ..< frameLength)
        let average = indicies.reduce(into: 0) { $0 += pow(channelData[$1], 2) } / Float(frameLength)
        let level =  10.0 * log10(average)
        let additionalCoef: CGFloat = 50
        return max(.zero, CGFloat(level) + additionalCoef) / 2
    }
}
