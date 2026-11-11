import Foundation

struct AdhkarItem: Identifiable {
    let id = UUID()
    let arabic: String
    let transliteration: String
    let german: String
    let english: String
    let count: Int
    let linkedTasbihCategory: TasbihCategory?
    var isMandatory: Bool
    var customSpeedStep: Int = 1
    let quickInterval: TimeInterval?
    let normalInterval: TimeInterval?
    let slowInterval: TimeInterval?
    var audioFileName: String? = nil

    init(arabic: String, transliteration: String = "", german: String, english: String = "", count: Int, linkedTasbihCategory: TasbihCategory? = nil, isMandatory: Bool = true, customSpeedStep: Int = 1, quickInterval: TimeInterval? = nil, normalInterval: TimeInterval? = nil, slowInterval: TimeInterval? = nil, audioFileName: String? = nil) {
        self.arabic = arabic
        self.transliteration = transliteration
        self.german = german
        self.english = english
        self.count = count
        self.linkedTasbihCategory = linkedTasbihCategory
        self.isMandatory = isMandatory
        self.customSpeedStep = customSpeedStep
        self.quickInterval = quickInterval
        self.normalInterval = normalInterval
        self.slowInterval = slowInterval
        self.audioFileName = audioFileName
    }

    var defaultBpm: Int {
        let normal = normalInterval ?? 2.0
        let bpm = Int(round(60.0 / normal))
        return max(40, bpm)
    }

    var currentBpm: Int {
        if customSpeedStep > 2 {
            return max(40, customSpeedStep)
        }
        let slowVal = slowInterval ?? ((normalInterval ?? 2.0) * 1.184)
        let normalVal = normalInterval ?? 2.0
        let quickVal = quickInterval ?? ((normalInterval ?? 2.0) * 0.816)
        let sec: TimeInterval
        switch customSpeedStep {
        case 0: sec = slowVal
        case 1: sec = normalVal
        case 2: sec = quickVal
        default: sec = normalVal
        }
        let bpm = Int(round(60.0 / sec))
        return max(40, bpm)
    }
}

let morgenAdhkar: [AdhkarItem] = [
    // 1. Ayat al-Kursi
    AdhkarItem(
        arabic: "اللَّهُ لاَ إِلَهَ إِلاَّ هُوَ الْحَيُّ الْقَيُّومُ لاَ تَأْخُذُهُ سِنَةٌ وَلاَ نَوْمٌ لَّهُ مَا فِي السَّمَوَاتِ وَمَا فِي الأَرْضِ مَن ذَا الَّذِي يَشْفَعُ عِنْدَهُ إِلاَّ بِإِذْنِهِ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ وَلاَ يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلاَّ بِمَا شَاء وَسِعَ كُرْسِيُّهُ السَّمَوَاتِ وَالْأَرْضَ وَلاَ يَؤُودُهُ حِفْظُهُمَا وَهُوَ الْعَلِيُّ الْعَظِيمُ",
        transliteration: "Allahu la ilaha illa Huwal-Hayyul-Qayyum. La ta'khudhuhu sinatun wa la nawm. Lahu ma fis-samawati wa ma fil-ard. Man dhal-ladhi yashfa'u 'indahu illa bi-idhnih. Ya'lamu ma bayna aydihim wa ma khalfahum. Wa la yuhituna bi-shay'im-min 'ilmihi illa bima sha'. Wasi'a kursiyyuhus-samawati wal-ard, wa la ya'uduhu hifdhuhuma, wa Huwal-'Aliyyul-'Adheem.",
        german: "Allah – es gibt keinen Gott außer Ihm, dem Lebendigen und Beständigen. Ihn überkommt weder Schlummer noch Schlaf. Ihm gehört, was in den Himmeln und was auf der Erde ist. Wer ist es, der bei Ihm Fürsprache einlegen könnte außer mit Seiner Erlaubnis? Er weiß, was vor ihnen und was hinter ihnen liegt; sie aber begreifen nichts von Seinem Wissen, es sei denn das, was Er will. Sein Thronschemel umfasst die Himmel und die Erde, und ihre Bewahrung beschwert Ihn nicht. Und Er ist der Erhabene, der Allgewaltige.",
        english: "Allah! There is no deity except Him, the Ever-Living, the Sustainer of all existence. Neither drowsiness overtakes Him nor sleep. To Him belongs whatever is in the heavens and whatever is on the earth. Who is it that can intercede with Him except by His permission? He knows what is presently before them and what will be after them, and they encompass not a thing of His knowledge except for what He wills. His Kursi extends over the heavens and the earth, and their preservation tires Him not. And He is the Most High, the Most Great.",
        count: 1,
        quickInterval: 15.52, normalInterval: 19.02, slowInterval: 22.52,
        audioFileName: "quran_ayat_kursi"),
    // 2. Sure Al-Ikhlas
    AdhkarItem(
        arabic: "بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ. قُلْ هُوَ اللَّهُ أَحَدٌ، اللَّهُ الصَّمَدُ، لَمْ يَلِدْ وَلَمْ يُولَدْ، وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ",
        transliteration: "Bismillahir-Rahmanir-Rahim. Qul Huwallahu Ahad. Allahus-Samad. Lam yalid wa lam yulad. Wa lam yakul-lahu kufuwan ahad.",
        german: "Im Namen Allahs, des Allerbarmers, des Barmherzigen. Sprich: Er ist Allah, ein Einziger, Allah, der Überlegene. Er hat nicht gezeugt und ist nicht gezeugt worden, und niemand ist Ihm jemals gleich.",
        english: "In the Name of Allah, the Most Gracious, the Most Merciful. Say: He is Allah, (who is) One, Allah, the Eternal Refuge. He neither begets nor is born, nor is there to Him any equivalent.",
        count: 3,
        quickInterval: 5.79, normalInterval: 7.09, slowInterval: 8.39,
        audioFileName: "quran_ikhlas"),
    // 3. Sure Al-Falaq
    AdhkarItem(
        arabic: "بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ. قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ، مِن شَرِّ مَا خَلَقَ، وَمِن شَرِّ غَاسِقٍ إِذَا وَقَبَ، وَمِن شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ، وَمِن شَرِّ حَاسِدٍ إِذَا حَسَدَ",
        transliteration: "Bismillahir-Rahmanir-Rahim. Qul a'udhu bi Rabbil-falaq. Min sharri ma khalaq. Wa min sharri ghasiqin idha waqab. Wa min sharrin-naffathati fil-'uqad. Wa min sharri hasidin idha hasad.",
        german: "Im Namen Allahs, des Allerbarmers, des Barmherzigen. Sprich: Ich nehme Zuflucht beim Herrn des Frühlichts, vor dem Übel dessen, was Er erschaffen hat, und vor dem Übel der Dunkelheit, wenn sie hereinbricht, und vor dem Übel der Knotenbläserinnen, und vor dem Übel eines Neiders, wenn er neidet.",
        english: "In the Name of Allah, the Most Gracious, the Most Merciful. Say: I seek refuge in the Lord of daybreak, from the evil of that which He created, and from the evil of darkness when it settles, and from the evil of the blowers in knots, and from the evil of an envier when he envies.",
        count: 3,
        quickInterval: 8.09, normalInterval: 9.91, slowInterval: 11.73,
        audioFileName: "quran_falaq"),
    // 4. Sure An-Nas
    AdhkarItem(
        arabic: "بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ. قُلْ أَعُوذُ بِرَبِّ النَّاسِ، مَلِكِ النَّاسِ، إِلَٰهِ النَّاسِ، مِن شَرِّ الْوَسْوَاسِ الْخَنَّاسِ، الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ، مِنَ الْجِنَّةِ وَالنَّاسِ",
        transliteration: "Bismillahir-Rahmanir-Rahim. Qul a'udhu bi Rabbin-nas. Malikin-nas. Ilahin-nas. Min sharril-waswasil-khannas. Alladhi yuwaswisu fi sudurin-nas. Minal-jinnati wan-nas.",
        german: "Im Namen Allahs, des Allerbarmers, des Barmherzigen. Sprich: Ich nehme Zuflucht beim Herrn der Menschen, dem König der Menschen, dem Gott der Menschen, vor dem Übel des Einflüsterers, der entweicht und wiederkehrt, der den Menschen in die Brüste einflüstert, von den Dschinn und den Menschen.",
        english: "In the Name of Allah, the Most Gracious, the Most Merciful. Say: I seek refuge in the Lord of mankind, the Sovereign of mankind, the God of mankind, from the evil of the retreating whisperer, who whispers into the breasts of mankind, from among the jinn and mankind.",
        count: 3,
        quickInterval: 8.42, normalInterval: 10.32, slowInterval: 12.22,
        audioFileName: "quran_nas"),
    // 5. Asbahna wa asbaha al-mulku lillah
    AdhkarItem(
        arabic: "أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَذَا الْيَوْمِ وَخَيْرَ مَا بَعْدَهُ، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَذَا الْيَوْمِ وَشَرِّ مَا بَعْدَهُ، رَبِّ أَعُوذُ بِكَ مِنَ الْكَسَلِ وَسُوءِ الْكِبَرِ، رَبِّ أَعُوذُ بِكَ مِنْ عَذَابٍ فِي النَّارِ وَعَذَابٍ فِي الْقَبْرِ",
        transliteration: "Asbahna wa asbahal-mulku lillah, walhamdulillah. La ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamd, wa Huwa 'ala kulli shay'in Qadir. Rabbi as'aluka khayra ma fi hadhal-yawm wa khayra ma ba'dah, wa a'udhu bika min sharri ma fi hadhal-yawm wa sharri ma ba'dah. Rabbi a'udhu bika minal-kasali wa su'il-kibar. Rabbi a'udhu bika min 'adhabin fin-nari wa 'adhabin fil-qabr.",
        german: "Wir haben den Morgen erreicht, und die Herrschaft gehört Allah. Alles Lob gebührt Allah. Es gibt keinen Gott außer Allah, dem Einzigen, der keinen Teilhaber hat. Ihm gehört die Herrschaft und Ihm gebührt das Lob, und Er ist über alle Dinge mächtig. Mein Herr, ich bitte Dich um das Gute dieses Tages und um das Gute, das danach kommt. Und ich suche Zuflucht bei Dir vor dem Übel dieses Tages und dem Übel, das danach kommt. Mein Herr, ich suche Zuflucht bei Dir vor Faulheit und einem schlechten Alter. Mein Herr, ich suche Zuflucht bei Dir vor der Strafe im Höllenfeuer und der Strafe im Grab.",
        english: "We have reached the morning and at this very time unto Allah belongs all sovereignty, and all praise is for Allah. None has the right to be worshipped except Allah, alone, without partner, to Him belongs all sovereignty and praise and He is over all things omnipotent. My Lord, I ask You for the good of this day and the good of what follows it and I take refuge in You from the evil of this day and the evil of what follows it. My Lord, I take refuge in You from laziness and senility. My Lord, I take refuge in You from torment in the Fire and punishment in the grave.",
        count: 1,
        quickInterval: 17.82, normalInterval: 21.84, slowInterval: 25.86),
    // 6. Allahumma bika asbahna
    AdhkarItem(
        arabic: "اللَّهُمَّ بِكَ أَصْبَحْنَا، وَبِكَ أَمْسَيْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتْ، وَإِلَيْكَ النُّشُورْ",
        transliteration: "Allahumma bika asbahna, wa bika amsayna, wa bika nahya, wa bika namut, wa ilaykan-nushur.",
        german: "O Allah, durch Dich haben wir den Morgen erreicht, und durch Dich haben wir den Abend erreicht. Durch Dich leben wir, und durch Dich sterben wir, und zu Dir ist die Auferstehung.",
        english: "O Allah, by You we enter the morning and by You we enter the evening, by You we live and by You we die, and to You is the Final Return.",
        count: 1,
        quickInterval: 3.95, normalInterval: 4.84, slowInterval: 5.73),
    // 7. Sayyidul Istighfar
    AdhkarItem(
        arabic: "اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلاَّ أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لاَ يَغْفِرُ الذُّنوبَ إِلاَّ أَنْتَ",
        transliteration: "Allahumma Anta Rabbi la ilaha illa Ant. Khalaqtani wa ana 'abduka, wa ana 'ala 'ahdika wa wa'dika ma-stata't. A'udhu bika min sharri ma sana't. Abu'u laka bi-ni'matika 'alayy, wa abu'u bi-dhanbi fa-ghfir li, fa-innahu la yaghfiru-dh-dhunuba illa Ant.",
        german: "O Allah, Du bist mein Herr. Es gibt keinen Gott außer Dir. Du hast mich erschaffen, und ich bin Dein Diener. Ich halte mich an Deinen Bund und Dein Versprechen, so gut ich kann. Ich suche Zuflucht bei Dir vor dem Übel, das ich begangen habe. Ich bekenne mich zu Deinen Gnaden über mich, und ich bekenne mich zu meiner Sünde. So vergib mir, denn niemand vergibt die Sünden außer Dir.",
        english: "O Allah, You are my Lord, there is none worthy of worship but You. You created me and I am Your slave. I keep Your covenant, and my pledge to You so far as I am able. I seek refuge in You from the evil of what I have done. I admit to Your blessings upon me, and I admit to my misdeeds. Forgive me, for there is none who may forgive sins but You.",
        count: 1,
        linkedTasbihCategory: .istighfar
        , quickInterval: 10.47, normalInterval: 12.97, slowInterval: 15.47),
    // 8. Allahumma inni asbahtu ushhiduka
    AdhkarItem(
        arabic: "اللَّهُمَّ إِنِّي أَصْبَحْتُ أُشْهِدُكَ، وَأُشْهِدُ حَمَلَةَ عَرْشِكَ، وَمَلاَئِكَتِكَ، وَجَمِيعَ خَلْقِكَ، أَنَّكَ أَنْتَ اللَّهُ لَا إِلَهَ إِلاَّ أَنْتَ وَحْدَكَ لاَ شَرِيكَ لَكَ، وَأَنَّ مُحَمَّداً عَبْدُكَ وَرَسُولُكَ",
        transliteration: "Allahumma inni asbahtu ushhiduka, wa ushhidu hamalata 'arshika, wa mala'ikatika, wa jami'a khalqika, annaka Antallahu la ilaha illa Anta wahdaka la sharika lak, wa anna Muhammadan 'abduka wa rasuluk.",
        german: "O Allah, ich habe den Morgen erreicht und rufe Dich als Zeugen an, ebenso wie die Träger Deines Thrones, Deine Engel und Deine gesamte Schöpfung, dass Du Allah bist, es gibt keinen Gott außer Dir allein, Du hast keinen Teilhaber, und dass Muhammad Dein Diener und Gesandter ist.",
        english: "O Allah, I have entered the morning calling You to witness, and calling the bearers of Your Throne to witness, Your angels and all of Your creation, that You are Allah, none has the right to be worshipped but You alone, without partner, and that Muhammad is Your servant and Messenger.",
        count: 4,
        quickInterval: 8.42, normalInterval: 10.32, slowInterval: 12.22),
    // 9. Allahumma ma asbaha bi min ni'matin
    AdhkarItem(
        arabic: "اللَّهُمَّ مَا أَصْبَحَ بِي مِنْ نِعْمَةٍ أَوْ بِأَحَدٍ مِنْ خَلْقِكْ، فَمِنْكَ وَحْدَكَ لاَ شَرِيكَ لَكَ، فَلَكَ الْحَمْدُ وَلَكَ الشُّكْرُ",
        transliteration: "Allahumma ma asbaha bi min ni'matin aw bi-ahadin min khalqik, fa-minka wahdaka la sharika lak, fa-lakal-hamdu wa lakash-shukr.",
        german: "O Allah, welche Gnade auch immer mich oder eines Deiner Geschöpfe an diesem Morgen erreicht hat, sie ist von Dir allein, Du hast keinen Teilhaber. Dir gebührt alles Lob und Dir gebührt der Dank.",
        english: "O Allah, whatever blessing has been received by me or anyone of Your creation this morning, is from You alone, You have no partner. All praise is for You and thanks is to You.",
        count: 1,
        quickInterval: 5.39, normalInterval: 6.61, slowInterval: 7.83),
    // 10. Allahumma 'afini fi badani
    AdhkarItem(
        arabic: "اللَّهُمَّ عَافِنِي فِي بَدَنِي، اللَّهُمَّ عَافِنِي فِي سَمْعِي، اللَّهُمَّ عَافِنِي فِي بَصَرِي، لاَ إِلَهَ إِلاَّ أَنْتَ. اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْكُفْرِ، وَالفَقْرِ، وَأَعُوذُ بِكَ مِنْ عَذَابِ القَبْرِ، لاَ إِلَهَ إِلاَّ أَنْتَ",
        transliteration: "Allahumma 'afini fi badani, Allahumma 'afini fi sam'i, Allahumma 'afini fi basari, la ilaha illa Ant. Allahumma inni a'udhu bika minal-kufri wal-faqr, wa a'udhu bika min 'adhabil-qabr, la ilaha illa Ant.",
        german: "O Allah, gib mir Gesundheit in meinem Körper. O Allah, gib mir Gesundheit in meinem Gehör. O Allah, gib mir Gesundheit in meinem Augenlicht. Es gibt keinen Gott außer Dir. O Allah, ich suche Zuflucht bei Dir vor dem Unglauben und der Armut. Und ich suche Zuflucht bei Dir vor der Strafe im Grab. Es gibt keinen Gott außer Dir.",
        english: "O Allah, grant my body health. O Allah, grant my hearing health. O Allah, grant my sight health. None has the right to be worshipped but You. O Allah, I take refuge with You from disbelief and poverty, and I take refuge with You from the punishment of the grave. None has the right to be worshipped but You.",
        count: 3,
        quickInterval: 10.06, normalInterval: 12.33, slowInterval: 14.60),
    // 11. Hasbiyallahu
    AdhkarItem(
        arabic: "حَسْبِيَ اللَّهُ لاَ إِلَهَ إِلاَّ هُوَ عَلَيهِ تَوَكَّلتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ",
        transliteration: "Hasbiyallahu la ilaha illa Huwa 'alayhi tawakkaltu wa Huwa Rabbul-'Arshil-'Adheem.",
        german: "Allah genügt mir. Es gibt keinen Gott außer Ihm. Auf Ihn vertraue ich, und Er ist der Herr des gewaltigen Thrones.",
        english: "Allah is sufficient for me. There is none worthy of worship but Him. I have placed my trust in Him, and He is the Lord of the Majestic Throne.",
        count: 7,
        quickInterval: 5.60, normalInterval: 6.85, slowInterval: 8.10),
    // 12. Allahumma inni as'aluka al-'afwa
    AdhkarItem(
        arabic: "اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي الدُّنْيَا وَالآخِرَةِ، اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي دِينِي وَدُنْيَايَ وَأَهْلِي، وَمَالِي، اللَّهُمَّ اسْتُرْ عَوْرَاتِي، وَآمِنْ رَوْعَاتِي، اللَّهُمَّ احْفَظْنِي مِنْ بَينِ يَدَيَّ، وَمِنْ خَلْفِي، وَعَنْ يَمِينِي، وَعَنْ شِمَالِي، وَمِنْ فَوْقِي، وَأَعُوذُ بِعَظَمَتِكَ أَنْ أُغْتَالَ مِنْ تَحْتِي",
        transliteration: "Allahumma inni as'aluka-l-'afwa wal-'afiyata fid-dunya wal-akhirah. Allahumma inni as'aluka-l-'afwa wal-'afiyata fi dini wa dunyaya wa ahli wa mali. Allahumma-stur 'awrati wa amin raw'ati. Allahumma-hfazni min bayni yadayya, wa min khalfi, wa 'an yamini, wa 'an shimali, wa min fawqi, wa a'udhu bi-'adhamatika an ughtala min tahti.",
        german: "O Allah, ich bitte Dich um Vergebung und Wohlergehen im Diesseits und im Jenseits. O Allah, ich bitte Dich um Vergebung und Wohlergehen für meine Religion, mein weltliches Leben, meine Familie und mein Vermögen. O Allah, bedecke meine Blößen und beruhige meine Ängste. O Allah, beschütze mich von vorn, von hinten, von rechts, von links und von oben. Und ich suche Zuflucht bei Deiner Erhabenheit davor, dass ich von unten her meuchlings vernichtet werde.",
        english: "O Allah, I ask You for pardon and well-being in this life and the next. O Allah, I ask You for pardon and well-being in my religious and worldly affairs, and my family and my wealth. O Allah, veil my weaknesses and set at ease my dismay. O Allah, preserve me from the front and from behind and on my right and on my left and from above, and I take refuge with You lest I be swallowed up by the earth.",
        count: 1,
        quickInterval: 15.65, normalInterval: 19.18, slowInterval: 22.71),
    // 13. Allahumma 'alimal-ghaybi
    AdhkarItem(
        arabic: "اللَّهُمَّ عَالِمَ الغَيْبِ وَالشَّهَادَةِ فَاطِرَ السَّمَوَاتِ وَالْأَرْضِ، رَبَّ كُلِّ شَيْءٍ وَمَلِيكَهُ، أَشْهَدُ أَنْ لاَ إِلَهَ إِلاَّ أَنْتَ، أَعُوذُ بِكَ مِنْ شَرِّ نَفْسِي، وَمِنْ شَرِّ الشَّيْطانِ وَشِـرْكِهِ، وَأَنْ أَقْتَرِفَ عَلَى نَفْسِي سُوءاً، أَوْ أَجُرَّهُ إِلَى مُسْلِمٍ",
        transliteration: "Allahumma 'Alimal-ghaybi wash-shahadati Fatiras-samawati wal-ard, Rabba kulli shay'in wa Malikah. Ash-hadu an la ilaha illa Ant. A'udhu bika min sharri nafsi, wa min sharrish-shaytani wa shirkihi, wa an aqtarifa 'ala nafsi su'an, aw ajurrahu ila Muslim.",
        german: "O Allah, Kenner des Verborgenen und des Offenbaren, Schöpfer der Himmel und der Erde, Herr und König von allem. Ich bezeuge, dass es keinen Gott gibt außer Dir. Ich suche Zuflucht bei Dir vor dem Übel meiner eigenen Seele, vor dem Übel des Satans und seiner Verführung zur Beigesellung (Schirk), und davor, dass ich mir selbst Böses antue oder es über einen Muslim bringe.",
        english: "O Allah, Knower of the unseen and the evident, Maker of the heavens and the earth, Lord of all things and their Sovereign, I bear witness that there is none worthy of worship but You. I seek refuge in You from the evil of my soul and from the evil of Satan and his helpers, and (I seek refuge in You) from bringing evil upon my soul or from harming a Muslim.",
        count: 1,
        quickInterval: 11.38, normalInterval: 13.94, slowInterval: 16.50),
    // 14. Bismillah-illadhi la yadurru
    AdhkarItem(
        arabic: "بِسْمِ اللَّهِ الَّذِي لاَ يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلاَ فِي السّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ",
        transliteration: "Bismillahil-ladhi la yadurru ma'as-mihi shay'un fil-ardi wa la fis-sama'i wa Huwas-Sami'ul-'Alim.",
        german: "Im Namen Allahs, mit Dessen Namen nichts auf der Erde oder im Himmel Schaden zufügen kann, und Er ist der Allhörende, der Allwissende.",
        english: "In the Name of Allah, Who with His Name nothing can cause harm in the earth nor in the heavens, and He is the All-Hearing, the All-Knowing.",
        count: 3,
        quickInterval: 4.80, normalInterval: 5.88, slowInterval: 6.96),
    // 15. Radiytu billahi
    AdhkarItem(
        arabic: "رَضِيتُ بِاللَّهِ رَبَّاً، وَبِالْإِسْلاَمِ دِيناً، وَبِمُحَمَّدٍ صلى الله عليه وسلم نَبِيّاً",
        transliteration: "Radiytu billahi Rabban wabil-Islami dinan wa bi-Muhammadin sallallahu 'alayhi wa sallama Nabiyya.",
        german: "Ich bin zufrieden mit Allah als meinem Herrn, mit dem Islam als meiner Religion und mit Muhammad, Allahs Segen und Frieden seien auf ihm, als meinem Propheten.",
        english: "I am pleased with Allah as my Lord, with Islam as my religion and with Muhammad (peace and blessings of Allah be upon him) as my Prophet.",
        count: 3,
        quickInterval: 4.08, normalInterval: 5.00, slowInterval: 5.92),
    // 16. Ya Hayyu ya Qayyum
    AdhkarItem(
        arabic: "يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغيثُ أَصْلِحْ لِي شَأْنِيَ كُلَّهُ وَلاَ تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ",
        transliteration: "Ya Hayyu ya Qayyum bi-rahmatika astaghith, aslih li sha'ni kullahu wa la takilni ila nafsi tarfata 'ayn.",
        german: "O Ewiglebender, O Beständiger, durch Deine Barmherzigkeit rufe ich um Hilfe. Bringe all meine Angelegenheiten in Ordnung und überlasse mich nicht mir selbst, nicht einmal für den Wimpernschlag eines Auges.",
        english: "O Ever Living One, O Sustainer, by Your mercy I call on You to set right all my affairs, do not place me in charge of my soul even for the blinking of an eye.",
        count: 1,
        quickInterval: 4.73, normalInterval: 5.80, slowInterval: 6.87),
    // 17. Asbahna wa asbahal-mulku lillahi rabbil-'alamin
    AdhkarItem(
        arabic: "أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ رَبِّ الْعَالَمِينَ، اللَّهُـمَّ إِنِّي أَسْأَلُكَ خَيْرَ هَذَا الْيَوْمِ فَتْحَهُ، وَنَصْرَهُ، وَنورَهُ، وَبَرَكَتَهُ، وَهُدَاهُ، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِيهِ وَشَرِّ مَا بَعْدَهُ",
        transliteration: "Asbahna wa asbahal-mulku lillahi Rabbil-'alamin. Allahumma inni as'aluka khayra hadhal-yawm: fathahu, wa nasrahu, wa nurahu, wa barakatahu, wa hudahu. Wa a'udhu bika min sharri ma fihi wa sharri ma ba'dah.",
        german: "Wir haben den Morgen erreicht, und die Herrschaft gehört Allah, dem Herrn der Welten. O Allah, ich bitte Dich um das Gute dieses Tages: seinen Erfolg, seinen Sieg, sein Licht, seinen Segen und seine Rechtleitung. Und ich suche Zuflucht bei Dir vor dem Übel, das darin ist, und dem Übel, das danach kommt.",
        english: "We have reached the morning and at this very time unto Allah, Lord of the worlds, belongs all sovereignty. O Allah, I ask You for the good of this day, its victories, its help, its light, its blessings, and its guidance. I take refuge in You from the evil that is in it and from the evil that follows it.",
        count: 1,
        quickInterval: 8.88, normalInterval: 10.88, slowInterval: 12.88),
    // 18. Asbahna 'ala fitratil-Islam
    AdhkarItem(
        arabic: "أَصْبَحْنا عَلَى فِطْرَةِ الْإِسْلاَمِ، وَعَلَى كَلِمَةِ الْإِخْلاَصِ، وَعَلَى دِينِ نَبِيِّنَا مُحَمَّدٍ صلى الله عليه وسلم، وَعَلَى مِلَّةِ أَبِينَا إِبْرَاهِيمَ، حَنِيفاً مُسْلِماً وَمَا كَانَ مِنَ الْمُشرِكِينَ",
        transliteration: "Asbahna 'ala fitratil-Islam, wa 'ala kalimatil-ikhlas, wa 'ala dini Nabiyyina Muhammadin sallallahu 'alayhi wa sallam, wa 'ala millati abina Ibrahima hanifan Musliman wa ma kana minal-mushrikin.",
        german: "Wir haben den Morgen erreicht in der natürlichen Veranlagung des Islam, auf dem Wort der reinen Ergebenheit, auf der Religion unseres Propheten Muhammad, Allahs Segen und Frieden seien auf ihm, und der Glaubensgemeinschaft unseres Vaters Ibrahim. Er war rechtgläubig, gottergeben und keiner der Götzendiener.",
        english: "We have entered a new day upon the natural religion of Islam, the word of sincere devotion, the religion of our Prophet Muhammad (peace and blessings of Allah be upon him), and the faith of our father Ibrahim. He was upright (in worshipping Allah), and a Muslim. He was not of those who worship others besides Allah.",
        count: 1,
        quickInterval: 9.14, normalInterval: 11.20, slowInterval: 13.26),
    // 19. Subhanallahi wa bihamdihi (100)
    AdhkarItem(
        arabic: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ",
        transliteration: "Subhanallahi wa bihamdihi.",
        german: "Preis sei Allah, und Ihm gebührt Sein Lob.",
        english: "Glory is to Allah and praise is to Him.",
        count: 100,
        quickInterval: 1.15, normalInterval: 1.45, slowInterval: 1.75),
    // 20. La ilaha illallah (10)
    AdhkarItem(
        arabic: "لَا إِلَهَ إِلَّا اللَّهُ، وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكْ، وَلَهُ الْحَمْدْ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرْ",
        transliteration: "La ilaha illallahu wahdahu la sharika lah, lahul-mulk, wa lahul-hamd, wa Huwa 'ala kulli shay'in Qadir.",
        german: "Es gibt keinen Gott außer Allah, dem Einzigen, der keinen Teilhaber hat. Ihm gehört die Herrschaft und Ihm gebührt das Lob, und Er ist über alle Dinge mächtig.",
        english: "None has the right to be worshipped but Allah alone, Who has no partner. His is the dominion and His is the praise and He is Able to do all things.",
        count: 10,
        linkedTasbihCategory: .laIlahaIllallah,
        quickInterval: 9.00, normalInterval: 11.08, slowInterval: 13.20),
    // 21. Subhanallahi wa bihamdihi 'adada
    AdhkarItem(
        arabic: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ : عَدَدَ خَلْقِهِ، وَرِضَا نَفْسِهِ، وَزِنَةَ عَرْشِهِ، وَمِدَادَ كَلِمَاتِهِ",
        transliteration: "Subhanallahi wa bihamdihi: 'Adada khalqihi, wa rida nafsihi, wa zinata 'arshihi, wa midada kalimatih.",
        german: "Preis sei Allah, und Ihm gebührt Sein Lob: In der Anzahl Seiner Schöpfung, nach Seinem Wohlgefallen, dem Gewicht Seines Thrones und der Menge der Tinte Seiner Worte.",
        english: "Glory is to Allah and praise is to Him, by the multitude of His creation, by His Pleasure, by the weight of His Throne, and by the extent of His Words.",
        count: 3,
        quickInterval: 3.50, normalInterval: 4.30, slowInterval: 5.10),
    // 22. Allahumma inni as'aluka 'ilman nafi'an
    AdhkarItem(
        arabic: "اللَّهُمَّ إِنِّي أَسْأَلُكَ عِلْماً نَافِعاً، وَرِزْقاً طَيِّباً، وَعَمَلاً مُتَقَبَّلاً",
        transliteration: "Allahumma inni as'aluka 'ilman nafi'an, wa rizqan tayyiban, wa 'amalan mutaqabbalan.",
        german: "O Allah, ich bitte Dich um nützliches Wissen, guten Lebensunterhalt und Taten, die von Dir angenommen werden.",
        english: "O Allah, I ask You for knowledge that is of benefit, a good provision, and deeds that will be accepted.",
        count: 1,
        quickInterval: 3.42, normalInterval: 4.19, slowInterval: 4.96),
    // 23. Astaghfirullah
    AdhkarItem(
        arabic: "أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ",
        transliteration: "Astaghfirullaha wa atubu ilayh.",
        german: "Ich bitte Allah um Vergebung und kehre in Reue zu Ihm zurück.",
        english: "I seek the forgiveness of Allah and repent to Him.",
        count: 100,
        linkedTasbihCategory: .istighfar
        , quickInterval: 1.25, normalInterval: 1.65, slowInterval: 2.05),
    // 24. A'udhu bikalimatillahit-tammati
    AdhkarItem(
        arabic: "أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ",
        transliteration: "A'udhu bi-kalimatillahit-tammati min sharri ma khalaq.",
        german: "Ich suche Zuflucht bei den vollkommenen Worten Allahs vor dem Übel dessen, was Er erschaffen hat.",
        english: "I seek refuge in the Perfect Words of Allah from the evil of what He has created.",
        count: 3,
        quickInterval: 2.43, normalInterval: 2.98, slowInterval: 3.53),
    // 25. Allahumma salli
    AdhkarItem(
        arabic: "اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبَيِّنَا مُحَمَّدٍ",
        transliteration: "Allahumma salli wa sallim 'ala Nabiyyina Muhammad.",
        german: "O Allah, sende Segen und Frieden auf unseren Propheten Muhammad.",
        english: "O Allah, send blessings and peace upon our Prophet Muhammad.",
        count: 10,
        linkedTasbihCategory: .salawat
        , quickInterval: 1.35, normalInterval: 1.75, slowInterval: 2.20),
]

