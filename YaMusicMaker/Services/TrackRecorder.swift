//
//  TrackRecorder.swift
//  YaMusicMaker
//
//  Created by Vlad Eliseev on 05.11.2023.
//

import Foundation
import RxSwift
import AVFoundation

final class TrackRecorder {
    
    let isRecording = BehaviorSubject<Bool>(value: false)
    let recordedSuccessfulyToFile = PublishSubject<URL>()
    
    private let trackOutputMixer = AudioService.shared.mixer
    private let filePath: String = {
        let libraryDirPath = (NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0])
        let fileName = "trackOutput.caf"
        return libraryDirPath + "/" + fileName
    }()
    
    func stopTrackRecording() {
        AudioService.shared.mixer.removeTap(onBus: 0)
        isRecording.onNext(false)
        let fileURL = URL(fileURLWithPath: filePath)
        recordedSuccessfulyToFile.onNext(fileURL)
    }
    
    func startTrackRecording() {
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
        let settings = trackOutputMixer.outputFormat(forBus: 0).settings
        do {
            let outputFile = try AVAudioFile(forWriting: tmpFileUrl as URL, settings: settings)
            print("[TEST] AVAudioFile created successfully.")
            trackOutputMixer.installTap(onBus: 0, bufferSize: 4096, format: nil) {
                (buffer: AVAudioPCMBuffer?, time: AVAudioTime!) -> Void in
//                print("TEST", buffer, time)
                do {
                    try outputFile.write(from: buffer!)
                } catch {
                    print("[ERROR] writing to file", error.localizedDescription)
                }
            }
            isRecording.onNext(true)
        } catch {
            print("[ERROR] AVAudioFile file", error)
        }
    }
}
