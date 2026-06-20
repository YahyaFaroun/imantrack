import SwiftUI

struct Theme {
    static var islamicGreen: Color {
        return Color(red: 46 / 255, green: 125 / 255, blue: 50 / 255) // green
    }
    
    static var background: Color {
        Color(uiColor: UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark
                ? .black
                : UIColor(red: 245 / 255, green: 247 / 255, blue: 245 / 255, alpha: 1.0)
        })
    }
    
    static var darkBackground: Color {
        Color.black
    }
    
    static var cardBackground: Color {
        Color(uiColor: UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 28 / 255, green: 28 / 255, blue: 30 / 255, alpha: 1.0)
                : .white
        })
    }
    
    static var accent: Color {
        return islamicGreen
    }
    
    static func uthmaniFont(size: CGFloat) -> Font {
        if UIFont(name: "kfgqpchafsuthmanicscript-Reg", size: size) != nil {
            return .custom("kfgqpchafsuthmanicscript-Reg", size: size)
        }
        if UIFont(name: "KFGQPCHAFSUthmanicScript-Regula", size: size) != nil {
            return .custom("KFGQPCHAFSUthmanicScript-Regula", size: size)
        }
        return .custom("Geeza Pro", size: size)
    }
    
    static func uthmaniUIFont(size: CGFloat) -> UIFont {
        if let font = UIFont(name: "kfgqpchafsuthmanicscript-Reg", size: size) {
            return font
        }
        if let font = UIFont(name: "KFGQPCHAFSUthmanicScript-Regula", size: size) {
            return font
        }
        return UIFont(name: "GeezaPro", size: size) ?? UIFont.systemFont(ofSize: size)
    }
    
    static func uthmaniFontForced(size: CGFloat) -> Font {
        if UIFont(name: "kfgqpchafsuthmanicscript-Reg", size: size) != nil {
            return .custom("kfgqpchafsuthmanicscript-Reg", size: size)
        }
        if UIFont(name: "KFGQPCHAFSUthmanicScript-Regula", size: size) != nil {
            return .custom("KFGQPCHAFSUthmanicScript-Regula", size: size)
        }
        return .custom("Geeza Pro", size: size)
    }
    
    static func surahNameFont(size: CGFloat) -> Font {
        if UIFont(name: "surah-name-v2", size: size) != nil {
            return .custom("surah-name-v2", size: size)
        } else if UIFont(name: "QCF_SurahHeader_COLOR", size: size) != nil {
            return .custom("QCF_SurahHeader_COLOR", size: size)
        }
        return .system(size: size)
    }
    
    static func getQuranBackgroundColor(for theme: String, systemColorScheme: ColorScheme) -> Color {
        switch theme {
        case "light":
            return .white
        case "sepia":
            return Color(red: 244/255, green: 236/255, blue: 216/255)
        case "dark":
            return .black
        default: // system
            return systemColorScheme == .dark ? .black : Color(red: 245 / 255, green: 247 / 255, blue: 245 / 255)
        }
    }

    static func getQuranTextColor(for theme: String, systemColorScheme: ColorScheme) -> Color {
        switch theme {
        case "light":
            return .black
        case "sepia":
            return Color(red: 44/255, green: 34/255, blue: 24/255) // dunkelbraun
        case "dark":
            return .white
        default: // system
            return .primary
        }
    }

    static func getQuranUIBackgroundColor(for theme: String, systemColorScheme: ColorScheme) -> UIColor {
        switch theme {
        case "light":
            return .white
        case "sepia":
            return UIColor(red: 244/255, green: 236/255, blue: 216/255, alpha: 1.0)
        case "dark":
            return .black
        default: // system
            return systemColorScheme == .dark ? .black : UIColor(red: 245 / 255, green: 247 / 255, blue: 245 / 255, alpha: 1.0)
        }
    }

    static func getQuranUITextColor(for theme: String, systemColorScheme: ColorScheme) -> UIColor {
        switch theme {
        case "light":
            return .black
        case "sepia":
            return UIColor(red: 44/255, green: 34/255, blue: 24/255, alpha: 1.0)
        case "dark":
            return .white
        default: // system
            return systemColorScheme == .dark ? .white : .black
        }
    }
}

