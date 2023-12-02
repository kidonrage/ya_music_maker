//
//  VisualizerPreviewViewController.swift
//  YaMusicMaker
//
//  Created by Vlad Eliseev on 02.12.2023.
//

import UIKit
import AVFoundation
import RxSwift
import RxRelay

final class VisualizerPreviewViewController: UIViewController {
    
    private let layers: [VisualizationEntity]
    private let trackUrl: URL
    
    let composition = AVMutableComposition()
    private let containerView = UIView()
    private let visLayer: VisualizationLayer
    
    private let playbackSlider: UISlider = {
        let slider = UISlider()
        return slider
    }()
    private let playButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "play.fill"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = Color.grayDark
        button.layer.cornerRadius = 12
        return button
    }()
    private let passedTimeLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        return label
    }()
    private let totalTimeLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        return label
    }()
    private lazy var controlsStack: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [passedTimeLabel, UIView(), playButton, UIView(), totalTimeLabel])
        stackView.axis = .horizontal
        stackView.distribution = .equalCentering
        stackView.spacing = 16
        return stackView
    }()
    
    private let isPlaying = BehaviorRelay(value: true)
    
    private let player: AVAudioPlayer?
    
    private var totalTime: TimeInterval?
    
    init(
        layers: [VisualizationEntity],
        trackUrl: URL
    ) {
        self.layers = layers
        self.trackUrl = trackUrl
        self.visLayer = VisualizationLayer(layers: layers)
        self.player = try? AVAudioPlayer(contentsOf: trackUrl)
        
        let asset = AVURLAsset(url: trackUrl)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        visLayer.frame = containerView.frame
        visLayer.update()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initialUISetup()
        setupBindings()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { [weak self] _ in
            guard let currentPlayerTime = self?.player?.currentTime else { return }
            self?.playbackSlider.value = Float(currentPlayerTime)
            let totalTime = self?.totalTime ?? 0
            self?.passedTimeLabel.text = "\(totalTime - (totalTime - currentPlayerTime))"
        })
    }
    
    private func initialUISetup() {
        view.backgroundColor = Color.grayDark2
        
        view.addSubview(controlsStack)
        view.addSubview(playbackSlider)
        view.addSubview(containerView)
        
        playButton.snp.makeConstraints { make in
            make.height.width.equalTo(50)
        }
        controlsStack.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        playbackSlider.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalTo(controlsStack.snp.top).inset(-16)
        }
        containerView.snp.makeConstraints { make in
            make.leading.trailing.top.equalTo(view.safeAreaLayoutGuide).inset(16)
            make.bottom.equalTo(playbackSlider.snp.top).inset(-16)
        }
        passedTimeLabel.snp.makeConstraints { make in
            make.width.equalTo(100)
        }
        totalTimeLabel.snp.makeConstraints { make in
            make.width.equalTo(100)
        }
        
        containerView.layer.addSublayer(visLayer)
        
        let audioAsset = AVURLAsset(url: trackUrl)
        playbackSlider.minimumValue = .zero
        let duration = Float(audioAsset.duration.seconds)
        totalTime = audioAsset.duration.seconds
        playbackSlider.maximumValue = duration
        totalTimeLabel.text = "\(duration)"
    }
    
    private var bag = DisposeBag()
    
    private var timer: Timer?
    
    private func setupBindings() {
        isPlaying
            .map { $0 ? UIImage(systemName: "stop.fill") : UIImage(systemName: "play.fill") }
            .bind(to: playButton.rx.image())
            .disposed(by: bag)
        
        isPlaying
            .bind { [weak self] isPlaying in
                if isPlaying {
                    self?.player?.play()
                } else {
                    self?.player?.stop()
                }
            }
            .disposed(by: bag)
        
        playButton.rx.tap.asObservable()
            .withLatestFrom(isPlaying)
            .map { !$0 }
            .bind(to: isPlaying)
            .disposed(by: bag)
        
        playbackSlider.rx.value.bind { [weak self] value in
            
        }.disposed(by: bag)
    }
    
    private func makeVisualizer(
        videoSize: CGSize,
        fromTrackAt trackURL: URL,
        forName name: String,
        onComplete: @escaping (URL?) -> Void
    ) {
        // cant render anything without blank video
        let videoResourceName = "blank"
        guard let path = Bundle.main.path(forResource: videoResourceName, ofType: "mp4") else {
            debugPrint("video \(videoResourceName) is not found")
            return
        }
        let videoUrl = URL(fileURLWithPath: path)
        let vidAsset = AVURLAsset(url: videoUrl)
        
        let audioAsset = AVURLAsset(url: trackURL)
        
        let composition = AVMutableComposition()
        
        guard
            let videoAssetTrack = vidAsset.tracks(withMediaType: .video).first,
            let compositionVideoTrack = composition.addMutableTrack(
              withMediaType: .video,
              preferredTrackID: kCMPersistentTrackID_Invalid
            ),
            let audioAssetTrack = audioAsset.tracks(withMediaType: .audio).first,
            let compositionAudioTrack = composition.addMutableTrack(
                withMediaType: .audio,
                preferredTrackID: kCMPersistentTrackID_Invalid
            )
        else {
            fatalError("Something went wrong while adding tracks")
            return
        }
        
        do {
            let timeRange = CMTimeRange(start: .zero, duration: audioAsset.duration)
            try compositionVideoTrack.insertTimeRange(timeRange, of: videoAssetTrack, at: .zero)
            try compositionAudioTrack.insertTimeRange(timeRange, of: audioAssetTrack, at: .zero)
        } catch {
            print(error)
            onComplete(nil)
            return
        }
        
        let videoLayer = CALayer()
        videoLayer.frame = CGRect(
            origin: .zero,
            size: videoSize
        )
        
        let outputLayer = CALayer()
        outputLayer.frame = CGRect(origin: .zero, size: videoSize)
        
        let visualizationLayer = VisualizationLayer(layers: self.layers)
        visualizationLayer.frame = CGRect(origin: .zero, size: videoSize)
        visualizationLayer.update()
        
        outputLayer.addSublayer(videoLayer)
        outputLayer.addSublayer(visualizationLayer)
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = videoSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
            postProcessingAsVideoLayer: videoLayer,
            in: outputLayer
        )
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: composition.duration)
        let layerinstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoAssetTrack)
        layerinstruction.setTransform(videoAssetTrack.preferredTransform, at: CMTime.zero)
        instruction.layerInstructions = [layerinstruction] as [AVVideoCompositionLayerInstruction]
        videoComposition.instructions = [instruction] as [AVVideoCompositionInstructionProtocol]
        
//        let instruction = AVMutableVideoCompositionInstruction()
//        instruction.timeRange = CMTimeRange(
//          start: .zero,
//          duration: audioAsset.duration
//        )
//        videoComposition.instructions = [instruction]
//        let layerInstruction = compositionLayerInstruction()
//        instruction.layerInstructions = [layerInstruction]

        guard let export = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality)
        else {
            print("Cannot create export session.")
            onComplete(nil)
            return
        }
        
        let videoName = UUID().uuidString
        let exportURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(videoName)
            .appendingPathExtension("mov")
        
        export.videoComposition = videoComposition
        export.outputFileType = .mov
        export.outputURL = exportURL
        
        export.exportAsynchronously {
            DispatchQueue.main.async {
                switch export.status {
                case .completed:
                    onComplete(exportURL)
                default:
                    print("Something went wrong during export.")
                    print(export.error ?? "unknown error")
                    onComplete(nil)
                    break
                }
            }
        }
    }
    
    private func compositionLayerInstruction() -> AVMutableVideoCompositionLayerInstruction {
        let instruction = AVMutableVideoCompositionLayerInstruction()
        let transform = CGAffineTransform.identity
        
        instruction.setTransform(transform, at: .zero)
        
        return instruction
    }
}
