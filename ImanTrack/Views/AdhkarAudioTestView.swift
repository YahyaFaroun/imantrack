import SwiftUI
import AVFoundation
import Combine

struct AudioTestItem: Identifiable, Equatable {
    let id: String // Stabile ID (z. B. Dateiname wie "morning_1")
    let title: String
    let subtitle: String
    let fileName: String
    let isQuran: Bool
    let defaultReps: Int
    let arabicSnippet: String
    let category: String
    
    static func == (lhs: AudioTestItem, rhs: AudioTestItem) -> Bool {
        lhs.id == rhs.id
    }
}

@MainActor
final class TestAudioPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying: Bool = false
    @Published var currentItemId: String? = nil
    @Published var currentRep: Int = 1
    @Published var targetReps: Int = 1
    @Published var currentTime: TimeInterval = 0.0
    @Published var duration: TimeInterval = 0.0
    @Published var selectedReciter: String = UserDefaults.standard.string(forKey: "adhkarReciter") ?? "iapetus"
    
    private var player: AVAudioPlayer?
    private var timer: Timer?
    private var activeItem: AudioTestItem?
    
    override init() {
        super.init()
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("TestAudioPlayer session error: \(error)")
        }
        #endif
    }
    
    func play(item: AudioTestItem, repeatCount: Int = 1) {
        // Wenn dasselbe Item angetippt wird: Pause / Weiter
        if currentItemId == item.id && player != nil {
            if isPlaying {
                pause()
            } else {
                resume()
            }
            return
        }
        
        // Anderes Item angetippt: Altes Audio stoppen und neues starten
        stop()
        self.activeItem = item
        self.currentItemId = item.id
        self.currentRep = 1
        self.targetReps = max(1, repeatCount)
        
        playItemFile(item: item)
    }
    
    private func playItemFile(item: AudioTestItem) {
        let baseName = item.fileName.replacingOccurrences(of: ".m4a", with: "")
        let isDuraihim = (selectedReciter == "duraihim")
        
        let url: URL?
        if isDuraihim {
            url = Bundle.main.url(forResource: "duraihim_\(baseName)", withExtension: "m4a")
                ?? Bundle.main.url(forResource: baseName, withExtension: "m4a")
        } else {
            url = Bundle.main.url(forResource: baseName, withExtension: "m4a")
                ?? Bundle.main.url(forResource: "duraihim_\(baseName)", withExtension: "m4a")
        }
        
        guard let finalUrl = url else {
            print("TestAudioPlayer: Datei nicht gefunden: \(item.fileName)")
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
            startTimer()
        } catch {
            print("TestAudioPlayer play error: \(error)")
            stop()
        }
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
        stopTimer()
    }
    
    func resume() {
        guard let p = player else { return }
        p.play()
        isPlaying = true
        startTimer()
    }
    
    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        currentItemId = nil
        currentTime = 0.0
        duration = 0.0
        stopTimer()
    }
    
    func seek(to time: TimeInterval) {
        player?.currentTime = time
        currentTime = time
    }
    
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, let p = self.player, p.isPlaying else { return }
                self.currentTime = p.currentTime
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            guard flag, let item = self.activeItem else {
                self.stop()
                return
            }
            
            if self.currentRep < self.targetReps {
                self.currentRep += 1
                self.playItemFile(item: item)
            } else {
                self.stop()
            }
        }
    }
}

