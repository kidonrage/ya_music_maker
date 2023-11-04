//
//  SampleEditorView.swift
//  YaMusicMaker
//
//  Created by Vlad Eliseev on 03.11.2023.
//

import UIKit

final class SampleEditorView: UIControl {
    
    private var minVolume: Double = 0.0
    private var maxVolume: Double = 2.0
    var currentVolume: Double = 1.0 {
        didSet {
            let height: CGFloat = 20
            let frame = CGRect(
                x: self.frame.minX,
                y: (1 - (currentVolume / (maxVolume - minVolume))) * frame.height,
                width: height,
                height: 90
            )
//            print("[TEST]", frame, frame.maxY)
            volumeIndicator.frame = frame
        }
    }
    
    private var minSpeed: Double = 0.25
    private var maxSpeed: Double = 2
    var currentSpeed: Double = 1.0 {
        didSet {
            let height: CGFloat = 20
            let frame = CGRect(
                x: (currentSpeed / (maxSpeed - minSpeed)) * frame.width,
                y: self.frame.height - height,
                width: 90,
                height: height
            )
//            print("[TEST]", frame, frame.maxY)
            speedIndicator.frame = frame
            
            sendActions(for: .valueChanged)
        }
    }
    
    private let volumeIndicator: UILabel = {
        let label = UILabel()
        label.text = "громкость"
        label.backgroundColor = Color.green
        label.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        return label
    }()
    
    private let speedIndicator: UILabel = {
        let label = UILabel()
        label.text = "скорость"
        label.backgroundColor = Color.green
        label.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        let relativeVolume = location.y / frame.height
        let volumeLevel = (maxVolume - minVolume) * (1 - relativeVolume)
        
        let relativeSpeed = location.x / frame.width
        let speedLevel = (maxSpeed - minSpeed) * relativeSpeed

//        print("[TEST] volume level", volumeLevel)
//        print("[TEST] speed level", speedLevel)
        self.currentVolume = volumeLevel
        self.currentSpeed = speedLevel
    }
    
    private func setupViews() {
        backgroundColor = Color.blue
        
        addSubview(speedIndicator)
        
        addSubview(volumeIndicator)
        volumeIndicator.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
        
        currentSpeed = 1
        currentVolume = 1
        
//        volumeIndicator.frame = CGRect(
//            x: <#T##Int#>,
//            y: <#T##Int#>,
//            width: <#T##Int#>,
//            height: <#T##Int#>
//        )
    }
}