let abendAdhkar: [AdhkarItem] = [
    // 1. Ayat al-Kursi
    AdhkarItem(
        arabic: "اللَّهُ لاَ إِلَهَ إِلاَّ هُوَ الْحَيُّ الْقَيُّومُ لاَ تَأْخُذُهُ سِنَةٌ وَلاَ نَوْمٌ لَّهُ مَا فِي السَّمَوَاتِ وَمَا فِي الأَرْضِ مَن ذَا الَّذِي يَشْفَعُ عِنْدَهُ إِلاَّ بِإِذْنِهِ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ وَلاَ يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلاَّ بِمَا شَاء وَسِعَ كُرْسِيُّهُ السَّمَوَاتِ وَالْأَرْضَ وَلاَ يَؤُودُهُ حِفْظُهُمَا وَهُوَ الْعَلِيُّ الْعَظِيمُ",
        transliteration: "Allahu la ilaha illa Huwal-Hayyul-Qayyum. La ta'khudhuhu sinatun wa la nawm. Lahu ma fis-samawati wa ma fil-ard. Man dhal-ladhi yashfa'u 'indahu illa bi-idhnih. Ya'lamu ma bayna aydihim wa ma khalfahum. Wa la yuhituna bi-shay'im-min 'ilmihi illa bima sha'. Wasi'a kursiyyuhus-samawati wal-ard, wa la ya'uduhu hifdhuhuma, wa Huwal-'Aliyyul-'Adheem.",
        german: "Allah – es gibt keinen Gott außer Ihm, dem Lebendigen und Beständigen. Ihn überkommt weder Schlummer noch Schlaf. Ihm gehört, was in den Himmeln und was auf der Erde ist. Wer ist es, der bei Ihm Fürsprache einlegen könnte außer mit Seiner Erlaubnis? Er weiß, was vor ihnen und was hinter ihnen liegt; sie aber begreifen nichts von Seinem Wissen, es sei denn das, was Er will. Sein Thronschemel umfasst die Himmel und die Erde, und ihre Bewahrung beschwert Ihn nicht. Und Er ist der Erhabene, der Allgewaltige.",
        english: "Allah! There is no deity except Him, the Ever-Living, the Sustainer of all existence. Neither drowsiness overtakes Him nor sleep. To Him belongs whatever is in the heavens and whatever is on the earth. Who is it that can intercede with Him except by His permission? He knows what is presently before them and what will be after them, and they encompass not a thing of His knowledge except for what He wills. His Kursi extends over the heavens and the earth, and their preservation tires Him not. And He is the Most High, the Most Great.",
        count: 1,
        quickInterval: 15.52, normalInterval: 19.02, slowInterval: 22.52,
        audioFileName: "quran_ayat_kursi"),
    // 2. Sure Al-Ikhlas
    AdhkarItem(
        arabic: "بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ. قُلْ هُوَ اللَّهُ أَحَدٌ، اللَّهُ الصَّمَدُ، لَمْ يَلِدْ وَلَمْ يُولَدْ، وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ",
        transliteration: "Bismillahir-Rahmanir-Rahim. Qul Huwallahu Ahad. Allahus-Samad. Lam yalid wa lam yulad. Wa lam yakul-lahu kufuwan ahad.",
        german: "Im Namen Allahs, des Allerbarmers, des Barmherzigen. Sprich: Er ist Allah, ein Einziger, Allah, der Überlegene. Er hat nicht gezeugt und ist nicht gezeugt worden, und niemand ist Ihm jemals gleich.",
        english: "In the Name of Allah, the Most Gracious, the Most Merciful. Say: He is Allah, (who is) One, Allah, the Eternal Refuge. He neither begets nor is born, nor is there to Him any equivalent.",
        count: 3,
        quickInterval: 5.79, normalInterval: 7.09, slowInterval: 8.39,
        audioFileName: "quran_ikhlas"),
    // 3. Sure Al-Falaq
    AdhkarItem(
        arabic: "بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ. قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ، مِن شَرِّ مَا خَلَقَ، وَمِن شَرِّ غَاسِقٍ إِذَا وَقَبَ، وَمِن شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ، وَمِن شَرِّ حَاسِدٍ إِذَا حَسَدَ",
        transliteration: "Bismillahir-Rahmanir-Rahim. Qul a'udhu bi Rabbil-falaq. Min sharri ma khalaq. Wa min sharri ghasiqin idha waqab. Wa min sharrin-naffathati fil-'uqad. Wa min sharri hasidin idha hasad.",
        german: "Im Namen Allahs, des Allerbarmers, des Barmherzigen. Sprich: Ich nehme Zuflucht beim Herrn des Frühlichts, vor dem Übel dessen, was Er erschaffen hat, und vor dem Übel der Dunkelheit, wenn sie hereinbricht, und vor dem Übel der Knotenbläserinnen, und vor dem Übel eines Neiders, wenn er neidet.",
        english: "In the Name of Allah, the Most Gracious, the Most Merciful. Say: I seek refuge in the Lord of daybreak, from the evil of that which He created, and from the evil of darkness when it settles, and from the evil of the blowers in knots, and from the evil of an envier when he envies.",
        count: 3,
        quickInterval: 8.09, normalInterval: 9.91, slowInterval: 11.73,
        audioFileName: "quran_falaq"),
    // 4. Sure An-Nas
    AdhkarItem(
        arabic: "بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ. قُلْ أَعُوذُ بِرَبِّ النَّاسِ، مَلِكِ النَّاسِ، إِلَٰهِ النَّاسِ، مِن شَرِّ الْوَسْوَاسِ الْخَنَّاسِ، الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ، مِنَ الْجِنَّةِ وَالنَّاسِ",
        transliteration: "Bismillahir-Rahmanir-Rahim. Qul a'udhu bi Rabbin-nas. Malikin-nas. Ilahin-nas. Min sharril-waswasil-khannas. Alladhi yuwaswisu fi sudurin-nas. Minal-jinnati wan-nas.",
        german: "Im Namen Allahs, des Allerbarmers, des Barmherzigen. Sprich: Ich nehme Zuflucht beim Herrn der Menschen, dem König der Menschen, dem Gott der Menschen, vor dem Übel des Einflüsterers, der entweicht und wiederkehrt, der den Menschen in die Brüste einflüstert, von den Dschinn und den Menschen.",
        english: "In the Name of Allah, the Most Gracious, the Most Merciful. Say: I seek refuge in the Lord of mankind, the Sovereign of mankind, the God of mankind, from the evil of the retreating whisperer, who whispers into the breasts of mankind, from among the jinn and mankind.",
        count: 3,
        quickInterval: 8.42, normalInterval: 10.32, slowInterval: 12.22,
        audioFileName: "quran_nas"),
    // 5. Amsayna wa amsal-mulku lillah (Abend)
    AdhkarItem(
        arabic: "أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَذِهِ اللَّيْلَةِ وَخَيْرَ مَا بَعْدَهَا، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَذِهِ اللَّيْلَةِ وَشَرِّ مَا بَعْدَهَا، رَبِّ أَعُوذُ بِكَ مِنَ الْكَسَلِ وَسُوءِ الْكِبَرِ، رَبِّ أَعُوذُ بِكَ مِنْ عَذَابٍ فِي النَّارِ وَعَذَابٍ فِي الْقَبْرِ",
        transliteration: "Amsayna wa amsal-mulku lillah, walhamdulillah. La ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamd, wa Huwa 'ala kulli shay'in Qadir. Rabbi as'aluka khayra ma fi hadhihil-laylah wa khayra ma ba'daha, wa a'udhu bika min sharri ma fi hadhihil-laylah wa sharri ma ba'daha. Rabbi a'udhu bika minal-kasali wa su'il-kibar. Rabbi a'udhu bika min 'adhabin fin-nari wa 'adhabin fil-qabr.",
        german: "Wir haben den Abend erreicht, und die Herrschaft gehört Allah. Alles Lob gebührt Allah. Es gibt keinen Gott außer Allah, dem Einzigen, der keinen Teilhaber hat. Ihm gehört die Herrschaft und Ihm gebührt das Lob, und Er ist über alle Dinge mächtig. Mein Herr, ich bitte Dich um das Gute dieser Nacht und um das Gute, das danach kommt. Und ich suche Zuflucht bei Dir vor dem Übel dieser Nacht und dem Übel, das danach kommt. Mein Herr, ich suche Zuflucht bei Dir vor Faulheit und einem schlechten Alter. Mein Herr, ich suche Zuflucht bei Dir vor der Strafe im Höllenfeuer und der Strafe im Grab.",
        english: "We have reached the evening and at this very time unto Allah belongs all sovereignty, and all praise is for Allah. None has the right to be worshipped except Allah, alone, without partner, to Him belongs all sovereignty and praise and He is over all things omnipotent. My Lord, I ask You for the good of this night and the good of what follows it and I take refuge in You from the evil of this night and the evil of what follows it. My Lord, I take refuge in You from laziness and senility. My Lord, I take refuge in You from torment in the Fire and punishment in the grave.",
        count: 1,
        quickInterval: 28.00, normalInterval: 34.36, slowInterval: 40.70),
    // 6. Allahumma bika amsayna (Abend)
    AdhkarItem(
        arabic: "اللَّهُمَّ بِكَ أَمْسَيْنَا، وَبِكَ أَصْبَحْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتْ، وَإِلَيْكَ الْمَصِيرْ",
        transliteration: "Allahumma bika amsayna, wa bika asbahna, wa bika nahya, wa bika namut, wa ilaykal-masir.",
        german: "O Allah, durch Dich haben wir den Abend erreicht, und durch Dich haben wir den Morgen erreicht. Durch Dich leben wir, und durch Dich sterben wir, und zu Dir ist die Heimkehr.",
        english: "O Allah, by You we enter the evening and by You we enter the morning, by You we live and by You we die, and to You is the Final Return.",
        count: 1,
        quickInterval: 7.00, normalInterval: 8.56, slowInterval: 10.15),
    // 7. Sayyidul Istighfar (Abend)
    AdhkarItem(
        arabic: "اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلاَّ أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لاَ يَغْفِرُ الذُّنوبَ إِلاَّ أَنْتَ",
        transliteration: "Allahumma Anta Rabbi la ilaha illa Ant. Khalaqtani wa ana 'abduka, wa ana 'ala 'ahdika wa wa'dika ma-stata't. A'udhu bika min sharri ma sana't. Abu'u laka bi-ni'matika 'alayy, wa abu'u bi-dhanbi fa-ghfir li, fa-innahu la yaghfiru-dh-dhunuba illa Ant.",
        german: "O Allah, Du bist mein Herr. Es gibt keinen Gott außer Dir. Du hast mich erschaffen, und ich bin Dein Diener. Ich halte mich an Deinen Bund und Dein Versprechen, so gut ich kann. Ich suche Zuflucht bei Dir vor dem Übel, das ich begangen habe. Ich bekenne mich zu Deinen Gnaden über mich, und ich bekenne mich zu meiner Sünde. So vergib mir, denn niemand vergibt die Sünden außer Dir.",
        english: "O Allah, You are my Lord, there is none worthy of worship but You. You created me and I am Your slave. I keep Your covenant, and my pledge to You so far as I am able. I seek refuge in You from the evil of what I have done. I admit to Your blessings upon me, and I admit to my misdeeds. Forgive me, for there is none who may forgive sins but You.",
        count: 1,
        linkedTasbihCategory: .istighfar
        , quickInterval: 10.47, normalInterval: 12.97, slowInterval: 15.47),
    // 8. Allahumma inni amsaytu ushhiduka (Abend)
    AdhkarItem(
        arabic: "اللَّهُمَّ إِنِّي أَمْسَيْتُ أُشْهِدُكَ، وَأُشْهِدُ حَمَلَةَ عَرْشِكَ، وَمَلاَئِكَتِكَ، وَجَمِيعَ خَلْقِكَ، أَنَّكَ أَنْتَ اللَّهُ لَا إِلَهَ إِلاَّ أَنْتَ وَحْدَكَ لاَ شَرِيكَ لَكَ، وَأَنَّ مُحَمَّداً عَبْدُكَ وَرَسُولُكَ",
        transliteration: "Allahumma inni amsaytu ushhiduka, wa ushhidu hamalata 'arshika, wa mala'ikatika, wa jami'a khalqika, annaka Antallahu la ilaha illa Anta wahdaka la sharika lak, wa anna Muhammadan 'abduka wa rasuluk.",
        german: "O Allah, ich habe den Abend erreicht und rufe Dich als Zeugen an, ebenso wie die Träger Deines Thrones, Deine Engel und Deine gesamte Schöpfung, dass Du Allah bist, es gibt keinen Gott außer Dir allein, Du hast keinen Teilhaber, und dass Muhammad Dein Diener und Gesandter ist.",
        english: "O Allah, I have entered the evening calling You to witness, and calling the bearers of Your Throne to witness, Your angels and all of Your creation, that You are Allah, none has the right to be worshipped but You alone, without partner, and that Muhammad is Your servant and Messenger.",
        count: 4,
        quickInterval: 8.42, normalInterval: 10.32, slowInterval: 12.22),
    // 9. Allahumma ma amsa bi min ni'matin (Abend)
    AdhkarItem(
        arabic: "اللَّهُمَّ مَا أَمْسَى بِي مِنْ نِعْمَةٍ أَوْ بِأَحَدٍ مِنْ خَلْقِكْ، فَمِنْكَ وَحْدَكَ لاَ شَرِيكَ لَكَ، فَلَكَ الْحَمْدُ وَلَكَ الشُّكْرُ",
        transliteration: "Allahumma ma amsa bi min ni'matin aw bi-ahadin min khalqik, fa-minka wahdaka la sharika lak, fa-lakal-hamdu wa lakash-shukr.",
        german: "O Allah, welche Gnade auch immer mich oder eines Deiner Geschöpfe an diesem Abend erreicht hat, sie ist von Dir allein, Du hast keinen Teilhaber. Dir gebührt alles Lob und Dir gebührt der Dank.",
        english: "O Allah, whatever blessing has been received by me or anyone of Your creation this evening, is from You alone, You have no partner. All praise is for You and thanks is to You.",
        count: 1,
        quickInterval: 5.39, normalInterval: 6.61, slowInterval: 7.83),
    // 10. Allahumma 'afini fi badani (Abend)
    AdhkarItem(
        arabic: "اللَّهُمَّ عَافِنِي فِي بَدَنِي، اللَّهُمَّ عَافِنِي فِي سَمْعِي، اللَّهُمَّ عَافِنِي فِي بَصَرِي، لاَ إِلَهَ إِلاَّ أَنْتَ. اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْكُفْرِ، وَالفَقْرِ، وَأَعُوذُ بِكَ مِنْ عَذَابِ القَبْرِ، لاَ إِلَهَ إِلاَّ أَنْتَ",
        transliteration: "Allahumma 'afini fi badani, Allahumma 'afini fi sam'i, Allahumma 'afini fi basari, la ilaha illa Ant. Allahumma inni a'udhu bika minal-kufri wal-faqr, wa a'udhu bika min 'adhabil-qabr, la ilaha illa Ant.",
        german: "O Allah, gib mir Gesundheit in meinem Körper. O Allah, gib mir Gesundheit in meinem Gehör. O Allah, gib mir Gesundheit in meinem Augenlicht. Es gibt keinen Gott außer Dir. O Allah, ich suche Zuflucht bei Dir vor dem Unglauben und der Armut. Und ich suche Zuflucht bei Dir vor der Strafe im Grab. Es gibt keinen Gott außer Dir.",
        english: "O Allah, grant my body health. O Allah, grant my hearing health. O Allah, grant my sight health. None has the right to be worshipped but You. O Allah, I take refuge with You from disbelief and poverty, and I take refuge with You from the punishment of the grave. None has the right to be worshipped but You.",
        count: 3,
        quickInterval: 10.06, normalInterval: 12.33, slowInterval: 14.60),
    // 11. Hasbiyallahu (Abend)
    AdhkarItem(
        arabic: "حَسْبِيَ اللَّهُ لاَ إِلَهَ إِلاَّ هُوَ عَلَيهِ تَوَكَّلتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ",
        transliteration: "Hasbiyallahu la ilaha illa Huwa 'alayhi tawakkaltu wa Huwa Rabbul-'Arshil-'Adheem.",
        german: "Allah genügt mir. Es gibt keinen Gott außer Ihm. Auf Ihn vertraue ich, und Er ist der Herr des gewaltigen Thrones.",
        english: "Allah is sufficient for me. There is none worthy of worship but Him. I have placed my trust in Him, and He is the Lord of the Majestic Throne.",
        count: 7,
        quickInterval: 5.60, normalInterval: 6.85, slowInterval: 8.10),
    // 12. Allahumma inni as'aluka al-'afwa (Abend)
    AdhkarItem(
        arabic: "اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي الدُّنْيَا وَالآخِرَةِ، اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي دِينِي وَدُنْيَايَ وَأَهْلِي، وَمَالِي، اللَّهُمَّ اسْتُرْ عَوْرَاتِي، وَآمِنْ رَوْعَاتِي، اللَّهُمَّ احْفَظْنِي مِنْ بَينِ يَدَيَّ، وَمِنْ خَلْفِي، وَعَنْ يَمِينِي، وَعَنْ شِمَالِي، وَمِنْ فَوْقِي، وَأَعُوذُ بِعَظَمَتِكَ أَنْ أُغْتَالَ مِنْ تَحْتِي",
        transliteration: "Allahumma inni as'aluka-l-'afwa wal-'afiyata fid-dunya wal-akhirah. Allahumma inni as'aluka-l-'afwa wal-'afiyata fi dini wa dunyaya wa ahli wa mali. Allahumma-stur 'awrati wa amin raw'ati. Allahumma-hfazni min bayni yadayya, wa min khalfi, wa 'an yamini, wa 'an shimali, wa min fawqi, wa a'udhu bi-'adhamatika an ughtala min tahti.",
        german: "O Allah, ich bitte Dich um Vergebung und Wohlergehen im Diesseits und im Jenseits. O Allah, ich bitte Dich um Vergebung und Wohlergehen für meine Religion, mein weltliches Leben, meine Familie und mein Vermögen. O Allah, bedecke meine Blößen und beruhige meine Ängste. O Allah, beschütze mich von vorn, von hinten, von rechts, von links und von oben. Und ich suche Zuflucht bei Deiner Erhabenheit davor, dass ich von unten her meuchlings vernichtet werde.",
        english: "O Allah, I ask You for pardon and well-being in this life and the next. O Allah, I ask You for pardon and well-being in my religious and worldly affairs, and my family and my wealth. O Allah, veil my weaknesses and set at ease my dismay. O Allah, preserve me from the front and from behind and on my right and on my left and from above, and I take refuge with You lest I be swallowed up by the earth.",
        count: 1,
        quickInterval: 15.65, normalInterval: 19.18, slowInterval: 22.71),
    // 13. Allahumma 'alimal-ghaybi (Abend)
    AdhkarItem(
        arabic: "اللَّهُمَّ عَالِمَ الْغَيْبِ وَالشَّهَادَةِ فَاطِرَ السَّمَوَاتِ وَالْأَرْضِ، رَبَّ كُلِّ شَيْءٍ وَمَلِيكَهُ، أَشْهَدُ أَنْ لاَ إِلَهَ إِلاَّ أَنْتَ، أَعُوذُ بِكَ مِنْ شَرِّ نَفْسِي، وَمِنْ شَرِّ الشَّيْطانِ وَشِـرْكِهِ، وَأَنْ أَقْتَرِفَ عَلَى نَفْسِي سُوءاً، أَوْ أَجُرَّهُ إِلَى مُسْلِمٍ",
        transliteration: "Allahumma 'Alimal-ghaybi wash-shahadati Fatiras-samawati wal-ard, Rabba kulli shay'in wa Malikah. Ash-hadu an la ilaha illa Ant. A'udhu bika min sharri nafsi, wa min sharrish-shaytani wa shirkihi, wa an aqtarifa 'ala nafsi su'an, aw ajurrahu ila Muslim.",
        german: "O Allah, Kenner des Verborgenen und des Offenbaren, Schöpfer der Himmel und der Erde, Herr und König von allem. Ich bezeuge, dass es keinen Gott gibt außer Dir. Ich suche Zuflucht bei Dir vor dem Übel meiner eigenen Seele, vor dem Übel des Satans und seiner Verführung zur Beigesellung (Schirk), und davor, dass ich mir selbst Böses antue oder es über einen Muslim bringe.",
        english: "O Allah, Knower of the unseen and the evident, Maker of the heavens and the earth, Lord of all things and their Sovereign, I bear witness that there is none worthy of worship but You. I seek refuge in You from the evil of my soul and from the evil of Satan and his helpers, and (I seek refuge in You) from bringing evil upon my soul or from harming a Muslim.",
        count: 1,
        quickInterval: 11.38, normalInterval: 13.94, slowInterval: 16.50),
    // 14. Bismillah-illadhi la yadurru (Abend)
    AdhkarItem(
        arabic: "بِسْمِ اللَّهِ الَّذِي لاَ يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلاَ فِي السّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ",
        transliteration: "Bismillahil-ladhi la yadurru ma'as-mihi shay'un fil-ardi wa la fis-sama'i wa Huwas-Sami'ul-'Alim.",
        german: "Im Namen Allahs, mit Dessen Namen nichts auf der Erde oder im Himmel Schaden zufügen kann, und Er ist der Allhörende, der Allwissende.",
        english: "In the Name of Allah, Who with His Name nothing can cause harm in the earth nor in the heavens, and He is the All-Hearing, the All-Knowing.",
        count: 3,
        quickInterval: 4.80, normalInterval: 5.88, slowInterval: 6.96),
    // 15. Radiytu billahi (Abend)
    AdhkarItem(
        arabic: "رَضِيتُ بِاللَّهِ رَبَّاً، وَبِالْإِسْلاَمِ دِيناً، وَبِمُحَمَّدٍ صلى الله عليه وسلم نَبِيّاً",
        transliteration: "Radiytu billahi Rabban wabil-Islami dinan wa bi-Muhammadin sallallahu 'alayhi wa sallama Nabiyya.",
        german: "Ich bin zufrieden mit Allah als meinem Herrn, mit dem Islam als meiner Religion und mit Muhammad, Allahs Segen und Frieden seien auf ihm, als meinem Propheten.",
        english: "I am pleased with Allah as my Lord, with Islam as my religion and with Muhammad (peace and blessings of Allah be upon him) as my Prophet.",
        count: 3,
        quickInterval: 4.08, normalInterval: 5.00, slowInterval: 5.92),
    // 16. Ya Hayyu ya Qayyum (Abend)
    AdhkarItem(
        arabic: "يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغيثُ أَصْلِحْ لِي شَأْنِيَ كُلَّهُ وَلاَ تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ",
        transliteration: "Ya Hayyu ya Qayyum bi-rahmatika astaghith, aslih li sha'ni kullahu wa la takilni ila nafsi tarfata 'ayn.",
        german: "O Ewiglebender, O Beständiger, durch Deine Barmherzigkeit rufe ich um Hilfe. Bringe all meine Angelegenheiten in Ordnung und überlasse mich nicht mir selbst, nicht einmal für den Wimpernschlag eines Auges.",
        english: "O Ever Living One, O Sustainer, by Your mercy I call on You to set right all my affairs, do not place me in charge of my soul even for the blinking of an eye.",
        count: 1,
        quickInterval: 4.73, normalInterval: 5.80, slowInterval: 6.87),
    // 17. Amsayna wa amsal-mulku lillahi rabbil-'alamin
    AdhkarItem(
        arabic: "أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ رَبِّ الْعَالَمِينَ، اللَّهُـمَّ إِنِّي أَسْأَلُكَ خَيْرَ هَذِهِ اللَّيْلَةِ فَتْحَهَا، وَنَصْرَهَا، وَنورَهَا، وَبَرَكَتَهَا، وَهُدَاهَا، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِيهَا وَشَرِّ مَا بَعْدَهَا",
        transliteration: "Amsayna wa amsal-mulku lillahi Rabbil-'alamin. Allahumma inni as'aluka khayra hadhihil-laylah: fathaha, wa nasraha, wa nuraha, wa barakataha, wa hudaha. Wa a'udhu bika min sharri ma fiha wa sharri ma ba'daha.",
        german: "Wir haben den Abend erreicht, und die Herrschaft gehört Allah, dem Herrn der Welten. O Allah, ich bitte Dich um das Gute dieser Nacht: ihren Erfolg, ihren Sieg, ihr Licht, ihren Segen und ihre Rechtleitung. Und ich suche Zuflucht bei Dir vor dem Übel, das darin ist, und dem Übel, das danach kommt.",
        english: "We have reached the evening and at this very time unto Allah, Lord of the worlds, belongs all sovereignty. O Allah, I ask You for the good of this night, its victories, its help, its light, its blessings, and its guidance. I take refuge in You from the evil that is in it and from the evil that follows it.",
        count: 1,
        quickInterval: 16.00, normalInterval: 19.72, slowInterval: 23.40),
    // 18. Amsayna 'ala fitratil-Islam
    AdhkarItem(
        arabic: "أَمْسَيْنَا عَلَى فِطْرَةِ الْإِسْلاَمِ، وَعَلَى كَلِمَةِ الْإِخْلاَصِ، وَعَلَى دِينِ نَبِيِّنَا مُحَمَّدٍ صلى الله عليه وسلم، وَعَلَى مِلَّةِ أَبِينَا إِبْرَاهِيمَ، حَنِيفاً مُسْلِماً وَمَا كَانَ مِنَ الْمُشرِكِينَ",
        transliteration: "Amsayna 'ala fitratil-Islam, wa 'ala kalimatil-ikhlas, wa 'ala dini Nabiyyina Muhammadin sallallahu 'alayhi wa sallam, wa 'ala millati abina Ibrahima hanifan Musliman wa ma kana minal-mushrikin.",
        german: "Wir haben den Abend erreicht in der natürlichen Veranlagung des Islam, auf dem Wort der reinen Ergebenheit, auf der Religion unseres Propheten Muhammad, Allahs Segen und Frieden seien auf ihm, und der Glaubensgemeinschaft unseres Vaters Ibrahim. Er war rechtgläubig, gottergeben und keiner der Götzendiener.",
        english: "We have entered a new night upon the natural religion of Islam, the word of sincere devotion, the religion of our Prophet Muhammad (peace and blessings of Allah be upon him), and the faith of our father Ibrahim. He was upright (in worshipping Allah), and a Muslim. He was not of those who worship others besides Allah.",
        count: 1,
        quickInterval: 9.14, normalInterval: 11.20, slowInterval: 13.26),
    // 19. Subhanallahi wa bihamdihi (Abend)
    AdhkarItem(
        arabic: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ",
        transliteration: "Subhanallahi wa bihamdihi.",
        german: "Preis sei Allah, und Ihm gebührt Sein Lob.",
        english: "Glory is to Allah and praise is to Him.",
        count: 100,
        quickInterval: 1.15, normalInterval: 1.45, slowInterval: 1.75),
    // 20. La ilaha illallah (Abend)
    AdhkarItem(
        arabic: "لَا إِلَهَ إِلَّا اللَّهُ، وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكْ، وَلَهُ الْحَمْدْ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرْ",
        transliteration: "La ilaha illallahu wahdahu la sharika lah, lahul-mulk, wa lahul-hamd, wa Huwa 'ala kulli shay'in Qadir.",
        german: "Es gibt keinen Gott außer Allah, dem Einzigen, der keinen Teilhaber hat. Ihm gehört die Herrschaft und Ihm gebührt das Lob, und Er ist über alle Dinge mächtig.",
        english: "None has the right to be worshipped but Allah alone, Who has no partner. His is the dominion and His is the praise and He is Able to do all things.",
        count: 10,
        linkedTasbihCategory: .laIlahaIllallah,
        quickInterval: 9.00, normalInterval: 11.08, slowInterval: 13.20),
    // 21. Astaghfirullah (Abend)
    AdhkarItem(
        arabic: "أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ",
        transliteration: "Astaghfirullaha wa atubu ilayh.",
        german: "Ich bitte Allah um Vergebung und kehre in Reue zu Ihm zurück.",
        english: "I seek the forgiveness of Allah and repent to Him.",
        count: 100,
        linkedTasbihCategory: .istighfar
        , quickInterval: 1.25, normalInterval: 1.65, slowInterval: 2.05),
    // 22. A'udhu bikalimatillahit-tammati (Abend)
    AdhkarItem(
        arabic: "أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ",
        transliteration: "A'udhu bi-kalimatillahit-tammati min sharri ma khalaq.",
        german: "Ich suche Zuflucht bei den vollkommenen Worten Allahs vor dem Übel dessen, was Er erschaffen hat.",
        english: "I seek refuge in the Perfect Words of Allah from the evil of what He has created.",
        count: 3,
        quickInterval: 2.43, normalInterval: 2.98, slowInterval: 3.53),
    // 23. Allahumma salli (Abend)
    AdhkarItem(
        arabic: "اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبَيِّنَا مُحَمَّدٍ",
        transliteration: "Allahumma salli wa sallim 'ala Nabiyyina Muhammad.",
        german: "O Allah, sende Segen und Frieden auf unseren Propheten Muhammad.",
        english: "O Allah, send blessings and peace upon our Prophet Muhammad.",
        count: 10,
        linkedTasbihCategory: .salawat
    , quickInterval: 1.35, normalInterval: 1.75, slowInterval: 2.20)
]

