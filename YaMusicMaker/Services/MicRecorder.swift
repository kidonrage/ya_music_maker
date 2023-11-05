//
//  MicRecorder.swift
//  YaMusicMaker
//
//  Created by Vlad Eliseev on 05.11.2023.
//

import AVFoundation
import RxSwift

final class MicRecorder: NSObject, AVAudioRecorderDelegate {
    
    let isRecording = BehaviorSubject<Bool>(value: false)
    let isRecordingAllowed = BehaviorSubject<Bool>(value: false)
    let recordedToFile = PublishSubject<URL>()
    
    private var recordingSession: AVAudioSession
    private var recorder: AVAudioRecorder?
    
    override init() {
        self.recordingSession = AVAudioSession.sharedInstance()
        super.init()
        
        setupRecordingMic()
    }
    
    func toggleIsRecording(isRecordingAllowed: Bool, isCurrentlyRecording: Bool) {
        guard isRecordingAllowed else {
            openSettings()
            return
        }
        if isCurrentlyRecording {
            // stop
            recorder?.stop()
            recorder = nil
            
            self.isRecording.onNext(false)
        } else {
            // start
            let audioURL = getNewRecordingURL()
//            print(audioURL.absoluteString)
            
            let settings = AudioService.shared.mixer.outputFormat(forBus: 0).settings
            
            do {
                recorder = try AVAudioRecorder(url: audioURL, settings: settings)
                recorder?.delegate = self
                recorder?.record()
                
                self.isRecording.onNext(true)
            } catch {
                print("[ERROR] starting recording", error.localizedDescription)
            }
        }
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        print("[TEST] recording succeeded", flag)
        guard flag else { return }
        let recordedFileUrl = recorder.url
        
        recordedToFile.onNext(recordedFileUrl)
        
//        let sample = Sample(
//            name: "Запись",
//            urlToFile: recordedFileUrl,
//            icon: UIImage(systemName: "music.mic")!
//        )
//        self.newLayerCreated.onNext(AudioRecordingLayerViewModel(sample: sample))
    }
    
    private func setupRecordingMic() {
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
    
    private func getNewRecordingURL() -> URL {
        return FileManager.default.getDocumentsDirectory().appendingPathComponent(UUID().uuidString + ".m4a")
    }
    
    private func openSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}
