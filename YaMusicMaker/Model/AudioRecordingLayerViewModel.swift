//
//  AudioRecordingLayerViewModel.swift
//  YaMusicMaker
//
//  Created by Vlad Eliseev on 05.11.2023.
//

import Foundation
import AVFoundation


// Заплатка для реализации слоя с аудиозаписью, которая не лупится. По-хорошему тут надо сделать нормальное наследование, но у меня не хватает времени :)
final class AudioRecordingLayerViewModel: LayerViewModel {
    
    override func setupLoop(tempo: Int) {
        timer?.invalidate()
        
        let fileURL = sample.urlToFile
        
        do {
            let audioFile = try AVAudioFile(forReading: fileURL)
            let audioFormat = audioFile.processingFormat
            let audioFrameCount = AVAudioFrameCount(audioFile.length)
            self.sampleBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: audioFrameCount)
            try audioFile.read(into: sampleBuffer, frameCount: audioFrameCount)
            self.samplePlayer.scheduleBuffer(self.sampleBuffer, at: nil, options: [.loops], completionHandler: nil)
        } catch {
            print("[ERROR] erorr setting a loop", error.localizedDescription)
        }
    }
}