struct L10n {
    static let translations: [String: [String: String]] = [
        "tab_adhkar": ["de": "Adhkar", "en": "Adhkar", "ar": "أذكار"],
        "tab_quran": ["de": "Quran", "en": "Quran", "ar": "القرآن"],
        "tab_today": ["de": "Heute", "en": "Today", "ar": "اليوم"],
        "tab_tasbih": ["de": "Tasbih", "en": "Tasbih", "ar": "تسبيح"],
        "tab_stats": ["de": "Statistik", "en": "Statistics", "ar": "إحصائيات"],
        "basmala": ["de": "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ", "en": "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ", "ar": "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ"],
        "quran_verses_read": ["de": "Heute gelesen: %d Verse", "en": "Read today: %d verses", "ar": "تمت قراءة %d آيات اليوم"],
        "quran_pages_read": ["de": "Heute gelesen: %d Seiten", "en": "Read today: %d pages", "ar": "تمت قراءة %d صفحات اليوم"],
        "quran_pages_read_goal": ["de": "%d von %d Seiten gelesen", "en": "Read %d of %d pages", "ar": "تمت قراءة %d من %d صفحات"],
        "verses": ["de": "Verse", "en": "verses", "ar": "آيات"],
        "pages": ["de": "Seiten", "en": "pages", "ar": "صفحات"],
        "daily_goal_verses": ["de": "Tagesziel: %d Verse", "en": "Daily goal: %d verses", "ar": "الهدف اليومي: %d آيات"],
        "adhkar_morning": ["de": "Morgen-Adhkar", "en": "Morning Adhkar", "ar": "أذكار الصباح"],
        "adhkar_evening": ["de": "Abend-Adhkar", "en": "Evening Adhkar", "ar": "أذكار المساء"],
        "adhkar_sleep": ["de": "Schlaf-Adhkar", "en": "Sleep Adhkar", "ar": "أذكار النوم"],
        "today_done": ["de": "Heute erledigt ✓", "en": "Completed today ✓", "ar": "تم اليوم ✓"],
        "pending": ["de": "Ausstehend", "en": "Pending", "ar": "في الانتظار"],
        "tasbih_istighfar": ["de": "Ich bitte Allah um Vergebung", "en": "I seek forgiveness from Allah", "ar": "أستغفر الله وأتوب إليه"],
        "tasbih_salawat": ["de": "O Allah, segne Muhammad", "en": "O Allah, send blessings upon Muhammad", "ar": "اللهم صل وسلم على نبينا محمد"],
        "tasbih_subhanallah": ["de": "Subhan Allahi wa bihamdihi, Subhan Allahil-Adhim", "en": "Subhan Allahi wa bihamdihi, Subhan Allahil-Adhim", "ar": "سبحان الله وبحمده سبحان الله العظيم"],
        "tasbih_alhamdulillah": ["de": "Subhanallah, walhamdulillah, wa la ilaha illallah, wallahu akbar", "en": "Subhanallah, walhamdulillah, wa la ilaha illallah, wallahu akbar", "ar": "سُبْحَانَ اللَّهِ وَالْحَمْدُ لِلَّهِ وَلَا إِلَهَ إِلَّا اللَّهُ وَاللَّهُ أَكْبَرُ"],
        "tasbih_lahawla": ["de": "La hawla wa la quwwata illa billah", "en": "La hawla wa la quwwata illa billah", "ar": "لا حول ولا قوة إلا بالله"],
        "daily_goal": ["de": "Tagesziel:", "en": "Daily goal:", "ar": "الهدف اليومي:"],
        "daily_goal_pages": ["de": "Tagesziel: %d Seiten", "en": "Daily goal: %d pages", "ar": "الهدف اليومي: %d صفحات"],
        "surah_alkahf": ["de": "Sure Al-Kahf", "en": "Surah Al-Kahf", "ar": "سورة الكهف"],
        "surah_alkahf_desc": ["de": "Freitagslesung (Do Sonnenuntergang bis Fr Sonnenuntergang)", "en": "Recitation on Fridays (Thu sunset to Fri sunset)", "ar": "قراءة الجمعة (من غروب الخميس إلى غروب الجمعة)"],
        "read_now": ["de": "Jetzt lesen", "en": "Read now", "ar": "اقرأ الآن"],
        "done": ["de": "Fertig", "en": "Done", "ar": "تم"],
        "mandatory": ["de": "Obligatorisch", "en": "Mandatory", "ar": "إلزامي"],
        "cancel": ["de": "Abbrechen", "en": "Cancel", "ar": "إلغاء"],
        "add": ["de": "Hinzufügen", "en": "Add", "ar": "إضافة"],
        "amount": ["de": "Anzahl", "en": "Amount", "ar": "العدد"],
        "manual_add": ["de": "Manuell hinzufügen", "en": "Add manually", "ar": "إضافة يدوية"],
        "manual_add_msg": ["de": "Wie viele Dhikr möchtest du eintragen?", "en": "How many Dhikr do you want to add?", "ar": "كم ذكراً تريد إضافته؟"],
        "session_finish": ["de": "Session abschließen", "en": "Finish session", "ar": "إنهاء الجلسة"],
        "actual_count": ["de": "Tatsächliche Anzahl", "en": "Actual count", "ar": "العدد الفعلي"],
        "session_finish_msg": ["de": "Die Auto-Counter Session hat +%d gezählt. Bitte korrigieren falls nötig.", "en": "The auto-counter session counted +%d. Please correct if necessary.", "ar": "عدّاد الجلسة التلقائي أحصى +%d. يرجى التصحيح إذا لزم الأمر."],
        "save": ["de": "Abrechnen", "en": "Save", "ar": "حفظ"],
        "correct": ["de": "Korrigieren", "en": "Correct", "ar": "تصحيح"],
        "reset_msg": ["de": "Zurückgesetzt", "en": "Reset", "ar": "تمت إعادة الضبط"],
        "alhamdulillah_finished": ["de": "Alhamdulillah, beendet!", "en": "Alhamdulillah, completed!", "ar": "الحمد لله، تم الانتهاء!"],
        "language": ["de": "Sprache", "en": "Language", "ar": "اللغة"],
        "dark_mode": ["de": "Dunkelmodus", "en": "Dark Mode", "ar": "الوضع الداكن"],
        "appearance": ["de": "Aussehen", "en": "Appearance", "ar": "المظهر"],
        "appearance_sec": ["de": "Darstellung", "en": "Appearance", "ar": "المظهر"],
        "adhkar_sec": ["de": "Adhkar", "en": "Adhkar", "ar": "الأذكار"],
        "adhkar_count_mode": ["de": "Adhkar Zählmodus", "en": "Adhkar Counting Mode", "ar": "طريقة عد الأذكار"],
        "tasbih_count_mode": ["de": "Tasbih Zählmodus", "en": "Tasbih Counting Mode", "ar": "طريقة عد التسبيح"],
        "adhkar_auto_advance": ["de": "Automatisch weitergehen", "en": "Auto Advance to Next", "ar": "الانتقال التلقائي للذكر التالي"],
        "adhkar_auto_advance_desc": ["de": "Startet im Automodus direkt das nächste Dhikr", "en": "In auto mode, automatically starts the next Dhikr", "ar": "في الوضع التلقائي، يبدأ الذكر التالي مباشرة"],
        "adhkar_count_manual": ["de": "Klicken", "en": "Manual Tap", "ar": "نقر"],
        "adhkar_count_auto": ["de": "Automatisch", "en": "Automatic", "ar": "تلقائي"],
        "versions": ["de": "Versionen", "en": "Versions", "ar": "النسخ"],
        "choose_version": ["de": "Wähle deine bevorzugte Version", "en": "Choose your preferred version", "ar": "اختر نسختك المفضلة"],
        "tempo": ["de": "Tempo: %d/Min", "en": "Tempo: %d/min", "ar": "السرعة: %d/دقيقة"],
        "settings": ["de": "Einstellungen", "en": "Settings", "ar": "الإعدادات"],
        "stats_this_month": ["de": "Gesamt diesen Monat: %d Verse", "en": "Total this month: %d verses", "ar": "المجموع هذا الشهر: %d آيات"],
        "stats_this_month_pages": ["de": "Diesen Monat: %d von %d Seiten", "en": "This month: %d of %d pages", "ar": "هذا الشهر: %d من %d صفحات"],
        "stats_avg": ["de": "Ø %.1f Verse/Tag", "en": "Avg %.1f verses/day", "ar": "معدل %.1f آيات/يوم"],
        "stats_avg_pages": ["de": "Ø %.1f Seiten/Tag", "en": "Avg %.1f pages/day", "ar": "معدل %.1f صفحات/يوم"],
        "stats_avg_dhikr": ["de": "Ø %d/Tag", "en": "Avg %d/day", "ar": "معدل %d/يوم"],
        "stats_comparison": ["de": "3-Monats Vergleich", "en": "3-Month Comparison", "ar": "مقارنة ٣ أشهر"],
        "stats_total": ["de": "Gesamt: %d", "en": "Total: %d", "ar": "المجموع: %d"],
        "quran_warning": ["de": "⚠️ Aktuell: Al-Fatiha + Al-Baqarah geladen. Vollständiger Quran wird in nächstem Update hinzugefügt.", "en": "⚠️ Currently: Al-Fatiha + Al-Baqarah loaded. Complete Quran will be added in the next update.", "ar": "⚠️ حالياً: سورة الفاتحة + البقرة محملة. سيتم إضافة القرآن كاملاً في التحديث القادم."],
        "last_read": ["de": "Letzte Lesung", "en": "Last read", "ar": "آخر قراءة"],
        "koran_sec": ["de": "Quran", "en": "Quran", "ar": "القرآن"],
        "tasbih_sec": ["de": "Tasbih", "en": "Tasbih", "ar": "تسبيح"],
        "completed_today_ar": ["de": "Heute erledigt ✓", "en": "Completed today ✓", "ar": "تم اليوم ✓"],
        "tasbih_type_istighfar": ["de": "Istighfar", "en": "Istighfar", "ar": "الاستغفار"],
        "tasbih_type_salawat": ["de": "Salawat", "en": "Salawat", "ar": "الصلاة على النبي"],
        "tasbih_type_subhanallah": ["de": "Subhan Allahi wa bihamdihi, Subhan Allahil-Adhim", "en": "Subhan Allahi wa bihamdihi, Subhan Allahil-Adhim", "ar": "سبحان الله وبحمده سبحان الله العظيم"],
        "tasbih_type_alhamdulillah": ["de": "Subhanallah, walhamdulillah, wa la ilaha illallah, wallahu akbar", "en": "Subhanallah, walhamdulillah, wa la ilaha illallah, wallahu akbar", "ar": "سُبْحَانَ اللَّهِ وَالْحَمْدُ لِلَّهِ وَلَا إِلَهَ إِلَّا اللَّهُ وَاللَّهُ أَكْبَرُ"],
        "tasbih_type_lahawla": ["de": "La hawla wa la quwwata illa billah", "en": "La hawla wa la quwwata illa billah", "ar": "لا حول ولا قوة إلا بالله"],
        "tasbih_type_lailahaillallah": ["de": "La ilaha illallah", "en": "La ilaha illallah", "ar": "لا إله إلا الله"],
        "tasbih_subhanallah_trans": [
            "de": "Gepriesen sei Allah und Lob sei Ihm, gepriesen sei Allah der Allgewaltige",
            "en": "Glory be to Allah and praise be to Him, glory be to Allah the Almighty",
            "ar": "سبحان الله وبحمده سبحان الله العظيم"
        ],
        "tasbih_alhamdulillah_trans": [
            "de": "Gepriesen sei Allah, alles Lob gebührt Allah, es gibt keinen Gott außer Allah, Allah ist am größten",
            "en": "Glory be to Allah, all praise is due to Allah, there is no god but Allah, Allah is the greatest",
            "ar": "سُبْحَانَ اللَّهِ وَالْحَمْدُ لِلَّهِ وَلَا إِلَهَ إِلَّا اللَّهُ وَاللَّهُ أَكْبَرُ"
        ],
        "tasbih_lahawla_trans": [
            "de": "Es gibt keine Macht noch Kraft außer durch Allah",
            "en": "There is no power nor strength except through Allah",
            "ar": "لا حول ولا قوة إلا بالله"
        ],
        "tasbih_lailahaillallah_trans": [
            "de": "Es gibt keinen Gott außer Allah, dem Einzigen, der keinen Teilhaber hat. Ihm gehört die Herrschaft und Ihm gebührt alles Lob, und Er hat Macht über alle Dinge.",
            "en": "There is no deity but Allah alone, who has no partner. His is the dominion and His is the praise, and He is Able to do all things.",
            "ar": "لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير"
        ],
        "global_tempo": ["de": "Globales Tempo", "en": "Global Tempo", "ar": "السرعة العامة"],
        "tempo_desc": ["de": "Ziel-Tempo (Dhikr/Min)", "en": "Target Tempo (Dhikr/min)", "ar": "السرعة المستهدفة (ذكر/دقيقة)"],
        "sayyidul_dua_text": ["de": "Sayyidul Istighfar Dua", "en": "Sayyidul Istighfar Dua", "ar": "دعاء سيد الاستغفار"],
        "transliteration": ["de": "Transliteration", "en": "Transliteration", "ar": "اللفظ اللاتيني"],
        "translation": ["de": "Übersetzung", "en": "Translation", "ar": "الترجمة"],
        "istighfar_kurz_title": ["de": "Ich bitte Allah um Vergebung.", "en": "I seek forgiveness from Allah.", "ar": "أَسْتَغْفِرُ اللَّهَ"],
        "istighfar_extended_title": ["de": "Ich bitte Allah um Vergebung und kehre reumütig zu Ihm zurück.", "en": "I seek forgiveness from Allah and repent to Him.", "ar": "أَسْتَغْفِرُ اللهَ وَأَتُوبُ إِلَيْهِ"],
        "istighfar_gewaltig_title": ["de": "Ich bitte Allah den Allgewaltigen um Vergebung, außer dem es keinen Gott gibt, den Lebendigen, den Beständigen, und ich kehre reumütig zu Ihm zurück.", "en": "I seek forgiveness from Allah, the All-Mighty, besides Whom there is no god, the Ever-Living, the Sustainer of all, and I repent to Him.", "ar": "أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ الَّذِي لَا إِلَهَ إِلَّا هُوَ الْحَيَّ الْقَيُّومَ وَأَتُوبُ إِلَيْهِ"],
        "istighfar_lang_title": ["de": "O Allah, Du bist mein Herr. Es gibt keinen Gott außer Dir. Du hast mich erschaffen, und ich bin Dein Diener. Ich halte mich an Deinen Bund und Dein Versprechen, so gut ich kann. Ich suche Zuflucht bei Dir vor dem Übel, das ich begangen habe. Ich bekenne mich zu Deinen Gnaden über mich, und ich bekenne mich zu meiner Sünde. So vergib mir, denn niemand vergibt die Sünden außer Dir.", "en": "O Allah, You are my Lord, there is none worthy of worship but You. You created me and I am Your slave. I keep Your covenant, and my pledge to You so far as I am able. I seek refuge in You from the evil of what I have done. I admit to Your blessings upon me, and I admit to my misdeeds. Forgive me, for there is none who may forgive sins but You.", "ar": "سيد الاستغفار"],
        "istighfar_quranisch_title": ["de": "Unser Herr, wir haben uns selbst Unrecht getan. Wenn Du uns nicht vergibst und Dich unser erbarmst, werden wir ganz gewiss zu den Verlierern gehören.", "en": "Our Lord, we have wronged ourselves, and if You do not forgive us and have mercy upon us, we will surely be among the losers.", "ar": "رَبَّنَا ظَلَمْنَا أَنْفُسَنَا وَإِنْ لَمْ تَغْفِرْ لَنَا وَتَرْحَمْنَا لَنَكُونَنَّ مِنَ الْخَاسِرِينَ"],
        "salawat_kurz_title": ["de": "O Allah, sende Segen auf Muhammad und auf die Familie Muhammads.", "en": "O Allah, send blessings upon Muhammad and upon the family of Muhammad.", "ar": "اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ"],
        "salawat_lang_title": ["de": "O Allah, sende Segen auf Muhammad und auf die Familie von Muhammad, so wie Du Segen auf Ibrahim und auf die Familie von Ibrahim gesandt hast. Wahrlich, Du bist lobenswert und ruhmreich. O Allah, segne Muhammad und die Familie von Muhammad, so wie Du Ibrahim und die Familie von Ibrahim gesegnet hast. Wahrlich, Du bist lobenswert und ruhmreich.", "en": "O Allah, send blessings upon Muhammad and upon the family of Muhammad, as You sent blessings upon Ibrahim and upon the family of Ibrahim. You are indeed worthy of praise, full of glory. O Allah, bless Muhammad and the family of Muhammad, as You blessed Ibrahim and the family of Ibrahim. You are indeed worthy of praise, full of glory.", "ar": "الصلاة الإبراهيمية"],
        "onboarding_welcome_title": [
            "de": "As-salamu alaykum wa rahmatullahi wa barakatuh",
            "en": "As-salamu alaykum wa rahmatullahi wa barakatuh",
            "ar": "السلام عليكم ورحمة الله وبركاته"
        ],
        "onboarding_welcome_desc": [
            "de": "EmanTrack ist dein minimalistischer Begleiter. Verfolge deine täglichen Adhkar, Tasbih und Koran-Leseziele ganz einfach und ohne Ablenkung.",
            "en": "EmanTrack is your minimalist companion. Track your daily Adhkar, Tasbih, and Quran reading goals simply and without distraction.",
            "ar": "تطبيق EmanTrack هو رفيقك البسيط. تابع أهدافك اليومية من الأذكار والتسبيح وقراءة القرآن بسهولة وبدون تشتيت."
        ],
        "onboarding_sunnah_title": ["de": "Im Rhythmus der Sunnah", "en": "Rhythm of the Sunnah", "ar": "على إيقاع السنة"],
        "onboarding_sunnah_desc": ["de": "Dein Tag setzt sich nicht um Mitternacht zurück, sondern traditionell zum Sonnenuntergang (Maghrib). Dafür benötigen wir deinen groben Standort.", "en": "Your day does not reset at midnight, but traditionally at sunset (Maghrib). We need your approximate location for this.", "ar": "يومك لا يتجدد عند منتصف الليل، بل تقليدياً عند غروب الشمس (المغرب). نحتاج إلى موقعك التقريبي لذلك."],
        "onboarding_sunnah_btn": ["de": "Standort erlauben", "en": "Allow Location", "ar": "السماح بالموقع"],
        "onboarding_goals_title": ["de": "Deine Tagesziele", "en": "Your Daily Goals", "ar": "أهدافك اليومية"],
        "onboarding_goals_desc": ["de": "Setze deine persönlichen Ziele. Du kannst diese später in den Einstellungen ändern.", "en": "Set your personal goals. You can change these later in the settings.", "ar": "حدد أهدافك الشخصية. يمكنك تغييرها لاحقًا في الإعدادات."],
        "onboarding_quran_goal": ["de": "Koran (Seiten)", "en": "Quran (pages)", "ar": "القرآن (صفحات)"],
        "onboarding_tasbih_goal": ["de": "Tasbih/Dhikr (Gesamtzahl)", "en": "Tasbih/Dhikr (total count)", "ar": "التسبيح/الذكر (العدد الإجمالي)"],
        "onboarding_ready_title": ["de": "Bismillah", "en": "Bismillah", "ar": "بسم الله"],
        "onboarding_ready_desc": ["de": "Möge Allah deine Taten segnen. Du kannst jetzt starten.", "en": "May Allah bless your deeds. You can start now.", "ar": "تقبل الله طاعاتكم. يمكنك البدء الآن."],
        "onboarding_ready_btn": ["de": "App starten", "en": "Start App", "ar": "ابدأ التطبيق"],
        "onboarding_skip": ["de": "Überspringen", "en": "Skip", "ar": "تخطي"],
        "onboarding_next": ["de": "Weiter", "en": "Next", "ar": "التالي"],
        "onboarding_location_granted": ["de": "Standort freigegeben ✓", "en": "Location allowed ✓", "ar": "تم السماح بالموقع ✓"],
        "fajr_alarm_sec": ["de": "Fajr-Wecker", "en": "Fajr Alarm", "ar": "منبه الفجر"],
        "fajr_alarm_enable": ["de": "Fajr-Wecker aktivieren", "en": "Enable Fajr Alarm", "ar": "تفعيل منبه الفجر"],
        "fajr_alarm_title": ["de": "Fajr Gebet", "en": "Fajr Prayer", "ar": "صلاة الفجر"],
        "fajr_alarm_body": ["de": "Zeit für das Fajr-Gebet. Das Gebet ist besser als der Schlaf.", "en": "Time for Fajr. As-salatu khayrun minan-nawm.", "ar": "حان وقت صلاة الفجر. الصلاة خير من النوم."],
        "fajr_alarm_mode": ["de": "Weckzeit", "en": "Alarm Time", "ar": "وقت المنبه"],
        "fajr_alarm_mode_at": ["de": "Pünktlich", "en": "At Fajr", "ar": "في وقت الفجر"],
        "fajr_alarm_mode_before": ["de": "Minuten vorher", "en": "Minutes before", "ar": "دقائق قبل الفجر"],
        "fajr_alarm_mode_fixed": ["de": "Feste Uhrzeit", "en": "Fixed Time", "ar": "وقت ثابت"],
        "fajr_alarm_next_prefix": ["de": "Nächster Alarm: Morgen um", "en": "Next alarm: Tomorrow at", "ar": "المنبه القادم: غداً عند"],
        "fajr_alarm_first_sec": ["de": "Fajr-Wecker 1", "en": "Fajr Alarm 1", "ar": "منبه الفجر ١"],
        "fajr_alarm_second_sec": ["de": "Fajr-Wecker 2", "en": "Fajr Alarm 2", "ar": "منبه الفجر ٢"],
        "fajr_alarm_sound": ["de": "Weckton", "en": "Alarm Sound", "ar": "صوت المنبه"],
        "fajr_sound_quran": ["de": "Koran-Rezitation", "en": "Quran Recitation", "ar": "تلاوة القرآن"],
        "fajr_sound_system": ["de": "System-Standard", "en": "System Default", "ar": "نغمة النظام"],
        "fajr_sound_preview_play": ["de": "Weckton anhören", "en": "Listen to Alarm Sound", "ar": "استماع لصوت المنبه"],
        "fajr_sound_preview_stop": ["de": "Vorschau stoppen", "en": "Stop Preview", "ar": "إيقاف الاستماع"],
        "fajr_sound_azan1": ["de": "Adhan 1", "en": "Adhan 1", "ar": "الأذان ١"],
        "fajr_sound_azan2": ["de": "Adhan 2", "en": "Adhan 2", "ar": "الأذان ٢"],
        "fajr_sound_azan_mecca": ["de": "Adhan Mekka", "en": "Adhan Mecca", "ar": "أذان مكة"],
        "fajr_sound_azan_beauty": ["de": "Schöner Adhan", "en": "Beautiful Adhan", "ar": "أذان جميل"],
        "fajr_sound_fajr1": ["de": "Fajr Adhan 1", "en": "Fajr Adhan 1", "ar": "أذان الفجر ١"],
        "fajr_sound_fajr2": ["de": "Fajr Adhan 2", "en": "Fajr Adhan 2", "ar": "أذان الفجر ٢"],
        "fajr_sound_alarm_mecca": ["de": "Fajr Alarm Mekka", "en": "Fajr Alarm Mecca", "ar": "منبه الفجر مكة"],
        "font_size": ["de": "Schriftgröße", "en": "Font Size", "ar": "حجم الخط"],
        "font_type": ["de": "Schriftart", "en": "Font Type", "ar": "نوع الخط"],
        "font_uthmanic": ["de": "Uthmanisch", "en": "Uthmanic", "ar": "رسم عثماني"],
        "font_geeza": ["de": "Klassisch (Geeza Pro)", "en": "Classic (Geeza Pro)", "ar": "جيزا برو (كلاسيكي)"],
        "font_system": ["de": "System (Modern)", "en": "System (Modern)", "ar": "خط النظام (حديث)"],
        "font_kfgqpchafs": ["de": "KFGQPC Hafs Script", "en": "KFGQPC Hafs Script", "ar": "رسم مصحف المدينة"],
        "font_me_quran": ["de": "Koran-Schrift (Volt)", "en": "Koran Font (Volt)", "ar": "خط مصحف التجويد"],
        "app_color": ["de": "App-Farbe", "en": "App Color", "ar": "لون التطبيق"],
        "vibration_feedback": ["de": "Vibration / Haptik", "en": "Vibration / Haptics", "ar": "الاهتزاز"],
        "fajr_prayer": ["de": "Fajr Gebet", "en": "Fajr Prayer", "ar": "صلاة الفجر"],
        "fajr_prayed_status": ["de": "Gebetet ✓", "en": "Prayed ✓", "ar": "تمت الصلاة ✓"],
        "fajr_not_prayed_status": ["de": "Noch nicht gebetet", "en": "Not prayed yet", "ar": "لم تتم الصلاة بعد"],
        "fajr_status_ontime": ["de": "Frühzeitig gebetet", "en": "Prayed on time", "ar": "صليت في الوقت"],
        "fajr_status_late": ["de": "Nach gebetet", "en": "Prayed late (Qada)", "ar": "قضاء"],
        "fajr_status_none": ["de": "Noch nicht gebetet", "en": "Not prayed yet", "ar": "لم تتم الصلاة بعد"],
        "fajr_option_ontime": ["de": "Frühzeitig gebetet", "en": "Prayed on time", "ar": "صليت في الوقت"],
        "fajr_option_late": ["de": "Nach gebetet", "en": "Prayed late (Qada)", "ar": "قضاء"],
        "fajr_option_reset": ["de": "Zurücksetzen (Nicht gebetet)", "en": "Reset (Not prayed)", "ar": "إعادة ضبط"],
        "fajr_option_title": ["de": "Fajr-Gebet Status ändern", "en": "Change Fajr Prayer Status", "ar": "تغيير حالة صلاة الفجر"],
        "playback_tempo": ["de": "Playback-Tempo", "en": "Playback Tempo", "ar": "سرعة التشغيل"],
        "tempo_slowest": ["de": "Langsamer", "en": "Slower", "ar": "أبطأ"],
        "tempo_slow": ["de": "Leicht langsamer", "en": "Slightly Slower", "ar": "أبطأ قليلاً"],
        "tempo_normal": ["de": "Normal", "en": "Normal", "ar": "عادي"],
        "tempo_fast": ["de": "Leicht schneller", "en": "Slightly Faster", "ar": "أسرع قليلاً"],
        "tempo_fastest": ["de": "Schneller", "en": "Faster", "ar": "أسرع"],
        "fajr_sec": ["de": "Fajr", "en": "Fajr", "ar": "الفجر"],
        "color_green": ["de": "Grün", "en": "Green", "ar": "أخضر"],
        "color_blue": ["de": "Blau", "en": "Blue", "ar": "أزرق"],
        "color_amber": ["de": "Gold", "en": "Amber", "ar": "ذهبي"],
        "color_purple": ["de": "Violett", "en": "Purple", "ar": "بنفسجي"],
        "color_crimson": ["de": "Rot", "en": "Crimson", "ar": "أحمر"]
    ]