let schlafAdhkar: [AdhkarItem] = [
    // 1. Schutzsuren mit Pusten und Streichen
    AdhkarItem(
        arabic: "يَجْمَعُ كَفَّيْهِ ثُمَّ يَنْفُثُ فِيهِمَا فَيَقْرَأُ فِيهِمَا: بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ ﴿قُلْ هُوَ اللَّهُ أَحَدٌ...﴾ وَ ﴿قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ...﴾ وَ ﴿قُلْ أَعُوذُ بِرَبِّ النَّاسِ...﴾ ثُمَّ يَمْسَحُ بِهِمَا مَا اسْتَطَاعَ مِنْ جَسَدِهِ، يَبْدَأُ بِهِمَا عَلَى رَأْسِهِ وَوَجْهِهِ وَمَا أَقْبَلَ مِنْ جَسَدِهِ",
        transliteration: "Yajma'u kaffayhi thumma yanfuthu fihima fayaqra'u fihima: Bismillahir-Rahmanir-Rahim: Qul Huwallahu Ahad... Qul a'udhu bi Rabbil-falaq... Qul a'udhu bi Rabbin-nas... thumma yamsahu bihima ma-stata'a min jasadihi, yabda'u bihima 'ala ra'sihi wa wajhihi wa ma aqbala min jasadihi.",
        german: "Er führt seine Handflächen zusammen, pustet hinein und rezitiert: Im Namen Allahs, des Allerbarmers, des Barmherzigen: Sprich: Er ist Allah, ein Einziger... Sprich: Ich nehme Zuflucht beim Herrn des Frühlichts... Sprich: Ich nehme Zuflucht beim Herrn der Menschen... Dann streicht er mit ihnen über so viel von seinem Körper, wie er kann, beginnend mit seinem Kopf, seinem Gesicht und der Vorderseite seines Körpers.",
        english: "He would join his hands together, blow into them and recite: In the Name of Allah, the Most Gracious, the Most Merciful: Say: He is Allah, (who is) One... Say: I seek refuge in the Lord of daybreak... Say: I seek refuge in the Lord of mankind... Then he would wipe as much of his body as he could with them, starting with his head, his face, and the front of his body.",
        count: 3),
    // 2. Ayat al-Kursi
    AdhkarItem(
        arabic: "اللَّهُ لاَ إِلَهَ إِلاَّ هُوَ الْحَيُّ الْقَيُّومُ لاَ تَأْخُذُهُ سِنَةٌ وَلاَ نَوْمٌ لَّهُ مَا فِي السَّمَوَاتِ وَمَا فِي الأَرْضِ مَن ذَا الَّذِي يَشْفَعُ عِنْدَهُ إِلاَّ بِإِذْنِهِ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ وَلاَ يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلاَّ بِمَا شَاء وَسِعَ كُرْسِيُّهُ السَّمَوَاتِ وَالْأَرْضَ وَلاَ يَؤُودُهُ حِفْظُهُمَا وَهُوَ الْعَلِيُّ الْعَظِيمُ",
        transliteration: "Allahu la ilaha illa Huwal-Hayyul-Qayyum. La ta'khudhuhu sinatun wa la nawm. Lahu ma fis-samawati wa ma fil-ard. Man dhal-ladhi yashfa'u 'indahu illa bi-idhnih. Ya'lamu ma bayna aydihim wa ma khalfahum. Wa la yuhituna bi-shay'im-min 'ilmihi illa bima sha'. Wasi'a kursiyyuhus-samawati wal-ard, wa la ya'uduhu hifdhuhuma, wa Huwal-'Aliyyul-'Adheem.",
        german: "Allah – es gibt keinen Gott außer Ihm, dem Lebendigen und Beständigen. Ihn überkommt weder Schlummer noch Schlaf. Ihm gehört, was in den Himmeln und was auf der Erde ist. Wer ist es, der bei Ihm Fürsprache einlegen könnte außer mit Seiner Erlaubnis? Er weiß, was vor ihnen und was hinter ihnen liegt; sie aber begreifen nichts von Seinem Wissen, es sei denn das, was Er will. Sein Thronschemel umfasst die Himmel und die Erde, und ihre Bewahrung beschwert Ihn nicht. Und Er ist der Erhabene, der Allgewaltige.",
        english: "Allah! There is no deity except Him, the Ever-Living, the Sustainer of all existence. Neither drowsiness overtakes Him nor sleep. To Him belongs whatever is in the heavens and whatever is on the earth. Who is it that can intercede with Him except by His permission? He knows what is presently before them and what will be after them, and they encompass not a thing of His knowledge except for what He wills. His Kursi extends over the heavens and the earth, and their preservation tires Him not. And He is the Most High, the Most Great.",
        count: 1,
        audioFileName: "quran_ayat_kursi"),
    // 3. Die letzten 2 Verse von Surah Al-Baqarah (Aamanar-Rasoolu)
    AdhkarItem(
        arabic: "آمَنَ الرَّسُولُ بِمَا أُنْزِلَ إِلَيْهِ مِنْ رَبِّهِ وَالْمُؤْمِنُونَ ۚ كُلٌّ آمَنَ بِاللَّهِ وَمَلَائِكَتِهِ وَكُتُبِهِ وَرُسُلِهِ لَا نُفَرِّقُ بَيْنَ أَحَدٍ مِنْ رُسُلِهِ ۚ وَقَالُوا سَمِعْنَا وَأَطَعْنَا ۖ غُفْرَانَكَ رَبَّنَا وَإِلَيْكَ الْمَصِيرُ ﴿٢٨٥﴾ لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا ۚ لَهَا مَا كَسَبَتْ وَعَلَيْهَا مَا اكْتَسَبَتْ ۗ رَبَّنَا لَا تُؤَاخِذْنَا إِنْ نَسِينَا أَوْ أَخْطَأْنَا ۚ رَبَّنَا وَلَا تَحْمِلْ عَلَيْنَا إِصْرًا كَمَا حَمَلْتَهُ عَلَى الَّذِينَ مِنْ قَبْلِنَا ۚ رَبَّنَا وَلَا تُحَمِّلْنَا مَا لَا طَاقَةَ لَنَا بِهِ ۖ وَاعْفُ عَنَّا وَاغْفِرْ لَنَا وَارْحَمْنَا ۚ أَنْتَ مَوْلَانَا فَانْصُرْنَا عَلَى الْقَوْمِ الْكَافِرِينَ ﴿٢٨٦﴾",
        transliteration: "Aamanar-Rasoolu bimaa unzila ilayhi mir-Rabbihi wal-mu'minoon. Kullun aamana billahi wa malaa'ikatihi wa kutubhi wa rusulih, laa nufarriqu bayna ahadim-mir-rusulih. Wa qaaloo sami'naa wa ata'naa, ghufranaka Rabbanaa wa ilaykal-maseer. Laa yukallifullahu nafsan illa wus'ahaa, lahaa maa kasabat wa 'alayhaa mak-tasabat. Rabbanaa laa tu'aakhidhnaa in-naseenaa aw akhta'naa. Rabbanaa wa laa tahmil 'alaynaa isran kamaa hamaltahu 'alal-ladheena min qablinaa. Rabbanaa wa laa tuhammilnaa maa laa taaqata lanaa bih, wa'fu 'annaa waghfir lanaa warhamnaa, Anta Mawlaanaa fansurnaa 'alal-qawmil-kaafireen.",
        german: "Der Gesandte glaubt an das, was ihm von seinem Herrn herabgesandt worden ist, und ebenso die Gläubigen; sie alle glauben an Allah, Seine Engel, Seine Bücher und Seine Gesandten: „Wir machen keinen Unterschied bei keinem Seiner Gesandten.“ Und sie sagen: „Wir hören und gehorchen. Deine Vergebung, unser Herr! Und zu Dir ist die Heimkehr.“ Allah erlegt keiner Seele mehr auf, als sie zu leisten vermag. Ihr kommt zu Gute, was sie erworben hat, und angerechnet wird ihr, was sie begangen hat. „Unser Herr, belange uns nicht, wenn wir vergessen oder Fehler begehen! Unser Herr, erlege uns keine Bürde auf, wie Du sie denjenigen vor uns auferlegt hast! Unser Herr, bürde uns nichts auf, wozu wir keine Kraft haben! Und verzeih uns, vergib uns und erbarme Dich unser! Du bist unser Schutzherr, so hilf uns gegen das ungläubige Volk!“",
        english: "The Messenger has believed in what was revealed to him from his Lord, and [so have] the believers. All of them have believed in Allah and His angels and His books and His messengers, [saying], \"We make no distinction between any of His messengers.\" And they said, \"We hear and we obey. [We seek] Your forgiveness, our Lord, and to You is the final destination.\" Allah does not charge a soul except [with that within] its capacity. It will have [the consequence of] what [good] it has gained, and it will bear [the consequence of] what [evil] it has earned. \"Our Lord, do not impose blame upon us if we have forgotten or errored. Our Lord, and lay not upon us a burden like that which You laid upon those before us. Our Lord, and burden us not with that which we have no ability to bear. And pardon us; and forgive us; and have mercy upon us. You are our protector, so give us victory over the disbelieving people.\"",
        count: 1,
        audioFileName: "quran_baqarah_last2"),
    // 4. Bismika rabbi wada'tu janbi
    AdhkarItem(
        arabic: "بِاسْمِكَ رَبِّي وَضَعْتُ جَنْبِي، وَبِكَ أَرْفَعُهُ، فَإِن أَمْسَكْتَ نَفْسِي فارْحَمْهَا، وَإِنْ أَرْسَلْتَهَا فَاحْفَظْهَا، بِمَا تَحْفَظُ بِهِ عِبَادَكَ الصَّالِحِينَ",
        transliteration: "Bismika Rabbi wada'tu janbi, wa bika arfa'uh. Fa-in amsakta nafsi farhamha, wa in arsaltaha fahfazha bima tahfazu bihi 'ibadakas-salihin.",
        german: "In Deinem Namen, mein Herr, lege ich mich auf die Seite, und durch Dich erhebe ich mich wieder. Wenn Du meine Seele zurückhältst, erbarme Dich ihrer, und wenn Du sie zurücksendest, beschütze sie, womit Du Deine rechtschaffenen Diener beschützt.",
        english: "In Your Name, my Lord, I lay my side down, and in Your Name I raise it. If You take my soul, have mercy on it, and if You send it back, protect it as You protect Your righteous slaves.",
        count: 1),
    // 5. Allahumma innaka khalaqta nafsi
    AdhkarItem(
        arabic: "اللَّهُمَّ إِنَّكَ خَلَقْتَ نَفْسِي وَأَنْتَ تَوَفَّاهَا، لَكَ مَمَاتُهَا وَمَحْياهَا، إِنْ أَحْيَيْتَهَا فَاحْفَظْهَا، وَإِنْ أَمَتَّهَا فَاغْفِرْ لَهَا. اللَّهُمَّ إِنِّي أَسْأَلُكَ العَافِيَةَ",
        transliteration: "Allahumma innaka khalaqta nafsi wa Anta tawaffaha. Laka mamatuha wa mahyaha. In ahyaytaha fahfazha, wa in amattaha faghfir laha. Allahumma inni as'alukal-'afiyah.",
        german: "O Allah, Du hast meine Seele erschaffen und Du nimmst sie zu Dir. Dir gehört ihr Tod und ihr Leben. Wenn Du sie am Leben lässt, beschütze sie, und wenn Du sie sterben lässt, vergib ihr. O Allah, ich bitte Dich um Wohlergehen.",
        english: "O Allah, You created my soul and You take it back. To You belongs its death and its life. If You keep it alive, protect it, and if You cause it to die, forgive it. O Allah, I ask You for well-being.",
        count: 1,
        quickInterval: 11.50, normalInterval: 14.04, slowInterval: 16.50),
    // 6. Allahumma qini 'adhabaka
    AdhkarItem(
        arabic: "اللَّهُمَّ قِنِي عَذَابَكَ يَوْمَ تَبْعَثُ عِبَادَكَ",
        transliteration: "Allahumma qini 'adhabaka yawma tab'athu 'ibadak.",
        german: "O Allah, bewahre mich vor Deiner Strafe an dem Tag, an dem Du Deine Diener auferweckst.",
        english: "O Allah, protect me from Your punishment on the day You resurrect Your slaves.",
        count: 3),
    // 7. Bismika Allahumma amutu wa ahya
    AdhkarItem(
        arabic: "بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا",
        transliteration: "Bismika Allahumma amutu wa ahya.",
        german: "In Deinem Namen, O Allah, sterbe ich und lebe ich.",
        english: "In Your Name, O Allah, I die and I live.",
        count: 1,
        quickInterval: 3.10, normalInterval: 3.88, slowInterval: 4.60),
    // 8. Tasbih vor dem Schlafen
    AdhkarItem(
        arabic: "سُبْحَانَ اللَّهِ (ثلاثاً وثلاثين) وَالْحَمْدُ لِلَّهِ (ثلاثاً وثلاثين) وَاللَّهُ أَكْبَرُ (أربعاً وثلاثينَ)",
        transliteration: "Subhanal-lah (thirty-three times), wal-hamdu lillah (thirty-three times), wal-lahu Akbar (thirty-four times).",
        german: "Verherrlicht sei Allah (dreiunddreißigmal), alles Lob gebührt Allah (dreiunddreißigmal) und Allah ist am größten (vierunddreißigmal).",
        english: "Glory is to Allah (thirty-three times), praise is to Allah (thirty-three times), and Allah is the Most Great (thirty-four times).",
        count: 33,
        quickInterval: 2.40, normalInterval: 3.10, slowInterval: 3.80),
    // 9. Allahumma rabbi as-samawatis-sab'i
    AdhkarItem(
        arabic: "اللَّهُمَّ رَبَّ السَّمَوَاتِ السَّبْعِ وَرَبَّ الْعَرْشِ الْعَظِيمِ، رَبَّنَا وَرَبَّ كُلِّ شَيْءٍ، فَالِقَ الْحَبِّ وَالنَّوَى، وَمُنْزِلَ التَّوْرَاةِ وَالإِنْجِيلِ وَالْفُرْقَانِ، أَعُوذُ بِكَ مِنْ شَرِّ كُلِّ شَيْءٍ أَنْتَ آخِذٌ بِنَاصِيَتِهِ. اللَّهُمَّ أَنْتَ الأَوَّلُ فَلَيْسَ قَبْلَكَ شَيْءٌ، وَأَنْتَ الآخِرُ فَلَيْسَ بَعْدَكَ شَيْءٌ، وَأَنْتَ الظَّاهِرُ فَلَيْسَ فَوْقَكَ شَيْءٌ، وَأَنْتَ الْبَاطِنُ فَلَيْسَ دُونَكَ شَيْءٌ، اقْضِ عَنَّا الدَّيْنَ وَأَغْنينا مِنَ الْفَقْرِ",
        transliteration: "Allahumma Rabbas-samawatis-sab'i wa Rabbal-'Arshil-'Azim, Rabbana wa Rabba kulli shay'in, Faliqal-habbi wan-nawa, wa Munzilat-Tawrati wal-Injili wal-Furqan, a'udhu bika min sharri kulli shay'in Anta akhidhum bi-nasiyatih. Allahumma Antal-Awwalu falaysa qablaka shay'un, wa Antal-Akhiru falaysa ba'daka shay'un, wa Antadh-Dhahiru falaysa fawqaka shay'un, wa Antal-Batinu falaysa dunaka shay'un, iqdi 'annad-dayna wa aghnina minal-faqr.",
        german: "O Allah, Herr der sieben Himmel und Herr des gewaltigen Throns, unser Herr und Herr von allem, Der das Korn und den Kern spaltet, Der die Thora, das Evangelium und den Koran herabgesandt hat. Ich suche Zuflucht bei Dir vor dem Übel jedes Dinges, dessen Stirnlocke Du hältst. O Allah, Du bist der Erste, und vor Dir gibt es nichts; Du bist der Letzte, und nach Dir gibt es nichts; Du bist der Offenbare, und über Dir gibt es nichts; Du bist der Verborgene, und unter Dir gibt es nichts. Begleiche für uns unsere Schulden und befreie uns von der Armut.",
        english: "O Allah, Lord of the seven heavens and Lord of the Magnificent Throne, our Lord and the Lord of everything, Splitter of the grain and date-stone, Revealer of the Torah, the Gospel, and the Criterion, I seek refuge in You from the evil of everything whose forelock You hold. O Allah, You are the First and there is nothing before You; You are the Last and there is nothing after You; You are the Manifest and there is nothing above You; You are the Hidden and there is nothing beneath You. Relieve us of debt and enrich us against poverty.",
        count: 1),
    // 10. Alhamdulillahil-ladhi at'amana
    AdhkarItem(
        arabic: "الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنَا وَسَقَانَا، وَكَفَانَا، وَآوَانَا، فَكَمْ مِمَّنْ لاَ كَافِيَ لَهُ وَلاَ مُؤْوِيَ",
        transliteration: "Alhamdulillahil-ladhi at'amana wa saqana, wa kafana wa awana. Fakam mimman la kafiya lahu wa la mu'wi.",
        german: "Alles Lob gebührt Allah, Der uns zu essen und zu trinken gab, uns genügen ließ und uns Obdach gab. Denn wie viele gibt es, für die niemand genügt und die kein Obdach haben!",
        english: "All praise is for Allah, Who fed us and gave us drink, and Who is sufficient for us and has sheltered us. For how many have none to suffice them or shelter them!",
        count: 1),
    // 11. Allahumma 'alimal-ghaybi
    AdhkarItem(
        arabic: "اللَّهُمَّ عَالِمَ الغَيْبِ وَالشَّهَادَةِ فَاطِرَ السَّمَوَاتِ وَالْأَرْضِ، رَبَّ كُلِّ شَيْءٍ وَمَلِيكَهُ، أَشْهَدُ أَنْ لاَ إِلَهَ إِلاَّ أَنْتَ، أَعُوذُ بِكَ مِنْ شَرِّ نَفْسِي، وَمِنْ شَرِّ الشَّيْطانِ وَشِرْكِهِ، وَأَنْ أَقْتَرِفَ عَلَى نَفْسِي سُوءاً، أَوْ أَجُرَّهُ إِلَى مُسْلِمٍ",
        transliteration: "Allahumma 'Alimal-ghaybi wash-shahadati Fatiras-samawati wal-ard, Rabba kulli shay'in wa Malikah. Ash-hadu an la ilaha illa Ant. A'udhu bika min sharri nafsi, wa min sharrish-shaytani wa shirkihi, wa an aqtarifa 'ala nafsi su'an, aw ajurrahu ila Muslim.",
        german: "O Allah, Kenner des Verborgenen und des Offenbaren, Schöpfer der Himmel und der Erde, Herr und König von allem. Ich bezeuge, dass es keinen Gott gibt außer Dir. Ich suche Zuflucht bei Dir vor dem Übel meiner eigenen Seele, vor dem Übel des Satans und seiner Verführung zur Beigesellung (Schirk), und davor, dass ich mir selbst Böses antue oder es über einen Muslim bringe.",
        english: "O Allah, Knower of the unseen and the evident, Maker of the heavens and the earth, Lord of all things and their Sovereign, I bear witness that there is none worthy of worship but You. I seek refuge in You from the evil of my soul and from the evil of Satan and his helpers, and (I seek refuge in You) from bringing evil upon my soul or from harming a Muslim.",
        count: 1),
    // 12. Sure Al-Mulk
    AdhkarItem(
        arabic: "سُورَةُ الْمُلْكِ",
        transliteration: "Surah Al-Mulk",
        german: "Sure Al-Mulk",
        english: "Surah Al-Mulk",
        count: 1,
        audioFileName: "quran_mulk"),
    // 13. Allahumma aslamtu nafsi ilayk
    AdhkarItem(
        arabic: "اللَّهُمَّ أَسْلَمْتُ نَفْسِي إِلَيْكَ، وَفَوَّضْتُ أَمْرِي إِلَيْكَ، وَوَجَّهْتُ وَجْهِي إِلَيْكَ، وَأَلْجَأْتُ ظَهْرِي إِلَيْكَ، رَغْبَةً وَرَهْبَةً إِلَيْكَ، لاَ مَلْجَأَ وَلاَ مَنْجَا مِنْكَ إِلاَّ إِلَيْكَ، آمَنْتُ بِكِتَابِكَ الَّذِي أَنْزَلْتَ، وَبِنَبِيِّكَ الَّذِي أَرْسَلْتَ",
        transliteration: "Allahumma aslamtu nafsi ilayk, wa fawwadtu amri ilayk, wa wajjahtu wajhi ilayk, wa alja'tu dhahri ilayk, raghbatan wa rahbatan ilayk. La malja'a wa la manja minka illa ilayk. Amantu bikitabikal-ladhi anzalt, wa bi-nabiyyikal-ladhi arsalt.",
        german: "O Allah, ich ergebe mich Dir, übergebe meine Angelegenheit an Dich, wende mein Gesicht Dir zu und lehne meinen Rücken an Dich, aus Verlangen nach Dir und aus Furcht vor Dir. Es gibt keine Zuflucht und keine Rettung vor Dir außer bei Dir. Ich glaube an Dein Buch, das Du herabgesandt hast, und an Deinen Propheten, den Du gesandt hast.",
        english: "O Allah, I submit myself to You, entrust my affairs to You, turn my face to You, and lay my back upon You, out of hope in You and fear of You. There is no refuge or escape from You except in You. I believe in Your Book which You have revealed, and in Your Prophet whom You have sent.",
        count: 1)
]

