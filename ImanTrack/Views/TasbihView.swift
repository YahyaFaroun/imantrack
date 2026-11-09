import SwiftUI
import SwiftData

struct TasbihView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allSettings: [UserSettings]
    @Query private var allDailyRecords: [DailyRecord]
    @Query(sort: \CustomTasbih.createdAt, order: .forward) private var customTasbihs: [CustomTasbih]
    
    private var settings: UserSettings {
        allSettings.first ?? UserSettings()
    }
    
    @AppStorage("selectedIstighfarForm") private var selectedIstighfarForm: IstighfarForm = .kurz
    @AppStorage("selectedSalawatForm") private var selectedSalawatForm: SalawatForm = .waSallim
    
    @StateObject private var solarManager = LocationAndSolarManager.shared
    
    private var todayRecord: DailyRecord {
        DailyRecord.current(in: modelContext, allRecords: allDailyRecords, date: solarManager.currentTrackingDate)
    }
    
    var body: some View {
        let (tsState, tsT0) = QuranPerf.shared.begin("2f_TasbihView_body")
        defer {
            QuranPerf.shared.end("2f_TasbihView_body", state: tsState, t0: tsT0)
        }
        return NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        if settings.istighfarEnabled {
                            DhikrMainCard(
                                titleAr: "الاستغفار",
                                titleDe: L10n.tr("tasbih_istighfar", settings.language),
                                transliteration: "Istighfar",
                                count: todayRecord.totalIstighfarCount,
                                goal: settings.istighfarGoal,
                                type: .istighfar
                            )
                        }
                        
                        if settings.salawatEnabled {
                            let isFridaySalawat = settings.salawatFridayGoalEnabled && settings.isIslamicFriday(for: todayRecord.date)
                            DhikrMainCard(
                                titleAr: "الصلاة على النبي",
                                titleDe: L10n.tr("tasbih_salawat", settings.language),
                                transliteration: "Salawat",
                                count: todayRecord.totalSalawatCount,
                                goal: settings.effectiveSalawatGoal(for: todayRecord.date),
                                type: .salawat,
                                isFridayGoal: isFridaySalawat
                            )
                        }
                        
                        if settings.subhanAllahEnabled {
                            DhikrMainCard(
                                titleAr: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ سُبْحَانَ اللَّهِ الْعَظِيمِ",
                                titleDe: L10n.tr("tasbih_subhanallah", settings.language),
                                transliteration: "SubhanAllahi wa bihamdihi SubhanAllahil 'Azim",
                                count: todayRecord.subhanAllahCount,
                                goal: settings.subhanAllahGoal,
                                type: .subhanAllah
                            )
                        }
                        
                        if settings.alhamdulillahEnabled {
                            DhikrMainCard(
                                titleAr: "سُبْحَانَ اللَّهِ وَالْحَمْدُ لِلَّهِ وَلَا إِلَهَ إِلَّا اللَّهُ وَاللَّهُ أَكْبَرُ",
                                titleDe: L10n.tr("tasbih_alhamdulillah", settings.language),
                                transliteration: "Subhanallah, walhamdulillah, wa la ilaha illallah, wallahu akbar",
                                count: todayRecord.alhamdulillahCount,
                                goal: settings.alhamdulillahGoal,
                                type: .alhamdulillah
                            )
                        }
                        
                        if settings.allahuAkbarEnabled {
                            DhikrMainCard(
                                titleAr: "لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ",
                                titleDe: L10n.tr("tasbih_lahawla", settings.language),
                                transliteration: "La hawla wa la quwwata illa billah",
                                count: todayRecord.allahuAkbarCount,
                                goal: settings.allahuAkbarGoal,
                                type: .allahuAkbar
                            )
                        }
                        
                        if settings.laIlahaIllallahEnabled {
                            DhikrMainCard(
                                titleAr: "لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ",
                                titleDe: L10n.tr("tasbih_lailahaillallah", settings.language),
                                transliteration: "La ilaha illallah wahdahu la sharika lah, lahul mulk wa lahul hamd wa huwa 'ala kulli shayin qadeer.",
                                count: todayRecord.laIlahaIllallahCount,
                                goal: settings.laIlahaIllallahGoal,
                                type: .laIlahaIllallah
                            )
                        }
                        

                        
                        ForEach(customTasbihs) { custom in
                            if custom.isEnabled {
                                DhikrMainCardCustom(
                                    custom: custom,
                                    count: todayRecord.getCustomTasbihCount(for: custom.id)
                                )
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(L10n.tr("tab_tasbih", settings.language))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

typealias DhikrType = TasbihCategory


struct DhikrMainCard: View {
    @Query private var allSettings: [UserSettings]
    
    let titleAr: String
    let titleDe: String
    let transliteration: String
    let count: Int
    let goal: Int
    let type: DhikrType
    var isFridayGoal: Bool = false
    
    private var settings: UserSettings {
        allSettings.first ?? UserSettings()
    }
    
    private var typeTitle: String {
        switch type {
        case .istighfar: return L10n.tr("tasbih_type_istighfar", settings.language)
        case .salawat: return L10n.tr("tasbih_type_salawat", settings.language)
        case .subhanAllah: return L10n.tr("tasbih_type_subhanallah", settings.language)
        case .alhamdulillah: return L10n.tr("tasbih_type_alhamdulillah", settings.language)
        case .allahuAkbar: return L10n.tr("tasbih_type_lahawla", settings.language)
        case .laIlahaIllallah: return L10n.tr("tasbih_type_lailahaillallah", settings.language)
        }
    }
    
    var body: some View {
        NavigationLink(destination: DhikrDetailView(type: type, titleAr: titleAr, titleDe: titleDe, transliteration: transliteration)) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text(typeTitle)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        
                        if isFridayGoal {
                            Text(L10n.tr("salawat_friday_goal", settings.language))
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(Theme.islamicGreen)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Theme.islamicGreen.opacity(0.12))
                                .cornerRadius(6)
                        }
                    }
                    
                    if settings.language != "ar" {
                        Text(titleAr)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.islamicGreen)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                ZStack {
                    Circle()
                        .stroke(Color.primary.opacity(0.1), lineWidth: 4)
                        .frame(width: 50, height: 50)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(count) / CGFloat(goal))
                        .stroke(count >= goal ? Theme.islamicGreen : Theme.islamicGreen.opacity(0.55), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int((Double(count)/Double(goal)) * 100))%")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.primary)
                }
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .padding(.leading, 4)
            }
            .padding()
            .background(Theme.cardBackground)
            .cornerRadius(16)
        }
    }
}

