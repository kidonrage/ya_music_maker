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
        button.tintColor = .white
        return button
    }()
    private let playButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "play.fill"), for: .normal)
        button.tintColor = .white
        return button
    }()
    private let recordMicButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        button.tintColor = .white
        return button
    }()
    private lazy var controlsView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [UIView(), share, playButton, recordMicButton])
        stackView.axis = .horizontal
        stackView.spacing = 16
        return stackView
    }()
    
    private let sampleRate: Double = 44100
    
    private let audioEngine: AVAudioEngine = AVAudioEngine()
    private let mixer = AVAudioMixerNode()
    private var players = Set<AVAudioPlayerNode>()
    
    private var outputBuffer = AVAudioPCMBuffer()
    
    var file: AVAudioFile?
    
    private let libraryDirPath = (NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0])
    private let fileName = "test.caf"
    private lazy var filePath = libraryDirPath + "/" + fileName

    override func viewDidLoad() {
        
        super.viewDidLoad()
        view.backgroundColor = Color.black
        
        view.addSubview(sampleEditor)
        view.addSubview(control)
        view.addSubview(controlsView)
        
        controlsView.snp.makeConstraints { make in
            make.bottom.leading.trailing.equalTo(view.safeAreaLayoutGuide)
        }
        
        share.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
        share.snp.makeConstraints { make in
            make.width.height.equalTo(50)
        }
        playButton.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
        playButton.snp.makeConstraints { make in
            make.width.height.equalTo(50)
        }
        recordMicButton.addTarget(self, action: #selector(recordMicButtonTapped), for: .touchUpInside)
        recordMicButton.snp.makeConstraints { make in
            make.width.height.equalTo(50)
        }
        
        control.snp.makeConstraints { make in
            make.width.equalTo(50)
            make.top.leading.equalTo(view.safeAreaLayoutGuide).inset(16)
        }
        
        sampleEditor.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(16)
            make.bottom.equalTo(controlsView.snp.top).inset(-16)
            make.top.equalTo(view.safeAreaLayoutGuide).inset(50 + 16 + 16)
        }
        
        do {
            audioEngine.attach(mixer)
            audioEngine.connect(mixer, to: audioEngine.outputNode, format: nil)
            try audioEngine.start()
            
            loadHiHats()
            loadSnares()
            loadKick()
            
            setupTrackRecording()
            
            startPlayers()
        } catch {
            print("[TEST]", error.localizedDescription)
        }
        
        setupRecordingMic()
    }
    
    private func startPlayers() {
        for player in players {
            player.play()
        }
    }
    
    private func stopPlayers() {
        for player in players {
            player.stop()
        }
    }
    
    private func setupTrackRecording() {
        if (FileManager.default.createFile(atPath: filePath, contents: nil, attributes: nil)) {
            print("[TEST] File created successfully.")
        } else {
            print("[TEST] File not created.")
        }
        
        let tmpFileUrl = URL(fileURLWithPath: filePath)
        
//        let settings = [
//            AVSampleRateKey : NSNumber(value: Float(44100.0)),
//            AVFormatIDKey : NSNumber(value: Int32(kAudioFormatMPEG4AAC)),
//            AVNumberOfChannelsKey : NSNumber(value: 1),
//            AVEncoderAudioQualityKey : NSNumber(value: Int32(AVAudioQuality.medium.rawValue))
//        ]
        let settings = mixer.outputFormat(forBus: 0).settings
        do {
            let outputFile = try AVAudioFile(forWriting: tmpFileUrl as URL, settings: settings)
            print("[TEST] AVAudioFile created successfully.")
            mixer.installTap(onBus: 0, bufferSize: 4096, format: nil) {
                (buffer: AVAudioPCMBuffer?, time: AVAudioTime!) -> Void in
//                print("TEST", buffer, time)
                do {
                    try outputFile.write(from: buffer!)
                } catch {
                    print("[ERROR] writing to file", error.localizedDescription)
                }
            }
        } catch {
            print("[ERROR] AVAudioFile file", error)
        }
    }
    
    @objc private func playButtonTapped() {
        if audioEngine.isRunning {
            stopPlayers()
            try! audioEngine.stop()
            playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        } else {
            try! audioEngine.start()
            startPlayers()
            playButton.setImage(UIImage(systemName: "stop.fill"), for: .normal)
        }
    }
    
    private var recordingSession: AVAudioSession!
    private var whistleRecorder: AVAudioRecorder!
    private var isRecording: Bool = false
    private var isRecordingAllowed: Bool = false {
        didSet {
            recordMicButton.alpha = isRecordingAllowed ? 1.0 : 0.5
        }
    }
    
    private func setupRecordingMic() {
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    self.isRecordingAllowed = allowed
                }
            }
        } catch {
            isRecordingAllowed = false
        }
    }
    
    @objc
    private func recordMicButtonTapped() {
        guard isRecordingAllowed else {
            openSettings()
            return
        }
        if isRecording {
            // stop
            whistleRecorder.stop()
            whistleRecorder = nil
            
            isRecording = false
            recordMicButton.tintColor = .white
        } else {
            // start
            let audioURL = getNewRecordingURL()
            print(audioURL.absoluteString)
            
            let settings = mixer.outputFormat(forBus: 0).settings
            
            do {
                // 5
                whistleRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
                whistleRecorder.delegate = self
                whistleRecorder.record()
                
                isRecording = true
                recordMicButton.tintColor = .red
            } catch {
                print("[ERROR] starting recording", error.localizedDescription)
            }
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    private func getNewRecordingURL() -> URL {
        return getDocumentsDirectory().appendingPathComponent(UUID().uuidString + ".m4a")
    }
    
    private func openSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    @objc
    private func shareButtonTapped() {
        mixer.removeTap(onBus: 0)
        
        let fileURL = URL(fileURLWithPath: filePath)
                
        // Create the Array which includes the files you want to share
        var filesToShare = [Any]()
                
        // Add the path of the file to the Array
        filesToShare.append(fileURL)
                
        // Make the activityViewContoller which shows the share-view
        let activityViewController = UIActivityViewController(activityItems: filesToShare, applicationActivities: nil)

        // Be notified of the result when the share sheet is dismissed
        activityViewController.completionWithItemsHandler = { activityType, completed, returnedItems, activityError in
            print("[TEST] file shared", completed)
        }

        // Show the share-view
        self.present(activityViewController, animated: true, completion: nil)
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
    
    private func loadAudioFile(at fileURL: URL) {
        let audioFilePlayer: AVAudioPlayerNode = AVAudioPlayerNode()

        do {
            let audioFile = try AVAudioFile(forReading: fileURL)
            let audioFormat = audioFile.processingFormat
            let audioFrameCount = AVAudioFrameCount(audioFile.length)
            let audioFileBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: audioFrameCount)!
            try audioFile.read(into: audioFileBuffer, frameCount: audioFrameCount)
            
            let mainMixer = mixer
            audioEngine.attach(audioFilePlayer)
            audioEngine.connect(audioFilePlayer, to:mainMixer, format: audioFileBuffer.format)
            
            audioFilePlayer.scheduleBuffer(audioFileBuffer, at: nil, options: [.loops], completionHandler: nil)
            
            players.insert(audioFilePlayer)
        } catch {
            print(error)
        }
    }
}


extension LayerEditorViewController: AVAudioRecorderDelegate {
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        print("[TEST] recording succeeded", flag)
        guard flag else { return }
        let recordedFileUrl = recorder.url
        loadAudioFile(at: recordedFileUrl)
        startPlayers()
    }
}
