import SwiftUI

struct Theme {
    static let islamicGreen = Color(red: 46 / 255, green: 125 / 255, blue: 50 / 255)
    
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
    
    static let accent = islamicGreen
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
        "adhkar_sec": ["de": "Adhkar-Einstellungen", "en": "Adhkar Settings", "ar": "إعدادات الأذكار"],
        "adhkar_count_mode": ["de": "Zählmodus", "en": "Counting Mode", "ar": "طريقة العد"],
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
        "onboarding_welcome_title": ["de": "Willkommen bei\nImanTracker", "en": "Welcome to\nImanTracker", "ar": "أهلاً بك في\nImanTracker"],
        "onboarding_welcome_desc": ["de": "Verfolge deine täglichen Adhkar, Tasbih und Quran-Leseziele in einem minimalistischen Design.", "en": "Track your daily Adhkar, Tasbih, and Quran reading goals in a minimalist design.", "ar": "تابع أهدافك اليومية من الأذكار والتسبيح وقراءة القرآن بتصميم بسيط ومريح."],
        "onboarding_sunnah_title": ["de": "Im Rhythmus der Sunnah", "en": "Rhythm of the Sunnah", "ar": "على إيقاع السنة"],
        "onboarding_sunnah_desc": ["de": "Dein Tag setzt sich nicht um Mitternacht zurück, sondern traditionell zum Sonnenuntergang (Maghrib). Dafür benötigen wir deinen groben Standort.", "en": "Your day does not reset at midnight, but traditionally at sunset (Maghrib). We need your approximate location for this.", "ar": "يومك لا يتجدد عند منتصف الليل، بل تقليدياً عند غروب الشمس (المغرب). نحتاج إلى موقعك التقريبي لذلك."],
        "onboarding_sunnah_btn": ["de": "Standort erlauben", "en": "Allow Location", "ar": "السماح بالموقع"],
        "onboarding_ready_title": ["de": "Bismillah", "en": "Bismillah", "ar": "بسم الله"],
        "onboarding_ready_desc": ["de": "Möge Allah deine Taten segnen. Du kannst jetzt starten.", "en": "May Allah bless your deeds. You can start now.", "ar": "تقبل الله طاعاتكم. يمكنك البدء الآن."],
        "onboarding_ready_btn": ["de": "App starten", "en": "Start App", "ar": "ابدأ التطبيق"],
        "onboarding_skip": ["de": "Überspringen", "en": "Skip", "ar": "تخطي"],
        "onboarding_next": ["de": "Weiter", "en": "Next", "ar": "التالي"],
        "onboarding_location_granted": ["de": "Standort freigegeben ✓", "en": "Location allowed ✓", "ar": "تم السماح بالموقع ✓"]
    ]

    static func tr(_ key: String, _ lang: String) -> String {
        let l = lang.lowercased()
        guard let translationsForKey = translations[key] else { return key }
        return translationsForKey[l] ?? translationsForKey["en"] ?? key
    }
}