extension AdhkarItem {
    var defaultInterval: TimeInterval {
        let text = self.arabic
        
        // Spezifische Optimierungen für bekannte Adhkar
        if text.contains("سُبْحَانَ اللَّهِ وَبِحَمْدِهِ") {
            return 1.45 // Subhanallahi wa bihamdihi (ca. 41 BPM)
        }
        if text.contains("أَسْتَغْفِرُ") {
            return 1.65 // Astaghfirullah wa atubu ilayh (ca. 36 BPM)
        }
        if text.contains("صَلِّ وَسَلِّمْ") || text.contains("اللَّهُمَّ صَلِّ") {
            return 1.75 // Allahumma salli... (ca. 34 BPM)
        }
        if text.contains("لاَ إِلَهَ إِلاَّ اللَّهُ") || text.contains("لَا إِلَهَ إِلَّا اللَّهُ") {
            return 5.5 // La ilaha illallah... (ca. 11 BPM)
        }
        
        // Dynamische Berechnung auf Buchstaben-Basis (ohne Tashkeel/Harakat)
        // Harakat liegen im Unicode-Bereich U+064B bis U+065F und U+0670
        let cleanedText = text.filter { char in
            guard let scalar = char.unicodeScalars.first else { return true }
            let val = scalar.value
            let isTashkeel = (val >= 0x064B && val <= 0x065F) || val == 0x0670
            return !isTashkeel
        }
        
        let letterCount = cleanedText.count
        // 85 Millisekunden (0.085s) pro Buchstabe/Leerzeichen ist ein sehr natürliches mittleres Tempo.
        return max(1.2, Double(letterCount) * 0.0806)
    }

