import Foundation
import AVFoundation
import Combine
#if os(iOS)
import UIKit
#endif

@MainActor
final class AdhkarAudioPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    static let shared = AdhkarAudioPlayer()
    
    @Published var isPlaying: Bool = false
    @Published var activeItemId: UUID? = nil
    @Published var currentRepetition: Int = 0
    @Published var targetRepetitions: Int = 1
    @Published var progress: Double = 0.0
    @Published var currentTime: TimeInterval = 0.0
    @Published var duration: TimeInterval = 0.0
    
    private var player: AVAudioPlayer?
    private var progressTimer: Timer?
    private var onRepetitionCompleted: ((Int) -> Void)?
    private var onFinished: (() -> Void)?
    
    private var currentFileName: String?
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        } catch {
            print("Failed to set audio session category: \(error)")
        }
        #endif
    }
    
    func play(
        item: AdhkarItem,
        startRepetition: Int = 0,
        targetRepetitions: Int? = nil,
        onRepetitionCompleted: @escaping (Int) -> Void,
        onFinished: @escaping () -> Void
    ) {
        guard let fileName = item.audioFileName, !fileName.isEmpty else {
            stop()
            return
        }
        
        self.currentFileName = fileName
        self.activeItemId = item.id
        self.currentRepetition = startRepetition
        self.targetRepetitions = targetRepetitions ?? item.count
        self.onRepetitionCompleted = onRepetitionCompleted
        self.onFinished = onFinished
        
        playCurrentFile()
    }
    
    private func playCurrentFile() {
        guard let fileName = currentFileName else { return }
        
        let ghamdiResource = "ghamdi_\(fileName)"
        let duraihimResource = "duraihim_\(fileName)"
        
        guard let url = Bundle.main.url(forResource: ghamdiResource, withExtension: "m4a")
            ?? Bundle.main.url(forResource: duraihimResource, withExtension: "m4a")
            ?? Bundle.main.url(forResource: fileName, withExtension: "m4a") else {
            print("Audio file not found for: \(fileName)")
            stop()
            return
        }
        
        do {
            #if os(iOS)
            try AVAudioSession.sharedInstance().setActive(true)
            #endif
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.prepareToPlay()
            player?.play()
            
            isPlaying = true
            duration = player?.duration ?? 0.0
            currentTime = 0.0
            progress = 0.0
            
            startProgressTimer()
            
            #if os(iOS)
            UIApplication.shared.isIdleTimerDisabled = true
            #endif
        } catch {
            print("Failed to start audio playback: \(error)")
            stop()
        }
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
        stopProgressTimer()
    }
    
    func resume() {
        guard player != nil else { return }
        player?.play()
        isPlaying = true
        startProgressTimer()
    }
    
    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        activeItemId = nil
        currentRepetition = 0
        progress = 0.0
        currentTime = 0.0
        duration = 0.0
        stopProgressTimer()
        onRepetitionCompleted = nil
        onFinished = nil
        currentFileName = nil
        
        #if os(iOS)
        UIApplication.shared.isIdleTimerDisabled = false
        #endif
    }
    
    // MARK: - AVAudioPlayerDelegate
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            guard flag else {
                self.stop()
                return
            }
            
            self.currentRepetition += 1
            self.onRepetitionCompleted?(self.currentRepetition)
            
            if self.currentRepetition < self.targetRepetitions {
                self.playCurrentFile()
            } else {
                let finishHandler = self.onFinished
                self.stop()
                finishHandler?()
            }
        }
    }
    
    private func startProgressTimer() {
        stopProgressTimer()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.player, player.isPlaying else { return }
            self.currentTime = player.currentTime
            let dur = player.duration
            if dur > 0 {
                self.progress = player.currentTime / dur
            }
        }
    }
    
    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
}
