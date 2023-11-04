//
//  LayerEditorViewController.swift
//  YaMusicMaker
//
//  Created by Vlad Eliseev on 03.11.2023.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import AVFoundation

class LayerEditorViewController: UIViewController {
    
    private let selectorA = SampleSelectorControl()
    private let selectorB = SampleSelectorControl()
    private let selectorC = SampleSelectorControl()
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
    private let layersButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "square.3.layers.3d"), for: .normal)
        button.tintColor = .white
        return button
    }()
    private let emptyLayersLabel: UILabel = {
        let label = UILabel()
        label.text = "Добавьте первый слой, выбрав семпл или записав звук с микрофона"
        label.textColor = Color.white
        label.numberOfLines = .zero
        label.textAlignment = .center
        return label
    }()
    private let emptyLayersContainer: UIView = {
        let view = UIView()
        return view
    }()
    private lazy var controlsView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [layersButton, UIView(), share, playButton, recordMicButton])
        stackView.axis = .horizontal
        stackView.spacing = 16
        return stackView
    }()
    private lazy var saplesSelectorsContainer: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [selectorA, selectorB, selectorC])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 24
        return stackView
    }()
    
    private lazy var layersTableView: UITableView = {
        let tableView = SelfSizingTableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(LayerTableViewCell.self, forCellReuseIdentifier: LayerTableViewCell.cellId)
        tableView.estimatedRowHeight = 56
        tableView.contentInset = .init(top: 5, left: .zero, bottom: 5, right: .zero)
        tableView.layer.cornerRadius = 12
        return tableView
    }()
    
    private let sampleRate: Double = 44100
    
    private let audioEngine: AVAudioEngine = AVAudioEngine()
    private let mixer = AVAudioMixerNode()
    
    private let layers = BehaviorSubject<[Layer]>(value: [])
    
    private let isRecording = BehaviorSubject<Bool>(value: false)
    private let isRecordingAllowed = BehaviorSubject<Bool>(value: false)
    
    private let isLayersListExpanded = BehaviorSubject<Bool>(value: false)
    
    private var bag = DisposeBag()
    
    private var players = Set<AVAudioPlayerNode>()
    
    var file: AVAudioFile?
    
    private let libraryDirPath = (NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0])
    private let fileName = "test.caf"
    private lazy var filePath = libraryDirPath + "/" + fileName

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupBindings()
        
        layersTableView.reloadData()
        
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
    
    private func setupUI() {
        view.backgroundColor = Color.grayDark2
        
        view.addSubview(emptyLayersContainer)
        emptyLayersContainer.addSubview(emptyLayersLabel)
        view.addSubview(sampleEditor)
        view.addSubview(saplesSelectorsContainer)
        view.addSubview(layersTableView)
        view.addSubview(controlsView)
        
        emptyLayersContainer.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(16)
            make.bottom.equalTo(controlsView.snp.top).inset(-16)
            make.top.equalTo(saplesSelectorsContainer.snp.bottom).inset(-16)
        }
        emptyLayersLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
        
        controlsView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        
        share.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
        share.snp.makeConstraints { make in
            make.width.height.equalTo(50)
        }
        playButton.addTarget(self, action: #selector(toggleIsSongPlaying), for: .touchUpInside)
        playButton.snp.makeConstraints { make in
            make.width.height.equalTo(50)
        }
//        recordMicButton.addTarget(self, action: #selector(recordMicButtonTapped), for: .touchUpInside)
        recordMicButton.snp.makeConstraints { make in
            make.width.height.equalTo(50)
        }
        
        selectorA.snp.makeConstraints { make in
            make.width.equalTo(50)
        }
        
        saplesSelectorsContainer.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(16)
        }
        
        sampleEditor.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(16)
            make.bottom.equalTo(controlsView.snp.top).inset(-16)
            make.top.equalTo(saplesSelectorsContainer.snp.bottom).inset(-16)
        }
    }
    
    private func setupLayersTableConstraints(isExpanded: Bool) {
        layersTableView.snp.removeConstraints()
        if isExpanded {
            layersTableView.snp.makeConstraints { make in
                make.leading.trailing.equalTo(view.safeAreaLayoutGuide)
                make.bottom.equalTo(controlsView.snp.top).inset(-16)
                make.top.greaterThanOrEqualTo(saplesSelectorsContainer.snp.bottom).inset(-16)
            }
        } else {
            layersTableView.snp.makeConstraints { make in
                make.leading.trailing.equalTo(view.safeAreaLayoutGuide)
                make.top.greaterThanOrEqualTo(view.snp.bottom)
            }
        }
    }
    
    private func setupBindings() {
        let isLayersEmpty = layers
            .map { $0.isEmpty }
        
        isLayersEmpty
            .map { !$0 }
            .bind(to: emptyLayersContainer.rx.isHidden)
            .disposed(by: bag)
        
        isLayersEmpty
            .bind(to: sampleEditor.rx.isHidden)
            .disposed(by: bag)
        
        // recording
        isRecordingAllowed
            .bind(to: recordMicButton.rx.isEnabled)
            .disposed(by: bag)
        
        recordMicButton.rx.tap
            .withLatestFrom(Observable.combineLatest(isRecordingAllowed, isRecording))
            .bind(onNext: { [weak self] values in
                let allowed = values.0
                let isRecording = values.1
                self?.toggleIsRecording(isRecordingAllowed: allowed, isRecording: isRecording)
            })
            .disposed(by: bag)
        
        // layers list
        layersButton.rx.tap
            .withLatestFrom(isLayersListExpanded)
            .map { !$0 }
            .bind(to: isLayersListExpanded)
            .disposed(by: bag)
        
        isLayersListExpanded
            .bind { [weak self] isExpanded in
                UIView.animate(withDuration: 0.25) {
                    self?.setupLayersTableConstraints(isExpanded: isExpanded)
                    self?.view.layoutIfNeeded()
                }
            }
            .disposed(by: bag)
    }
    
    private func startPlayers() {
        do {
            try audioEngine.start()
            playButton.setImage(UIImage(systemName: "stop.fill"), for: .normal)
            for player in players {
                player.play()
            }
        } catch {
            print("[ERROR] starting song", error)
        }
    }
    
    private func stopPlayers() {
        for player in players {
            player.stop()
        }
        audioEngine.stop()
        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
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
    
    @objc private func toggleIsSongPlaying() {
        if audioEngine.isRunning {
            stopPlayers()
        } else {
            startPlayers()
        }
    }
    
    private var recordingSession: AVAudioSession!
    private var whistleRecorder: AVAudioRecorder!
    
    private func setupRecordingMic() {
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    self.isRecordingAllowed.onNext(allowed)
                }
            }
        } catch {
            self.isRecordingAllowed.onNext(false)
        }
    }
    
    private func toggleIsRecording(isRecordingAllowed: Bool, isRecording: Bool) {
        guard isRecordingAllowed else {
            openSettings()
            return
        }
        if isRecording {
            // stop
            whistleRecorder.stop()
            whistleRecorder = nil
            
            self.isRecording.onNext(false)
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
                
                self.isRecording.onNext(true)
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

extension LayerEditorViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let layerCell = tableView.dequeueReusableCell(withIdentifier: LayerTableViewCell.cellId) as? LayerTableViewCell else {
            return UITableViewCell()
        }
        layerCell.configure()
        return layerCell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }
}
