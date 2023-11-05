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

final class LayerViewModel: IdentifiableType {
    
    let sample: Sample
    
    let identity: String = UUID().uuidString
    let isMuted = BehaviorSubject<Bool>(value: false)
    let speed = BehaviorSubject<Float>(value: Float(Constants.baseSampleTempo))
    let volume = BehaviorSubject<Float>(value: 1)
    let isPlaying = BehaviorSubject<Bool>(value: false)
    
    private var samplePlayer: AVAudioPlayerNode!
    private var sampleBuffer: AVAudioPCMBuffer!
    
    private var timer: Timer?
    
    private var bag = DisposeBag()
    
    init(sample: Sample) {
        self.sample = sample
        
        loadSample()
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
    
    private func setupLoop(tempo: Int) {
        let samplesPerMinute = tempo
        timer?.invalidate()
        let timer = Timer(timeInterval: 60.0 / Double(samplesPerMinute), repeats: true) { [weak self] timer in
            guard let self else { return }
            self.samplePlayer.scheduleBuffer(self.sampleBuffer, at: nil, options: [], completionHandler: nil)
        }
        self.timer = timer
        RunLoop.current.add(timer, forMode: .common)
    }
    
    private func loadSample() {
        do {
            self.samplePlayer = AVAudioPlayerNode()
            
            let fileURL = sample.urlToFile
            let audioFile = try AVAudioFile(forReading: fileURL)
            let audioFormat = audioFile.processingFormat
            let audioFrameCount = AVAudioFrameCount(audioFile.length)
            self.sampleBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: audioFrameCount)
            try audioFile.read(into: sampleBuffer, frameCount: audioFrameCount)
            
            let mixer = AudioService.shared.mixer
            let audioEngine = AudioService.shared.audioEngine
            audioEngine.attach(samplePlayer)
            audioEngine.connect(samplePlayer, to: mixer, format: sampleBuffer.format)
        } catch {
            print("[ERROR] loading sample in layer", error)
        }
    }
}

extension LayerViewModel: Equatable {
    
    static func == (lhs: LayerViewModel, rhs: LayerViewModel) -> Bool {
        lhs.identity == rhs.identity
    }
}
