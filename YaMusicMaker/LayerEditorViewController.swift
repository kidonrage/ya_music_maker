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
import RxDataSources

typealias LayersListSectionModel = AnimatableSectionModel<String, LayerViewModel>

class LayerEditorViewController: UIViewController {
    
    private let sampleEditor = SampleEditorView()
    private let recordToFileButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "record.circle"), for: .normal)
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
        let stackView = UIStackView(arrangedSubviews: [layersButton, UIView(), recordToFileButton, playButton, recordMicButton])
        stackView.axis = .horizontal
        stackView.spacing = 16
        return stackView
    }()
    private let saplesSelectorsContainer: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .equalCentering
        stackView.spacing = 24
        return stackView
    }()
    
    private lazy var layersTableView: UITableView = {
        let tableView = SelfSizingTableView()
        tableView.register(LayerTableViewCell.self, forCellReuseIdentifier: LayerTableViewCell.cellId)
        tableView.estimatedRowHeight = 56
        tableView.contentInset = .init(top: 5, left: .zero, bottom: 5, right: .zero)
        tableView.layer.cornerRadius = 12
        tableView.separatorStyle = .none
        return tableView
    }()
    
    let sampleSelectorPanelHeight: CGFloat = 80
    
    private let mixer = AudioService.shared.mixer
    
    private let layers = BehaviorSubject<[LayerViewModel]>(value: [])
    
    private let isRecording = BehaviorSubject<Bool>(value: false)
    private let isRecordingAllowed = BehaviorSubject<Bool>(value: false)
    
    private let isPlaying = BehaviorSubject<Bool>(value: false)
    
    private let isRecordingToFile = BehaviorSubject<Bool>(value: false)
    
    private let isLayersListExpanded = BehaviorSubject<Bool>(value: false)
    
    private let newSampleSelected = PublishSubject<Sample>()
    private let newLayerCreated = PublishSubject<LayerViewModel>()
    private let currentlySelectedLayer = BehaviorRelay<LayerViewModel?>(value: nil)
    
    private let deleteLayerHandler = PublishSubject<LayerViewModel>()
    
    private lazy var dataSource = RxTableViewSectionedAnimatedDataSource<LayersListSectionModel>(
        animationConfiguration: AnimationConfiguration(
            reloadAnimation: .none,
            deleteAnimation: .left
        ),
        configureCell: configureCell
    )
    
    private var configureCell: RxTableViewSectionedAnimatedDataSource<LayersListSectionModel>.ConfigureCell {
        return { [weak self] _, tableView, indexPath, layer in
            guard
                let self,
                let layerCell = tableView.dequeueReusableCell(withIdentifier: LayerTableViewCell.cellId) as? LayerTableViewCell
            else {
                return UITableViewCell()
            }
            layerCell.configure(
                with: layer,
                deleteLayerHandler: .init(eventHandler: { [weak self, weak layer] event in
                    guard
                        case .next = event,
                        let layer
                    else { return }
                    self?.deleteLayerHandler.onNext(layer)
                }),
                selectedLayer: self.currentlySelectedLayer.compactMap { $0 } .asObservable()
            )
            return layerCell
        }
    }
    
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
        
        setupRecordingMic()
    }
    
    private func setupUI() {
        view.backgroundColor = Color.grayDark2
        
        view.addSubview(emptyLayersContainer)
        emptyLayersContainer.addSubview(emptyLayersLabel)
        view.addSubview(sampleEditor)
        view.addSubview(layersTableView)
        view.addSubview(controlsView)
        view.addSubview(saplesSelectorsContainer)
        
        emptyLayersContainer.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(16)
            make.bottom.equalTo(controlsView.snp.top).inset(-16)
        }
        emptyLayersLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
        
        controlsView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        
        recordToFileButton.snp.makeConstraints { make in
            make.width.height.equalTo(50)
        }
        
        playButton.snp.makeConstraints { make in
            make.width.height.equalTo(50)
        }
        
        recordMicButton.snp.makeConstraints { make in
            make.width.height.equalTo(50)
        }
        
        setupSampleSelector()
        
        sampleEditor.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).inset(sampleSelectorPanelHeight + 56)
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(16)
            make.bottom.equalTo(controlsView.snp.top).inset(-16)
        }
    }
    
    private func setupSampleSelector() {
        saplesSelectorsContainer.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(16)
            make.height.greaterThanOrEqualTo(sampleSelectorPanelHeight)
        }
        
        let viewModels = getMockedSampleSelectorViewModels(sampleSelectedHandler: newSampleSelected.asObserver())
        for (i, viewModel) in viewModels.enumerated() {
            let selector = SampleSelectorControl(viewModel: viewModel)
            saplesSelectorsContainer.addArrangedSubview(selector)
            if i < viewModels.count - 1 {
                saplesSelectorsContainer.addArrangedSubview(UIView())
            }
            
            selector.snp.makeConstraints { make in
                make.width.equalTo(sampleSelectorPanelHeight)
            }
        }
    }
    
    private func setupLayersTableConstraints(isExpanded: Bool) {
        layersTableView.snp.removeConstraints()
        if isExpanded {
            layersTableView.snp.makeConstraints { make in
                make.leading.trailing.equalTo(view.safeAreaLayoutGuide)
                make.bottom.equalTo(controlsView.snp.top).inset(-16)
                make.top.greaterThanOrEqualTo(sampleEditor.snp.top)
            }
        } else {
            layersTableView.snp.makeConstraints { make in
                make.leading.trailing.equalTo(view.safeAreaLayoutGuide)
                make.top.greaterThanOrEqualTo(view.snp.bottom)
            }
        }
    }
    
    private func setupBindings() {
        let isLayerSelected = currentlySelectedLayer
            .map { $0 != nil }
        
        isLayerSelected
            .bind(to: emptyLayersContainer.rx.isHidden)
            .disposed(by: bag)
        
        isLayerSelected
            .map { !$0 }
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
        
        // play / stop
        isPlaying
            .map { $0 ? UIImage(systemName: "stop.fill") : UIImage(systemName: "play.fill") }
            .bind(to: playButton.rx.image())
            .disposed(by: bag)
        
        playButton.rx.tap.asObservable()
            .withLatestFrom(isPlaying)
            .map { !$0 }
            .bind(to: isPlaying)
            .disposed(by: bag)
        
        Observable.combineLatest(layers, isPlaying)
            .bind { layers, isPlaying in
                for layer in layers {
                    layer.isPlaying.onNext(isPlaying)
                }
            }
            .disposed(by: bag)
        
        // record to file
        isRecordingToFile
            .map { $0 ? Color.red : Color.white }
            .bind(to: recordToFileButton.rx.tintColor)
            .disposed(by: bag)
        
        recordToFileButton.rx.tap
            .withLatestFrom(isRecordingToFile)
            .bind { [weak self] isRecordingToFile in
                if isRecordingToFile {
                    // stop & share
                    self?.shareButtonTapped()
                } else {
                    // start
                    self?.startTrackRecording()
                }
            }
            .disposed(by: bag)
        
        // sample selection
        newSampleSelected
            .map { LayerViewModel(sample: $0) }
            .bind(to: newLayerCreated)
            .disposed(by: bag)
        
        newLayerCreated
            .withLatestFrom(layers) { $1 + [ $0 ] }
            .bind(to: layers)
            .disposed(by: bag)
        
        newLayerCreated
            .bind(to: currentlySelectedLayer)
            .disposed(by: bag)
        
        currentlySelectedLayer
            .bind { [weak self] layer in
                self?.sampleEditor.configure(with: layer)
            }
            .disposed(by: bag)
        
        // layers list
        let isLayersEmpty = layers
            .map { $0.isEmpty }

        isLayersEmpty
            .map { !$0 }
            .bind(to: layersButton.rx.isEnabled)
            .disposed(by: bag)
        
        layersButton.rx.tap
            .withLatestFrom(isLayersListExpanded)
            .map { !$0 }
            .bind(to: isLayersListExpanded)
            .disposed(by: bag)
        
        Observable.combineLatest(isLayersListExpanded, isLayersEmpty)
            .bind { [weak self] isExpanded, isLayersEmpty in
                UIView.animate(withDuration: 0.25) {
                    self?.setupLayersTableConstraints(isExpanded: isExpanded && !isLayersEmpty)
                    self?.view.layoutIfNeeded()
                }
            }
            .disposed(by: bag)
        
        layersTableView.rx.setDelegate(self)
            .disposed(by: bag)
        
        layersTableView.rx.itemSelected
            .withLatestFrom(layers) { $1[$0.row] }
            .bind(to: currentlySelectedLayer)
            .disposed(by: bag)
        
        layers
            .map { [LayersListSectionModel(model: "", items: $0)] }
            .bind(to: layersTableView.rx.items(dataSource: dataSource))
            .disposed(by: bag)
        
        // deleting layers
        deleteLayerHandler
            .withLatestFrom(layers) { deletedLayer, layers in
                var updatedLayers = layers
                updatedLayers.removeAll { $0.identity == deletedLayer.identity }
                return updatedLayers
            }
            .bind(to: layers)
            .disposed(by: bag)
        
        deleteLayerHandler
            .withLatestFrom(currentlySelectedLayer) {
                $0.identity == $1?.identity
            }
            .filter { $0 }
            .withLatestFrom(layers)
            .map { $0.first }
            .bind(to: currentlySelectedLayer)
            .disposed(by: bag)
    }
    
    private func startTrackRecording() {
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
            isRecordingToFile.onNext(true)
        } catch {
            print("[ERROR] AVAudioFile file", error)
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
        isRecordingToFile.onNext(false)
        
        AudioService.shared.mixer.removeTap(onBus: 0)
        
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
}


extension LayerEditorViewController: AVAudioRecorderDelegate {
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        print("[TEST] recording succeeded", flag)
        guard flag else { return }
        let recordedFileUrl = recorder.url
        let sample = Sample(
            name: "Запись",
            urlToFile: recordedFileUrl,
            icon: UIImage(systemName: "music.mic")!
        )
        self.newLayerCreated.onNext(AudioRecordingLayerViewModel(sample: sample))
    }
}

extension LayerEditorViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }
}
