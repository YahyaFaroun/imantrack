import SwiftUI
import SwiftData

struct FAQItem: Identifiable {
    var id: String { question }
    let question: String
    let answer: String
}

struct FAQSection: Identifiable {
    var id: String { title }
    let title: String
    let icon: String
    let iconColor: Color
    let items: [FAQItem]
}

struct FAQView: View {
    @Query private var settingsList: [UserSettings]
    @State private var expandedItems: Set<String> = []
    
    private var language: String {
        settingsList.first?.language ?? "de"
    }
    
    private var localizedData: (navTitle: String, bannerTitle: String, bannerDesc: String, sections: [FAQSection]) {
        FAQLanguageData.getData(for: language)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Banner
                VStack(spacing: 12) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(Theme.islamicGreen)
                    
                    Text(localizedData.bannerTitle)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(localizedData.bannerDesc)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                .padding(.top, 16)
                
                // Kategorien mit FAQ-Items
                ForEach(localizedData.sections) { section in
                    VStack(alignment: .leading, spacing: 12) {
                        // Kategorie Header
                        HStack(spacing: 8) {
                            Image(systemName: section.icon)
                                .foregroundColor(section.iconColor)
                                .font(.headline)
                            
                            Text(section.title)
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 4)
                        
                        // Fragen-Liste
                        VStack(spacing: 10) {
                            ForEach(section.items) { item in
                                FAQCardView(
                                    item: item,
                                    isExpanded: expandedItems.contains(item.id),
                                    onToggle: {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                            if expandedItems.contains(item.id) {
                                                expandedItems.remove(item.id)
                                            } else {
                                                expandedItems.insert(item.id)
                                            }
                                        }
                                    }
                                )
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .navigationTitle(localizedData.navTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Eine klickbare FAQ-Karte für jede Frage
struct FAQCardView: View {
    let item: FAQItem
    let isExpanded: Bool
    let onToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                Text(item.question)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .animation(.easeInOut(duration: 0.2), value: isExpanded)
                    .padding(.top, 2)
            }
            
            if isExpanded {
                Text(item.answer)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 12)
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(14)
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
    }
}

// MARK: - Localized FAQ Data Dictionary
struct FAQLanguageData {
    static func getData(for lang: String) -> (navTitle: String, bannerTitle: String, bannerDesc: String, sections: [FAQSection]) {
        switch lang {
        case "en": return getEnglish()
        case "ar": return getArabic()
        case "fr": return getFrench()
        case "es": return getSpanish()
        case "tr": return getTurkish()
        case "ru": return getRussian()
        case "id": return getIndonesian()
        case "ms": return getMalay()
        case "ur": return getUrdu()
        case "bn": return getBengali()
        default: return getGerman()
        }
    }
    
    // GERMAN (de)
    private static func getGerman() -> (String, String, String, [FAQSection]) {
        (
            "FAQ & Hilfe",
            "Häufig gestellte Fragen (FAQ)",
            "Hier findest du Antworten zu den wichtigsten Funktionen und Einstellungen in ImanTrack.",
            [
                FAQSection(title: "Erste Schritte", icon: "sparkles", iconColor: Theme.islamicGreen, items: [
                    FAQItem(question: "Was bezweckt diese App?", answer: "ImanTrack hilft dir, deinen Iman im Alltag zu stärken: Die App dient hauptsächlich dazu, deine Adhkar, deine Tasbih und dein Quran-Lesen zu tracken – damit du jederzeit nachvollziehen kannst, was du an einem Tag, in einer Woche und in einem Monat geleistet hast."),
                    FAQItem(question: "Muss ich mich registrieren?", answer: "Nein, ImanTrack ist kostenlos und funktioniert ohne Account. Deine Daten bleiben lokal auf deinem Gerät gespeichert, solange du die App nicht deinstallierst."),
                    FAQItem(question: "Wie stelle ich meine Ziele ein?", answer: "Unter Einstellungen → Ziele findest du dein Quran- und dein Tasbih-Ziel: Bei Quran legst du dein tägliches Seiten-Ziel fest, bei Tasbih ein Tagesziel pro Dhikr-Kategorie. Adhkar haben kein eigenes Ziel – hier hakst du einfach ab, sobald du sie gelesen hast."),
                    FAQItem(question: "Wie kann ich die Geschwindigkeit anpassen?", answer: "Die Geschwindigkeit für alle Adhkar und Tasbih kannst du generell unter Einstellungen in fünf Stufen anpassen. Zusätzlich kannst du die Geschwindigkeit für jede einzelne Kategorie manuell überschreiben, indem du oben rechts auf das „i\"-Symbol tippst.")
                ]),
                FAQSection(title: "Der Tagesrhythmus", icon: "sunset.fill", iconColor: .orange, items: [
                    FAQItem(question: "Warum beginnt mein Tag nicht um Mitternacht?", answer: "ImanTrack orientiert sich traditionell am Sonnenuntergang (Maghrib) statt an Mitternacht – so wie der islamische Tag beginnt. Dafür nutzt die App deinen groben Standort."),
                    FAQItem(question: "Was passiert, wenn ich den Standortzugriff nicht erlaube – und ändert sich mein Fortschritt, wenn ich ihn später doch erlaube?", answer: "Ohne Standortfreigabe wechselt dein Tag automatisch um Mitternacht. Du kannst den Standortzugriff jederzeit nachträglich in den iOS-Einstellungen aktivieren – bereits erfasste Tage bleiben dabei unverändert, nur der Zeitpunkt des Tageswechsels passt sich ab sofort an.")
                ]),
                FAQSection(title: "Quran-Tracking", icon: "book.fill", iconColor: Theme.islamicGreen, items: [
                    FAQItem(question: "Wie funktioniert das automatische Quran-Tracking?", answer: "Während du im Quran-Bereich der App scrollst, erkennt ImanTrack automatisch, welche Seiten und Verse du liest, und speichert deinen Fortschritt in Echtzeit."),
                    FAQItem(question: "Was bedeutet der Prozentwert bei „Tagesziel\"?", answer: "Er zeigt, wie viel Prozent deines heutigen Lese-Ziels du bereits erreicht hast, basierend auf den heute gelesenen Seiten."),
                    FAQItem(question: "Warum kann ich nicht zwischen den Suren wechseln?", answer: "Bei ImanTrack geht es nicht darum, frei zwischen Suren zu springen, sondern den Quran von Anfang bis Ende zu lesen, um dein persönliches Leseziel („Wird\") zu erreichen.")
                ]),
                FAQSection(title: "Adhkar", icon: "moon.stars.fill", iconColor: .purple, items: [
                    FAQItem(question: "Wie passe ich meine Adhkar an?", answer: "Adhkar ein- und ausschalten kannst du nur innerhalb der jeweiligen Adhkar-Kategorie selbst, oben rechts über das „i\"-Symbol."),
                    FAQItem(question: "Ich habe eine Adhkar-Zeit verpasst – kann ich sie nachholen?", answer: "Ja, aber nur innerhalb eines islamischen Tages, also von Maghrib bis Maghrib."),
                    FAQItem(question: "Warum wechselt die aktive Adhkar-Kategorie automatisch?", answer: "Die Kategorien richten sich nach den Gebetszeiten: Morgen-Adhkar sind bis Dhuhr aktiv, Abend-Adhkar von Dhuhr bis nach Isha, Schlaf-Adhkar in der Nacht."),
                    FAQItem(question: "Wie kann ich die Reihenfolge anpassen?", answer: "Halte eine Adhkar-Box gedrückt und nutze die Pfeile oben links, um sie nach oben oder unten zu verschieben."),
                    FAQItem(question: "Welche Möglichkeiten habe ich, die Adhkar zu tracken?", answer: "Du kannst manuell abhaken, automatisch pro einzelnem Dhikr tracken lassen, oder automatisch mit Übergängen zum jeweils nächsten Dhikr.")
                ]),
                FAQSection(title: "Tasbih", icon: "circle.hexagongrid.fill", iconColor: Theme.islamicGreen, items: [
                    FAQItem(question: "Wie benutze ich den Tasbih-Zähler?", answer: "Tippe im Tasbih-Tab auf den Zähler, um deine Dhikr-Wiederholungen zu erfassen. Bei jedem Tippen spürst du eine kurze Vibration zur Bestätigung."),
                    FAQItem(question: "Was bedeutet die Einstellung unter „Minus\"?", answer: "Über das Minus-Symbol kannst du deinen Zähler nachträglich korrigieren: Entweder ziehst du manuell eine bestimmte Zahl ab (z. B. bei einer Fehleingabe), oder du reduzierst prozentual den zuletzt erfassten Tracking-Zeitraum – praktisch, um Fehler im Nachhinein auszugleichen."),
                    FAQItem(question: "Wie kann ich einen eigenen Tasbih hinzufügen?", answer: "Unter Einstellungen → Tasbih kannst du manuell weitere Tasbih hinzufügen.")
                ]),
                FAQSection(title: "Fajr-Gebet", icon: "alarm.fill", iconColor: .blue, items: [
                    FAQItem(question: "Was bedeutet „frühzeitig gebetet\" in der Statistik?", answer: "„Frühzeitig gebetet\" bedeutet, dass du dein Fajr-Gebet vor Sonnenaufgang verrichtet hast. Betest du erst nach Ablauf der Fajr-Zeit (also nach Sonnenaufgang), wird es als „nach gebetet\" gezählt.")
                ]),
                FAQSection(title: "Statistik", icon: "chart.bar.fill", iconColor: .indigo, items: [
                    FAQItem(question: "Welche Zeiträume kann ich mir in der Statistik ansehen?", answer: "Woche, Monat und Jahr – jeweils mit Vergleich zur vorherigen Periode."),
                    FAQItem(question: "Warum hat sich meine Statistik für eine vergangene Woche verändert, nachdem ich mein Ziel angepasst habe?", answer: "Die Statistik bezieht sich immer auf dein aktuell eingestelltes Ziel, nicht auf das Ziel, das zum jeweiligen Zeitpunkt galt. Deine tatsächlich erzielten Werte (z. B. gelesene Seiten) bleiben davon unberührt."),
                    FAQItem(question: "Was bedeutet die gestrichelte Linie im Diagramm?", answer: "Sie zeigt dein aktuelles Ziel für den gewählten Zeitraum, umgerechnet aus deinem Tagesziel.")
                ])
            ]
        )
    }

    // ENGLISH (en)
    private static func getEnglish() -> (String, String, String, [FAQSection]) {
        (
            "FAQ & Help",
            "Frequently Asked Questions (FAQ)",
            "Here you will find answers to the most important features and settings in ImanTrack.",
            [
                FAQSection(title: "Getting Started", icon: "sparkles", iconColor: Theme.islamicGreen, items: [
                    FAQItem(question: "What is the purpose of this app?", answer: "ImanTrack helps you strengthen your Iman in daily life: The main purpose is to track your Adhkar, Tasbih, and Quran reading so you can monitor your achievements daily, weekly, and monthly."),
                    FAQItem(question: "Do I need to register?", answer: "No, ImanTrack is completely free and works without an account. Your data remains stored locally on your device unless you uninstall the app."),
                    FAQItem(question: "How do I set my goals?", answer: "Under Settings → Goals you can find your Quran and Tasbih goals: For Quran, set your daily page goal; for Tasbih, set a daily target per Dhikr category. Adhkar do not have a numerical target – simply check them off once completed."),
                    FAQItem(question: "How can I adjust the speed?", answer: "You can adjust the speed for all Adhkar and Tasbih generally under Settings in five levels. Additionally, you can override the speed for each category manually by tapping the 'i' icon at the top right.")
                ]),
                FAQSection(title: "Daily Rhythm", icon: "sunset.fill", iconColor: .orange, items: [
                    FAQItem(question: "Why does my day not start at midnight?", answer: "ImanTrack traditionally aligns with sunset (Maghrib) instead of midnight – just as the Islamic day begins. The app uses your location for this calculation."),
                    FAQItem(question: "What happens if I don't allow location access?", answer: "Without location access, your day automatically resets at midnight. You can enable location access anytime in iOS settings – past recorded days remain unchanged.")
                ]),
                FAQSection(title: "Quran Tracking", icon: "book.fill", iconColor: Theme.islamicGreen, items: [
                    FAQItem(question: "How does automatic Quran tracking work?", answer: "While scrolling in the Quran section, ImanTrack automatically detects which pages and verses you read and saves your progress in real time."),
                    FAQItem(question: "What does the percentage for 'Daily Goal' mean?", answer: "It shows the percentage of today's reading goal completed based on the pages read today."),
                    FAQItem(question: "Why can't I switch freely between Surahs?", answer: "ImanTrack is designed to read the Quran sequentially from start to finish to fulfill your personal reading goal ('Wird').")
                ]),
                FAQSection(title: "Adhkar", icon: "moon.stars.fill", iconColor: .purple, items: [
                    FAQItem(question: "How do I customize my Adhkar?", answer: "You can enable or disable individual Adhkar inside each category via the 'i' icon at the top right."),
                    FAQItem(question: "I missed an Adhkar period – can I make it up?", answer: "Yes, but only within the same Islamic day (from Maghrib to Maghrib)."),
                    FAQItem(question: "Why does the active Adhkar category switch automatically?", answer: "Categories follow prayer times: Morning Adhkar are active until Dhuhr, Evening Adhkar from Dhuhr to Isha, Night Adhkar at night."),
                    FAQItem(question: "How can I change the order?", answer: "Press and hold an Adhkar card and use the arrows at the top left to move it up or down."),
                    FAQItem(question: "What tracking options do I have?", answer: "You can check off manually, auto-track per single Dhikr, or auto-track with automatic transitions to the next Dhikr.")
                ]),
                FAQSection(title: "Tasbih", icon: "circle.hexagongrid.fill", iconColor: Theme.islamicGreen, items: [
                    FAQItem(question: "How do I use the Tasbih counter?", answer: "Tap the counter in the Tasbih tab to record your repetitions. A subtle haptic vibration confirms each tap."),
                    FAQItem(question: "What does the setting under 'Minus' mean?", answer: "The minus button lets you correct your count: either manually subtract a number or deduct a percentage of the last tracking period."),
                    FAQItem(question: "How can I add a custom Tasbih?", answer: "Under Settings → Tasbih, you can manually add custom Tasbih categories.")
                ]),
                FAQSection(title: "Fajr Prayer", icon: "alarm.fill", iconColor: .blue, items: [
                    FAQItem(question: "What does 'prayed on time' mean in statistics?", answer: "'Prayed on time' means you performed your Fajr prayer before sunrise. If prayed after sunrise, it is logged as 'prayed late (Qada)'.")
                ]),
                FAQSection(title: "Statistics", icon: "chart.bar.fill", iconColor: .indigo, items: [
                    FAQItem(question: "Which time periods can I view in statistics?", answer: "Week, month, and year – each with a comparison to the previous period."),
                    FAQItem(question: "Why did my past statistics change after adjusting my goal?", answer: "Statistics are always calculated based on your currently set goal. Your actual recorded values remain untouched."),
                    FAQItem(question: "What does the dashed line in the chart mean?", answer: "It represents your current target for the selected period converted from your daily goal.")
                ])
            ]
        )
    }

    // ARABIC (ar)
    private static func getArabic() -> (String, String, String, [FAQSection]) {
        (
            "الأسئلة الشائعة والتعليمات",
            "الأسئلة الشائعة (FAQ)",
            "تجد هنا إجابات لأهم الميزات والإعدادات في تطبيق إيمانتراك.",
            [
                FAQSection(title: "البداية", icon: "sparkles", iconColor: Theme.islamicGreen, items: [
                    FAQItem(question: "ما الهدف من هذا التطبيق؟", answer: "يهدف إيمانتراك إلى تعزيز إيمانك في حياتك اليومية: يتيح لك تتبع أذكارك وتسابيحك وقراءتك للقرآن لتتعرف على إنجازاتك اليومية والأسبوعية والشهرية."),
                    FAQItem(question: "هل أحتاج إلى التسجيل؟", answer: "لا، التطبيق مجاني بالكامل ويعمل بدون حساب. تبقى جميع بياناتك محفوظة محلياً على جهازك."),
                    FAQItem(question: "كيف أضبط أهدافي؟", answer: "من الإعدادات ← الأهداف: حدد هدفك اليومي للقرآن بالصفحات وللتسابيح بكل فئة. الأذكار ليس لها عدد محدد، فقط قم بتحديدها عند الانتهاء."),
                    FAQItem(question: "كيف أضبط السرعة؟", answer: "يمكنك ضبط سرعة التكرار لجميع الأذكار والتسابيح عموماً من الإعدادات بـ 5 مستويات، كما يمكنك تخصيص سرعة كل فئة بالضغط على أيقونة \"i\" في الأعلى.")
                ]),
                FAQSection(title: "الإيقاع اليومي", icon: "sunset.fill", iconColor: .orange, items: [
                    FAQItem(question: "لماذا لا يبدأ يومي عند منتصف الليل؟", answer: "يعتمد إيمانتراك التوقيت الإسلامي التقليدي الذي يبدأ مع غروب الشمس (المغرب)، باستعمال موقعك الجغرافي."),
                    FAQItem(question: "ماذا يحدث إذا لم أسمح بالوصول للموقع؟", answer: "بدون تحديد الموقع، يتغير اليوم تلقائياً عند منتصف الليل. يمكنك تفعيل الموقع لاحقاً دون التأثير على الأيام السابقة.")
                ]),
                FAQSection(title: "تتبع القرآن", icon: "book.fill", iconColor: Theme.islamicGreen, items: [
                    FAQItem(question: "كيف يعمل التتبع التلقائي للقرآن؟", answer: "أثناء التصفح في قسم القرآن، يتعرف التطبيق تلقائياً على الصفحات والآيات القارئة ويحفظ تقدمك فوراً."),
                    FAQItem(question: "ماذا يعني النسبة المئوية لـ \"الهدف اليومي\"؟", answer: "توضح النسبة المئوية التي أنجزتها اليوم بناءً على عدد الصفحات المقروءة."),
                    FAQItem(question: "لماذا لا أستطيع التنقل الحر بين السور؟", answer: "صُمم إيمانتراك لقراءة القرآن بالترتيب من البداية إلى النهاية لتحقيق وردك اليومي.")
                ]),
                FAQSection(title: "الأذكار", icon: "moon.stars.fill", iconColor: .purple, items: [
                    FAQItem(question: "كيف أخصص أذكاري؟", answer: "يمكنك تفعيل أو إيقاف أي ذكر داخل الفئة بالضغط على أيقونة \"i\" في الأعلى."),
                    FAQItem(question: "فاتني وقت الذكر، هل يمكنني قضاؤه؟", answer: "نعم، لكن خلال اليوم الإسلامي نفسه (من المغرب إلى المغرب)."),
                    FAQItem(question: "لماذا تتغير فئة الأذكار تلقائياً؟", answer: "ترتبط الفئات بأوقات الصلاة: أذكار الصباح حتى الظهر، أذكار المساء حتى العشاء، وأذكار النوم ليلاً."),
                    FAQItem(question: "كيف أغير ترتيب الأذكار؟", answer: "اضغط مطولاً على بطاقة الذكر واستخدم الأسهم في الأعلى للتحريك."),
                    FAQItem(question: "ما هي خيارات التتبع المتاحة؟", answer: "يمكنك التأشير يدوياً، التتبع التلقائي لكل ذكر، أو الانتقال التلقائي بين الأذكار.")
                ]),
                FAQSection(title: "التسبيح", icon: "circle.hexagongrid.fill", iconColor: Theme.islamicGreen, items: [
                    FAQItem(question: "كيف أستخدم عداد التسبيح؟", answer: "اضغط على العداد في تبويب التسبيح لتسجيل التكرارات، مع اهتزاز تفاعلي عند كل ضغطة."),
                    FAQItem(question: "ماذا يعني زر \"الناقص\"؟", answer: "يتيح لك تعديل العداد بخصم عدد محدد أو نسبة مئوية من الفترة الأخيرة لتصحيح الأخطاء."),
                    FAQItem(question: "كيف أضيف تسبيحاً خاصاً؟", answer: "يمكنك إضافة تسبيح جديد من الإعدادات ← التسبيح.")
                ]),
                FAQSection(title: "صلاة الفجر", icon: "alarm.fill", iconColor: .blue, items: [
                    FAQItem(question: "ماذا يعني \"صليت في الوقت\" في الإحصائيات؟", answer: "يعني أداء صلاة الفجر قبل الشروق. أما بعد الشروق فتعتبر قضاءً.")
                ]),
                FAQSection(title: "الإحصائيات", icon: "chart.bar.fill", iconColor: .indigo, items: [
                    FAQItem(question: "ما هي الفترات التي يمكنني استعراضها؟", answer: "أسبوعياً، شهرياً، وسنوياً، مع مقارنة بالفترة السابقة."),
                    FAQItem(question: "لماذا تغيرت إحصائيات الأسابيع الماضية بعد تعديل الهدف؟", answer: "تحسب الإحصائيات دائماً بناءً على الهدف الحالي، أما الأرقام الحقيقية لإنجازك فلا تتغير."),
                    FAQItem(question: "ماذا يعني الخط المنقط في الرسم البياني؟", answer: "يمثل هدفك الحالي المترجم للفترة المحددة.")
                ])
            ]
        )
    }

    // FRENCH (fr)
    private static func getFrench() -> (String, String, String, [FAQSection]) {
        (
            "FAQ et Aide",
            "Foire Aux Questions (FAQ)",
            "Vous trouverez ici les réponses aux fonctionnalités et paramètres les plus importants d'ImanTrack.",
            [
                FAQSection(title: "Premiers pas", icon: "sparkles", iconColor: Theme.islamicGreen, items: [
                    FAQItem(question: "Quel est l'objectif de cette application ?", answer: "ImanTrack vous aide à renforcer votre foi au quotidien en suivant vos Adhkar, votre Tasbih et votre lecture du Coran."),
                    FAQItem(question: "Dois-je me créer un compte ?", answer: "Non, ImanTrack est gratuite et fonctionne sans compte. Vos données restent enregistrées localement sur votre appareil."),
                    FAQItem(question: "Comment définir mes objectifs ?", answer: "Allez dans Paramètres → Objectifs pour définir vos objectifs quotidiens de Coran et de Tasbih. Les Adhkar se cochant simplement au fur et à mesure.")
                ]),
                FAQSection(title: "Rythme quotidien", icon: "sunset.fill", iconColor: .orange, items: [
                    FAQItem(question: "Pourquoi ma journée ne commence-t-elle pas à minuit ?", answer: "ImanTrack s'aligne traditionnellement sur le coucher du soleil (Maghrib) pour marquer le début de la journée islamique.")
                ]),
                FAQSection(title: "Suivi du Coran", icon: "book.fill", iconColor: Theme.islamicGreen, items: [
                    FAQItem(question: "Comment fonctionne le suivi automatique ?", answer: "En faisant défiler les pages dans la section Coran, ImanTrack enregistre automatiquement votre progression en temps réel.")
                ]),
                FAQSection(title: "Adhkar & Tasbih", icon: "circle.hexagongrid.fill", iconColor: Theme.islamicGreen, items: [
                    FAQItem(question: "Comment utiliser le compteur de Tasbih ?", answer: "Appuyez sur le compteur dans l'onglet Tasbih. Une légère vibration confirme chaque incrémentation.")
                ]),
                FAQSection(title: "Statistiques", icon: "chart.bar.fill", iconColor: .indigo, items: [
                    FAQItem(question: "Quelles périodes puis-je consulter ?", answer: "Consultez vos statistiques par semaine, mois et année avec des comparaisons par rapport aux périodes précédentes.")
                ])
            ]
        )
    }

    // SPANISH (es)
    private static func getSpanish() -> (String, String, String, [FAQSection]) {
        (
            "Preguntas Frecuentes",
            "Preguntas Frecuentes (FAQ)",
            "Aquí encontrarás respuestas a las funciones y ajustes más importantes de ImanTrack.",
            [
                FAQSection(title: "Primeros pasos", icon: "sparkles", iconColor: Theme.islamicGreen, items: [
                    FAQItem(question: "¿Cuál es el propósito de esta aplicación?", answer: "ImanTrack te ayuda a fortalecer tu fe diaria mediante el seguimiento de tus Adhkar, Tasbih y lectura del Corán."),
                    FAQItem(question: "¿Necesito registrarme?", answer: "No, ImanTrack es gratuita y funciona sin cuenta. Tus datos permanecen guardados localmente en tu dispositivo.")
                ]),
                FAQSection(title: "Ritmo diario", icon: "sunset.fill", iconColor: .orange, items: [
                    FAQItem(question: "¿Por qué mi día no empieza a medianoche?", answer: "ImanTrack sigue el inicio del día islámico al atardecer (Magreb) usando tu ubicación aproximada.")
                ]),
                FAQSection(title: "Seguimiento del Corán", icon: "book.fill", iconColor: Theme.islamicGreen, items: [
                    FAQItem(question: "¿Cómo funciona el seguimiento automático?", answer: "Al desplazarte por la sección del Corán, la aplicación detecta tus páginas leídas en tiempo real.")
                ]),
                FAQSection(title: "Estadísticas", icon: "chart.bar.fill", iconColor: .indigo, items: [
                    FAQItem(question: "¿Qué períodos puedo ver?", answer: "Puedes ver estadísticas semanales, mensuales y anuales comparadas con el período anterior.")
                ])
            ]
        )
    }

    // TURKISH (tr)
    private static func getTurkish() -> (String, String, String, [FAQSection]) {
        (
            "SSS ve Yardım",
            "Sıkça Sorulan Sorular (SSS)",
            "İmanTrack'teki en önemli özellikler ve ayarlar hakkında yanıtları burada bulabilirsiniz.",
            [
                FAQSection(title: "Başlangıç", icon: "sparkles", iconColor: Theme.islamicGreen, items: [
                    FAQItem(question: "Bu uygulamanın amacı nedir?", answer: "ImanTrack, günlük ibadetlerinizi, Zikirlerinizi, Tesbihatınızı ve Kuran okumanızı takip ederek imanınızı güçlendirmenize yardımcı olur."),
                    FAQItem(question: "Kayıt olmam gerekiyor mu?", answer: "Hayır, ImanTrack ücretsizdir ve hesap gerektirmeden çalışır. Verileriniz yalnızca cihazınızda saklanır.")
                ]),
                FAQSection(title: "Günlük Düzen", icon: "sunset.fill", iconColor: .orange, items: [
                    FAQItem(question: "Günün neden gece yarısı başlamıyor?", answer: "İslami gün takvimine uygun olarak ImanTrack'te gün akşam ezanı (Akşam/Mağrib) ile başlar.")
                ]),
                FAQSection(title: "Kuran Takibi", icon: "book.fill", iconColor: Theme.islamicGreen, items: [
                    FAQItem(question: "Otomatik Kuran takibi nasıl çalışır?", answer: "Kuran bölümünde sayfaları okurken uygulama ilerlemenizi otomatik olarak gerçek zamanlı kaydeder.")
                ])
            ]
        )
    }

    // RUSSIAN (ru)
    private static func getRussian() -> (String, String, String, [FAQSection]) {
        (
            "Чаво и Помощь",
            "Часто задаваемые вопросы (FAQ)",
            "Здесь вы найдете ответы на самые важные вопросы о функциях и настройках ImanTrack.",
            [
                FAQSection(title: "Первые шаги", icon: "sparkles", iconColor: Theme.islamicGreen, items: [
                    FAQItem(question: "Какова цель этого приложения?", answer: "ImanTrack помогает укреплять иман каждый день, отслеживая ваши Азкары, Тасбих и чтение Корана."),
                    FAQItem(question: "Нужна ли регистрация?", answer: "Нет, приложение бесплатно и работает без регистрации. Все данные хранятся локально на вашем устройстве.")
                ]),
                FAQSection(title: "Суточный ритм", icon: "sunset.fill", iconColor: .orange, items: [
                    FAQItem(question: "Почему день начинается не в полночь?", answer: "Согласно исламской традиции, день в ImanTrack начинается с захода солнца (Магриб).")
                ])
            ]
        )
    }

    // INDONESIAN (id)
    private static func getIndonesian() -> (String, String, String, [FAQSection]) {
        (
            "FAQ & Bantuan",
            "Pertanyaan Umum (FAQ)",
            "Temukan jawaban atas fitur dan pengaturan penting di ImanTrack.",
            [
                FAQSection(title: "Langkah Awal", icon: "sparkles", iconColor: Theme.islamicGreen, items: [
                    FAQItem(question: "Apa tujuan aplikasi ini?", answer: "ImanTrack membantu memperkuat Iman harian Anda dengan mencatat Adhkar, Tasbih, dan bacaan Al-Qur'an Anda."),
                    FAQItem(question: "Apakah perlu mendaftar?", answer: "Tidak, ImanTrack gratis dan bekerja tanpa akun. Data Anda tersimpan lokal di perangkat Anda.")
                ])
            ]
        )
    }

    // MALAY (ms)
    private static func getMalay() -> (String, String, String, [FAQSection]) {
        (
            "FAQ & Bantuan",
            "Soalan Lazim (FAQ)",
            "Jawapan kepada ciri dan tetapan penting dalam ImanTrack.",
            [
                FAQSection(title: "Permulaan", icon: "sparkles", iconColor: Theme.islamicGreen, items: [
                    FAQItem(question: "Apakah tujuan aplikasi ini?", answer: "ImanTrack membantu memperkasakan Iman anda dengan menjejak Adhkar, Tasbih dan bacaan Al-Quran anda."),
                    FAQItem(question: "Adakah saya perlu mendaftar?", answer: "Tidak, ImanTrack percuma dan berfungsi tanpa akaun. Data anda disimpan secara tempatan pada peranti anda.")
                ])
            ]
        )
    }

    // URDU (ur)
    private static func getUrdu() -> (String, String, String, [FAQSection]) {
        (
            "سوالات و جوابات",
            "عام سوالات (FAQ)",
            "ایمان ٹریک کی اہم خصوصیات اور ترتیبات کے بارے میں جوابات یہاں حاصل کریں۔",
            [
                FAQSection(title: "ابتدائی مراحل", icon: "sparkles", iconColor: Theme.islamicGreen, items: [
                    FAQItem(question: "اس ایپ کا مقصد کیا ہے؟", answer: "ایمان ٹریک آپ کے روزمرہ کے اذکار، تسبیح اور تلاوتِ قرآن کو ٹریک کرکے آپ کے ایمان کو مضبوط بنانے میں مدد کرتا ہے۔"),
                    FAQItem(question: "کیا اکاؤنٹ بنانا ضروری ہے؟", answer: "نہیں، یہ ایپ بالکل مفت ہے اور بغیر کسی اکاؤنٹ کے کام کرتی ہے۔ آپ کا ڈیٹا صرف آپ کے ڈیوائس پر محفوظ رہتا ہے۔")
                ])
            ]
        )
    }

    // BENGALI (bn)
    private static func getBengali() -> (String, String, String, [FAQSection]) {
        (
            "প্রশ্নোত্তর ও সহায়তা",
            "সাধারণ জিজ্ঞাসা (FAQ)",
            "ইমানট্র্যাকের اہم فیچرز اور سیٹنگز کے بارے میں معلومات حاصل کریں۔",
            [
                FAQSection(title: "শুরু করা", icon: "sparkles", iconColor: Theme.islamicGreen, items: [
                    FAQItem(question: "এই অ্যাপের উদ্দেশ্য কী?", answer: "ইমানট্র্যাক আপনার প্রতিদিনের জিকির, তাসবিহ এবং কুরআন তেলাওয়াত ট্র্যাক করে আপনার ইমান মজবুত করতে সাহায্য করে।"),
                    FAQItem(question: "রেজিস্ট্রেশন করা কি আবশ্যক?", answer: "না، ইমানট্র্যাক সম্পূর্ণ বিনামূল্যে এবং কোন অ্যাকাউন্ট ছাড়াই কাজ করে।")
                ])
            ]
        )
    }
}
