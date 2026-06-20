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
    @AppStorage("selectedSalawatForm") private var selectedSalawatForm: SalawatForm = .kurz
    
    @StateObject private var solarManager = LocationAndSolarManager.shared
    
    private var todayRecord: DailyRecord {
        DailyRecord.current(in: modelContext, allRecords: allDailyRecords, date: solarManager.currentTrackingDate)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        if settings.istighfarEnabled {
                            DhikrMainCard(
                                titleAr: "الاستغفار",
                                titleDe: "Ich bitte Allah um Vergebung",
                                transliteration: "Istighfar",
                                count: todayRecord.totalIstighfarCount,
                                goal: settings.istighfarGoal,
                                type: .istighfar
                            )
                        }
                        
                        if settings.salawatEnabled {
                            DhikrMainCard(
                                titleAr: "الصلاة على النبي",
                                titleDe: "O Allah, segne Muhammad",
                                transliteration: "Salawat",
                                count: todayRecord.totalSalawatCount,
                                goal: settings.salawatGoal,
                                type: .salawat
                            )
                        }
                        
                        if settings.subhanAllahEnabled {
                            DhikrMainCard(
                                titleAr: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ سُبْحَانَ اللَّهِ الْعَظِيمِ",
                                titleDe: "Gepriesen sei Allah und Lob sei Ihm, gepriesen sei Allah der Allgewaltige",
                                transliteration: "SubhanAllahi wa bihamdihi SubhanAllahil 'Azim",
                                count: todayRecord.subhanAllahCount,
                                goal: settings.subhanAllahGoal,
                                type: .subhanAllah
                            )
                        }
                        
                        if settings.alhamdulillahEnabled {
                            DhikrMainCard(
                                titleAr: "سُبْحَانَ اللَّهِ وَالْحَمْدُ لِلَّهِ وَلَا إِلَهَ إِلَّا اللَّهُ وَاللَّهُ أَكْبَرُ",
                                titleDe: "Gepriesen sei Allah, alles Lob gebührt Allah, es gibt keinen Gott außer Allah, Allah ist am größten",
                                transliteration: "Subhanallah, walhamdulillah, wa la ilaha illallah, wallahu akbar",
                                count: todayRecord.alhamdulillahCount,
                                goal: settings.alhamdulillahGoal,
                                type: .alhamdulillah
                            )
                        }
                        
                        if settings.allahuAkbarEnabled {
                            DhikrMainCard(
                                titleAr: "لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ",
                                titleDe: "Es gibt keine Macht noch Kraft außer durch Allah",
                                transliteration: "La hawla wa la quwwata illa billah",
                                count: todayRecord.allahuAkbarCount,
                                goal: settings.allahuAkbarGoal,
                                type: .allahuAkbar
                            )
                        }
                        
                        if settings.laIlahaIllallahEnabled {
                            DhikrMainCard(
                                titleAr: "لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير",
                                titleDe: "Es gibt keinen Gott außer Allah, dem Einzigen, der keinen Teilhaber hat. Ihm gehört die Herrschaft und Ihm gebührt alles Lob, und Er hat Macht über alle Dinge.",
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
        let isRTL = settings.language == "ar"
        NavigationLink(destination: DhikrDetailView(type: type, titleAr: titleAr, titleDe: titleDe, transliteration: transliteration)) {
            HStack {
                VStack(alignment: isRTL ? .trailing : .leading, spacing: 6) {
                    Text(typeTitle)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(isRTL ? .trailing : .leading)
                    
                    if settings.language != "ar" {
                        Text(titleAr)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.islamicGreen)
                            .multilineTextAlignment(isRTL ? .trailing : .leading)
                            .environment(\.layoutDirection, .rightToLeft)
                    }
                }
                .frame(maxWidth: .infinity, alignment: isRTL ? .trailing : .leading)
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(Color.primary.opacity(0.1), lineWidth: 4)
                        .frame(width: 50, height: 50)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(count) / CGFloat(goal))
                        .stroke(Theme.islamicGreen, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int((Double(count)/Double(goal)) * 100))%")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.primary)
                }
                
                Image(systemName: isRTL ? "chevron.left" : "chevron.right")
                    .foregroundColor(.gray)
                    .padding(isRTL ? .trailing : .leading, 8)
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
        let isRTL = settings.language == "ar"
        NavigationLink(destination: DhikrDetailView(customTasbih: custom)) {
            HStack {
                VStack(alignment: isRTL ? .trailing : .leading, spacing: 6) {
                    Text(custom.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(isRTL ? .trailing : .leading)
                    
                    if settings.language != "ar" && !custom.arabic.isEmpty {
                        Text(custom.arabic)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.islamicGreen)
                            .multilineTextAlignment(isRTL ? .trailing : .leading)
                            .environment(\.layoutDirection, .rightToLeft)
                    }
                }
                .frame(maxWidth: .infinity, alignment: isRTL ? .trailing : .leading)
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(Color.primary.opacity(0.1), lineWidth: 4)
                        .frame(width: 50, height: 50)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(count) / CGFloat(custom.goal))
                        .stroke(Theme.islamicGreen, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(custom.goal > 0 ? Int((Double(count)/Double(custom.goal)) * 100) : 0)%")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.primary)
                }
                
                Image(systemName: isRTL ? "chevron.left" : "chevron.right")
                    .foregroundColor(.gray)
                    .padding(isRTL ? .trailing : .leading, 8)
            }
            .padding()
            .background(Theme.cardBackground)
            .cornerRadius(16)
        }
    }
}
