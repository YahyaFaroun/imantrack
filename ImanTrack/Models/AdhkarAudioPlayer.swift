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
    @Published var isPlayingPreview: Bool = false
    @Published var previewingReciter: String? = nil
    @Published var activeItemId: UUID? = nil
    @Published var currentRepetition: Int = 0
    @Published var targetRepetitions: Int = 1
    @Published var progress: Double = 0.0
    @Published var currentTime: TimeInterval = 0.0
    @Published var duration: TimeInterval = 0.0
    
    private var player: AVAudioPlayer?
    private var previewPlayer: AVAudioPlayer?
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
        stopPreview()
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
    
    static let equivalentAudioMap: [String: String] = [
        "evening_1": "quran_ayat_kursi",
        "evening_2": "quran_ikhlas",
        "evening_3": "quran_falaq",
        "evening_4": "quran_nas",
        "evening_7": "morning_7",
        "evening_10": "morning_10",
        "evening_11": "morning_11",
        "evening_12": "morning_12",
        "evening_13": "morning_13",
        "evening_14": "morning_14",
        "evening_15": "morning_15",
        "evening_16": "morning_16",
        "evening_17": "morning_17",
        "evening_19": "morning_19",
        "evening_20": "morning_20",
        "evening_21": "morning_23",
        "evening_22": "morning_24",
        "evening_23": "morning_25",
        "sleep_2": "quran_ayat_kursi",
        "sleep_3": "quran_baqarah_last2",
        "quran_baqarah_last2": "sleep_3",
        "sleep_12": "quran_mulk",
        "quran_mulk": "sleep_12"
    ]
    
    private static func audioUrl(for name: String) -> URL? {
        Bundle.main.url(forResource: name, withExtension: "m4a")
            ?? Bundle.main.url(forResource: name, withExtension: "mp3")
    }
    
    private func playCurrentFile() {
        guard let fileName = currentFileName else { return }
        
        let effectiveFile = fileName
        let equivalent = Self.equivalentAudioMap[effectiveFile] ?? Self.equivalentAudioMap[fileName]
        let reciter = UserDefaults.standard.string(forKey: "adhkarReciter") ?? "iapetus"
        let prefix = (reciter == "duraihim") ? "duraihim_" : ""
        
        let url: URL?
        if !prefix.isEmpty {
            url = Self.audioUrl(for: "\(prefix)\(effectiveFile)")
                ?? (equivalent != nil ? Self.audioUrl(for: "\(prefix)\(equivalent!)") : nil)
                ?? Self.audioUrl(for: "\(prefix)\(fileName)")
                ?? Self.audioUrl(for: effectiveFile)
                ?? (equivalent != nil ? Self.audioUrl(for: equivalent!) : nil)
                ?? Self.audioUrl(for: fileName)
        } else {
            url = Self.audioUrl(for: effectiveFile)
                ?? (equivalent != nil ? Self.audioUrl(for: equivalent!) : nil)
                ?? Self.audioUrl(for: fileName)
                ?? Self.audioUrl(for: "duraihim_\(effectiveFile)")
                ?? (equivalent != nil ? Self.audioUrl(for: "duraihim_\(equivalent!)") : nil)
        }
        
        guard let finalUrl = url else {
            print("Audio file not found for: \(effectiveFile) (reciter: \(reciter))")
            stop()
            return
        }
        
        do {
            #if os(iOS)
            try AVAudioSession.sharedInstance().setActive(true)
            #endif
            player = try AVAudioPlayer(contentsOf: finalUrl)
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
    
    // MARK: - Reciter Preview
    func toggleReciterPreview(reciter: String) {
        if isPlayingPreview && previewingReciter == reciter {
            stopPreview()
            return
        }
        playReciterPreview(reciter: reciter)
    }
    
    func playReciterPreview(reciter: String) {
        stop()
        stopPreview()
        
        let sampleBase: String
        if reciter == "duraihim" {
            sampleBase = "duraihim_morning_14"
        } else {
            sampleBase = "morning_14"
        }
        guard let url = Self.audioUrl(for: sampleBase) else {
            print("Preview audio not found for reciter: \(reciter)")
            return
        }
        
        do {
            #if os(iOS)
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            #endif
            previewPlayer = try AVAudioPlayer(contentsOf: url)
            previewPlayer?.delegate = self
            previewPlayer?.prepareToPlay()
            previewPlayer?.play()
            isPlayingPreview = true
            previewingReciter = reciter
        } catch {
            print("Failed to play reciter preview: \(error)")
            stopPreview()
        }
    }
    
    func stopPreview() {
        previewPlayer?.stop()
        previewPlayer = nil
        isPlayingPreview = false
        previewingReciter = nil
    }
    
    // MARK: - AVAudioPlayerDelegate
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            if player === self.previewPlayer {
                self.stopPreview()
                return
            }
            
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
