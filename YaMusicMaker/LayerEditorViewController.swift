//
//  LayerEditorViewController.swift
//  YaMusicMaker
//
//  Created by Vlad Eliseev on 03.11.2023.
//

import UIKit
import SnapKit

import AVFoundation

class LayerEditorViewController: UIViewController {
    
    private let control = SampleSelectorControl()
    private let sampleEditor = SampleEditorView()
    private let share: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        return button
    }()
    
    private let sampleRate: Double = 44100
    
    private let audioEngine: AVAudioEngine = AVAudioEngine()
    private let mixer = AVAudioMixerNode()
    private var players = Set<AVAudioPlayerNode>()

    override func viewDidLoad() {
        
        super.viewDidLoad()
        view.backgroundColor = Color.black
        
        view.addSubview(sampleEditor)
        view.addSubview(control)
        view.addSubview(share)
        
        share.snp.makeConstraints { make in
            make.width.height.equalTo(50)
            make.center.equalToSuperview()
        }
        
        control.snp.makeConstraints { make in
            make.width.equalTo(50)
            make.top.leading.equalTo(view.safeAreaLayoutGuide).inset(16)
        }
        
        sampleEditor.snp.makeConstraints { make in
            make.bottom.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(16)
            make.top.equalTo(view.safeAreaLayoutGuide).inset(50 + 16 + 16)
        }
        
        do {
            audioEngine.attach(mixer)
            audioEngine.connect(mixer, to: audioEngine.outputNode, format: nil)
            try audioEngine.start()
            
            loadHiHats()
            loadSnares()
            loadKick()
            
            for player in players {
                player.play()
            }
        } catch {
            print("[TEST]", error.localizedDescription)
        }
        
        
    }
    
    private func loadHiHats() {
        let audioFilePlayer: AVAudioPlayerNode = AVAudioPlayerNode()
        let samplesPerMinute: Double = 240
        let periodLengthInSamples: Double = 60.0 / samplesPerMinute * sampleRate
        
        do {
            let path = Bundle.main.path(forResource: "hihat.wav", ofType:nil)!
            let fileURL = URL(fileURLWithPath: path)
            let audioFile = try AVAudioFile(forReading: fileURL)
            let audioFormat = audioFile.processingFormat
            let audioFrameCount = AVAudioFrameCount(periodLengthInSamples)
            let audioFileBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: audioFrameCount)!
            try audioFile.read(into: audioFileBuffer, frameCount: audioFrameCount)
            
            let mainMixer = mixer
            audioEngine.attach(audioFilePlayer)
            audioEngine.connect(audioFilePlayer, to:mainMixer, format: audioFileBuffer.format)
            
            Timer.scheduledTimer(withTimeInterval: 60.0 / samplesPerMinute, repeats: true) { timer in
                audioFilePlayer.scheduleBuffer(audioFileBuffer, at: nil, options: [], completionHandler: nil)
            }
            
            players.insert(audioFilePlayer)
        } catch {
            print(error)
        }
    }
    
    private func loadSnares() {
        let audioFilePlayer: AVAudioPlayerNode = AVAudioPlayerNode()
        let samplesPerMinute: Double = 60
        let periodLengthInSamples: Double = 60.0 / samplesPerMinute * sampleRate
        
        do {
            let path = Bundle.main.path(forResource: "snare.wav", ofType:nil)!
            let fileURL = URL(fileURLWithPath: path)
            let audioFile = try AVAudioFile(forReading: fileURL)
            let audioFormat = audioFile.processingFormat
            let audioFrameCount = AVAudioFrameCount(periodLengthInSamples)
            let audioFileBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: audioFrameCount)!
            try audioFile.read(into: audioFileBuffer, frameCount: audioFrameCount)
            
            let mainMixer = mixer
            audioEngine.attach(audioFilePlayer)
            audioEngine.connect(audioFilePlayer, to:mainMixer, format: audioFileBuffer.format)
            
            Timer.scheduledTimer(withTimeInterval: 60.0 / samplesPerMinute, repeats: true) { timer in
                audioFilePlayer.scheduleBuffer(audioFileBuffer, at: nil, options: [], completionHandler: nil)
            }
            
            players.insert(audioFilePlayer)
        } catch {
            print(error)
        }
    }
    
    private func loadKick() {
        let audioFilePlayer: AVAudioPlayerNode = AVAudioPlayerNode()
        let samplesPerMinute: Double = 120
        let periodLengthInSamples: Double = 60.0 / samplesPerMinute * sampleRate
        
        do {
            let path = Bundle.main.path(forResource: "kick.wav", ofType:nil)!
            let fileURL = URL(fileURLWithPath: path)
            let audioFile = try AVAudioFile(forReading: fileURL)
            let audioFormat = audioFile.processingFormat
            let audioFrameCount = AVAudioFrameCount(periodLengthInSamples)
            let audioFileBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: audioFrameCount)!
            try audioFile.read(into: audioFileBuffer, frameCount: audioFrameCount)
            
            let mainMixer = mixer
            audioEngine.attach(audioFilePlayer)
            audioEngine.connect(audioFilePlayer, to:mainMixer, format: audioFileBuffer.format)
            
            Timer.scheduledTimer(withTimeInterval: 60.0 / samplesPerMinute, repeats: true) { timer in
                audioFilePlayer.scheduleBuffer(audioFileBuffer, at: nil, options: [], completionHandler: nil)
            }
            
            players.insert(audioFilePlayer)
        } catch {
            print(error)
        }
    }
}