    func translation(for lang: String) -> String {
        let l = lang.lowercased()
        if l == "ar" {
            return ""
        }
        if l == "en" {
            if !self.english.isEmpty {
                return self.english
            }
            return AdhkarTranslations.getEnglish(for: self.arabic) ?? self.german
        }
        if l == "de" {
            return self.german
        }
        if let loc = AdhkarTranslations.getLocalized(for: self.arabic, lang: l) {
            return loc
        }
        return self.english.isEmpty ? (AdhkarTranslations.getEnglish(for: self.arabic) ?? self.german) : self.english
    }
}

struct AdhkarTranslations {
    static func getEnglish(for arabic: String) -> String? {
        for (key, val) in translations {
            if arabic.range(of: key, options: .literal) != nil {
                return val
            }
        }
        return nil
    }
    
    static let localizedTranslations: [String: [String: String]] = [
        "أَصْبَحْنَا وَأَصْبَحَ": [
            "fr": "Nous voici au matin et la royauté appartient à Allah. Toute louange est à Allah. Mon Seigneur, je Te demande le bien de cette journée. Je cherche refuge auprès de Toi contre la paresse et la vieillesse, et contre le châtiment du Feu et de la Tombe.",
            "es": "Hemos llegado a la mañana y el reino pertenece a Allah. Toda alabanza es para Allah. Mi Señor, te pido el bien de este día. Busco refugio en Ti de la pereza y la senilidad, y del castigo del Fuego y de la Tumba.",
            "ur": "ہم نے صبح کی اور تمام بادشاہی اللہ کی ہے، اور تمام تعریفیں اللہ کے لیے ہیں۔ اے میرے رب، میں تجھ سے اس دن کی بھلائی مانگتا ہوں۔ میں تیری پناہ مانگتا ہوں سستی اور بڑھاپے سے، اور آگ اور قبر کے عذاب سے۔",
            "id": "Kami telah memasuki pagi dan pada saat ini seluruh kerajaan milik Allah, dan segala puji bagi Allah. Tuhanku, aku memohon kepada-Mu kebaikan hari ini. Aku berlindung kepada-Mu dari kemalasan dan kepikunan, serta dari siksaan Neraka dan Kubur.",
            "tr": "Sabaha ulaştık ve bu vakitte mülk Allah'ındır, hamd Allah'adır. Rabbim, Senden bu günün hayrını dilerim. Tembellikten ve yaşlılıktan, cehennem ve kabir azabından Sana sığınırım.",
            "ru": "Мы дожили до утра, и вся власть принадлежит Аллаху. Вся хвала Аллаху. Господь мой, я прошу у Тебя блага этого дня. Я ищу у Тебя защиты от лени и дряхлости, а также от мучений Огня и Могилы.",
            "bn": "আমরা সকালে উপনীত হয়েছি, আর রাজত্ব একমাত্র আল্লাহর। সমস্ত প্রশংসা আল্লাহর। হে আমার রব, আমি আপনার কাছে এই দিনের কল্যাণ প্রার্থনা করছি। আমি আপনার আশ্রয় চাচ্ছি অলসতা ও বার্ধক্য থেকে, এবং জাহান্নাম ও কবরের আজাব থেকে।",
        ],
        "اللَّهُمَّ بِكَ أَصْبَ": [
            "fr": "Ô Allah, par Toi nous entrons dans le matin et par Toi nous entrons dans le soir, par Toi nous vivons et par Toi nous mourons, et vers Toi est la résurrection.",
            "es": "Oh Allah, por Ti entramos en la mañana y por Ti entramos en la tarde, por Ti vivimos y por Ti morimos, y hacia Ti es la resurrección.",
            "ur": "اے اللہ، ہم نے تیری ہی مدد سے صبح کی اور تیری ہی مدد سے شام کی، تیرے ہی نام پر ہم جیتے ہیں اور مرتے ہیں، اور تیری ہی طرف اٹھ کر جانا ہے۔",
            "id": "Ya Allah, dengan-Mu kami memasuki pagi dan dengan-Mu kami memasuki petang, dengan-Mu kami hidup dan dengan-Mu kami mati, dan kepada-Mulah kebangkitan.",
            "tr": "Allahım, Seninle sabaha erdik, Seninle akşama erdik, Seninle yaşarız, Seninle ölürüz ve diriliş Sanadır.",
            "ru": "О Аллах, благодаря Тебе мы дожили до утра и благодаря Тебе мы доживаем до вечера, благодаря Тебе мы живем и благодаря Тебе мы умираем, и к Тебе предстоит воскрешение.",
            "bn": "হে আল্লাহ, আপনারই অনুগ্রহে আমরা সকালে উপনীত হই এবং আপনারই অনুগ্রহে সন্ধ্যায় উপনীত হই, আপনারই আদেশে আমরা বাঁচি এবং আপনারই আদেশে আমরা মৃত্যুবরণ করি, আর আপনার কাছেই পুনরুত্থান।",
        ],
        "اللَّهُمَّ مَا أَصْبَ": [
            "fr": "Ô Allah, tout bienfait qui m'a atteint ou qui a atteint l'une de Tes créatures ce matin vient de Toi seul. Tu n'as pas d'associé.",
            "es": "Oh Allah, cualquier bendición que me haya alcanzado a mí o a cualquiera de Tus creaciones esta mañana es solo de Ti. No tienes compañero.",
            "ur": "اے اللہ، اس صبح جو بھی نعمت مجھے یا تیری کسی مخلوق کو پہنچی ہے وہ صرف تیری طرف سے ہے۔ تیرا کوئی شریک نہیں۔",
            "id": "Ya Allah, nikmat apa pun yang sampai kepadaku atau kepada siapa pun dari ciptaan-Mu pada pagi ini adalah dari-Mu semata. Engkau tidak memiliki sekutu.",
            "tr": "Allahım, bu sabah bana veya yaratıklarından herhangi birine ulaşan nimet sadece Sendendir. Senin ortağın yoktur.",
            "ru": "О Аллах, любая милость, которая достигла меня или кого-либо из Твоих творений этим утром, исходит только от Тебя. У Тебя нет сотоварища.",
            "bn": "হে আল্লাহ, এই সকালে আমার কাছে বা আপনার কোনো সৃষ্টির কাছে যে নিয়ামত পৌঁছেছে তা কেবল আপনারই পক্ষ থেকে। আপনার কোনো শরিক নেই।",
        ],
        "أَصْبَحْنَا عَلَى فِ": [
            "fr": "Nous sommes au matin sur la nature de l'Islam, la parole de sincérité, la religion de notre Prophète Muhammad et la voie de notre père Ibrahim.",
            "es": "Hemos entrado en la mañana en el estado natural del Islam, la palabra de sinceridad, la religión de nuestro Profeta Muhammad y el camino de nuestro padre Ibrahim.",
            "ur": "ہم نے اسلام کی فطرت، اخلاص کے کلمے، اپنے نبی محمد صلی اللہ علیہ وسلم کے دین اور اپنے باپ ابراہیم علیہ السلام کے طریقے پر صبح کی۔",
            "id": "Kami memasuki pagi di atas fitrah Islam, kalimat ikhlas, agama Nabi kami Muhammad dan jalan ayah kami Ibrahim.",
            "tr": "İslam fıtratı, ihlas kelimesi, Peygamberimiz Muhammed'in dini ve atamız İbrahim'in yolu üzere sabaha erdik.",
            "ru": "Мы дожили до утра в естественном состоянии ислама, на слове искренности, в религии нашего Пророка Мухаммада и на пути нашего отца Ибрахима.",
            "bn": "আমরা সকালে উপনীত হয়েছি ইসলামের ফিতরতের ওপর, ইখলাসের বাণীর ওপর, আমাদের নবী মুহাম্মাদ (সা.)-এর ধর্মের ওপর এবং আমাদের পিতা ইবরাহিম (আ.)-এর তরিকার ওপর।",
        ],
        "اللَّهُمَّ أَنْتَ رَ": [
            "fr": "Ô Allah, Tu es mon Seigneur. Il n'y a de divinité que Toi. Tu m'as créé et je suis Ton serviteur. Je reconnais Tes bienfaits et mes péchés. Pardonne-moi — Sayyidul Istighfar.",
            "es": "Oh Allah, Tú eres mi Señor. No hay deidad excepto Tú. Me creaste y soy Tu siervo. Admito Tus favores y mi pecado. Perdóname — Sayyidul Istighfar.",
            "ur": "اے اللہ، تو میرا رب ہے۔ تیرے سوا کوئی معبود نہیں۔ تو نے مجھے پیدا کیا اور میں تیرا بندہ ہوں۔ میں تیری نعمتوں اور اپنے گناہوں کا اقرار کرتا ہوں۔ مجھے بخش دے — سید الاستغفار۔",
            "id": "Ya Allah, Engkaulah Tuhanku. Tidak ada Tuhan selain Engkau. Engkau menciptakanku dan aku adalah hamba-Mu. Aku mengakui nikmat-Mu dan dosaku. Ampunilah aku — Sayyidul Istighfar.",
            "tr": "Allahım, Sen benim Rabbimsin. Senden başka ilah yoktur. Beni Sen yarattın ve ben Senin kulunum. Nimetini ve günahımı itiraf ediyorum. Beni bağışla — Seyyidül İstiğfar.",
            "ru": "О Аллах, Ты — мой Господь. Нет божества, кроме Тебя. Ты создал меня, и я Твой раб. Я признаю Твои милости и свои грехи. Прости меня — Саййидуль Истигфар.",
            "bn": "হে আল্লাহ, আপনি আমার রব। আপনি ছাড়া আর কোনো উপাস্য নেই। আপনি আমাকে সৃষ্টি করেছেন এবং আমি আপনার বান্দা। আমি আপনার নিয়ামত ও আমার পাপ স্বীকার করছি। আমাকে ক্ষমা করুন — সাইয়্যিদুল ইস্তিগফার।",
        ],
        "اللَّهُمَّ إِنِّي أَ": [
            "fr": "Ô Allah, je Te demande le bien-être dans ce monde et dans l'au-delà. Couvre mes défauts, apaise mes peurs. Protège-moi de tous côtés.",
            "es": "Oh Allah, te pido bienestar en este mundo y en el Más Allá. Cubre mis faltas, calma mis miedos. Protégeme por todos lados.",
            "ur": "اے اللہ، میں تجھ سے دنیا اور آخرت میں عافیت مانگتا ہوں۔ میرے عیبوں کو چھپا، میرے خوف کو دور کر۔ مجھے ہر طرف سے محفوظ رکھ۔",
            "id": "Ya Allah, aku memohon kepada-Mu kesejahteraan di dunia dan di akhirat. Tutupilah aibku, tenangkanlah rasa takutku. Lindungilah aku dari semua sisi.",
            "tr": "Allahım, Senden dünya ve ahirette afiyet dilerim. Ayıplarımı ört, korkularımı gider. Beni her yönden koru.",
            "ru": "О Аллах, я прошу у Тебя благополучия в этом мире и в Последней жизни. Скрой мои недостатки, успокой мои страхи. Защити меня со всех сторон.",
            "bn": "হে আল্লাহ, আমি আপনার কাছে দুনিয়া ও আখিরাতে নিরাপত্তা প্রার্থনা করছি। আমার দোষত্রুটি ঢেকে রাখুন, আমার ভয় দূর করুন। আমাকে সব দিক থেকে রক্ষা করুন।",
        ],
        "اللَّهُمَّ عَافِنِي ": [
            "fr": "Ô Allah, accorde-moi le bien-être dans mon corps, dans mon ouïe et dans ma vue. Il n'y a de divinité digne d'être adorée que Toi.",
            "es": "Oh Allah, concédeme bienestar en mi cuerpo, en mi audición y en mi vista. No hay deidad digna de adoración excepto Tú.",
            "ur": "اے اللہ، مجھے میرے جسم میں، میری سماعت میں، اور میری بصارت میں عافیت دے۔ تیرے سوا کوئی عبادت کے لائق نہیں۔",
            "id": "Ya Allah, berikanlah kesehatan pada tubuhku, pada pendengaranku, dan pada penglihatanku. Tidak ada Tuhan yang berhak disembah selain Engkau.",
            "tr": "Allahım, bedenime, işitmeme ve görmeme afiyet ver. Senden başka ibadete layık ilah yoktur.",
            "ru": "О Аллах, даруй мне здоровье в моем теле, в моем слухе и в моем зрении. Нет божества, достойного поклонения, кроме Тебя.",
            "bn": "হে আল্লাহ, আমাকে আমার শরীরে, আমার শ্রবণে এবং আমার দৃষ্টিতে সুস্থতা দান করুন। আপনি ছাড়া ইবাদতের যোগ্য আর কোনো উপাস্য নেই।",
        ],
        "رَضِيتُ بِاللَّهِ رَ": [
            "fr": "Je suis satisfait d'Allah comme mon Seigneur, de l'Islam comme ma religion, et de Muhammad comme mon Prophète.",
            "es": "Estoy complacido con Allah como mi Señor, con el Islam como mi religión y con Muhammad como mi Profeta.",
            "ur": "میں اللہ کے رب ہونے، اسلام کے دین ہونے، اور محمد صلی اللہ علیہ وسلم کے نبی ہونے پر راضی ہوں۔",
            "id": "Aku rida Allah sebagai Tuhanku, Islam sebagai agamaku, dan Muhammad sebagai Nabiku.",
            "tr": "Rab olarak Allah'tan, din olarak İslam'dan ve peygamber olarak Muhammed'den razı oldum.",
            "ru": "Я доволен Аллахом как моим Господом, исламом как моей религией и Мухаммадом как моим Пророком.",
            "bn": "আমি আল্লাহকে রব হিসেবে, ইসলামকে ধর্ম হিসেবে এবং মুহাম্মাদ (সা.)-কে নবী হিসেবে পেয়ে সন্তুষ্ট।",
        ],
        "بِاسْمِ اللَّهِ الَّذ": [
            "fr": "Au nom d'Allah, dont le nom protège contre tout mal sur terre et dans les cieux. Il est l'Audient, l'Omniscient.",
            "es": "En el nombre de Allah, con cuyo nombre nada en la tierra ni en el cielo puede causar daño. Él es Quien todo lo oye, Quien todo lo sabe.",
            "ur": "اللہ کے نام سے، جس کے نام کے ساتھ زمین اور آسمان کی کوئی چیز نقصان نہیں پہنچا سکتی۔ وہ سب کچھ سننے والا، سب کچھ جاننے والا ہے۔",
            "id": "Dengan nama Allah, yang dengan nama-Nya tidak ada sesuatu pun di bumi maupun di langit yang dapat mendatangkan bahaya. Dialah Yang Maha Mendengar lagi Maha Mengetahui.",
            "tr": "İsmiyle yerde ve gökte hiçbir şeyin zarar veremeyeceği Allah'ın adıyla. O, hakkıyla işiten, hakkıyla bilendir.",
            "ru": "С именем Аллаха, с именем которого ничто на земле и на небесах не может причинить вреда. Он — Всеслышащий, Всезнающий.",
            "bn": "আল্লাহর নামে, যাঁর নামের সাথে আসমান ও জমিনের কোনো কিছুই ক্ষতি করতে পারে না। তিনি সর্বশ্রোতা, সর্বজ্ঞ।",
        ],
        "اللَّهُمَّ فَاطِرَ ال": [
            "fr": "Ô Allah, Créateur des cieux et de la terre, Connaisseur de l'invisible et du visible. J'atteste qu'il n'y a de divinité digne d'être adorée que Toi. Je cherche refuge auprès de Toi contre le mal de mon âme et le diable.",
            "es": "Oh Allah, Creador de los cielos y la tierra, Conocedor de lo oculto y lo manifiesto. Atestiguo que nadie tiene derecho a ser adorado excepto Tú. Busco refugio en Ti del mal de mí mismo y del diablo.",
            "ur": "اے اللہ، آسمانوں اور زمین کے پیدا کرنے والے، غیب اور حاضر کو جاننے والے۔ میں گواہی دیتا ہوں کہ تیرے سوا کوئی عبادت کے لائق نہیں۔ میں اپنے نفس کے شر اور شیطان کے شر سے تیری پناہ مانگتا ہوں۔",
            "id": "Ya Allah, Pencipta langit dan bumi, Yang Mengetahui yang ghaib dan yang nyata. Aku bersaksi bahwa tidak ada Tuhan yang berhak disembah selain Engkau. Aku berlindung kepada-Mu dari keburukan diriku dan setan.",
            "tr": "Allahım, göklerin ve yerin Yaratıcısı, gizliyi ve açığı bilen. Senden başka ibadete layık hiçbir ilah olmadığına şahitlik ederim. Nefsimin şerrinden ve şeytanın şerrinden Sana sığınırım.",
            "ru": "О Аллах, Творец небес и земли, Знающий сокровенное и явное. Я свидетельствую, что нет никого достойного поклонения, кроме Тебя. Я ищу у Тебя защиты от зла моей души и шайтана.",
            "bn": "হে আল্লাহ, আসমান ও জমিনের স্রষ্টা, দৃশ্য ও অদৃশ্যের জ্ঞাতা। আমি সাক্ষ্য দিচ্ছি যে, আপনি ছাড়া ইবাদতের যোগ্য আর কেউ নেই। আমি আমার নিজের অনিষ্ট এবং শয়তানের অনিষ্ট থেকে আপনার আশ্রয় চাই।",
        ],
        "يَا حَيُّ يَا قَيُّ": [
            "fr": "Ô Vivant, ô Subsistant, par Ta miséricorde je T'invoque. Rectifie toutes mes affaires et ne me laisse pas à moi-même le temps d'un clin d'œil.",
            "es": "Oh Viviente, oh Sustentador, por Tu misericordia te invoco. Rectifica todos mis asuntos y no me dejes a mí mismo ni por un abrir y cerrar de ojos.",
            "ur": "اے ہمیشہ زندہ رہنے والے، اے سب کو قائم رکھنے والے، تیری رحمت کے واسطے سے تجھے پکارتا ہوں۔ میرے تمام کام سنوار دے اور مجھے ایک لمحے کے لیے بھی میرے نفس کے حوالے نہ کر۔",
            "id": "Wahai Yang Maha Hidup, Wahai Yang Berdiri Sendiri, dengan rahmat-Mu aku memohon kepada-Mu. Perbaikilah semua urusanku dan janganlah Engkau serahkan aku kepada diriku sendiri walau sekejap mata.",
            "tr": "Ey Hayy (diri) ve Kayyum (her şeyi ayakta tutan), rahmetinle Sana sığınıyorum. Bütün işlerimi düzelt ve beni göz açıp kapayıncaya kadar bile kendi nefsime bırakma.",
            "ru": "О Живой, о Поддерживающий жизнь, к милости Твоей я взываю. Устрой все мои дела наилучшим образом и не оставляй меня наедине с моей душой даже на мгновение ока.",
            "bn": "হে চিরঞ্জীব, হে চিরস্থায়ী, আমি আপনার রহমতের উসিলায় আপনাকে ডাকছি। আমার সমস্ত কাজ সংশোধন করে দিন এবং চোখের পলকের জন্যও আমাকে আমার নিজের কাছে সোপর্দ করবেন না।",
        ],
        "حَسْبِيَ اللَّهُ لَا": [
            "fr": "Allah me suffit. Il n'y a de divinité que Lui. En Lui je place ma confiance. Il est le Seigneur du Trône Majestueux.",
            "es": "Allah es suficiente para mí. No hay deidad excepto Él. Pongo mi confianza en Él. Él es el Señor del Trono Majestuoso.",
            "ur": "اللہ میرے لیے کافی ہے۔ اس کے سوا کوئی معبود نہیں۔ میں نے اسی پر بھروسہ کیا ہے۔ وہ عرشِ عظیم کا رب ہے۔",
            "id": "Cukuplah Allah bagiku. Tidak ada Tuhan selain Dia. Hanya kepada-Nya aku bertawakal. Dia adalah Tuhan pemilik Arsy yang agung.",
            "tr": "Allah bana yeter. O'ndan başka ilah yoktur. Ben O'na güvendim. O, Yüce Arş'ın Rabbidir.",
            "ru": "Мне достаточно Аллаха. Нет божества, кроме Него. Я уповаю на Него. Он — Господь Великого Трона.",
            "bn": "আমার জন্য আল্লাহই যথেষ্ট। তিনি ছাড়া কোনো উপাস্য নেই। আমি তাঁরই ওপর ভরসা করি। তিনি মহান আরশের রব।",
        ],
        "سُبْحَانَ اللَّهِ وَب": [
            "fr": "Gloire et louange à Allah, autant de fois qu'il y a de créatures, selon Sa satisfaction, le poids de Son Trône et l'encre de Ses paroles.",
            "es": "Gloria a Allah y alabanza a Él, según el número de Su creación, Su complacencia, el peso de Su Trono y la tinta de Sus palabras.",
            "ur": "اللہ کی پاکی بیان کرتا ہوں اور اس کی تعریف، اس کی مخلوق کی تعداد، اس کی رضا، اس کے عرش کے وزن اور اس کے کلمات کی سیاہی کے برابر۔",
            "id": "Maha Suci Allah dan segala puji bagi-Nya, sebanyak jumlah ciptaan-Nya, keridhaan-Nya, berat Arsy-Nya, dan tinta firman-Nya.",
            "tr": "Yarattıklarının sayısı, Kendi hoşnutluğu, Arş'ının ağırlığı ve kelimelerinin mürekkebi kadar Allah'ı tesbih eder ve O'na hamdederim.",
            "ru": "Слава Аллаху и хвала Ему по числу Его творений, по Его довольству, по весу Его Трона и по чернилам Его слов.",
            "bn": "আল্লাহর পবিত্রতা ও প্রশংসা বর্ণনা করছি, তাঁর সৃষ্টির সংখ্যার সমান, তাঁর সন্তুষ্টির সমান, তাঁর আরশের ওজনের সমান এবং তাঁর বাক্যসমূহের কালির সমান।",
        ],
        "سُبْحَانَ اللَّهِ (": [
            "fr": "Tasbih avant de dormir : Gloire à Allah (33x), Louange à Allah (33x), Allah est le plus Grand (34x).",
            "es": "Tasbih antes de dormir: Gloria a Allah (33x), Alabanza a Allah (33x), Allah es el Más Grande (34x).",
            "ur": "سونے سے پہلے کی تسبیح: سبحان اللہ (33 مرتبہ)، الحمد للہ (33 مرتبہ)، اللہ اکبر (34 مرتبہ)۔",
            "id": "Tasbih sebelum tidur: Maha Suci Allah (33x), Segala Puji bagi Allah (33x), Allah Maha Besar (34x).",
            "tr": "Uyumadan önce tesbih: Sübhanallah (33x), Elhamdülillah (33x), Allahu Ekber (34x).",
            "ru": "Тасбих перед сном: Субханаллах (33x), Альхамдулиллах (33x), Аллаху Акбар (34x).",
            "bn": "ঘুমানোর আগে তাসবিহ: সুবহানাল্লাহ (৩৩ বার), আলহামদুলিল্লাহ (৩৩ বার), আল্লাহু আকবার (৩৪ বার)।",
        ],
        "لَا إِلَهَ إِلَّا ال": [
            "fr": "Il n'y a de divinité digne d'être adorée qu'Allah, seul, sans associé. À Lui la royauté et toute louange. Il est capable de toute chose.",
            "es": "No hay deidad digna de adoración excepto Allah, solo, sin asociados. A Él pertenece el dominio y toda alabanza. Él es capaz de todas las cosas.",
            "ur": "اللہ کے سوا کوئی عبادت کے لائق نہیں، وہ اکیلا ہے، اس کا کوئی شریک نہیں۔ اسی کے لیے بادشاہی اور تمام تعریف ہے۔ وہ ہر چیز پر قادر ہے۔",
            "id": "Tidak ada Tuhan yang berhak disembah selain Allah semata, tidak ada sekutu bagi-Nya. Bagi-Nya kerajaan dan segala puji. Dia Maha Kuasa atas segala sesuatu.",
            "tr": "Allah'tan başka ibadete layık ilah yoktur, O tektir ve ortağı yoktur. Mülk O'nundur ve bütün hamd O'nadır. O, her şeye gücü yetendir.",
            "ru": "Нет божества, достойного поклонения, кроме одного Аллаха, у которого нет сотоварища. Ему принадлежит власть и вся хвала. Он способен на всякую вещь.",
            "bn": "একমাত্র আল্লাহ ছাড়া ইবাদতের যোগ্য কোনো উপাস্য নেই, তাঁর কোনো শরিক নেই। রাজত্ব এবং সমস্ত প্রশংসা তাঁরই। তিনি সবকিছুর ওপর ক্ষমতাবান।",
        ],
        "أَسْتَغْفِرُ اللهَ وَ": [
            "fr": "Je demande pardon à Allah et je me repens à Lui.",
            "es": "Pido perdón a Allah y me vuelvo a Él en arrepentimiento.",
            "ur": "میں اللہ سے معافی مانگتا ہوں اور اسی کی طرف توبہ کرتا ہوں۔",
            "id": "Aku memohon ampun kepada Allah dan bertaubat kepada-Nya.",
            "tr": "Allah'tan bağışlanma dilerim ve O'na tövbe ederim.",
            "ru": "Я прошу у Аллаха прощения и обращаюсь к Нему с покаянием.",
            "bn": "আমি আল্লাহর কাছে ক্ষমা প্রার্থনা করছি এবং তাঁর কাছে তওবা করছি।",
        ],
        "أَمْسَيْنَا وَأَمْسَى": [
            "fr": "Nous voici au soir et la royauté appartient à Allah. Toute louange est à Allah. Mon Seigneur, je Te demande le bien de cette nuit. Je cherche refuge auprès de Toi contre la paresse et la vieillesse, et contre le châtiment du Feu et de la Tombe.",
            "es": "Hemos llegado a la tarde y el reino pertenece a Allah. Toda alabanza es para Allah. Mi Señor, te pido el bien de esta noche. Busco refugio en Ti de la pereza y la senilidad, y del castigo del Fuego y de la Tumba.",
            "ur": "ہم نے شام کی اور تمام بادشاہی اللہ کی ہے، اور تمام تعریفیں اللہ کے لیے ہیں۔ اے میرے رب، میں تجھ سے اس رات کی بھلائی مانگتا ہوں۔ میں تیری پناہ مانگتا ہوں سستی اور بڑھاپے سے، اور آگ اور قبر کے عذاب سے۔",
            "id": "Kami telah memasuki petang dan pada saat ini seluruh kerajaan milik Allah, dan segala puji bagi Allah. Tuhanku, aku memohon kepada-Mu kebaikan malam ini. Aku berlindung kepada-Mu dari kemalasan dan kepikunan, serta dari siksaan Neraka dan Kubur.",
            "tr": "Akşama ulaştık ve bu vakitte mülk Allah'ındır, hamd Allah'adır. Rabbim, Senden bu gecenin hayrını dilerim. Tembellikten ve yaşlılıktan, cehennem ve kabir azabından Sana sığınırım.",
            "ru": "Мы дожили до вечера, и вся власть принадлежит Аллаху. Вся хвала Аллаху. Господь мой, я прошу у Тебя блага этой ночи. Я ищу у Тебя защиты от лени и дряхлости, а также от мучений Огня и Могилы.",
            "bn": "আমরা সন্ধ্যায় উপনীত হয়েছি, আর রাজত্ব একমাত্র আল্লাহর। সমস্ত প্রশংসা আল্লাহর। হে আমার রব, আমি আপনার কাছে এই রাতের কল্যাণ প্রার্থনা করছি। আমি আপনার আশ্রয় চাচ্ছি অলসতা ও বার্ধক্য থেকে, এবং জাহান্নাম ও কবরের আজাব থেকে।",
        ],
        "اللَّهُمَّ بِكَ أَمْسَ": [
            "fr": "Ô Allah, par Toi nous entrons dans le soir et par Toi nous entrons dans le matin, par Toi nous vivons et par Toi nous mourons, et vers Toi est le retour.",
            "es": "Oh Allah, por Ti entramos en la tarde y por Ti entramos en la mañana, por Ti vivimos y por Ti morimos, y a Ti es el retorno.",
            "ur": "اے اللہ، ہم نے تیری ہی مدد سے شام کی اور تیری ہی مدد سے صبح کی، تیرے ہی نام پر ہم جیتے ہیں اور مرتے ہیں، اور تیری ہی طرف لوٹ کر جانا ہے۔",
            "id": "Ya Allah, dengan-Mu kami memasuki petang dan dengan-Mu kami memasuki pagi, dengan-Mu kami hidup dan dengan-Mu kami mati, dan kepada-Mulah tempat kembali.",
            "tr": "Allahım, Seninle akşama erdik, Seninle sabaha erdik, Seninle yaşarız, Seninle ölürüz ve dönüş Sanadır.",
            "ru": "О Аллах, благодаря Тебе мы доживаем до вечера и благодаря Тебе мы доживаем до утра, благодаря Тебе мы живем и благодаря Тебе мы умираем, и к Тебе предстоит возвращение.",
            "bn": "হে আল্লাহ, আপনারই অনুগ্রহে আমরা সন্ধ্যায় উপনীত হই এবং আপনারই অনুগ্রহে সকালে উপনীত হই, আপনারই আদেশে আমরা বাঁচি এবং আপনারই আদেশে আমরা মৃত্যুবরণ করি, আর আপনার কাছেই ফিরে যেতে হবে।",
        ],
        "اللَّهُمَّ مَا أَمْسَ": [
            "fr": "Ô Allah, tout bienfait qui m'a atteint ou qui a atteint l'une de Tes créatures ce soir vient de Toi seul. Tu n'as pas d'associé.",
            "es": "Oh Allah, cualquier bendición que me haya alcanzado a mí o a cualquiera de Tus creaciones esta tarde es solo de Ti. No tienes compañero.",
            "ur": "اے اللہ، اس شام جو بھی نعمت مجھے یا تیری کسی مخلوق کو پہنچی ہے وہ صرف تیری طرف سے ہے۔ تیرا کوئی شریک نہیں۔",
            "id": "Ya Allah, nikmat apa pun yang sampai kepadaku atau kepada siapa pun dari ciptaan-Mu pada petang ini adalah dari-Mu semata. Engkau tidak memiliki sekutu.",
            "tr": "Allahım, bu akşam bana veya yaratıklarından herhangi birine ulaşan nimet sadece Sendendir. Senin ortağın yoktur.",
            "ru": "О Аллах, любая милость, которая достигла меня или кого-либо из Твоих творений этим вечером, исходит только от Тебя. У Тебя нет сотоварища.",
            "bn": "হে আল্লাহ, এই সন্ধ্যায় আমার কাছে বা আপনার কোনো সৃষ্টির কাছে যে নিয়ামত পৌঁছেছে তা কেবল আপনারই পক্ষ থেকে। আপনার কোনো শরিক নেই।",
        ],
        "بِسْمِ اللهِ الرَّحْم": [
            "fr": "Dis : Il est Allah, Unique, Allah, le Soutien universel. Il n'a pas engendré et n'a pas été engendré. Dis : Je cherche refuge auprès du Seigneur de l'aube naissante contre le mal de ce qu'Il a créé. Dis : Je cherche refuge auprès du Seigneur des hommes, le Souverain des hommes, le Dieu des hommes.",
            "es": "Di: Él es Allah, Uno, Allah, el Refugio Eterno. No engendra ni ha sido engendrado. Di: Busco refugio en el Señor del amanecer del mal de lo que Él ha creado. Di: Busco refugio en el Señor de la humanidad, el Soberano de la humanidad, el Dios de la humanidad.",
            "ur": "کہہ دیجئے: وہ اللہ ایک ہے۔ اللہ بے نیاز ہے۔ نہ اس کی کوئی اولاد ہے اور نہ وہ کسی کی اولاد ہے۔ کہہ دیجئے: میں صبح کے رب کی پناہ مانگتا ہوں ہر اس چیز کے شر سے جو اس نے پیدا کی ہے۔ کہہ دیجئے: میں لوگوں کے رب، لوگوں کے بادشاہ، لوگوں کے معبود کی پناہ مانگتا ہوں۔",
            "id": "Katakanlah: Dialah Allah, Yang Maha Esa, Allah tempat meminta segala sesuatu. Dia tiada beranak dan tiada pula diperanakkan. Katakanlah: Aku berlindung kepada Tuhan Yang Menguasai subuh dari kejahatan makhluk-Nya. Katakanlah: Aku berlindung kepada Tuhannya manusia, Rajanya manusia, Sembahannya manusia.",
            "tr": "De ki: O Allah tektir, Allah Samed'dir. Doğurmamış ve doğmamıştır. De ki: Yarattığı şeylerin şerrinden sabahın Rabbine sığınırım. De ki: İnsanların Rabbine, İnsanların Melikine, İnsanların İlahına sığınırım.",
            "ru": "Скажи: Он — Аллах Единый, Аллах Самодостаточный. Он не родил и не был рожден. Скажи: Я прибегаю к защите Господа рассвета от зла того, что Он сотворил. Скажи: Я прибегаю к защите Господа людей, Царя людей, Бога людей.",
            "bn": "বলুন: তিনি আল্লাহ, এক, আল্লাহ অমুখাপেক্ষী। তিনি কাউকে জন্ম দেননি এবং তাঁকেও জন্ম দেয়া হয়নি। বলুন: আমি আশ্রয় চাই ভোরবেলার রবের কাছে, তিনি যা সৃষ্টি করেছেন তার অনিষ্ট থেকে। বলুন: আমি আশ্রয় চাই মানুষের রবের কাছে, মানুষের অধিপতির কাছে, মানুষের ইলাহের কাছে।",
        ],
        "أَعُوذُ بِكَلِمَاتِ ": [
            "fr": "Je cherche refuge dans les paroles parfaites d'Allah contre le mal de ce qu'Il a créé.",
            "es": "Busco refugio en las palabras perfectas de Allah del mal de lo que Él ha creado.",
            "ur": "میں اللہ کے کامل کلمات کے ذریعے ہر اس چیز کے شر سے پناہ مانگتا ہوں جو اس نے پیدا کی ہے۔",
            "id": "Aku berlindung dengan kalimat-kalimat Allah yang sempurna dari keburukan apa yang Dia ciptakan.",
            "tr": "Yarattıklarının şerrinden Allah'ın eksiksiz kelimelerine sığınırım.",
            "ru": "Я прибегаю к совершенным словам Аллаха от зла того, что Он сотворил.",
            "bn": "আমি আল্লাহর পরিপূর্ণ বাক্যসমূহের সাহায্যে তাঁর সৃষ্ট বস্তুর অনিষ্ট থেকে আশ্রয় চাই।",
        ],
        "بِاسْمِكَ رَبِّي وَض": [
            "fr": "En Ton nom, mon Seigneur, je pose mon côté, et par Toi je le relève. Si Tu prends mon âme, fais-lui miséricorde, et si Tu la relâches, protège-la comme Tu protèges Tes pieux serviteurs.",
            "es": "En Tu nombre, mi Señor, acuesto mi costado, y por Ti lo levanto. Si tomas mi alma, ten piedad de ella, y si la liberas, protégela como proteges a Tus siervos justos.",
            "ur": "اے میرے رب، میں نے تیرے نام پر اپنا پہلو رکھا اور تیری ہی مدد سے اسے اٹھاؤں گا۔ اگر تو میری جان قبض کر لے تو اس پر رحم فرما، اور اگر اسے چھوڑ دے تو اس کی حفاظت فرما جس طرح تو اپنے نیک بندوں کی حفاظت کرتا ہے۔",
            "id": "Dengan nama-Mu, Tuhanku, aku membaringkan lambungku, dan dengan-Mu aku mengangkatnya. Jika Engkau menahan ruhku, rahmatilah ia, dan jika Engkau melepaskannya, jagalah ia sebagaimana Engkau menjaga hamba-hamba-Mu yang saleh.",
            "tr": "Senin adınla Rabbim, yanımı yatağa koydum ve Seninle kaldırırım. Eğer ruhumu alırsan ona merhamet et, eğer serbest bırakırsan salih kullarını koruduğun gibi onu koru.",
            "ru": "С именем Твоим, Господи, я ложусь на бок, и с Тобой я поднимаюсь. Если Ты заберешь мою душу, помилуй ее, а если отпустишь — защити ее так, как Ты защищаешь Своих праведных рабов.",
            "bn": "আপনার নামে, হে আমার রব, আমি আমার শরীর বিছানায় রাখলাম, এবং আপনার সাহায্যেই তা উঠাব। আপনি যদি আমার প্রাণ কেড়ে নেন, তবে তার প্রতি দয়া করুন, আর যদি তা ছেড়ে দেন, তবে তাকে রক্ষা করুন যেভাবে আপনি আপনার নেক বান্দাদের রক্ষা করেন।",
        ],
        "اللَّهُمَّ إِنَّكَ خ": [
            "fr": "Ô Allah, Tu as créé mon âme et Tu la reprends. À Toi appartiennent sa mort et sa vie. Si Tu la gardes en vie, protège-la, et si Tu la fais mourir, pardonne-lui. Ô Allah, je Te demande le bien-être.",
            "es": "Oh Allah, Tú creaste mi alma y Tú la tomas. A Ti pertenece su muerte y su vida. Si la mantienes viva, protégela, y si la haces morir, perdónala. Oh Allah, te pido bienestar.",
            "ur": "اے اللہ، تو نے میری جان کو پیدا کیا اور تو ہی اسے قبض کرے گا۔ اس کی موت اور اس کی زندگی تیرے ہی اختیار میں ہے۔ اگر تو اسے زندہ رکھے تو اس کی حفاظت فرما اور اگر تو اسے موت دے تو اسے بخش دے۔ اے اللہ، میں تجھ سے عافیت مانگتا ہوں۔",
            "id": "Ya Allah, Engkau menciptakan jiwaku dan Engkau yang mencabutnya. Milik-Mulah kematian dan kehidupannya. Jika Engkau menghidupkannya, jagalah ia, dan jika Engkau mematikannya, ampunilah ia. Ya Allah, aku memohon kesejahteraan kepada-Mu.",
            "tr": "Allahım, ruhumu Sen yarattın ve Sen alacaksın. Onun ölümü ve hayatı Sana aittir. Onu yaşatırsan koru, eğer öldürürsen bağışla. Allahım, Senden afiyet dilerim.",
            "ru": "О Аллах, Ты создал мою душу, и Ты забираешь ее. Тебе принадлежит ее смерть и ее жизнь. Если Ты сохранишь ей жизнь — защити ее, а если умертвишь — прости ее. О Аллах, я прошу у Тебя благополучия.",
            "bn": "হে আল্লাহ, আপনি আমার আত্মা সৃষ্টি করেছেন এবং আপনিই তা কবজ করবেন। এর মরণ ও জীবন আপনারই হাতে। যদি আপনি একে বাঁচিয়ে রাখেন, তবে একে রক্ষা করুন, আর যদি মৃত্যু দেন, তবে একে ক্ষমা করুন। হে আল্লাহ, আমি আপনার কাছে নিরাপত্তা চাই।",
        ],
        "اللَّهُمَّ قِنِي عَذ": [
            "fr": "Ô Allah, protège-moi de Ton châtiment le Jour où Tu ressusciteras Tes serviteurs.",
            "es": "Oh Allah, protégeme de Tu castigo el Día que resucites a Tus siervos.",
            "ur": "اے اللہ، مجھے اس دن اپنے عذاب سے بچانا جس دن تو اپنے بندوں کو اٹھائے گا۔",
            "id": "Ya Allah, lindungilah aku dari azab-Mu pada hari Engkau membangkitkan hamba-hamba-Mu.",
            "tr": "Allahım, kullarını dirilteceğin gün beni azabından koru.",
            "ru": "О Аллах, защити меня от Твоего наказания в Тот День, когда Ты воскресишь Своих рабов.",
            "bn": "হে আল্লাহ, যেদিন আপনি আপনার বান্দাদের পুনরুত্থিত করবেন, সেদিন আমাকে আপনার আজাব থেকে রক্ষা করুন।",
        ],
        "بِاسْمِكَ اللَّهُمَّ ": [
            "fr": "En Ton nom, ô Allah, je meurs et je vis.",
            "es": "En Tu nombre, oh Allah, muero y vivo.",
            "ur": "اے اللہ، میں تیرے ہی نام پر مرتا اور جیتا ہوں۔",
            "id": "Dengan nama-Mu, ya Allah, aku mati dan aku hidup.",
            "tr": "Senin adınla, ey Allahım, ölür ve yaşarım.",
            "ru": "С именем Твоим, о Аллах, я умираю и живу.",
            "bn": "আপনার নামে, হে আল্লাহ, আমি মরি এবং বাঁচি।",
        ],
        "اللَّهُمَّ رَبَّ الس": [
            "fr": "Ô Allah, Seigneur des sept cieux et Seigneur du Trône immense... soulage-nous de nos dettes et épargne-nous la pauvreté.",
            "es": "Oh Allah, Señor de los siete cielos y Señor del gran Trono... alíviame de las deudas y sálvanos de la pobreza.",
            "ur": "اے اللہ، ساتوں آسمانوں کے رب اور عرش عظیم کے رب... ہمارا قرض ادا کر دے اور ہمیں غریبی سے بچا لے۔",
            "id": "Ya Allah, Tuhan langit yang tujuh dan Tuhan Arsy yang agung... lunasilah utang kami dan selamatkanlah kami dari kemiskinan.",
            "tr": "Allahım, yedi kat göğün ve Yüce Arş'ın Rabbi... borcumuzu ödemeyi nasip et ve bizi fakirlikten kurtar.",
            "ru": "О Аллах, Господь семи небес и Господь великого Трона... избавь нас от долгов и спаси нас от бедности.",
            "bn": "হে আল্লাহ, সাত আসমান ও মহান আরশের রব... আমাদের ঋণ পরিশোধ করে দিন এবং দারিদ্র্য থেকে মুক্তি দিন।",
        ],
        "الْحَمْدُ لِلَّهِ ال": [
            "fr": "Louange à Allah qui nous a nourris, abreuvés, qui nous a suffi et nous a donné refuge. Combien sont ceux qui n'ont personne pour leur suffire ni les abriter !",
            "es": "Alabado sea Allah, que nos alimentó, nos dio de beber, nos bastó y nos dio refugio, porque cuántos hay que no tienen quien les baste o les dé refugio.",
            "ur": "تمام تعریفیں اللہ کے لیے ہیں جس نے ہمیں کھلایا، پلایا، ہمارے لیے کافی ہوا اور ہمیں پناہ دی۔ کتنے ہی لوگ ایسے ہیں جنہیں کوئی کافی ہونے والا اور پناہ دینے والا نہیں۔",
            "id": "Segala puji bagi Allah yang telah memberi kami makan, minum, mencukupi kami dan memberi kami tempat berteduh. Betapa banyak orang yang tidak memiliki siapa pun yang dapat mencukupi atau memberi mereka tempat berteduh.",
            "tr": "Bizi yediren, içiren, bize yeten ve bizi barındıran Allah'a hamdolsun. Nice kimseler var ki onlara yetecek ve barındıracak kimseleri yoktur.",
            "ru": "Хвала Аллаху, который накормил нас, напоил, удовлетворил наши нужды и дал нам приют, ведь как много тех, у кого нет никого, кто мог бы удовлетворить их нужды или дать им приют.",
            "bn": "সমস্ত প্রশংসা আল্লাহর জন্য, যিনি আমাদের খাইয়েছেন, পান করিয়েছেন, আমাদের জন্য যথেষ্ট হয়েছেন এবং আমাদের আশ্রয় দিয়েছেন। অথচ কত মানুষ এমন আছে যাদের জন্য যথেষ্ট হওয়ার বা আশ্রয় দেওয়ার কেউ নেই।",
        ],
        "اللَّهُمَّ عَالِمَ ال": [
            "fr": "Ô Allah, Connaisseur de l'invisible et du visible, Créateur des cieux et de la terre, Seigneur et Souverain de toute chose. J'atteste qu'il n'y a de divinité que Toi. Je cherche refuge auprès de Toi contre le mal de mon âme et le diable.",
            "es": "Oh Allah, Conocedor de lo oculto y lo manifiesto, Creador de los cielos y la tierra, Señor y Rey de todas las cosas. Atestiguo que no hay deidad excepto Tú. Busco refugio en Ti del mal de mí mismo y del diablo.",
            "ur": "اے اللہ، غیب اور حاضر کو جاننے والے، آسمانوں اور زمین کو پیدا کرنے والے، ہر چیز کے رب اور بادشاہ۔ میں گواہی دیتا ہوں کہ تیرے سوا کوئی معبود نہیں۔ میں اپنے نفس کے شر اور شیطان کے شر سے تیری پناہ مانگتا ہوں۔",
            "id": "Ya Allah, Yang Mengetahui yang ghaib dan yang nyata, Pencipta langit dan bumi, Tuhan dan Raja segala sesuatu. Aku bersaksi bahwa tidak ada Tuhan selain Engkau. Aku berlindung kepada-Mu dari keburukan diriku dan setan.",
            "tr": "Allahım, gizliyi ve açığı bilen, göklerin ve yerin Yaratıcısı, her şeyin Rabbi ve Hükümdarı. Senden başka ilah olmadığına şehadet ederim. Nefsimin şerrinden ve şeytanın şerrinden Sana sığınırım.",
            "ru": "О Аллах, Знающий сокровенное и явное, Творец небес и земли, Господь и Владыка всего сущего. Я свидетельствую, что нет божества, кроме Тебя. Я ищу у Тебя защиты от зла моей души и шайтана.",
            "bn": "হে আল্লাহ, দৃশ্য ও অদৃশ্যের জ্ঞাতা, আসমান ও জমিনের স্রষ্টা, সবকিছুর রব ও অধিপতি। আমি সাক্ষ্য দিচ্ছি যে, আপনি ছাড়া কোনো উপাস্য নেই। আমি আমার নিজের এবং শয়তানের অনিষ্ট থেকে আপনার আশ্রয় চাই।",
        ],
        "يَقْرَأُ ﴿الم﴾ تَنْ": [
            "fr": "Recommandation de la Sunnah : Réciter la Sourate As-Sajdah (Chapitre 32) et la Sourate Al-Mulk (Chapitre 67).",
            "es": "Recomendación de la Sunnah: Recitar la Surah As-Sajdah (Capítulo 32) y la Surah Al-Mulk (Capítulo 67).",
            "ur": "سنت کی سفارش: سورۃ السجدہ (باب 32) اور سورۃ الملک (باب 67) کی تلاوت کریں۔",
            "id": "Anjuran Sunnah: Membaca Surah As-Sajdah (Surah ke-32) dan Surah Al-Mulk (Surah ke-67).",
            "tr": "Sünnet tavsiyesi: Secde Suresi (32. Bölüm) ve Mülk Suresi'ni (67. Bölüm) okuyun.",
            "ru": "Рекомендация Сунны: читать суру «Ас-Сажда» (32-я глава) и суру «Аль-Мульк» (67-я глава).",
            "bn": "সুন্নাহর সুপারিশ: সূরা আস-সাজদাহ (অধ্যায় ৩২) এবং সূরা আল-মুলক (অধ্যায় ৬৭) তিলাওয়াত করুন।",
        ],
        "اللَّهُمَّ أَسْلَمْت": [
            "fr": "Ô Allah, je Te soumets mon âme, je Te délègue mes affaires, je tourne mon visage vers Toi, et je m'en remets à Toi, par espoir et par crainte de Toi. Il n'y a de refuge ni d'échappatoire contre Toi qu'auprès de Toi...",
            "es": "Oh Allah, someto mi alma a Ti, delego mi asunto en Ti, vuelvo mi rostro hacia Ti y confío en Ti, por esperanza y temor a Ti. No hay refugio ni escape de Ti sino hacia Ti...",
            "ur": "اے اللہ، میں نے اپنی جان تیرے سپرد کر دی، اپنا معاملہ تیرے حوالے کر دیا، اپنا رخ تیری طرف کر لیا، اور تجھ پر ہی بھروسہ کیا، تیری امید اور تیرے خوف کی وجہ سے۔ تیرے سوا تجھ سے بچنے کا کوئی ٹھکانہ اور پناہ گاہ نہیں...",
            "id": "Ya Allah, aku menyerahkan jiwaku kepada-Mu, menyerahkan urusanku kepada-Mu, menghadapkan wajahku kepada-Mu, dan bersandar kepada-Mu, karena harap dan cemas kepada-Mu. Tidak ada tempat berlindung dan tempat keselamatan dari-Mu kecuali kepada-Mu...",
            "tr": "Allahım, nefsimi Sana teslim ettim, işimi Sana havale ettim, yüzümü Sana döndüm ve Sana sığındım, Senden umarak ve Senden korkarak. Senden sığınılacak ve kaçılacak yer ancak yine Sensin...",
            "ru": "О Аллах, я предаю свою душу Тебе, вверяю свои дела Тебе, обращаю свое лицо к Тебе и полагаюсь на Тебя с надеждой и страхом перед Тобой. Нет убежища и спасения от Тебя, кроме как у Тебя...",
            "bn": "হে আল্লাহ, আমি আমার আত্মাকে আপনার কাছে সমর্পণ করলাম, আমার বিষয় আপনার কাছে অর্পণ করলাম, আমার চেহারা আপনার দিকে ফেরালাম, এবং আপনার ওপরই ভরসা করলাম, আপনার প্রতি আশা ও ভয়ের কারণে। আপনার আজাব থেকে বাঁচতে আপনি ছাড়া কোনো আশ্রয় বা পলায়নস্থল নেই...",
        ],
        "يَجْمَعُ كَفَّيْهِ ث": [
            "fr": "Joindre les paumes, souffler dedans, et réciter les trois Sourates protectrices (Al-Ikhlas, Al-Falaq, An-Nas). Puis essuyer la tête, le visage et l'avant du corps.",
            "es": "Juntar las palmas, soplar en ellas y recitar las tres Surahs protectoras (Al-Ikhlas, Al-Falaq, An-Nas). Luego pasar las manos sobre la cabeza, el rostro y la parte delantera del cuerpo.",
            "ur": "دونوں ہتھیلیوں کو ملائیں، ان میں پھونکیں، اور تینوں پناہ مانگنے والی سورتیں (الإخلاص، الفلق، الناس) پڑھیں۔ پھر سر، چہرے اور جسم کے اگلے حصے پر پھیریں۔",
            "id": "Gabungkan kedua telapak tangan, tiup ke dalamnya, lalu bacalah tiga Surah perlindungan (Al-Ikhlas, Al-Falaq, An-Nas). Kemudian usapkan ke atas kepala, wajah, dan bagian depan tubuh.",
            "tr": "Avuç içlerini birleştir, içlerine üfle ve koruyucu üç sureyi (İhlas, Felak, Nas) oku. Sonra başı, yüzü ve bedenin ön kısmını mesh et.",
            "ru": "Соедините ладони, подуйте на них и прочитайте три защитные суры (Аль-Ихляс, Аль-Фаляк, Ан-Нас). Затем проведите ими по голове, лицу и передней части тела.",
            "bn": "দুটি হাতের তালু একত্রিত করুন, তাতে ফুঁ দিন এবং তিনটি রক্ষাকারী সূরা (আল-ইখলাস, আল-ফালাক, আন-নাস) তিলাওয়াত করুন। এরপর মাথা, চেহারা এবং শরীরের সামনের অংশে হাত বুলিয়ে নিন।",
        ],
        "اللَّهُ لاَ إِلَهَ إ": [
            "fr": "Ayat al-Kursi (Le Verset du Trône, Sourate 2:255). Quiconque le récite avant de dormir restera sous la protection d'Allah, et aucun diable ne s'approchera de lui jusqu'au matin.",
            "es": "Ayatul Kursi (El Verso del Trono, Surah 2:255). Quien lo recite antes de dormir permanecerá bajo la protección de Allah, y ningún diablo se le acercará hasta la mañana.",
            "ur": "آیت الکرسی (سورۃ البقرہ: 255)۔ جو شخص اسے سونے سے پہلے پڑھے گا، وہ اللہ کی حفاظت میں رہے گا، اور صبح تک کوئی شیطان اس کے قریب نہیں آئے گا۔",
            "id": "Ayat Kursi (Surah 2:255). Barangsiapa membacanya sebelum tidur akan tetap berada dalam lindungan Allah, dan tidak ada setan yang akan mendekatinya hingga pagi.",
            "tr": "Ayetel Kürsi (Bakara Suresi 255. Ayet). Kim uyumadan önce bunu okursa Allah'ın koruması altında kalır ve sabaha kadar hiçbir şeytan ona yaklaşamaz.",
            "ru": "Аятуль-Курси (Аят Трона, Сура 2:255). Тот, кто прочитает его перед сном, останется под защитой Аллаха, и ни один дьявол не приблизится к нему до самого утра.",
            "bn": "আয়াতুল কুরসি (সূরা বাকারার ২৫৫ নং আয়াত)। যে ব্যক্তি ঘুমানোর আগে এটি তিলাওয়াত করবে, সে আল্লাহর সুরক্ষায় থাকবে এবং সকাল পর্যন্ত কোনো শয়তান তার কাছে ঘেঁষতে পারবে না।",
        ],
    ]

