//
//  Laye.swift
//  YaMusicMaker
//
//  Created by Vlad Eliseev on 04.11.2023.
//

import Foundation
import AVFoundation
import RxSwift
import Differentiator

class LayerViewModel: IdentifiableType {
    
    let sample: Sample
    
    let identity: String = UUID().uuidString
    let isMuted = BehaviorSubject<Bool>(value: false)
    let speed = BehaviorSubject<Float>(value: Float(Constants.baseSampleTempo))
    let volume = BehaviorSubject<Float>(value: 1)
    let isPlaying = BehaviorSubject<Bool>(value: false)
    
    var samplePlayer: AVAudioPlayerNode
    var sampleBuffer: AVAudioPCMBuffer!
    
    var timer: Timer?
    
    private var bag = DisposeBag()
    
    init(sample: Sample) {
        self.sample = sample
        self.samplePlayer = AVAudioPlayerNode()
        
        let mixer = AudioService.shared.mixer
        let audioEngine = AudioService.shared.audioEngine
        audioEngine.attach(samplePlayer)
        audioEngine.connect(samplePlayer, to: mixer, format: nil)
        
        setupBindings()
    }
    
    deinit {
        timer?.invalidate()
        samplePlayer.stop()
    }
    
    private func setupBindings() {
        let tempo = speed
            .map { Int($0) }
            .distinctUntilChanged()
        
        tempo
            .bind { [weak self] tempo in
                self?.setupLoop(tempo: tempo)
            }
            .disposed(by: bag)
        
        Observable.combineLatest(volume, isMuted)
            .bind { [weak self] (updatedVolume, isMuted) in
                self?.samplePlayer.volume = isMuted ? .zero : Float(updatedVolume)
            }
            .disposed(by: bag)
        
        Observable.combineLatest(tempo, isPlaying)
            .bind { [weak self] tempo, isPlaying in
                if isPlaying {
                    self?.setupLoop(tempo: tempo)
                    self?.samplePlayer.play()
                } else {
                    self?.timer?.invalidate()
                    self?.samplePlayer.stop()
                }
            }
            .disposed(by: bag)
    }
    
    func setupLoop(tempo: Int) {
        timer?.invalidate()
        
        let samplesPerMinute = Double(tempo)
        let periodLengthInSamples: Double = 60.0 / samplesPerMinute * Constants.sampleRate
        let fileURL = sample.urlToFile
        
        do {
            let audioFile = try AVAudioFile(forReading: fileURL)
            let audioFormat = audioFile.processingFormat
            let audioFrameCount = AVAudioFrameCount(periodLengthInSamples)
            self.sampleBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: audioFrameCount)
            try audioFile.read(into: sampleBuffer, frameCount: audioFrameCount)
            let timer = Timer(timeInterval: 60.0 / samplesPerMinute, repeats: true) { [weak self] timer in
                guard let self else { return }
                self.samplePlayer.scheduleBuffer(self.sampleBuffer, at: nil, options: [], completionHandler: nil)
            }
            self.timer = timer
            RunLoop.current.add(timer, forMode: .common)
        } catch {
            print("[ERROR] erorr setting a loop", error.localizedDescription)
        }
    }
}

extension LayerViewModel: Equatable {
    
    static func == (lhs: LayerViewModel, rhs: LayerViewModel) -> Bool {
        lhs.identity == rhs.identity
    }
}
