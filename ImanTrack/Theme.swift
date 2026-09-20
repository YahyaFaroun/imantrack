// MARK: - CRITICAL RULE / REGEL
// DIE KORAN-SCHRIFTART (KFGQPCHAFSUthmanicScript-Regula / UthmanicHafs1Ver18.ttf) DARF NIEMALS GEÄNDERT WERDEN!
// JEDE ÄNDERUNG AN DER KORAN-SCHRIFTART ERFORDERT DIE EXPLIZITE ZUSTIMMUNG DES USERS.

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
        if UIFont(name: "KFGQPCHAFSUthmanicScript-Regula", size: size) != nil {
            return .custom("KFGQPCHAFSUthmanicScript-Regula", size: size)
        }
        if UIFont(name: "kfgqpchafsuthmanicscript-Reg", size: size) != nil {
            return .custom("kfgqpchafsuthmanicscript-Reg", size: size)
        }
        return .custom("Geeza Pro", size: size)
    }
    
    static func uthmaniUIFont(size: CGFloat) -> UIFont {
        if let font = UIFont(name: "KFGQPCHAFSUthmanicScript-Regula", size: size) {
            return font
        }
        if let font = UIFont(name: "kfgqpchafsuthmanicscript-Reg", size: size) {
            return font
        }
        return UIFont(name: "GeezaPro", size: size) ?? UIFont.systemFont(ofSize: size)
    }
    
    static func uthmaniFontForced(size: CGFloat) -> Font {
        if UIFont(name: "KFGQPCHAFSUthmanicScript-Regula", size: size) != nil {
            return .custom("KFGQPCHAFSUthmanicScript-Regula", size: size)
        }
        if UIFont(name: "kfgqpchafsuthmanicscript-Reg", size: size) != nil {
            return .custom("kfgqpchafsuthmanicscript-Reg", size: size)
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
    
    static func quranFont(type: String = "uthmanic", size: CGFloat) -> Font {
        return uthmaniFont(size: size)
    }
    
    static func quranUIFont(type: String = "uthmanic", size: CGFloat) -> UIFont {
        return uthmaniUIFont(size: size)
    }
}

struct L10n {
    static let translations: [String: [String: String]] = [
        "onboarding_page6_btn": ["de": "App starten (Bismillah)", "en": "Start App (Bismillah)", "ar": "ابدأ التطبيق (بسم الله)", "tr": "Uygulamayı Başlat (Bismillah)", "id": "Mulai Aplikasi (Bismillah)", "ms": "Mulakan Aplikasi (Bismillah)", "fr": "Démarrer l'application (Bismillah)", "es": "Iniciar aplicación (Bismillah)", "ur": "ایپ شروع کریں (بسم اللہ)", "ru": "Запустить приложение (Бисмиллях)", "bn": "অ্যাপ শুরু করুন (বিسمিল্লাহ)", "fa": "شروع برنامه (بسم الله)", "ha": "Fara Application (Bismillah)", "jv": "Mulai Aplikasi (Bismillah)", "ku": "Serîlêdanê Dest Pê Bikin (Bismillah)", "pa": "ਐਪ ਸ਼ੁਰੂ ਕਰੋ (ਬਿਸਮਿੱਲਾਹ)", "ps": "اپلیکیشن پیل کړئ (بسم الله)", "so": "Bilaab App-ka (Bismillah)", "sw": "Anza Programu (Bismillah)", "uz": "Ilovani boshlash (Bismillah)"],
        "onboarding_page6_desc": ["de": "Besondere Empfehlungen für gesegnete Tage, wie Sure Al-Kahf am Freitag.", "en": "Special recommendations for blessed days, such as Surah Al-Kahf on Friday.", "ar": "توصيات خاصة للأيام المباركة، مثل سورة الكهف يوم الجمعة.", "tr": "Mübarek günler için özel tavsiyeler, örneğin Cuma günü Kehf Suresi.", "id": "Rekomendasi khusus untuk hari-hari penuh berkah, seperti Surah Al-Kahf pada hari Jumat.", "ms": "Syor khas untuk hari-hari yang diberkati, seperti Surah Al-Kahf pada hari Jumaat.", "fr": "Recommandations spéciales pour les jours bénis, comme la sourate Al-Kahf le vendredi.", "es": "Recomendaciones especiales para días benditos, como la Sura Al-Kahf los viernes.", "ur": "مبارک دنوں کے لیے خاص سفارشات، جیسے جمعہ کو سورۃ الکہف۔", "ru": "Особые рекомендации для благословенных дней, такие как сура Аль-Кахф в пятницу.", "bn": "ধন্য দিনগুলির জন্য বিশেষ বার্তা, যেমন শুক্রবারে সূরা আল-কাহফ।", "fa": "توصیه‌های ویژه برای روزهای مبارک، مانند سوره کهف در روز جمعه.", "ha": "Shawarwari na musamman don ranaku masu albarka, kamar Suratul Kahf a ranar Juma'a.", "jv": "Rekomendasi khusus kanggo dina sing berkah, kayata Surah Al-Kahf ing dina Jumuah.", "ku": "Pêşniyarên taybet ji bo rojên pîroz, wekî Sureya Kehf di roja Înê de.", "pa": "ਮੁਬਾਰਕ ਦਿਨਾਂ ਲਈ ਵਿਸ਼ੇਸ਼ ਸਿਫਾਰਸ਼ਾਂ, ਜਿਵੇਂ ਕਿ ਸ਼ੁੱਕਰਵਾਰ ਨੂੰ ਸੂਰਤ ਅਲ-ਕਹਫ਼।", "ps": "د مبارکو ورځو لپاره ځانګړي سپارښتنې، لکه د جمعې په ورځ سوره الکهف.", "so": "Ka xulo tusmada aad ka hesho oo ka timid riwaayado sax ah.", "sw": "Mapendekezo maalum kwa siku zenye baraka, kama vile Surah Al-Kahf siku ya Ijumaa.", "uz": "Barakali kunlar uchun maxsus tavsiyalar, masalan, Juma kuni Qahf surasi."],
        "onboarding_page6_title": ["de": "Wöchentliche Sunnah-Highlights", "en": "Weekly Sunnah Highlights", "ar": "أبرز سنن الأسبوع", "tr": "Haftalık Sünnet Öne Çıkanlar", "id": "Sorotan Sunnah Mingguan", "ms": "Sorotan Sunnah Mingguan", "fr": "Temps forts de la Sunna hebdomadaire", "es": "Destacados semanales de la Sunnah", "ur": "ہفتہ وار سنت کے اہم نکات", "ru": "Еженедельные ключевые Сунны", "bn": "সাপ্তাহিক সুন্নাহ হাইলাইটস", "fa": "برجسته‌های هفتگی سنت", "ha": "Abubuwan Lura na Sunnah na Mako", "jv": "Sorotan Sunnah Mingguan", "ku": "Nîşaneyên Sünnetê Yên Heftane", "pa": "ਹਫ਼ਤਾਵਾਰੀ ਸੁੰਨਤ ਦੇ ਹਾਈਲਾਈਟਸ", "ps": "د اونیزو سنتو نښې", "so": "Qodobada Sunnada ee Toddobaadkan", "sw": "Mambo Muhimu ya Sunnah ya Kila Wiki", "uz": "Haftalik Sunnat muhim nuqtalari"],
        "onboarding_tasbih_goal_desc": ["de": "Setze Tagesziele für deine Zikr-Praxis.", "en": "Set daily goals for your Dhikr practice.", "ar": "حدد أهدافاً يومية لممارسة الذكر.", "tr": "Zikir uygulamanız için günlük hedefler belirleyin.", "id": "Tetapkan target harian untuk amalan Dzikir Anda.", "ms": "Tetapkan sasaran harian untuk amalan Zikir anda.", "fr": "Définissez des objectifs quotidiens pour votre pratique du Dhikr.", "es": "Establece objetivos diarios para tu práctica de Dhikr.", "ur": "اپنے ذکر کی مشق کے لیے یومیہ اہداف مقرر کریں۔", "ru": "Установите ежедневные цели для практики Зикра.", "bn": "আপনার জিকির অনুশীলনের জন্য দৈনিক লক্ষ্য নির্ধারণ করুন।", "fa": "اهداف روزانه‌ای برای تمرین ذکر خود تعیین کنید.", "ha": "Saita burori na yau da kullum don aikin Dhikr dinka.", "jv": "Setel target saben dina kanggo amalan Dzikir sampeyan.", "ku": "Ji bo pratîka xwe ya Zikirê hedefên rojane diyar bikin.", "pa": "ਆਪਣੇ ਜ਼ਿਕਰ ਅਭਿਆਸ ਲਈ ਰੋਜ਼ਾਨਾ ਟੀਚੇ ਸੈੱਟ ਕਰੋ।", "ps": "ستاسو د ذکر تمرین لپاره ورځني اهداف وټاکئ.", "so": "Dejiso hadafyo maalinle ah oo ku saabsan ku dhaqanka Dikirka.", "sw": "Weka malengo ya kila siku kwa mazoezi yako ya Dhikr.", "uz": "Zikr amaliyotingiz uchun kundalik maqsadlar belgilang."],
        "onboarding_tasbih_goal_title": ["de": "Tasbih Tagesziele", "en": "Tasbih Daily Goals", "ar": "أهداف التسبيح اليومية", "tr": "Günlük Tesbih Hedefleri", "id": "Target Tasbih Harian", "ms": "Sasaran Tasbih Harian", "fr": "Objectifs quotidiens de Tasbih", "es": "Objetivos diarios de Tasbih", "ur": "تسبیح کے یومیہ اہداف", "ru": "Ежедневные цели по Тасбих", "bn": "তাসবীহ দৈনিক লক্ষ্য", "fa": "اهداف روزانه تسبیح", "ha": "Burorin Tasbih na yau", "jv": "Target Tasbih Saben Dina", "ku": "Hedefên Tesbîhê Yên Rojane", "pa": "ਤਸਬੀਹ ਦੇ ਰੋਜ਼ਾਨਾ ਟੀਚੇ", "ps": "د تسبیح ورځني اهداف", "so": "Hadafyada Tasbiixda ee Maalinlaha ah", "sw": "Malengo ya Kila Siku ya Tasbih", "uz": "Tasbeh kundalik maqsadlari"],
        "onboarding_page5_desc": ["de": "Zähle dein Tasbih manuell oder nutze das automatische Freihand-Tracking.", "en": "Count your Tasbih manually or use automatic hands-free tracking.", "ar": "احسب تسبيحك يدوياً أو استخدم التتبع التلقائي بدون يدين.", "tr": "Tesbihinizi manuel olarak sayın veya otomatik eller serbest takibi kullanın.", "id": "Hitung Tasbih Anda secara manual atau gunakan pelacakan hands-free otomatis.", "ms": "Kira Tasbih anda secara manual atau gunakan penjejakan automatik tanpa tangan.", "fr": "Comptez votre Tasbih manuellement ou utilisez le suivi automatique mains libres.", "es": "Cuenta tu Tasbih manualmente o usa el seguimiento automático manos libres.", "ur": "اپنی تسبیح دستی طور پر گنیں یا خودکار ہینڈز فری ٹریکنگ کا استعمال کریں۔", "ru": "Считайте Тасбих вручную или используйте автоматическое отслеживание без рук.", "bn": "আপনার তাসবীহ ম্যানুয়ালি গণনা করুন বা স্বয়ংক্রিয় হ্যান্ডস-ফ্রি ট্র্যাকিং ব্যবহার করুন।", "fa": "تسبیح خود را به صورت دستی بشمارید یا از ردیابی خودکار بدون دست استفاده کنید.", "ha": "Ƙirga Tasbih ɗinka da hannu ko amfani da bin diddigin kansa.", "jv": "Etung Tasbih sampeyan kanthi manual utawa gunakake pelacakan hands-free otomatis.", "ku": "Tesbîha xwe bi destan bijmêrin an şopandina otomatîk a bêdest bikar bînin.", "pa": "ਆਪਣੀ ਤਸਬੀਹ ਨੂੰ ਮੈਨੁਅਲ ਤੌਰ 'ਤੇ ਗਿਣੋ ਜਾਂ ਆਟੋਮੈਟਿਕ ਹੈਂਡਸ-ਫ੍ਰੀ ਟ੍ਰੈਕਿੰਗ ਦੀ ਵਰਤੋਂ ਕਰੋ।", "ps": "خپله تسبیح په لاسي ډول وشمېرئ یا د لاسونو وړیا خپلکار تعقیب وکاروئ.", "so": "Tiri Tasbiixdaada gacan ku rimis ama adeegso raadraaca otomaatigga ah ee gacanta la'aan.", "sw": "Hesabu Tasbih yako kwa mikono au tumia ufuatiliaji wa kiotomatiki bila mikono.", "uz": "Tasbehingizni qo'lda sanang yoki avtomatik qo'lsiz kuzatuvdan foydalaning."],
        "onboarding_page5_title": ["de": "Digitale Tasbih & Ziele", "en": "Digital Tasbih & Goals", "ar": "التسبيح الرقمي والأهداف", "tr": "Dijital Tesbih ve Hedefler", "id": "Tasbih Digital & Target", "ms": "Tasbih Digital & Sasaran", "fr": "Tasbih numérique & Objectifs", "es": "Tasbih Digital y Objetivos", "ur": "ڈیجیٹل تسبیح اور اہداف", "ru": "Цифровой Тасбих и цели", "bn": "ডিজিটাল তাসবীহ ও লক্ষ্য", "fa": "تسبیح دیجیتال و اهداف", "ha": "Tasbih ta Na'ura & Burori", "jv": "Tasbih Digital & Target", "ku": "Tesbîha Dîjîtal û Hedef", "pa": "ਡਿਜੀਟਲ ਤਸਬੀਹ ਅਤੇ ਟੀਚੇ", "ps": "دیجیټل تسبیح او اهداف", "so": "Tasbiixda Dijitaalka ah & Hadafyada", "sw": "Tasbih ya Kijiti na Malengo", "uz": "Raqamli tasbeh va maqsadlar"],
        "onboarding_page4_footer": ["de": "Wähle dein bevorzugtes Set aus authentischen Überlieferungen.", "en": "Choose your preferred set from authentic narrations.", "ar": "اختر مجموعتك المفضلة من الأحاديث الصحيحة.", "tr": "Sahih rivayetlerden tercih ettiğiniz seti seçin.", "id": "Pilih kumpulan pilihan Anda dari riwayat shahih.", "ms": "Pilih set pilihan anda daripada riwayat yang sahih.", "fr": "Choisissez votre ensemble préféré parmi les narrations authentiques.", "es": "Elige tu conjunto preferido de narraciones auténticas.", "ur": "مستند احادیث میں سے اپنا پسندیدہ سیٹ منتخب کریں۔", "ru": "Выберите предпочтительный набор из достоверных источников.", "bn": "সহিহ বর্ণনা থেকে আপনার পছন্দের সেটটি নির্বাচন করুন।", "fa": "مجموعه مورد علاقه خود را از روایات معتبر انتخاب کنید.", "ha": "Zaɓi saitin da ka fi so daga ingantattun hanyoyi.", "jv": "Pilih set pilihan sampeyan saka riwayat sing shahih.", "ku": "Koma ku hûn hez dikin ji rîwayetên rast hilbijêrin.", "pa": "ਸਹੀ ਰਵਾਇਤਾਂ ਵਿੱਚੋਂ ਆਪਣਾ ਪਸੰਦੀਦਾ ਸੈੱਟ ਚੁਣੋ।", "ps": "له معتبرو روایتونو څخه خپله خوښه سیټ وټاکئ.", "so": "Ka xulo tusmada aad ka hesho oo ka timid riwaayado sax ah.", "sw": "Chagua seti unayoipendelea kutoka kwa riwaya sahihi.", "uz": "Sahihi rivoyatlardan afzal ko'rgan to'plamingizni tanlang."],
        "onboarding_page4_evening": ["de": "Abend-Adhkar", "en": "Evening Adhkar", "ar": "أذكار المساء", "tr": "Akşam Zikirleri", "id": "Adzkar Petang", "ms": "Zikir Petang", "fr": "Adhkar du soir", "es": "Adhkar de la tarde", "ur": "شام کے اذکار", "ru": "Вечерние Азкар", "bn": "সন্ধ্যার আজকার", "fa": "اذکار عصر", "ha": "Adhkar na Yamma", "jv": "Dzikir Sore", "ku": "Zikirên Êvarê", "pa": "ਸ਼ਾਮ ਦੇ ਅਜ਼ਕਾਰ", "ps": "د ماښام اذکار", "so": "Adkarta Fiidnimo", "sw": "Adhkar ya Jioni", "uz": "Kechki zikrlar"],
        "onboarding_page4_morning": ["de": "Morgen-Adhkar", "en": "Morning Adhkar", "ar": "أذكار الصباح", "tr": "Sabah Zikirleri", "id": "Adzkar Pagi", "ms": "Zikir Pagi", "fr": "Adhkar du matin", "es": "Adhkar de la mañana", "ur": "صبح کے اذکار", "ru": "Утренние Азкар", "bn": "সকালের আজকার", "fa": "اذکار صبح", "ha": "Adhkar na Safiya", "jv": "Dzikir Esuk", "ku": "Zikirên Sibê", "pa": "ਸਵੇਰ ਦੇ ਅਜ਼ਕਾਰ", "ps": "د سهار اذکار", "so": "Adkarta Subaxnimo", "sw": "Adhkar ya Asubuhi", "uz": "Tonggi zikrlar"],
        "onboarding_page4_sleep": ["de": "Schlaf-Adhkar", "en": "Sleep Adhkar", "ar": "أذكار النوم", "tr": "Uyku Zikirleri", "id": "Adzkar Tidur", "ms": "Zikir Tidur", "fr": "Adhkar du sommeil", "es": "Adhkar del sueño", "ur": "سونے کے اذکار", "ru": "Азкар перед сном", "bn": "ঘুমের আজকার", "fa": "اذکار خواب", "ha": "Adhkar na Barci", "jv": "Dzikir Turu", "ku": "Zikirên Xewê", "pa": "ਸੌਣ ਦੇ ਅਜ਼ਕਾਰ", "ps": "د خوب اذکار", "so": "Adkarta Hurdada", "sw": "Adhkar ya Kulala", "uz": "Uxlashdan oldingi zikrlar"],
        "onboarding_page4_desc": ["de": "Verfolge deine Morgen-, Abend- und Schlaf-Adhkar mühelos.", "en": "Track your Morning, Evening, and Sleep Adhkar effortlessly.", "ar": "تابع أذكار الصباح والمساء والنوم بكل سهولة.", "tr": "Sabah, Akşam ve Uyku zikirlerinizi zahmetsizce takip edin.", "id": "Lacak Adzkar Pagi, Petang, dan Tidur Anda dengan mudah.", "ms": "Jejak Zikir Pagi, Petang, dan Tidur anda dengan mudah.", "fr": "Suivez vos Adhkar du matin, du soir et du sommeil sans effort.", "es": "Rastrea tus Adhkar de la mañana, tarde y sueño sin esfuerzo.", "ur": "اپنے صبح، شام اور سونے کے اذکار کو بغیر کسی کوشش کے ٹریک کریں۔", "ru": "Легко отслеживайте утренние, вечерние Азкар и Азкар перед сном.", "bn": "অনায়াসে আপনার সকাল, সন্ধ্যা এবং ঘুমের আজকার ট্র্যাক করুন।", "fa": "اذکار صبح، عصر و خواب خود را به راحتی پیگیری کنید.", "ha": "Bi Adhkar na Safiya, Yamma da Barci ba tare da wahala ba.", "jv": "Lacak Dzikir Esuk, Sore, lan Turu sampeyan kanthi gampang.", "ku": "Zikirên xwe yên Sibê, Êvarê û Xewê bi hêsanî bişopînin.", "pa": "ਆਪਣੀ ਸਵੇਰ, ਸ਼ਾਮ ਅਤੇ ਸੌਣ ਦੇ ਅਜ਼ਕਾਰ ਨੂੰ ਆਸਾਨੀ ਨਾਲ ਟ੍ਰੈਕ ਕਰੋ।", "ps": "ستاسو د سهار، ماښام او خوب اذکار په اسانۍ تعقیب کړئ.", "so": "La soco Adkartaada Subaxnimo, Fiidnimo, iyo Hurdada si fudud.", "sw": "Fuatilia Adhkar yako ya Asubuhi, Jioni, na Kulala bila juhudi.", "uz": "Tonggi, kechki va uxlashdan oldingi zikrlaringizni osonlikcha kuzatib boring."],
        "onboarding_page4_title": ["de": "Deine täglichen Adhkar", "en": "Your Daily Adhkar", "ar": "أذكارك اليومية", "tr": "Günlük Zikirleriniz", "id": "Adzkar Harian Anda", "ms": "Zikir Harian Anda", "fr": "Vos Adhkar quotidiens", "es": "Tus Adhkar diarios", "ur": "آپ کے روزمرہ کے اذکار", "ru": "Ваши ежедневные Азкар", "bn": "আপনার দৈনন্দিন আজকার", "fa": "اذکار روزانه شما", "ha": "Adhkar dinki na Yau da Kullum", "jv": "Dzikir Saben Dina Sampeyan", "ku": "Zikirên We Yên Rojane", "pa": "ਤੁਹਾਡੇ ਰੋਜ਼ਾਨਾ ਦੇ ਅਜ਼ਕਾਰ", "ps": "ستاسو ورځني اذکار", "so": "Adkartaada Maalinlaha ah", "sw": "Adhkar Yako ya Kila Siku", "uz": "Kundalik zikrlaringiz"],
        "onboarding_quran_goal_unit": ["de": "Seiten pro Tag", "en": "pages per day", "ar": "صفحات يومياً", "tr": "sayfa / gün", "id": "halaman per hari", "ms": "halaman sehari", "fr": "pages par jour", "es": "páginas por día", "ur": "صفحات فی دن", "ru": "страниц в день", "bn": "প্রতিদিন পৃষ্ঠা", "fa": "صفحه در روز", "ha": "shafuka a rana", "jv": "kaca saben dina", "ku": "rûpel di rojê de", "pa": "ਪੰਨੇ ਪ੍ਰਤੀ ਦਿਨ", "ps": "پاڼې په ورځ کې", "so": "bogag maalintii", "sw": "kurasa kwa siku", "uz": "sahifa kuniga"],
        "onboarding_quran_goal_desc": ["de": "Setze dein tägliches Seitenziel. Du kannst es jederzeit in den Einstellungen anpassen.", "en": "Set your daily page goal. You can adjust it anytime in settings.", "ar": "حدد هدفك اليومي من الصفحات. يمكنك تعديله في أي وقت من الإعدادات.", "tr": "Günlük sayfa hedefinizi belirleyin. Ayarlardan istediğiniz zaman değiştirebilirsiniz.", "id": "Atur target halaman harian Anda. Anda dapat menyesuaikannya kapan saja di pengaturan.", "ms": "Tetapkan sasaran halaman harian anda. Anda boleh melaraskannya pada bila-bila masa di tetapan.", "fr": "Définissez votre objectif de pages quotidien. Vous pouvez l'ajuster à tout moment dans les paramètres.", "es": "Establece tu objetivo diario de páginas. Puedes ajustarlo en cualquier momento en la configuración.", "ur": "اپنا روزانہ کے صفحات کا ہدف مقرر کریں۔ آپ اسے ترتیبات میں کسی بھی وقت تبدیل کر سکتے ہیں۔", "ru": "Задайте ежедневную цель по страницам. Вы можете изменить ее в любой момент в настройках.", "bn": "আপনার দৈনিক পৃষ্ঠা লক্ষ্য নির্ধারণ করুন। আপনি সেটিংসে যেকোনো সময় এটি সংশোধন করতে পারেন।", "fa": "هدف روزانه صفحات خود را تعیین کنید. می‌توانید هر زمان در تنظیمات آن را تغییر دهید.", "ha": "Saita burin shafukanka na yau. Zaka iya gyara shi a kowane lokaci a saituna.", "jv": "Setel target kaca saben dina sampeyan. Sampeyan bisa nyetel kapan wae ing pengaturan.", "ku": "Hedefa rûpelên xwe yên rojane diyar bikin. Hûn dikarin wê di mîhengan de her dem biguherînin.", "pa": "ਆਪਣਾ ਰੋਜ਼ਾਨਾ ਪੰਨਿਆਂ ਦਾ ਟੀਚਾ ਸੈੱਟ ਕਰੋ। ਤੁਸੀਂ ਇਸਨੂੰ ਸੈਟਿੰਗਾਂ ਵਿੱਚ ਕਿਸੇ ਵੀ ਸਮੇਂ ਬਦਲ ਸਕਦੇ ਹੋ।", "ps": "خپل د ورځنیو پاڼو هدف وټاکئ. تاسو کولی شئ دا په تنظیماتو کې هر وخت بدل کړئ.", "so": "Dejiso hadafkaaga bogagga ee maalinlaha ah. Waxaad ka beddeli kartaa dejinta wakhti kasta.", "sw": "Weka lengo lako la kurasa za kila siku. Unaweza kulirekebisha wakati wowote kwenye mipangilio.", "uz": "Kundalik sahifa maqsadingizni belgilang. Sozlamalarda uni istalgan vaqtda o'zgartirishingiz mumkin."],
        "onboarding_quran_goal_title": ["de": "Tägliches Quran-Ziel", "en": "Daily Quran Goal", "ar": "هدف القرآن اليومي", "tr": "Günlük Kuran Hedefi", "id": "Target Al-Qur'an Harian", "ms": "Sasaran Al-Quran Harian", "fr": "Objectif quotidien du Coran", "es": "Objetivo diario del Corán", "ur": "یومیہ قرآن کا ہدف", "ru": "Ежедневная цель по Корану", "bn": "দৈনিক কুরআন লক্ষ্য", "fa": "هدف روزانه قرآن", "ha": "Burin Alkur'ani na yau", "jv": "Target Al-Qur'an Saben Dina", "ku": "Hedefa Quranê ya Rojane", "pa": "ਰੋਜ਼ਾਨਾ ਕੁਰਾਨ ਟੀਚਾ", "ps": "ورځنی د قرآن هدف", "so": "Hadafka Quraanka ee Maalinlaha ah", "sw": "Lengo la Kila Siku la Kurani", "uz": "Kundalik Qur'on maqsadi"],
        "onboarding_page3_desc": ["de": "Scrollst du im Quran nach unten, wird dein Lesefluss automatisch in Echtzeit erfasst.", "en": "As you scroll down in the Quran, your reading flow is automatically tracked in real time.", "ar": "أثناء التمرير لأسفل في القرآن، يتم تتبع تدفق قراءتك تلقائيًا في الوقت الفعلي.", "tr": "Kuran'da aşağı kaydırdıkça, okuma akışınız gerçek zamanlı olarak otomatik takip edilir.", "id": "Saat Anda menggeser ke bawah di Al-Qur'an, alur membaca Anda dilacak secara otomatis secara real-time.", "ms": "Semasa anda menatal ke bawah dalam Al-Quran, aliran bacaan anda dijejak secara automatik dalam masa nyata.", "fr": "Lorsque vous défilez vers le bas dans le Coran, votre flux de lecture est suivi automatiquement en temps réel.", "es": "Al desplazarte hacia abajo en el Corán, tu flujo de lectura se rastrea automáticamente en tiempo real.", "ur": "قرآن میں نیچے سکرول کرتے ہوئے، آپ کے پڑھنے کا بہاؤ حقیقی وقت میں خودکار طور پر ٹریک ہوتا ہے۔", "ru": "При прокрутке Корана вниз ваш поток чтения автоматически отслеживается в реальном времени.", "bn": "কুরআনে নিচে স্ক্রোল করার সাথে সাথে আপনার পড়ার ধারা রিয়েল-টাইমে স্বয়ংক্রিয়ভাবে ট্র্যাক হয়.", "fa": "با اسکرول به پایین در قرآن، روند مطالعه شما به طور خودکار و زنده ثبت می‌شود.", "ha": "Yayin da kake gungurar ƙasa a Alkur'ani, ana bin karatunka ta atomatik a ainihin lokacin.", "jv": "Nalika sampeyan nggulung mudhun ing Al-Qur'an, alur moco sampeyan dilacak kanthi otomatis ing waktu nyata.", "ku": "Gava ku hûn di Quranê de ber bi jêr ve biçin, herikîna xwendina we di dema rast de bi otomatîk tê şopandin.", "pa": "ਜਿਵੇਂ ਹੀ ਤੁਸੀਂ ਕੁਰਾਨ ਵਿੱਚ ਹੇਠਾਂ ਸਕ੍ਰੋਲ ਕਰਦੇ ਹੋ, ਤੁਹਾਡਾ ਪੜ੍ਹਨ ਦਾ ਪ੍ਰਵਾਹ ਆਟੋਮੈਟਿਕਲੀ ਰੀਅਲ ਟਾਈਮ ਵਿੱਚ ਟਰੈਕ ਹੁੰਦਾ ਹੈ।", "ps": "کله چې تاسو په قرآن کې ښکته سکرول کوئ، ستاسو د لوستلو جریان په ریښتیني وخت کې خپلکار تعقیب کیږي.", "so": "Markaad hoos u duubto Quraanka, socodka akhriskaaga waxaa toos looga raadraacaa waqtiga dhabta ah.", "sw": "Unaposogeza chini kwenye Kurani, mtiririko wako wa kusoma unafuatiliwa kiotomatiki kwa wakati halisi.", "uz": "Qur'onda pastga aylantirganingizda, o'qish oqimingiz real vaqt rejimida avtomatik ravishda kuzatib boriladi."],
        "onboarding_page3_title": ["de": "Quran & Automatisches Tracking", "en": "Quran & Automatic Tracking", "ar": "القرآن والتتبع التلقائي", "tr": "Kuran ve Otomatik Takip", "id": "Al-Qur'an & Pelacakan Otomatis", "ms": "Al-Quran & Penjejakan Automatik", "fr": "Coran & Suivi Automatique", "es": "Corán y Seguimiento Automático", "ur": "قرآن اور خودکار ٹریکنگ", "ru": "Коран и авто-отслеживание", "bn": "কুরআন ও স্বয়ংক্রিয় ট্র্যাকিং", "fa": "قرآن و ردیابی خودکار", "ha": "Alkur'ani & Bi da kansa", "jv": "Al-Qur'an & Pelacakan Otomatis", "ku": "Quran û Şopandina Otomatîk", "pa": "ਕੁਰਾਨ ਅਤੇ ਆਟੋਮੈਟਿਕ ਟ੍ਰੈਕਿੰਗ", "ps": "قرآن او خپلکار تعقیب", "so": "Quraanka & Raadraaca Otomaatigga ah", "sw": "Kurani na Ufuatiliaji wa Kiotomatiki", "uz": "Qur'on va avtomatik kuzatuv"],
        "onboarding_page2_btn": ["de": "Weiter", "en": "Next", "ar": "التالي", "tr": "Devam Et", "id": "Lanjutkan", "ms": "Teruskan", "fr": "Continuer", "es": "Continuar", "ur": "آگے بڑھیں", "ru": "Далее", "bn": "পরবর্তী", "fa": "ادامه", "ha": "Ci gaba", "jv": "Banjurake", "ku": "Berdewam bibe", "pa": "ਅੱਗੇ ਵਧੋ", "ps": "دوام ورکړئ", "so": "Sii wad", "sw": "Endelea", "uz": "Davom etish"],
        "onboarding_page2_desc": ["de": "Dein Tag beginnt traditionell mit Maghrib, nicht um Mitternacht. Dafür reicht dein grober Standort – ohne Freigabe gilt Mitternacht als Fallback.", "en": "Your day traditionally begins at Maghrib, not midnight. Your approximate location is enough – without permission, midnight is used as a fallback.", "ar": "يبدأ يومك تقليدياً مع المغرب وليس منتصف الليل. يكفي موقعك التقريبي – بدون إذنه، يُستخدم منتصف الليل كبديل.", "tr": "Gününüz gece yarısı değil, geleneksel olarak Akşam vakti başlar. Yaklaşık konumunuz yeterlidir – izin verilmezse varsayılan gece yarısıdır.", "id": "Hari Anda secara tradisional dimulai saat Maghrib, bukan tengah malam. Perkiraan lokasi Anda cukup – tanpa izin, tengah malam digunakan sebagai fallback.", "ms": "Hari anda bermula pada waktu Maghrib, bukan tengah malam. Lokasi anggaran anda mencukupi – tanpa kebenaran, tengah malam digunakan sebagai fallback.", "fr": "Votre journée commence traditionnellement au Maghrib, pas à minuit. Votre position approximative suffit – sans autorisation, minuit sert de repli.", "es": "Tu día comienza tradicionalmente en Maghrib, no a medianoche. Tu ubicación aproximada es suficiente; sin permiso, se usa la medianoche como reserva.", "ur": "آپ کا دن آدھی رات کے بجائے روایتی طور پر مغرب سے شروع ہوتا ہے۔ اس کے لیے آپ کا تخمینی مقام کافی ہے - بغیر اجازت کے آدھی رات کا وقت استعمال ہوگا۔", "ru": "Ваш день традиционно начинается с Магриба, а не в полночь. Достаточно примерного местоположения — без разрешения используется полночь.", "bn": "আপনার দিনটি ঐতিহ্যগতভাবে মাগরিবে শুরু হয়, মধ্যরাতে নয়। আপনার আনুমানিক অবস্থানই যথেষ্ট – অনুমতি ছাড়া মধ্যরাত ব্যবহার করা হবে।", "fa": "روز شما به طور سنتی با مغرب آغاز می‌شود نه نیمه‌شب. موقعیت تقریبی کافی است – بدون اجازه، نیمه‌شب جایگزین است.", "ha": "Ranarku tana farawa ne daga Magriba, ba tsakar dare ba. Wurin ku na ƙiyasta ya wadatar – ba tare da izini ba, tsakar dare za a yi amfani da shi.", "jv": "Dina sampeyan distarts saka Maghrib, dudu tengah wengi. Lokasi kasar sampeyan wis cukup – tanpa izin, tengah wengi dadi fallback.", "ku": "Roja we bi kevneşopî bi Maghribê dest pê dike, ne nîvê şevê. Cihê we yê texmînî bes e – bêî destûr nîvê şevê tê bikaranîn.", "pa": "ਤੁਹਾਡਾ ਦਿਨ ਅੱਧੀ ਰਾਤ ਦੀ ਬਜਾਏ ਮਗਰਿਬ ਤੋਂ ਸ਼ੁਰੂ ਹੁੰਦਾ ਹੈ। ਤੁਹਾਡੀ ਅਨੁਮਾਨਿਤ ਲੋਕੇਸ਼ਨ ਕਾਫੀ ਹੈ - ਇਜਾਜ਼ਤ ਤੋਂ ਬਿਨਾਂ ਅੱਧੀ ਰਾਤ ਵਰਤੀ ਜਾਵੇਗੀ।", "ps": "ستاسو ورځ په روایتی ډول له مغرب څخه پیل کیږي نه له نیمې شپې. ستاسو تقريبي موقعیت کافي دی – له اجازې پرته نیمه شپه کارول کیږي.", "so": "Maalintaadu waxay dhaqan ahaan ka bilaabmataa Maghrib, maaha saqda dhexe. Goobtaada qiyaasta ah waa ku filan tahay.", "sw": "Siku yako huanza wakati wa Maghrib, si katikati ya usiku. Eneo lako la makadirio linatosha – bila ruhusa, katikati ya usiku hutumika.", "uz": "Kuningiz yarim tunda emas, an'anaviy ravishda Shom vaqtida boshlanadi. Taxminiy joylashuvingiz yetarli – ruxsatsiz yarim tun ishlatiladi."],
        "onboarding_page2_title": ["de": "Im Rhythmus der Sunnah", "en": "Rhythm of the Sunnah", "ar": "على إيقاع السنة", "tr": "Sünnetin Ritmi", "id": "Irama Sunnah", "ms": "Irama Sunnah", "fr": "Rythme de la Sunna", "es": "Ritmo de la Sunnah", "ur": "سنت کی تال", "ru": "Ритм Сунны", "bn": "সুন্নাহর তাল", "fa": "بر ریتم سنت", "ha": "Motsi na Sunnah", "jv": "Irama Sunnah", "ku": "Rîtma Sünnetê", "pa": "ਸੁੰਨਤ ਦੀ ਲਹਿਰ", "ps": "د سنتو تال", "so": "Tusmada Sunnada", "sw": "Mfumo wa Sunnah", "uz": "Sunnat maromi"],
        "onboarding_page1_desc": ["de": "Verfolge deinen Quran-Fortschritt, deine Adhkar und deine Tasbih – alles an einem Ort.", "en": "Track your Quran progress, your Adhkar, and your Tasbih – all in one place.", "ar": "تابع تقدمك في القرآن، وأذكارك، وتسبيحك – كل ذلك في مكان واحد.", "tr": "Kuran ilerlemenizi, zikirlerinizi ve tesbihinizi tek bir yerden takip edin.", "id": "Lacak kemajuan Al-Qur'an, Adzkar, dan Tasbih Anda – semuanya di satu tempat.", "ms": "Jejak kemajuan Al-Quran, Zikir, dan Tasbih anda – semuanya di satu tempat.", "fr": "Suivez votre progression dans le Coran, vos Adhkar et votre Tasbih – le tout au même endroit.", "es": "Sigue tu progreso en el Corán, tus Adhkar y tu Tasbih, todo en un solo lugar.", "ur": "اپنے قرآن کی پیشرفت، اذکار اور تسبیح کو ایک ہی جگہ ٹریک کریں۔", "ru": "Отслеживайте свой прогресс в Коране, Азкар и Тасбих — все в одном месте.", "bn": "আপনার কুরআন অগ্রগতি, আজকার এবং তাসবীহ ট্র্যাক করুন – সবই এক জায়গায়।", "fa": "پیشرفت قرآن، اذکار و تسبیح خود را یکجا دنبال کنید.", "ha": "Bi ci gaban Karatun Alkur'ani, Adhkar da Tasbih duka a wuri ɗaya.", "jv": "Lacak kemajuan Al-Qur'an, Dzikir, lan Tasbih sampeyan – kabeh ing siji papan.", "ku": "Pêşveçûna xwe ya Quranê, Zikir û Tesbîha xwe hemû li cihê yek bopêş bixînin.", "pa": "ਆਪਣੀ ਕੁਰਾਨ ਦੀ ਤਰੱਕੀ, ਅਜ਼ਕਾਰ ਅਤੇ ਤਸਬੀਹ ਨੂੰ ਇੱਕੋ ਜਗ੍ਹਾ ਟ੍ਰੈਕ ਕਰੋ।", "ps": "د قرآن پرمختګ، اذکار او تسبیح ټول په یو ځای کې تعقیب کړئ.", "so": "La soco horumarka Quraankaaga, Adkartaada, iyo Tasbiixdaada – dhammaan hal lugar.", "sw": "Fuatilia maendeleo yako ya Kurani, Adhkar na Tasbih – vyote mahali pamoja.", "uz": "Qur'on taraqqiyotingiz, zikrlaringiz va tasbehingizni bir joyda kuzatib boring."],
        "onboarding_page1_title": ["de": "Willkommen bei EmanTrack", "en": "Welcome to EmanTrack", "ar": "مرحباً بك في EmanTrack", "tr": "EmanTrack'e Hoş Geldiniz", "id": "Selamat datang di EmanTrack", "ms": "Selamat datang ke EmanTrack", "fr": "Bienvenue sur EmanTrack", "es": "Bienvenido a EmanTrack", "ur": "EmanTrack میں خوش آمدید", "ru": "Добро пожаловать в EmanTrack", "bn": "EmanTrack-এ স্বাগতম", "fa": "به EmanTrack خوش آمدید", "ha": "Barka da zuwa EmanTrack", "jv": "Sugeng rawuh ing EmanTrack", "ku": "Hûn bi xêr hatin EmanTrack", "pa": "EmanTrack ਵਿੱਚ ਤੁਹਾਡਾ ਸੁਆਗਤ է", "ps": "EmanTrack ته ښه راغلاست", "so": "Ku soo dhowaw EmanTrack", "sw": "Karibu EmanTrack", "uz": "EmanTrack-ga xush kelibsiz"],
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
        "daily_goal_title": ["de": "Tagesziel", "en": "Daily Goal", "ar": "الهدف اليومي"],
        "khatm_title": [
            "de": "Koran abgeschlossen! 🎉", "en": "Quran Completed! 🎉", "ar": "ختم القرآن الكريم 🎉",
            "tr": "Kur'an Tamamlandı! 🎉", "id": "Khatam Al-Qur'an! 🎉", "ms": "Khatam Al-Quran! 🎉",
            "fr": "Coran Terminé ! 🎉", "es": "¡Corán Completado! 🎉", "ur": "قرآن مکمل ہوا! 🎉", "ru": "Коран завершен! 🎉"
        ],
        "khatm_desc": [
            "de": "MashaAllah! Du hast den gesamten Koran gelesen. Möge Allah es von dir annehmen.",
            "en": "MashaAllah! You have completed reading the entire Quran. May Allah accept it from you.",
            "ar": "ماشاء الله! لقد أتممت قراءة القرآن الكريم كاملاً. تقبل الله منك.",
            "tr": "Maşallah! Kur'an-ı Kerim'in tamamını okudunuz. Allah kabul etsin.",
            "id": "MasyaAllah! Anda telah membaca seluruh Al-Qur'an. Semoga Allah menerimanya.",
            "fr": "MashaAllah ! Vous avez terminé la lecture de tout le Coran. Qu'Allah l'accepte."
        ],
        "khatm_button_complete": [
            "de": "Khatm abschließen & neu beginnen",
            "en": "Complete Khatm & Start New",
            "ar": "إتمام الختمة والبدء من جديد",
            "tr": "Hatmi Tamamla ve Yeniden Başla",
            "id": "Selesaikan Khatam & Mulai Baru",
            "fr": "Terminer la Khatm et Recommencer"
        ],
        "stats_khatm_count": [
            "de": "Abgeschlossene Khatm",
            "en": "Completed Khatm",
            "ar": "الختمات المكتملة",
            "tr": "Tamamlanan Hatim",
            "id": "Khatam Selesai",
            "fr": "Khatm Terminées"
        ],
        "daily_goal_pages": ["de": "Tagesziel: %d Seiten", "en": "Daily goal: %d pages", "ar": "الهدف اليومي: %d صفحات"],
        "surah_alkahf": ["de": "Sure Al-Kahf", "en": "Surah Al-Kahf", "ar": "سورة الكهف"],
        "surah_alkahf_desc": ["de": "Freitagslesung (Do Sonnenuntergang bis Fr Sonnenuntergang)", "en": "Recitation on Fridays (Thu sunset to Fri sunset)", "ar": "قراءة الجمعة (من غروب الخميس إلى غروب الجمعة)"],
        "read_now": ["de": "Jetzt lesen", "en": "Read now", "ar": "اقرأ الآن"],
        "done": ["de": "Fertig", "en": "Done", "ar": "تم"],
        "mandatory": ["de": "Obligatorisch", "en": "Mandatory", "ar": "إلزامي"],
        "cancel": ["de": "Abbrechen", "en": "Cancel", "ar": "إلغاء"],
        "add": ["de": "Hinzufügen", "en": "Add", "ar": "إضافة"],
        "amount": ["de": "Anzahl", "en": "Amount", "ar": "العدد"],
        "custom_dhikr": ["de": "Eigene Dhikr", "en": "Custom Dhikr", "ar": "أذكار خاصة"],
        "add_custom_dhikr": ["de": "Eigenen Dhikr hinzufügen", "en": "Add Custom Dhikr", "ar": "إضافة ذكر خاص"],
        "dhikr_details": ["de": "Dhikr-Details", "en": "Dhikr Details", "ar": "تفاصيل الذكر"],
        "title_translation": ["de": "Titel / Übersetzung", "en": "Title / Translation", "ar": "العنوان / الترجمة"],
        "arabic_text_optional": ["de": "Arabischer Text (optional)", "en": "Arabic Text (optional)", "ar": "النص العربي (اختياري)"],
        "transliteration_optional": ["de": "Transliteration (optional)", "en": "Transliteration (optional)", "ar": "اللفظ اللاتيني (اختياري)"],
        "new_dhikr": ["de": "Neuer Dhikr", "en": "New Dhikr", "ar": "ذكر جديد"],
        "edit_dhikr": ["de": "Dhikr bearbeiten", "en": "Edit Dhikr", "ar": "تعديل الذكر"],
        "period_week": ["de": "Woche", "en": "Week", "ar": "أسبوع"],
        "period_month": ["de": "Monat", "en": "Month", "ar": "شهر"],
        "calendar_week": ["de": "Kalenderwoche %@", "en": "Week %@", "ar": "الأسبوع %@"],
        "stats_goal": ["de": "Ziel", "en": "Goal", "ar": "الهدف"],
        "stats_days_goal_reached": ["de": "An %d Tagen Ziele erreicht", "en": "Goals reached on %d days", "ar": "تم تحقيق الأهداف في %d أيام"],
        "stats_prev_week": ["de": "letzte Woche", "en": "last week", "ar": "الأسبوع الماضي"],
        "stats_prev_year": ["de": "letztes Jahr", "en": "last year", "ar": "العام الماضي"],
        "stats_no_data": ["de": "Keine Daten vorhanden", "en": "No data available", "ar": "لا توجد بيانات"],
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
        "settings_goals": [
            "de": "Ziele", "en": "Goals", "ar": "الأهداف", "fr": "Objectifs", "es": "Objetivos",
            "ur": "مقاصد", "id": "Target", "tr": "Hedefler", "ru": "Цели", "bn": "লক্ষ্য", "ms": "Sasaran"
        ],
        "settings_general": [
            "de": "Allgemein", "en": "General", "ar": "عام", "fr": "Général", "es": "General",
            "ur": "عام", "id": "Umum", "tr": "Genel", "ru": "Общие", "bn": "সাধারণ", "ms": "Umum"
        ],
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
        "playback_tempo": [
            "de": "Abspielgeschwindigkeit", "en": "Playback Speed", "ar": "سرعة التشغيل",
            "fr": "Vitesse de lecture", "es": "Velocidad de reproducción", "tr": "Oynatma Hızı",
            "ru": "Скорость воспроизведения", "id": "Kecepatan Putar", "ms": "Kelajuan Main Balik",
            "ur": "چلانے کی رفتار", "fa": "سرعت پخش", "bn": "প্লেব্যাক গতি"
        ],
        "tempo_slowest": ["de": "Langsam", "en": "Slow", "ar": "بطيء"],
        "tempo_slow": [
            "de": "Langsam", "en": "Slow", "ar": "بطيء",
            "tr": "Yavaş", "id": "Lambat", "ms": "Perlahan", "fr": "Lent", "es": "Lento",
            "ur": "سست", "ru": "Медленно", "bn": "ধীর", "fa": "آهسته", "ha": "Akwai hankali",
            "jv": "Alon", "ku": "Hêdî", "pa": "ਹੌਲੀ", "ps": "خورا ورو", "so": "Tartiib",
            "sw": "Polepole", "uz": "Dasta-dasta"
        ],
        "tempo_normal": [
            "de": "Normal", "en": "Normal", "ar": "عادي",
            "tr": "Normal", "id": "Normal", "ms": "Normal", "fr": "Normal", "es": "Normal",
            "ur": "معمول", "ru": "Обычный", "bn": "সাধারণ", "fa": "عادی", "ha": "Na al'ada",
            "jv": "Biasa", "ku": "Asayî", "pa": "ਸਧਾਰਨ", "ps": "عادي", "so": "Kawaan",
            "sw": "Kawaida", "uz": "Me'yoriy"
        ],
        "tempo_fast": [
            "de": "Schnell", "en": "Fast", "ar": "سريع",
            "tr": "Hızlı", "id": "Cepat", "ms": "Laju", "fr": "Rapide", "es": "Rápido",
            "ur": "تیز", "ru": "Быстро", "bn": "দ্রুত", "fa": "سریع", "ha": "Sauri",
            "jv": "Cepat", "ku": "Zû", "pa": "ਤੇਜ਼", "ps": "ګړندی", "so": "Daqsi",
            "sw": "Haraka", "uz": "Tez"
        ],
        "tempo_fastest": ["de": "Schnell", "en": "Fast", "ar": "سريع"],
        "fajr_sec": ["de": "Fajr", "en": "Fajr", "ar": "الفجر"],
        "color_green": ["de": "Grün", "en": "Green", "ar": "أخضر"],
        "color_blue": ["de": "Blau", "en": "Blue", "ar": "أزرق"],
        "color_amber": ["de": "Gold", "en": "Amber", "ar": "ذهبي"],
        "color_purple": ["de": "Violett", "en": "Purple", "ar": "بنفسجي"],
        "color_crimson": ["de": "Rot", "en": "Crimson", "ar": "أحمر"],
        "reader_background": [
            "de": "Hintergrund", "en": "Background", "ar": "الخلفية", "fr": "Arrière-plan",
            "es": "Fondo", "tr": "Arka Plan", "ru": "Фон", "id": "Latar Belakang",
            "ms": "Latar Belakang", "ur": "پس منظر", "fa": "پس‌زمینه", "bn": "পটভূমি"
        ],
        "theme": [
            "de": "Lesethema", "en": "Theme", "ar": "المظهر", "fr": "Thème",
            "es": "Tema", "tr": "Tema", "ru": "Тема", "id": "Tema"
        ],
        "theme_system": [
            "de": "System", "en": "System", "ar": "النظام", "fr": "Système",
            "es": "Sistema", "tr": "Sistem", "ru": "Системный", "id": "Sistem",
            "ms": "Sistem", "ur": "سسٹم"
        ],
        "theme_light": [
            "de": "Hell", "en": "Light", "ar": "فاتح", "fr": "Clair",
            "es": "Claro", "tr": "Açık", "ru": "Светлый", "id": "Terang", "ms": "Cerah"
        ],
        "theme_sepia": [
            "de": "Sepia", "en": "Sepia", "ar": "سيبيا", "fr": "Sépia",
            "es": "Sepia", "tr": "Sepya", "ru": "Сепия", "id": "Sepia", "ms": "Sepia"
        ],
        "theme_dark": [
            "de": "Dunkel", "en": "Dark", "ar": "داكن", "fr": "Sombre",
            "es": "Oscuro", "tr": "Koyu", "ru": "Тёмный", "id": "Gelap", "ms": "Gelap"
        ],
        "preview": [
            "de": "Vorschau", "en": "Preview", "ar": "معاينة", "fr": "Aperçu",
            "es": "Vista previa", "tr": "Önizleme", "ru": "Предпросмотр", "id": "Pratinjau",
            "ms": "Pratonton", "ur": "پیش نظارہ"
        ],
        "fajr_settings_info_title": [
            "de": "Wichtiger Hinweis zum Wecker", "en": "Important Alarm Information", "ar": "معلومات مهمة المنبه",
            "fr": "Information importante sur l'alarme", "es": "Información importante de la alarma",
            "tr": "Önemli Alarm Bilgisi", "ru": "Важная информация о будильнике",
            "id": "Informasi Alarm Penting", "ms": "Maklumat Penggera Penting", "ur": "الارم کی اہم معلومات"
        ],
        "fajr_settings_info_desc": [
            "de": "Damit der Fajr-Wecker auch im Stumm- oder Nicht-Stören-Modus zuverlässig klingelt, erlaube bitte Mitteilungen und Kritische Hinweise in den iOS-Einstellungen.",
            "en": "To ensure the Fajr alarm rings reliably even in Silent or Do Not Disturb mode, please enable Notifications and Critical Alerts in iOS Settings.",
            "ar": "لضمان رنين منبه الفجر بانتظام حتى في وضع الصامت أو عدم الإزعاج، يرجى تفعيل الإشعارات والتنبيهات الهامة في إعدادات iOS.",
            "fr": "Pour vous assurer que l'alarme du Fajr sonne même en mode Silencieux ou Ne pas déranger, veuillez activer les Notifications et les Alertes Critiques dans les réglages iOS.",
            "es": "Para garantizar que la alarma de Fajr suene de forma fiable incluso en modo Silencio o No molestar, activa las Notificaciones y Alertas Críticas en los Ajustes de iOS.",
            "tr": "Fajr alarmının Sessiz veya Rahatsız Etmeyin modunda bile güvenilir bir şekilde çalmasını sağlamak için lütfen iOS Ayarlarında Bildirimleri ve Kritik Uyarıları etkinleştirin.",
            "ru": "Чтобы будильник Фаджр надёжно срабатывал даже в бесшумном режиме или режиме «Не беспокоить», включите уведомления и критические предупреждения в настройках iOS.",
            "id": "Agar alarm Fajr berbunyi dengan andal bahkan dalam mode Hening atau Jangan Ganggu, aktifkan Pemberitahuan dan Peringatan Kritis di Pengaturan iOS.",
            "ms": "Bagi memastikan penggera Fajr berbunyi walaupun dalam mod Senyap atau Jangan Ganggu, sila benarkan Pemberitahuan dan Amaran Kritikal dalam Tetapan iOS.",
            "ur": "فجر کا الارم خاموش یا ڈسٹرب نہ کریں موڈ میں بھی باقاعدگی سے بجنے کے لیے، براہ کرم iOS ترتیبات میں اطلاعات اور تنبیہات کو فعال کریں۔"
        ],
        "fajr_settings_open_ios_settings": [
            "de": "iOS-Einstellungen öffnen", "en": "Open iOS Settings", "ar": "فتح إعدادات iOS",
            "fr": "Ouvrir les réglages iOS", "es": "Abrir Ajustes de iOS", "tr": "iOS Ayarlarını Aç",
            "ru": "Открыть настройки iOS", "id": "Buka Pengaturan iOS", "ms": "Buka Tetapan iOS", "ur": "iOS ترتیبات کھولیں"
        ],
        "fajr_alarm_next_prefix_dynamic": [
            "de": "Nächster Alarm:", "en": "Next alarm:", "ar": "المنبه القادم:",
            "fr": "Prochaine alarme :", "es": "Próxima alarma:", "tr": "Sonraki alarm:",
            "ru": "Следующий будильник:", "id": "Alarm berikutnya:", "ms": "Penggera seterusnya:", "ur": "اگلا الارم:"
        ],
        "today": [
            "de": "Heute", "en": "Today", "ar": "اليوم", "fr": "Aujourd'hui",
            "es": "Hoy", "tr": "Bugün", "ru": "Сегодня", "id": "Hari ini", "ms": "Hari ini", "ur": "آج"
        ],
        "tomorrow": [
            "de": "Morgen", "en": "Tomorrow", "ar": "غداً", "fr": "Demain",
            "es": "Mañana", "tr": "Yarın", "ru": "Завтра", "id": "Besok", "ms": "Esok", "ur": "کل"
        ],
        "adhkar_time_expired": [
            "de": "Die Zeit für diese Adhkar ist bereits abgelaufen.",
            "en": "The time for these Adhkar has expired.",
            "ar": "لقد انتهى وقت هذه الأذكار.",
            "fr": "Le temps pour ces Adhkar est écoulé.",
            "es": "El tiempo para estos Adhkar ha expirado.",
            "tr": "Bu Zikirler için süre doldu.",
            "ru": "Время для этих Азкаров истекло.",
            "id": "Waktu untuk Adhkar ini telah berakhir.",
            "ms": "Masa untuk Adhkar ini telah tamat.",
            "ur": "ان اذکار کا وقت ختم ہو چکا ہے۔"
        ],
        "mark_as_read_retro": [
            "de": "Nachträglich als gelesen markieren",
            "en": "Mark as read retrospectively",
            "ar": "تحديد كمقروء لاحقاً",
            "fr": "Marquer comme lu rétrospectivement",
            "es": "Marcar como leído retrospectivamente",
            "tr": "Geriye dönük okundu olarak işaretle",
            "ru": "Отметить как прочитанное",
            "id": "Tandai telah dibaca",
            "ms": "Tanda sebagai telah dibaca",
            "ur": "پڑھا ہوا نشان زد کریں"
        ],
        "today_day_counter": [
            "de": "Tag %@", "en": "Day %@", "ar": "اليوم %@", "tr": "Gün %@",
            "id": "Hari ke-%@", "ms": "Hari ke-%@", "fr": "Jour %@", "es": "Día %@",
            "ur": "دن %@", "ru": "День %@", "bn": "দিন %@", "fa": "روز %@",
            "ha": "Rana %@", "jv": "Dina ke-%@", "ku": "Roja %@", "pa": "ਦਿਨ %@",
            "ps": "ورځ %@", "so": "Maalinta %@", "sw": "Siku ya %@", "uz": "Kun %@"
        ],
        "settings_feedback": [
            "de": "Feedback & Bewertung", "en": "Feedback & Rating", "ar": "التقييم والملاحظات",
            "tr": "Geri Bildirim ve Değerlendirme", "id": "Umpan Balik & Penilaian", "ms": "Maklum Balas & Penilaian",
            "fr": "Avis et Évaluation", "es": "Comentarios y Valoración", "ur": "رائے اور درجہ بندی",
            "ru": "Отзывы и оценка", "bn": "মতামত ও রেটিং"
        ],
        "rate_app": [
            "de": "App bewerten", "en": "Rate App", "ar": "تقييم التطبيق",
            "tr": "Uygulamayı Değerlendir", "id": "Beri Rating Aplikasi", "ms": "Nilaikan Aplikasi",
            "fr": "Évaluer l'application", "es": "Valorar la aplicación", "ur": "ایپ کی درجہ بندی کریں",
            "ru": "Оценить приложение", "bn": "অ্যাপ রেট করুন", "fa": "امتیاز به برنامه",
            "ha": "Kimanta Application", "jv": "Basa Rating Aplikasi", "ku": "Serîlêdanê Bilind Bikin",
            "pa": "ਐਪ ਨੂੰ ਦਰਜਾ ਦਿਓ", "ps": "اپلیکیشن ته درجه ورکړئ", "so": "U qiimee App-ka",
            "sw": "Kadiria Programu", "uz": "Ilovani baholash"
        ],
        "adhkar_done_reading": [
            "de": "Fertig gelesen", "en": "Done reading", "ar": "إتمام القراءة",
            "tr": "Okuma Tamamlandı", "id": "Selesai Membaca", "ms": "Selesai Membaca",
            "fr": "Lecture terminée", "es": "Lectura completada", "ur": "پڑھنا مکمل ہوا",
            "ru": "Чтение завершено", "bn": "পড়া শেষ", "fa": "پایان خواندن",
            "ha": "An gama karatu", "jv": "Rampung moco", "ku": "Xwendin bi dawî bû",
            "pa": "ਪੜ੍ਹਨਾ ਪੂਰਾ ਹੋਇਆ", "ps": "لوستل پای ته ورسېدل", "so": "Akhrisku waa dhamaaday",
            "sw": "Umesoma tayari", "uz": "O'qish yakunlandi"
        ]
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
        
        // 1. Ersetze Standard-Sukun (U+0652) durch das koranische Sukun-Zeichen (U+06E1 - kleine Khah-Kopfform)
        cleaned = cleaned.replacingOccurrences(of: "\u{0652}", with: "\u{06E1}")
        
        // 2. Entferne schwarze/ausgefüllte Kreise und Dotted Circles (U+06DF, U+06E0, U+25CC),
        // da sie auf iOS als störende schwarze Punkte (z. B. auf 'أُولَـٰٓئِكَ') dargestellt werden.
        cleaned = cleaned.replacingOccurrences(of: "\u{06DF}", with: "")
        cleaned = cleaned.replacingOccurrences(of: "\u{06E0}", with: "")
        cleaned = cleaned.replacingOccurrences(of: "\u{25CC}", with: "")
        
        // 3. Positionierungs-Fix: Ersetze Tatweel (U+0640) + Dagger Alif (U+0670) durch einfaches Dagger Alif,
        // um das Verrutschen des Dagger Alif auf das Folgezeichen (z.B. bei 'Ar-Rahman') zu verhindern.
        cleaned = cleaned.replacingOccurrences(of: "\u{0640}\u{0670}", with: "\u{0670}")
        cleaned = cleaned.replacingOccurrences(of: "\u{064E}\u{0640}\u{0670}", with: "\u{064E}\u{0670}")
        
        return cleaned
    }
}