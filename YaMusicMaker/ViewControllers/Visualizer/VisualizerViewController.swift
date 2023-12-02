//
//  VisualizerViewController.swift
//  YaMusicMaker
//
//  Created by Vlad Eliseev on 02.12.2023.
//



import UIKit
import AVFoundation

struct VisualizationEntity {
    
    let isMuted: Bool
    let speed: Float
    let volume: Float
}

enum VisualizationLayerType: CaseIterable {
    
    case spiral
    case filledCircle
    case outlinedCircle
}

final class VisualizerViewController: UIViewController {
    
    private let layers: [VisualizationEntity]
    
    let composition = AVMutableComposition()
    private let containerView = UIView()
    private let visLayer: VisualizationLayer
    
    init(layers: [VisualizationEntity]) {
        self.layers = layers
        self.visLayer = VisualizationLayer(layers: layers)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initialUISetup()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        visLayer.frame = containerView.frame
        visLayer.update()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
        
//        let videoComposition = AVMutableVideoComposition()
//        videoComposition.renderSize = videoSize
//        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
//        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
//          postProcessingAsVideoLayer: videoLayer,
//          in: outputLayer)
        
//        let instruction = AVMutableVideoCompositionInstruction()
//        instruction.timeRange = CMTimeRange(
//          start: .zero,
//          duration: composition.duration)
//        videoComposition.instructions = [instruction]
//        let layerInstruction = compositionLayerInstruction(
//          for: compositionTrack,
//          assetTrack: assetTrack)
//        instruction.layerInstructions = [layerInstruction]
        
//        guard let export = AVAssetExportSession(
//          asset: composition,
//          presetName: AVAssetExportPresetHighestQuality)
//          else {
//            print("Cannot create export session.")
//            onComplete(nil)
//            return
//        }
        
//        let videoName = UUID().uuidString
//        let exportURL = URL(fileURLWithPath: NSTemporaryDirectory())
//          .appendingPathComponent(videoName)
//          .appendingPathExtension("mov")
//
//        export.videoComposition = videoComposition
//        export.outputFileType = .mov
//        export.outputURL = exportURL
    }
    
    private func initialUISetup() {
        view.backgroundColor = Color.grayDark2
        
        view.addSubview(containerView)
        
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
        
        containerView.layer.addSublayer(visLayer)
    }
    
//    private func compositionLayerInstruction(for track: AVCompositionTrack, assetTrack: AVAssetTrack) -> AVMutableVideoCompositionLayerInstruction {
//      let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
//      let transform = assetTrack.preferredTransform
//      
//      instruction.setTransform(transform, at: .zero)
//      
//      return instruction
//    }
}