struct DhikrMainCardCustom: View {
    @Query private var allSettings: [UserSettings]
    let custom: CustomTasbih
    let count: Int
    
    private var settings: UserSettings {
        allSettings.first ?? UserSettings()
    }
    
    var body: some View {
        NavigationLink(destination: DhikrDetailView(customTasbih: custom)) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(custom.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    if settings.language != "ar" && !custom.arabic.isEmpty {
                        Text(custom.arabic)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.islamicGreen)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                ZStack {
                    Circle()
                        .stroke(Color.primary.opacity(0.1), lineWidth: 4)
                        .frame(width: 50, height: 50)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(count) / CGFloat(custom.goal))
                        .stroke(count >= custom.goal ? Theme.islamicGreen : Theme.islamicGreen.opacity(0.55), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(custom.goal > 0 ? Int((Double(count)/Double(custom.goal)) * 100) : 0)%")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.primary)
                }
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .padding(.leading, 4)
            }
            .padding()
            .background(Theme.cardBackground)
            .cornerRadius(16)
        }
    }
}

struct SurahBaqarahTasbihCard: View {
    let progress: Int
    let goal: Int
    let language: String
    
    var body: some View {
        NavigationLink(destination: AlBaqarahReaderView()) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.tr("surah_baqarah", language))
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text("سورة البقرة")
                        .font(.subheadline)
                        .foregroundColor(Theme.islamicGreen)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                ZStack {
                    Circle()
                        .stroke(Color.primary.opacity(0.1), lineWidth: 4)
                        .frame(width: 50, height: 50)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(progress) / 100.0)
                        .stroke(progress >= goal ? Theme.islamicGreen : Theme.islamicGreen.opacity(0.55), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(progress)%")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.primary)
                }
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .padding(.leading, 8)
            }
            .padding()
            .background(Theme.cardBackground)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