    static func getLocalized(for arabic: String, lang: String) -> String? {
        for (key, dict) in localizedTranslations {
            if arabic.range(of: key, options: .literal) != nil {
                return dict[lang]
            }
        }
        return nil
    }
    static let translations: [String: String] = [
        "أَصْبَحْنَا وَأَصْبَحَ": "We have entered the morning and at this very time the whole kingdom belongs to Allah, and all praise is due to Allah. My Lord, I ask You for the good of this day. I seek refuge in You from laziness and senility, and from the punishment of the Fire and the Grave.",
        "اللَّهُمَّ بِكَ أَصْبَ": "O Allah, by You we enter the morning and by You we enter the evening, by You we live and by You we die, and to You is the resurrection.",
        "اللَّهُمَّ مَا أَصْبَ": "O Allah, whatever blessing has reached me or any of Your creation this morning is from You alone. You have no partner.",
        "أَصْبَحْنَا عَلَى فِ": "We have entered the morning upon the natural state of Islam, the word of sincerity, the religion of our Prophet Muhammad ﷺ and the way of our father Ibrahim.",
        "اللَّهُمَّ أَنْتَ رَ": "O Allah, You are my Lord. There is no deity except You. You created me and I am Your servant. I admit Your favor and my sin. Forgive me — Sayyidul Istighfar.",
        "اللَّهُمَّ إِنِّي أَ": "O Allah, I ask You for well-being in this world and the Hereafter. Cover my faults, calm my fears. Protect me from all sides.",
        "اللَّهُمَّ عَافِنِي ": "O Allah, grant me well-being in my body, in my hearing, and in my sight. There is no deity worthy of worship except You.",
        "رَضِيتُ بِاللَّهِ رَ": "I am pleased with Allah as my Lord, with Islam as my religion, and with Muhammad ﷺ as my Prophet.",
        "بِاسْمِ اللَّهِ الَّذ": "In the name of Allah, with whose name nothing on earth or in heaven can cause harm. He is the All-Hearing, the All-Knowing.",
        "اللَّهُمَّ فَاطِرَ ال": "O Allah, Creator of the heavens and the earth, Knower of the unseen and the seen. I bear witness that none has the right to be worshipped except You. I seek refuge in You from the evil of myself and the devil.",
        "يَا حَيُّ يَا قَيُّ": "O Ever Living, O Self-Sustaining, by Your mercy I call upon You. Rectify all my affairs and do not leave me to myself for even a blink of an eye.",
        "حَسْبِيَ اللَّهُ لَا": "Allah is sufficient for me. There is no deity except Him. I put my trust in Him. He is the Lord of the Majestic Throne.",
        "سُبْحَانَ اللَّهِ وَب": "Glory be to Allah and praise be to Him, according to the number of His creation, His pleasure, the weight of His Throne, and the ink of His words.",
        "سُبْحَانَ اللَّهِ (": "Tasbih before sleep: Glory be to Allah (33x), Praise be to Allah (33x), Allah is the Greatest (34x).",
        "لَا إِلَهَ إِلَّا ال": "There is no deity worthy of worship except Allah alone, without partner. To Him belongs the dominion and all praise. He is capable of all things.",
        "أَسْتَغْفِرُ اللهَ وَ": "I ask Allah for forgiveness and turn to Him in repentance.",
        "أَمْسَيْنَا وَأَمْسَى": "We have entered the evening and at this very time the whole kingdom belongs to Allah, and all praise is due to Allah. My Lord, I ask You for the good of this night. I seek refuge in You from laziness and senility, and from the punishment of the Fire and the Grave.",
        "اللَّهُمَّ بِكَ أَمْسَ": "O Allah, by You we enter the evening and by You we enter the morning, by You we live and by You we die, and to You is the return.",
        "اللَّهُمَّ مَا أَمْسَ": "O Allah, whatever blessing has reached me or any of Your creation this evening is from You alone. You have no partner.",
        "بِسْمِ اللهِ الرَّحْم": "Say: He is Allah, One, Allah, the Eternal Refuge. He neither begets nor is born.\n\nSay: I seek refuge in the Lord of the daybreak from the evil of what He created.\n\nSay: I seek refuge in the Lord of mankind, the Sovereign of mankind, the God of mankind.",
        "أَعُوذُ بِكَلِمَاتِ ": "I seek refuge in the perfect words of Allah from the evil of what He has created.",
        "بِاسْمِكَ رَبِّي وَض": "In Your name, my Lord, I lay down my side, and by You I raise it. If You take my soul, have mercy on it, and if You release it, protect it as You protect Your righteous servants.",
        "اللَّهُمَّ إِنَّكَ خ": "O Allah, You created my soul and You take it. To You belongs its death and its life. If You keep it alive, protect it, and if You cause it to die, forgive it. O Allah, I ask You for well-being.",
        "اللَّهُمَّ قِنِي عَذ": "O Allah, protect me from Your punishment on the Day You resurrect Your servants.",
        "بِاسْمِكَ اللَّهُمَّ ": "In Your name, o Allah, I die and I live.",
        "اللَّهُمَّ رَبَّ الس": "O Allah, Lord of the seven heavens and Lord of the great Throne... relieve us of debt and save us from poverty.",
        "الْحَمْدُ لِلَّهِ ال": "Praise be to Allah who fed us, gave us drink, sufficed us and gave us shelter, for how many are there who have no one to suffice them or shelter them.",
        "اللَّهُمَّ عَالِمَ ال": "O Allah, Knower of the unseen and the seen, Creator of the heavens and the earth, Lord and King of all things. I bear witness that there is no deity except You. I seek refuge in You from the evil of myself and the devil.",
        "يَقْرَأُ ﴿الم﴾ تَنْ": "Sunnah recommendation: Recite Surah As-Sajdah (Chapter 32) and Surah Al-Mulk (Chapter 67).",
        "اللَّهُمَّ أَسْلَمْت": "O Allah, I submit my soul to You, delegate my affair to You, turn my face to You, and rely on You, out of hope and fear of You. There is no refuge or escape from You except to You...",
        "يَجْمَعُ كَفَّيْهِ ث": "Join the palms, blow into them, and recite the three protective Surahs (Al-Ikhlas, Al-Falaq, An-Nas). Then wipe over the head, face, and front of the body.",
        "اللَّهُ لاَ إِلَهَ إ": "Ayat al-Kursi (The Throne Verse, Surah 2:255). Whoever recites this before sleeping will remain under Allah's protection, and no devil will approach him until morning."
    ]
}

func adhkarItems(for type: AdhkarSessionType) -> [AdhkarItem] {
    switch type {
    case .sleep: return schlafAdhkar
    case .morning: return morgenAdhkar
    case .evening: return abendAdhkar
    }
}

func safeAdhkarKey(typeId: String, item: AdhkarItem) -> String {
    let germanClean = item.german.components(separatedBy: CharacterSet.alphanumerics.inverted).joined()
    let transClean = item.transliteration.components(separatedBy: CharacterSet.alphanumerics.inverted).joined()
    let combined = String((germanClean + transClean).prefix(60))
    return "\(typeId)_\(item.count)_\(combined)"
}