struct AdhkarAudioTestView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var player = TestAudioPlayer()
    
    @State private var selectedFilter: String = "Alle"
    @State private var enableAutoRepetition: Bool = false
    @State private var searchText: String = ""
    
    // Stabile Liste (wird einmalig berechnet)
    private let allItems: [AudioTestItem] = {
        var result: [AudioTestItem] = []
        
        // 1. Morgen (25 Items)
        for (i, item) in morgenAdhkar.enumerated() {
            let fn = "morning_\(i + 1)"
            let isQuran = i < 4 // 1: Ayat al-Kursi, 2-4: 3 Schutzsuren
            let snippet = item.arabic.components(separatedBy: " ").prefix(8).joined(separator: " ")
            let title = extractTitleStatic(item: item, fallback: "Morgen #\(i + 1)")
            result.append(AudioTestItem(
                id: fn,
                title: title,
                subtitle: "Morgen #\(i + 1) (\(fn).m4a)",
                fileName: fn,
                isQuran: isQuran,
                defaultReps: item.count,
                arabicSnippet: snippet,
                category: "Morgen"
            ))
        }
        
        // 2. Abend (23 Items)
        for (i, item) in abendAdhkar.enumerated() {
            let fn = "evening_\(i + 1)"
            let isQuran = i < 4 // 1: Ayat al-Kursi, 2-4: 3 Schutzsuren
            let snippet = item.arabic.components(separatedBy: " ").prefix(8).joined(separator: " ")
            let title = extractTitleStatic(item: item, fallback: "Abend #\(i + 1)")
            result.append(AudioTestItem(
                id: fn,
                title: title,
                subtitle: "Abend #\(i + 1) (\(fn).m4a)",
                fileName: fn,
                isQuran: isQuran,
                defaultReps: item.count,
                arabicSnippet: snippet,
                category: "Abend"
            ))
        }
        
        // 3. Schlaf (13 Items)
        for (i, item) in schlafAdhkar.enumerated() {
            let fn = "sleep_\(i + 1)"
            let isQuran = (i == 0 || i == 1 || i == 2 || i == 11) // Schutzsuren, Kursi, Baqarah, Mulk
            let snippet = item.arabic.components(separatedBy: " ").prefix(8).joined(separator: " ")
            let title = extractTitleStatic(item: item, fallback: "Schlaf #\(i + 1)")
            result.append(AudioTestItem(
                id: fn,
                title: title,
                subtitle: "Schlaf #\(i + 1) (\(fn).m4a)",
                fileName: fn,
                isQuran: isQuran,
                defaultReps: item.count,
                arabicSnippet: snippet,
                category: "Schlaf"
            ))
        }
        
        // 4. Schlaf-Tasbih 3 Einzelfiles (SubhanAllah, Alhamdulillah, Allahu Akbar)
        result.append(AudioTestItem(
            id: "sleep_8_subhanallah",
            title: "Schlaf-Tasbih: SubhanAllah (33×)",
            subtitle: "Schlaf #8 Teil A (sleep_8_subhanallah.m4a)",
            fileName: "sleep_8_subhanallah",
            isQuran: false,
            defaultReps: 33,
            arabicSnippet: "سُبْحَانَ اللّٰهْ",
            category: "Schlaf"
        ))
        result.append(AudioTestItem(
            id: "sleep_8_alhamdulillah",
            title: "Schlaf-Tasbih: Alhamdulillah (33×)",
            subtitle: "Schlaf #8 Teil B (sleep_8_alhamdulillah.m4a)",
            fileName: "sleep_8_alhamdulillah",
            isQuran: false,
            defaultReps: 33,
            arabicSnippet: "الْحَمْدُ لِلَّهِ",
            category: "Schlaf"
        ))
        result.append(AudioTestItem(
            id: "sleep_8_allahuakbar",
            title: "Schlaf-Tasbih: Allahu Akbar (34×)",
            subtitle: "Schlaf #8 Teil C (sleep_8_allahuakbar.m4a)",
            fileName: "sleep_8_allahuakbar",
            isQuran: false,
            defaultReps: 34,
            arabicSnippet: "اللَّهُ أَكْبَرُ",
            category: "Schlaf"
        ))
        
        return result
    }()
    
    private static func extractTitleStatic(item: AdhkarItem, fallback: String) -> String {
        let g = item.german
        if g.contains("Ayat al-Kursi") || item.arabic.contains("الْحَيُّ الْقَيُّومُ") { return "Ayat al-Kursi (2:255)" }
        if g.contains("Al-Ikhlas") || item.arabic.contains("قُلْ هُوَ اللَّهُ أَحَدٌ") { return "Sure Al-Ikhlas (112)" }
        if g.contains("Al-Falaq") || item.arabic.contains("قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ") { return "Sure Al-Falaq (113)" }
        if g.contains("An-Nas") || item.arabic.contains("قُلْ أَعُوذُ بِرَبِّ النَّاسِ") { return "Sure An-Nas (114)" }
        if g.contains("Al-Mulk") || item.arabic.contains("الْمُلْكِ") { return "Sure Al-Mulk (vollständig)" }
        if g.contains("Al-Baqarah") || item.arabic.contains("آمَنَ الرَّسُولُ") { return "Al-Baqarah (285–286)" }
        if g.contains("Sayyidul") || g.contains("Herr aller Bittgebete") || (item.arabic.contains("اللَّهُمَّ أَنْتَ رَبِّي") && item.arabic.contains("خَلَقْتَنِي")) { return "Sayyidul Istighfar" }
        if item.transliteration.count > 3 {
            let words = item.transliteration.components(separatedBy: " ")
            return words.prefix(5).joined(separator: " ")
        }
        let gWords = g.components(separatedBy: " ")
        return gWords.prefix(5).joined(separator: " ")
    }
    
    private var filteredItems: [AudioTestItem] {
        var list = allItems
        
        switch selectedFilter {
        case "Morgen": list = list.filter { $0.category == "Morgen" }
        case "Abend": list = list.filter { $0.category == "Abend" }
        case "Schlaf": list = list.filter { $0.category == "Schlaf" }
        case "Quran": list = list.filter { $0.isQuran }
        case "Iapetus": list = list.filter { !$0.isQuran }
        default: break
        }
        
        if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            let q = searchText.lowercased()
            list = list.filter {
                $0.title.lowercased().contains(q) ||
                $0.subtitle.lowercased().contains(q) ||
                $0.arabicSnippet.contains(q)
            }
        }
        
        return list
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Info Card
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "headphones")
                        .foregroundColor(Theme.islamicGreen)
                    Text("Adhkar Audio-Qualitätsprüfung")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Text("\(allItems.count) Aufnahmen")
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.islamicGreen.opacity(0.15))
                        .foregroundColor(Theme.islamicGreen)
                        .cornerRadius(8)
                }
                
                Text("Tippe auf Play, um ein Dua anzuhören. Ein erneuter Tipp pausiert die Wiedergabe. Tippe auf ein anderes Dua, um sofort dorthin zu wechseln.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Toggle(isOn: $enableAutoRepetition) {
                    Text("Wiederholungslogik aktivieren (z. B. 3× / 33×)")
                        .font(.caption.bold())
                        .foregroundColor(.primary)
                }
                .tint(Theme.islamicGreen)
                .padding(.top, 4)
                
                Divider()
                    .padding(.vertical, 4)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Stimme / Rezitator:")
                        .font(.caption2.bold())
                        .foregroundColor(.secondary)
                    
                    Picker("Stimme", selection: $player.selectedReciter) {
                        Text("Iapetus (Standard)").tag("iapetus")
                        Text("Hamad Al-Duraihim").tag("duraihim")
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: player.selectedReciter) { _, newReciter in
                        UserDefaults.standard.set(newReciter, forKey: "adhkarReciter")
                        if player.isPlaying {
                            player.stop()
                        }
                    }
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Filter Segments
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterPill(title: "Alle (\(allItems.count))", isSelected: selectedFilter == "Alle") {
                        selectedFilter = "Alle"
                    }
                    FilterPill(title: "🌅 Morgen (25)", isSelected: selectedFilter == "Morgen") {
                        selectedFilter = "Morgen"
                    }
                    FilterPill(title: "🌇 Abend (23)", isSelected: selectedFilter == "Abend") {
                        selectedFilter = "Abend"
                    }
                    FilterPill(title: "🌙 Schlaf (16)", isSelected: selectedFilter == "Schlaf") {
                        selectedFilter = "Schlaf"
                    }
                    FilterPill(title: "📖 Quran", isSelected: selectedFilter == "Quran") {
                        selectedFilter = "Quran"
                    }
                    FilterPill(title: "🎙️ Iapetus", isSelected: selectedFilter == "Iapetus") {
                        selectedFilter = "Iapetus"
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            
            // List of items
            List {
                ForEach(filteredItems) { item in
                    AudioTestRow(
                        item: item,
                        isPlaying: player.currentItemId == item.id && player.isPlaying,
                        isCurrent: player.currentItemId == item.id,
                        currentRep: player.currentRep,
                        targetReps: enableAutoRepetition ? item.defaultReps : 1,
                        currentTime: player.currentTime,
                        duration: player.duration,
                        onPlayTapped: {
                            let reps = enableAutoRepetition ? item.defaultReps : 1
                            player.play(item: item, repeatCount: reps)
                        },
                        onStopTapped: {
                            player.stop()
                        },
                        onSeek: { time in
                            player.seek(to: time)
                        }
                    )
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .searchable(text: $searchText, prompt: "Adhkar suchen...")
        }
        .navigationTitle("Audio Test Center")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Fertig") {
                    player.stop()
                    dismiss()
                }
                .font(.body.bold())
                .foregroundColor(Theme.islamicGreen)
            }
        }
        .onDisappear {
            player.stop()
        }
    }
}

private struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Theme.islamicGreen : Color(UIColor.tertiarySystemGroupedBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

struct AudioTestRow: View {
    let item: AudioTestItem
    let isPlaying: Bool
    let isCurrent: Bool
    let currentRep: Int
    let targetReps: Int
    let currentTime: TimeInterval
    let duration: TimeInterval
    let onPlayTapped: () -> Void
    let onStopTapped: () -> Void
    let onSeek: (TimeInterval) -> Void
    
    private var progress: Double {
        guard isCurrent, duration > 0 else { return 0.0 }
        return min(1.0, max(0.0, currentTime / duration))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                // Play / Pause Button
                Button(action: onPlayTapped) {
                    ZStack {
                        Circle()
                            .fill(isCurrent ? Theme.islamicGreen : Color(UIColor.systemGray5))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.headline)
                            .foregroundColor(isCurrent ? .white : Theme.islamicGreen)
                    }
                }
                .buttonStyle(.plain)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(item.title)
                            .font(.subheadline.bold())
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Badge
                        if item.isQuran {
                            Text("QURAN")
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.15))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        } else {
                            Text("IAPETUS")
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Theme.islamicGreen.opacity(0.15))
                                .foregroundColor(Theme.islamicGreen)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(item.subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(item.arabicSnippet)
                        .font(.custom("KFGQPCHAFSUthmanicScript-Regula", size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // Expliziter Stop Button wenn aktiv
                if isCurrent {
                    Button(action: onStopTapped) {
                        Image(systemName: "stop.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color(UIColor.systemGray3))
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 4)
                }
            }
            
            // Progress Bar & Info if active
            if isCurrent {
                VStack(spacing: 4) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(UIColor.systemGray4))
                                .frame(height: 6)
                            
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Theme.islamicGreen)
                                .frame(width: geo.size.width * CGFloat(progress), height: 6)
                        }
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { val in
                                    let pct = max(0.0, min(1.0, val.location.x / geo.size.width))
                                    onSeek(duration * Double(pct))
                                }
                        )
                    }
                    .frame(height: 6)
                    .padding(.vertical, 4)
                    
                    HStack {
                        Text(formatTime(currentTime))
                            .font(.caption2.monospacedDigit())
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if targetReps > 1 {
                            Text("Wiederholung \(currentRep) von \(targetReps)")
                                .font(.caption2.bold())
                                .foregroundColor(Theme.islamicGreen)
                            Spacer()
                        }
                        
                        Text(formatTime(duration))
                            .font(.caption2.monospacedDigit())
                            .foregroundColor(.secondary)
                    }
                }
                .transition(.opacity)
            }
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCurrent ? Theme.islamicGreen.opacity(0.4) : Color.clear, lineWidth: 1.5)
        )
    }
    
    private func formatTime(_ sec: TimeInterval) -> String {
        let m = Int(sec) / 60
        let s = Int(sec) % 60
        return String(format: "%02d:%02d", m, s)
    }
}