    static func tr(_ key: String, _ lang: String) -> String {
        let l = lang.lowercased()
        guard let translationsForKey = translations[key] else { return key }
        return translationsForKey[l] ?? translationsForKey["en"] ?? key
    }
}

extension String {
    func cleanQuranText() -> String {
        var cleaned = self
        
        // 1. Entferne stumme Vokalzeichen (Arabic Small High Round Zero U+06DF und Arabic Small High Upright Rectangular Zero U+06E1),
        // da sie auf iOS-Renderern oft Dotted Circles oder unschöne schwarze Kugeln erzeugen.
        cleaned = cleaned.replacingOccurrences(of: "\u{06DF}", with: "")
        cleaned = cleaned.replacingOccurrences(of: "\u{06E1}", with: "")
        
        // 2. Das Maddah-Dehnungszeichen (U+0653) wird nicht mehr entfernt, da die neue Uthmanic-Schriftart 
        // und Geeza Pro das Maddah-Symbol fehlerfrei unterstützen und darstellen.
        // cleaned = cleaned.replacingOccurrences(of: "\u{0653}", with: "")
        
        // 3. Bereinige unsichtbare Störzeichen (Zero-Width Space, Zero-Width Non-Joiner U+200C, Zero-Width Joiner)
        // und doppelte Leerzeichen direkt vor Combining Marks, um Dotted Circles (U+25CC) zu verhindern.
        let pattern = "[\\u{200B}\\u{200C}\\u{200D}\\u{0020}]+(?=[\\u{0610}-\\u{061A}\\u{064B}-\\u{065F}\\u{0670}\\u{06D6}-\\u{06DC}\\u{06DF}-\\u{06E8}\\u{06EA}-\\u{06EC}])"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let range = NSRange(location: 0, length: cleaned.utf16.count)
            cleaned = regex.stringByReplacingMatches(in: cleaned, options: [], range: range, withTemplate: "")
        }
        
        // 4. Positionierungs-Fix für me_quran: Ersetze Tatweel (U+0640) + Dagger Alif (U+0670) durch einfaches Dagger Alif,
        // um das Verrutschen des Dagger Alif auf das Folgezeichen (z.B. bei 'Ar-Rahman') zu verhindern.
        cleaned = cleaned.replacingOccurrences(of: "\u{0640}\u{0670}", with: "\u{0670}")
        cleaned = cleaned.replacingOccurrences(of: "\u{064E}\u{0640}\u{0670}", with: "\u{064E}\u{0670}")
        
        return cleaned
    }
}
