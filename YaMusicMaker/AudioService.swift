//
//  AudioService.swift
//  YaMusicMaker
//
//  Created by Vlad Eliseev on 04.11.2023.
//

import RxSwift
import AVFoundation

final class AudioService {
    
    private let _sampleToPreplay = PublishSubject<Sample>()
    lazy var sampleToPreplay = _sampleToPreplay.asObserver()
    
    private var bag = DisposeBag()
    
    private let audioEngine: AVAudioEngine = AVAudioEngine()
    private let mixer = AVAudioMixerNode()
    private var samplePreplayPlayer = AVAudioPlayerNode()
    
    private init() {
        do {
            audioEngine.attach(mixer)
            audioEngine.connect(mixer, to: audioEngine.outputNode, format: nil)
            try audioEngine.start()
        } catch {
            print("[ERROR]", error)
        }
        
        setupBindings()
    }
    
    private func setupBindings() {
        _sampleToPreplay
            .bind { [weak self] sample in
                DispatchQueue.global().async {
                    self?.loadSample(sample)
                }
            }
            .disposed(by: bag)
    }
    
    private func loadSample(_ sample: Sample) {
        do {
            let fileURL = sample.urlToFile
            let audioFile = try AVAudioFile(forReading: fileURL)
            let audioFormat = audioFile.processingFormat
            let audioFrameCount = AVAudioFrameCount(audioFile.length)
            let audioFileBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: audioFrameCount)!
            try audioFile.read(into: audioFileBuffer, frameCount: audioFrameCount)
                
            audioEngine.attach(samplePreplayPlayer)
            audioEngine.connect(samplePreplayPlayer, to: mixer, format: audioFileBuffer.format)
            
            samplePreplayPlayer.scheduleBuffer(audioFileBuffer, at: nil, options: [], completionHandler: nil)
            
            samplePreplayPlayer.play()
        } catch {
            print(error)
        }
    }
    
    static let shared = AudioService()
}
