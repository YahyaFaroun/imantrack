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
    var customSpeedStep: Int = 2
    let quickInterval: TimeInterval?
    let normalInterval: TimeInterval?

    init(arabic: String, transliteration: String = "", german: String, english: String = "", count: Int, linkedTasbihCategory: TasbihCategory? = nil, isMandatory: Bool = true, customSpeedStep: Int = 2, quickInterval: TimeInterval? = nil, normalInterval: TimeInterval? = nil) {
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
    }
}

let morgenAdhkar: [AdhkarItem] = [
    // 1. Ayat al-Kursi
    AdhkarItem(
        arabic: "اللَّهُ لاَ إِلَهَ إِلاَّ هُوَ الْحَيُّ الْقَيُّومُ لاَ تَأْخُذُهُ سِنَةٌ وَلاَ نَوْمٌ لَّهُ مَا فِي السَّمَوَاتِ وَمَا فِي الأَرْضِ مَن ذَا الَّذِي يَشْفَعُ عِنْدَهُ إِلاَّ بِإِذْنِهِ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ وَلاَ يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلاَّ بِمَا شَاء وَسِعَ كُرْسِيُّهُ السَّمَوَاتِ وَالْأَرْضَ وَلاَ يَؤُودُهُ حِفْظُهُمَا وَهُوَ الْعَلِيُّ الْعَظِيمُ",
        transliteration: "Allahu la ilaha illa Huwal-Hayyul-Qayyum. La ta'khudhuhu sinatun wa la nawm. Lahu ma fis-samawati wa ma fil-ard. Man dhal-ladhi yashfa'u 'indahu illa bi-idhnih. Ya'lamu ma bayna aydihim wa ma khalfahum. Wa la yuhituna bi-shay'im-min 'ilmihi illa bima sha'. Wasi'a kursiyyuhus-samawati wal-ard, wa la ya'uduhu hifdhuhuma, wa Huwal-'Aliyyul-'Adheem.",
        german: "Allah – es gibt keinen Gott außer Ihm, dem Lebendigen und Beständigen. Ihn überkommt weder Schlummer noch Schlaf. Ihm gehört, was in den Himmeln und was auf der Erde ist. Wer ist es, der bei Ihm Fürsprache einlegen könnte außer mit Seiner Erlaubnis? Er weiß, was vor ihnen und was hinter ihnen liegt; sie aber begreifen nichts von Seinem Wissen, es sei denn das, was Er will. Sein Thronschemel umfasst die Himmel und die Erde, und ihre Bewahrung beschwert Ihn nicht. Und Er ist der Erhabene, der Allgewaltige.",
        english: "Allah! There is no deity except Him, the Ever-Living, the Sustainer of all existence. Neither drowsiness overtakes Him nor sleep. To Him belongs whatever is in the heavens and whatever is on the earth. Who is it that can intercede with Him except by His permission? He knows what is presently before them and what will be after them, and they encompass not a thing of His knowledge except for what He wills. His Kursi extends over the heavens and the earth, and their preservation tires Him not. And He is the Most High, the Most Great.",
        count: 1
    , quickInterval: 17.7, normalInterval: 26.5),
    // 2. Sure Al-Ikhlas
    AdhkarItem(
        arabic: "بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ. قُلْ هُوَ اللَّهُ أَحَدٌ، اللَّهُ الصَّمَدُ، لَمْ يَلِدْ وَلَمْ يُولَدْ، وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ",
        transliteration: "Bismillahir-Rahmanir-Rahim. Qul Huwallahu Ahad. Allahus-Samad. Lam yalid wa lam yulad. Wa lam yakul-lahu kufuwan ahad.",
        german: "Im Namen Allahs, des Allerbarmers, des Barmherzigen. Sprich: Er ist Allah, ein Einziger, Allah, der Überlegene. Er hat nicht gezeugt und ist nicht gezeugt worden, und niemand ist Ihm jemals gleich.",
        english: "In the Name of Allah, the Most Gracious, the Most Merciful. Say: He is Allah, (who is) One, Allah, the Eternal Refuge. He neither begets nor is born, nor is there to Him any equivalent.",
        count: 3
    , quickInterval: 5.04, normalInterval: 9.06),
    // 3. Sure Al-Falaq
    AdhkarItem(
        arabic: "بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ. قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ، مِن شَرِّ مَا خَلَقَ، وَمِن شَرِّ غَاسِقٍ إِذَا وَقَبَ، وَمِن شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ، وَمِن شَرِّ حَاسِدٍ إِذَا حَسَدَ",
        transliteration: "Bismillahir-Rahmanir-Rahim. Qul a'udhu bi Rabbil-falaq. Min sharri ma khalaq. Wa min sharri ghasiqin idha waqab. Wa min sharrin-naffathati fil-'uqad. Wa min sharri hasidin idha hasad.",
        german: "Im Namen Allahs, des Allerbarmers, des Barmherzigen. Sprich: Ich nehme Zuflucht beim Herrn des Frühlichts, vor dem Übel dessen, was Er erschaffen hat, und vor dem Übel der Dunkelheit, wenn sie hereinbricht, und vor dem Übel der Knotenbläserinnen, und vor dem Übel eines Neiders, wenn er neidet.",
        english: "In the Name of Allah, the Most Gracious, the Most Merciful. Say: I seek refuge in the Lord of daybreak, from the evil of that which He created, and from the evil of darkness when it settles, and from the evil of the blowers in knots, and from the evil of an envier when he envies.",
        count: 3
    , quickInterval: 8.4, normalInterval: 11.15),
    // 4. Sure An-Nas
    AdhkarItem(
        arabic: "بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ. قُلْ أَعُوذُ بِرَبِّ النَّاسِ، مَلِكِ النَّاسِ، إِلَٰهِ النَّاسِ، مِن شَرِّ الْوَسْوَاسِ الْخَنَّاسِ، الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ، مِنَ الْجِنَّةِ وَالنَّاسِ",
        transliteration: "Bismillahir-Rahmanir-Rahim. Qul a'udhu bi Rabbin-nas. Malikin-nas. Ilahin-nas. Min sharril-waswasil-khannas. Alladhi yuwaswisu fi sudurin-nas. Minal-jinnati wan-nas.",
        german: "Im Namen Allahs, des Allerbarmers, des Barmherzigen. Sprich: Ich nehme Zuflucht beim Herrn der Menschen, dem König der Menschen, dem Gott der Menschen, vor dem Übel des Einflüsterers, der entweicht und wiederkehrt, der den Menschen in die Brüste einflüstert, von den Dschinn und den Menschen.",
        english: "In the Name of Allah, the Most Gracious, the Most Merciful. Say: I seek refuge in the Lord of mankind, the Sovereign of mankind, the God of mankind, from the evil of the retreating whisperer, who whispers into the breasts of mankind, from among the jinn and mankind.",
        count: 3
    , quickInterval: 7.63, normalInterval: 12.2),
    // 5. Asbahna wa asbaha al-mulku lillah
    AdhkarItem(
        arabic: "أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَذَا الْيَوْمِ وَخَيْرَ مَا بَعْدَهُ، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَذَا الْيَوْمِ وَشَرِّ مَا بَعْدَهُ، رَبِّ أَعُوذُ بِكَ مِنَ الْكَسَلِ وَسُوءِ الْكِبَرِ، رَبِّ أَعُوذُ بِكَ مِنْ عَذَابٍ فِي النَّارِ وَعَذَابٍ فِي الْقَبْرِ",
        transliteration: "Asbahna wa asbahal-mulku lillah, walhamdulillah. La ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamd, wa Huwa 'ala kulli shay'in Qadir. Rabbi as'aluka khayra ma fi hadhal-yawm wa khayra ma ba'dah, wa a'udhu bika min sharri ma fi hadhal-yawm wa sharri ma ba'dah. Rabbi a'udhu bika minal-kasali wa su'il-kibar. Rabbi a'udhu bika min 'adhabin fin-nari wa 'adhabin fil-qabr.",
        german: "Wir haben den Morgen erreicht, und die Herrschaft gehört Allah. Alles Lob gebührt Allah. Es gibt keinen Gott außer Allah, dem Einzigen, der keinen Teilhaber hat. Ihm gehört die Herrschaft und Ihm gebührt das Lob, und Er ist über alle Dinge mächtig. Mein Herr, ich bitte Dich um das Gute dieses Tages und um das Gute, das danach kommt. Und ich suche Zuflucht bei Dir vor dem Übel dieses Tages und dem Übel, das danach kommt. Mein Herr, ich suche Zuflucht bei Dir vor Faulheit und einem schlechten Alter. Mein Herr, ich suche Zuflucht bei Dir vor der Strafe im Höllenfeuer und der Strafe im Grab.",
        english: "We have reached the morning and at this very time unto Allah belongs all sovereignty, and all praise is for Allah. None has the right to be worshipped except Allah, alone, without partner, to Him belongs all sovereignty and praise and He is over all things omnipotent. My Lord, I ask You for the good of this day and the good of what follows it and I take refuge in You from the evil of this day and the evil of what follows it. My Lord, I take refuge in You from laziness and senility. My Lord, I take refuge in You from torment in the Fire and punishment in the grave.",
        count: 1
    , quickInterval: 17.33, normalInterval: 21.77),
    // 6. Allahumma bika asbahna
    AdhkarItem(
        arabic: "اللَّهُمَّ بِكَ أَصْبَحْنَا، وَبِكَ أَمْسَيْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ وَإِلَيْكَ النُّشُورُ",
        transliteration: "Allahumma bika asbahna, wa bika amsayna, wa bika nahya, wa bika namutu wa ilaykan-nushur.",
        german: "O Allah, durch Dich haben wir den Morgen erreicht, und durch Dich haben wir den Abend erreicht. Durch Dich leben wir, und durch Dich sterben wir, und zu Dir ist die Auferstehung.",
        english: "O Allah, by You we enter the morning and by You we enter the evening, by You we live and by You we die, and to You is the Final Return.",
        count: 1
    , quickInterval: 4.87, normalInterval: 7.07),
    // 7. Sayyidul Istighfar
    AdhkarItem(
        arabic: "اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلاَّ أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لاَ يَغْفِرُ الذُّنوبَ إِلاَّ أَنْتَ",
        transliteration: "Allahumma Anta Rabbi la ilaha illa Ant. Khalaqtani wa ana 'abduka, wa ana 'ala 'ahdika wa wa'dika ma-stata't. A'udhu bika min sharri ma sana't. Abu'u laka bi-ni'matika 'alayy, wa abu'u bi-dhanbi fa-ghfir li, fa-innahu la yaghfiru-dh-dhunuba illa Ant.",
        german: "O Allah, Du bist mein Herr. Es gibt keinen Gott außer Dir. Du hast mich erschaffen, und ich bin Dein Diener. Ich halte mich an Deinen Bund und Dein Versprechen, so gut ich kann. Ich suche Zuflucht bei Dir vor dem Übel, das ich begangen habe. Ich bekenne mich zu Deinen Gnaden über mich, und ich bekenne mich zu meiner Sünde. So vergib mir, denn niemand vergibt die Sünden außer Dir.",
        english: "O Allah, You are my Lord, there is none worthy of worship but You. You created me and I am Your slave. I keep Your covenant, and my pledge to You so far as I am able. I seek refuge in You from the evil of what I have done. I admit to Your blessings upon me, and I admit to my misdeeds. Forgive me, for there is none who may forgive sins but You.",
        count: 1,
        linkedTasbihCategory: .istighfar
    , quickInterval: 10.47, normalInterval: 15.47),
    // 8. Allahumma inni asbahtu ushhiduka
    AdhkarItem(
        arabic: "اللَّهُمَّ إِنِّي أَصْبَحْتُ أُشْهِدُكَ، وَأُشْهِدُ حَمَلَةَ عَرْشِكَ، وَمَلاَئِكَتِكَ، وَجَمِيعَ خَلْقِكَ، أَنَّكَ أَنْتَ اللَّهُ لَا إِلَهَ إِلاَّ أَنْتَ وَحْدَكَ لاَ شَرِيكَ لَكَ، وَأَنَّ مُحَمَّداً عَبْدُكَ وَرَسُولُكَ",
        transliteration: "Allahumma inni asbahtu ushhiduka, wa ushhidu hamalata 'arshika, wa mala'ikatika, wa jami'a khalqika, annaka Antallahu la ilaha illa Anta wahdaka la sharika lak, wa anna Muhammadan 'abduka wa rasuluk.",
        german: "O Allah, ich habe den Morgen erreicht und rufe Dich als Zeugen an, ebenso wie die Träger Deines Thrones, Deine Engel und Deine gesamte Schöpfung, dass Du Allah bist, es gibt keinen Gott außer Dir allein, Du hast keinen Teilhaber, und dass Muhammad Dein Diener und Gesandter ist.",
        english: "O Allah, I have entered the morning calling You to witness, and calling the bearers of Your Throne to witness, Your angels and all of Your creation, that You are Allah, none has the right to be worshipped but You alone, without partner, and that Muhammad is Your servant and Messenger.",
        count: 4
    , quickInterval: 7.87, normalInterval: 10.6),
    // 9. Allahumma ma asbaha bi min ni'matin
    AdhkarItem(
        arabic: "اللَّهُمَّ مَا أَصْبَحَ بِي مِنْ نِعْمَةٍ أَوْ بِأَحَدٍ مِنْ خَلْقِكَ فَمِنْكَ وَحْدَكَ لاَ شَرِيكَ لَكَ، فَلَكَ الْحَمْدُ وَلَكَ الشُّكْرُ",
        transliteration: "Allahumma ma asbaha bi min ni'matin aw bi-ahadin min khalqika fa-minka wahdaka la sharika lak, fa-lakal-hamdu wa lakash-shukr.",
        german: "O Allah, welche Gnade auch immer mich oder eines Deiner Geschöpfe an diesem Morgen erreicht hat, sie ist von Dir allein, Du hast keinen Teilhaber. Dir gebührt alles Lob und Dir gebührt der Dank.",
        english: "O Allah, whatever blessing has been received by me or anyone of Your creation this morning, is from You alone, You have no partner. All praise is for You and thanks is to You.",
        count: 1
    , quickInterval: 5.79, normalInterval: 7.83),
    // 10. Allahumma 'afini fi badani
    AdhkarItem(
        arabic: "اللَّهُمَّ عَافِنِي فِي بَدَنِي، اللَّهُمَّ عَافِنِي فِي سَمْعِي، اللَّهُمَّ عَافِنِي فِي بَصَرِي، لاَ إِلَهَ إِلاَّ أَنْتَ. اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْكُفْرِ، وَالفَقْرِ، وَأَعُوذُ بِكَ مِنْ عَذَابِ القَبْرِ، لاَ إِلَهَ إِلاَّ أَنْتَ",
        transliteration: "Allahumma 'afini fi badani, Allahumma 'afini fi sam'i, Allahumma 'afini fi basari, la ilaha illa Ant. Allahumma inni a'udhu bika minal-kufri wal-faqr, wa a'udhu bika min 'adhabil-qabr, la ilaha illa Ant.",
        german: "O Allah, gib mir Gesundheit in meinem Körper. O Allah, gib mir Gesundheit in meinem Gehör. O Allah, gib mir Gesundheit in meinem Augenlicht. Es gibt keinen Gott außer Dir. O Allah, ich suche Zuflucht bei Dir vor dem Unglauben und der Armut. Und ich suche Zuflucht bei Dir vor der Strafe im Grab. Es gibt keinen Gott außer Dir.",
        english: "O Allah, grant my body health. O Allah, grant my hearing health. O Allah, grant my sight health. None has the right to be worshipped but You. O Allah, I take refuge with You from disbelief and poverty, and I take refuge with You from the punishment of the grave. None has the right to be worshipped but You.",
        count: 3
    , quickInterval: 8.25, normalInterval: 12.63),
    // 11. Hasbiyallahu
    AdhkarItem(
        arabic: "حَسْبِيَ اللَّهُ لاَ إِلَهَ إِلاَّ هُوَ عَلَيهِ تَوَكَّلتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ",
        transliteration: "Hasbiyallahu la ilaha illa Huwa 'alayhi tawakkaltu wa Huwa Rabbul-'Arshil-'Adheem.",
        german: "Allah genügt mir. Es gibt keinen Gott außer Ihm. Auf Ihn vertraue ich, und Er ist der Herr des gewaltigen Thrones.",
        english: "Allah is sufficient for me. There is none worthy of worship but Him. I have placed my trust in Him, and He is the Lord of the Majestic Throne.",
        count: 7
    , quickInterval: 3.3, normalInterval: 5.04),
    // 12. Allahumma inni as'aluka al-'afwa
    AdhkarItem(
        arabic: "اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي الدُّنْيَا وَالآخِرَةِ، اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي دِينِي وَدُنْيَايَ وَأَهْلِي، وَمَالِي، اللَّهُمَّ اسْتُرْ عَوْرَاتِي، وَآمِنْ رَوْعَاتِي، اللَّهُمَّ احْفَظْنِي مِنْ بَينِ يَدَيَّ، وَمِنْ خَلْفِي، وَعَنْ يَمِينِي، وَعَنْ شِمَالِي، وَمِنْ فَوْقِي، وَأَعُوذُ بِعَظَمَتِكَ أَنْ أُغْتَالَ مِنْ تَحْتِي",
        transliteration: "Allahumma inni as'aluka-l-'afwa wal-'afiyata fid-dunya wal-akhirah. Allahumma inni as'aluka-l-'afwa wal-'afiyata fi dini wa dunyaya wa ahli wa mali. Allahumma-stur 'awrati wa amin raw'ati. Allahumma-hfazni min bayni yadayya, wa min khalfi, wa 'an yamini, wa 'an shimali, wa min fawqi, wa a'udhu bi-'adhamatika an ughtala min tahti.",
        german: "O Allah, ich bitte Dich um Vergebung und Wohlergehen im Diesseits und im Jenseits. O Allah, ich bitte Dich um Vergebung und Wohlergehen für meine Religion, mein weltliches Leben, meine Familie und mein Vermögen. O Allah, bedecke meine Blößen und beruhige meine Ängste. O Allah, beschütze mich von vorn, von hinten, von rechts, von links und von oben. Und ich suche Zuflucht bei Deiner Erhabenheit davor, dass ich von unten her meuchlings vernichtet werde.",
        english: "O Allah, I ask You for pardon and well-being in this life and the next. O Allah, I ask You for pardon and well-being in my religious and worldly affairs, and my family and my wealth. O Allah, veil my weaknesses and set at ease my dismay. O Allah, preserve me from the front and from behind and on my right and on my left and from above, and I take refuge with You lest I be swallowed up by the earth.",
        count: 1
    , quickInterval: 15.83, normalInterval: 21.0),
    // 13. Allahumma 'alimal-ghaybi
    AdhkarItem(
        arabic: "اللَّهُمَّ عَالِمَ الغَيْبِ وَالشَّهَادَةِ فَاطِرَ السَّمَوَاتِ وَالْأَرْضِ، رَبَّ كُلِّ شَيْءٍ وَمَلِيكَهُ، أَشْهَدُ أَنْ لاَ إِلَهَ إِلاَّ أَنْتَ، أَعُوذُ بِكَ مِنْ شَرِّ نَفْسِي، وَمِنْ شَرِّ الشَّيْطانِ وَشِـرْكِهِ، وَأَنْ أَقْتَرِفَ عَلَى نَفْسِي سُوءاً، أَوْ أَجُرَّهُ إِلَى مُسْلِمٍ",
        transliteration: "Allahumma 'Alimal-ghaybi wash-shahadati Fatiras-samawati wal-ard, Rabba kulli shay'in wa Malikah. Ash-hadu an la ilaha illa Ant. A'udhu bika min sharri nafsi, wa min sharrish-shaytani wa shirkihi, wa an aqtarifa 'ala nafsi su'an, aw ajurrahu ila Muslim.",
        german: "O Allah, Kenner des Verborgenen und des Offenbaren, Schöpfer der Himmel und der Erde, Herr und König von allem. Ich bezeuge, dass es keinen Gott gibt außer Dir. Ich suche Zuflucht bei Dir vor dem Übel meiner eigenen Seele, vor dem Übel des Satans und seiner Verführung zur Beigesellung (Schirk), und davor, dass ich mir selbst Böses antue oder es über einen Muslim bringe.",
        english: "O Allah, Knower of the unseen and the evident, Maker of the heavens and the earth, Lord of all things and their Sovereign, I bear witness that there is none worthy of worship but You. I seek refuge in You from the evil of my soul and from the evil of Satan and his helpers, and (I seek refuge in You) from bringing evil upon my soul or from harming a Muslim.",
        count: 1
    , quickInterval: 11.2, normalInterval: 14.62),
    // 14. Bismillah-illadhi la yadurru
    AdhkarItem(
        arabic: "بِسْمِ اللَّهِ الَّذِي لاَ يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلاَ فِي السّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ",
        transliteration: "Bismillahil-ladhi la yadurru ma'as-mihi shay'un fil-ardi wa la fis-sama'i wa Huwas-Sami'ul-'Alim.",
        german: "Im Namen Allahs, mit Dessen Namen nichts auf der Erde oder im Himmel Schaden zufügen kann, und Er ist der Allhörende, der Allwissende.",
        english: "In the Name of Allah, Who with His Name nothing can cause harm in the earth nor in the heavens, and He is the All-Hearing, the All-Knowing.",
        count: 3
    , quickInterval: 4.42, normalInterval: 6.22),
    // 15. Radiytu billahi
    AdhkarItem(
        arabic: "رَضِيتُ بِاللَّهِ رَبَّاً، وَبِالْإِسْلاَمِ دِيناً، وَبِمُحَمَّدٍ صلى الله عليه وسلم نَبِيّاً",
        transliteration: "Radiytu billahi Rabban wabil-Islami dinan wa bi-Muhammadin sallallahu 'alayhi wa sallama Nabiyya.",
        german: "Ich bin zufrieden mit Allah als meinem Herrn, mit dem Islam als meiner Religion und mit Muhammad, Allahs Segen und Frieden seien auf ihm, als meinem Propheten.",
        english: "I am pleased with Allah as my Lord, with Islam as my religion and with Muhammad (peace and blessings of Allah be upon him) as my Prophet.",
        count: 3
    , quickInterval: 4.17, normalInterval: 6.4),
    // 16. Ya Hayyu ya Qayyum
    AdhkarItem(
        arabic: "يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغيثُ أَصْلِحْ لِي شَأْنِيَ كُلَّهُ وَلاَ تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ",
        transliteration: "Ya Hayyu ya Qayyum bi-rahmatika astaghith, aslih li sha'ni kullahu wa la takilni ila nafsi tarfata 'ayn.",
        german: "O Ewiglebender, O Beständiger, durch Deine Barmherzigkeit rufe ich um Hilfe. Bringe all meine Angelegenheiten in Ordnung und überlasse mich nicht mir selbst, nicht einmal für den Wimpernschlag eines Auges.",
        english: "O Ever Living One, O Sustainer, by Your mercy I call on You to set right all my affairs, do not place me in charge of my soul even for the blinking of an eye.",
        count: 1
    , quickInterval: 5.1, normalInterval: 7.9),
    // 17. Asbahna wa asbahal-mulku lillahi rabbil-'alamin
    AdhkarItem(
        arabic: "أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ رَبِّ الْعَالَمِينَ، اللَّهُـمَّ إِنِّي أَسْأَلُكَ خَيْرَ هَذَا الْيَوْمِ فَتْحَهُ، وَنَصْرَهُ، وَنورَهُ، وَبَرَكَتَهُ، وَهُدَاهُ، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِيهِ وَشَرِّ مَا بَعْدَهُ",
        transliteration: "Asbahna wa asbahal-mulku lillahi Rabbil-'alamin. Allahumma inni as'aluka khayra hadhal-yawm: fathahu, wa nasrahu, wa nurahu, wa barakatahu, wa hudahu. Wa a'udhu bika min sharri ma fihi wa sharri ma ba'dah.",
        german: "Wir haben den Morgen erreicht, und die Herrschaft gehört Allah, dem Herrn der Welten. O Allah, ich bitte Dich um das Gute dieses Tages: seinen Erfolg, seinen Sieg, sein Licht, seinen Segen und seine Rechtleitung. Und ich suche Zuflucht bei Dir vor dem Übel, das darin ist, und dem Übel, das danach kommt.",
        english: "We have reached the morning and at this very time unto Allah, Lord of the worlds, belongs all sovereignty. O Allah, I ask You for the good of this day, its victories, its help, its light, its blessings, and its guidance. I take refuge in You from the evil that is in it and from the evil that follows it.",
        count: 1
    , quickInterval: 8.77, normalInterval: 13.23),
    // 18. Asbahna 'ala fitratil-Islam
    AdhkarItem(
        arabic: "أَصْبَحْنا عَلَى فِطْرَةِ الْإِسْلاَمِ، وَعَلَى كَلِمَةِ الْإِخْلاَصِ، وَعَلَى دِينِ نَبِيِّنَا مُحَمَّدٍ صلى الله عليه وسلم، وَعَلَى مِلَّةِ أَبِينَا إِبْرَاهِيمَ، حَنِيفاً مُسْلِماً وَمَا كَانَ مِنَ الْمُشرِكِينَ",
        transliteration: "Asbahna 'ala fitratil-Islam, wa 'ala kalimatil-ikhlas, wa 'ala dini Nabiyyina Muhammadin sallallahu 'alayhi wa sallam, wa 'ala millati abina Ibrahima hanifan Musliman wa ma kana minal-mushrikin.",
        german: "Wir haben den Morgen erreicht in der natürlichen Veranlagung des Islam, auf dem Wort der reinen Ergebenheit, auf der Religion unseres Propheten Muhammad, Allahs Segen und Frieden seien auf ihm, und der Glaubensgemeinschaft unseres Vaters Ibrahim. Er war rechtgläubig, gottergeben und keiner der Götzendiener.",
        english: "We have entered a new day upon the natural religion of Islam, the word of sincere devotion, the religion of our Prophet Muhammad (peace and blessings of Allah be upon him), and the faith of our father Ibrahim. He was upright (in worshipping Allah), and a Muslim. He was not of those who worship others besides Allah.",
        count: 1
    , quickInterval: 9.1, normalInterval: 11.17),
    // 19. Subhanallahi wa bihamdihi (100)
    AdhkarItem(
        arabic: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ",
        transliteration: "Subhanallahi wa bihamdihi.",
        german: "Preis sei Allah, und Ihm gebührt Sein Lob.",
        english: "Glory is to Allah and praise is to Him.",
        count: 100
    , quickInterval: 1.01, normalInterval: 1.92),
    // 20. La ilaha illallah (10)
    AdhkarItem(
        arabic: "لاَ إِلَهَ إِلاَّ اللَّهُ، وَحْدَهُ لاَ شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ",
        transliteration: "La ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamdu wa Huwa 'ala kulli shay'in Qadir.",
        german: "Es gibt keinen Gott außer Allah, dem Einzigen, der keinen Teilhaber hat. Ihm gehört die Herrschaft und Ihm gebührt das Lob, und Er ist über alle Dinge mächtig.",
        english: "None has the right to be worshipped but Allah alone, Who has no partner. His is the dominion and His is the praise and He is Able to do all things.",
        count: 10
    , quickInterval: 4.67, normalInterval: 7.52),
    // 21. Subhanallahi wa bihamdihi 'adada
    AdhkarItem(
        arabic: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ : عَدَدَ خَلْقِهِ، وَرِضَا نَفْسِهِ، وَزِنَةَ عَرْشِهِ، وَمِدَادَ كَلِمَاتِهِ",
        transliteration: "Subhanallahi wa bihamdihi: 'Adada khalqihi, wa rida nafsihi, wa zinata 'arshihi, wa midada kalimatih.",
        german: "Preis sei Allah, und Ihm gebührt Sein Lob: In der Anzahl Seiner Schöpfung, nach Seinem Wohlgefallen, dem Gewicht Seines Thrones und der Menge der Tinte Seiner Worte.",
        english: "Glory is to Allah and praise is to Him, by the multitude of His creation, by His Pleasure, by the weight of His Throne, and by the extent of His Words.",
        count: 3
    , quickInterval: 4.8, normalInterval: 8.1),
    // 22. Allahumma inni as'aluka 'ilman nafi'an
    AdhkarItem(
        arabic: "اللَّهُمَّ إِنِّي أَسْأَلُكَ عِلْماً نَافِعاً، وَرِزْقاً طَيِّباً، وَعَمَلاً مُتَقَبَّلاً",
        transliteration: "Allahumma inni as'aluka 'ilman nafi'an, wa rizqan tayyiban, wa 'amalan mutaqabbalan.",
        german: "O Allah, ich bitte Dich um nützliches Wissen, guten Lebensunterhalt und Taten, die von Dir angenommen werden.",
        english: "O Allah, I ask You for knowledge that is of benefit, a good provision, and deeds that will be accepted.",
        count: 1
    , quickInterval: 3.67, normalInterval: 5.7),
    // 23. Astaghfirullah
    AdhkarItem(
        arabic: "أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ",
        transliteration: "Astaghfirullaha wa atubu ilayh.",
        german: "Ich bitte Allah um Vergebung und kehre in Reue zu Ihm zurück.",
        english: "I seek the forgiveness of Allah and repent to Him.",
        count: 100,
        linkedTasbihCategory: .istighfar
    , quickInterval: 0.79, normalInterval: 2.67),
    // 24. A'udhu bikalimatillahit-tammati
    AdhkarItem(
        arabic: "أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ",
        transliteration: "A'udhu bi-kalimatillahit-tammati min sharri ma khalaq.",
        german: "Ich suche Zuflucht bei den vollkommenen Worten Allahs vor dem Übel dessen, was Er erschaffen hat.",
        english: "I seek refuge in the Perfect Words of Allah from the evil of what He has created.",
        count: 3
    , quickInterval: 2.63, normalInterval: 4.22),
    // 25. Allahumma salli
    AdhkarItem(
        arabic: "اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبَيِّنَا مُحَمَّدٍ",
        transliteration: "Allahumma salli wa sallim 'ala Nabiyyina Muhammad.",
        german: "O Allah, sende Segen und Frieden auf unseren Propheten Muhammad.",
        english: "O Allah, send blessings and peace upon our Prophet Muhammad.",
        count: 10,
        linkedTasbihCategory: .salawat
    , quickInterval: 1.56, normalInterval: 3.85)
]

let abendAdhkar: [AdhkarItem] = [
    // 1. Ayat al-Kursi
    AdhkarItem(
        arabic: "اللَّهُ لاَ إِلَهَ إِلاَّ هُوَ الْحَيُّ الْقَيُّومُ لاَ تَأْخُذُهُ سِنَةٌ وَلاَ نَوْمٌ لَّهُ مَا فِي السَّمَوَاتِ وَمَا فِي الأَرْضِ مَن ذَا الَّذِي يَشْفَعُ عِنْدَهُ إِلاَّ بِإِذْنِهِ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ وَلاَ يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلاَّ بِمَا شَاء وَسِعَ كُرْسِيُّهُ السَّمَوَاتِ وَالْأَرْضَ وَلاَ يَؤُودُهُ حِفْظُهُمَا وَهُوَ الْعَلِيُّ الْعَظِيمُ",
        transliteration: "Allahu la ilaha illa Huwal-Hayyul-Qayyum. La ta'khudhuhu sinatun wa la nawm. Lahu ma fis-samawati wa ma fil-ard. Man dhal-ladhi yashfa'u 'indahu illa bi-idhnih. Ya'lamu ma bayna aydihim wa ma khalfahum. Wa la yuhituna bi-shay'im-min 'ilmihi illa bima sha'. Wasi'a kursiyyuhus-samawati wal-ard, wa la ya'uduhu hifdhuhuma, wa Huwal-'Aliyyul-'Adheem.",
        german: "Allah – es gibt keinen Gott außer Ihm, dem Lebendigen und Beständigen. Ihn überkommt weder Schlummer noch Schlaf. Ihm gehört, was in den Himmeln und was auf der Erde ist. Wer ist es, der bei Ihm Fürsprache einlegen könnte außer mit Seiner Erlaubnis? Er weiß, was vor ihnen und was hinter ihnen liegt; sie aber begreifen nichts von Seinem Wissen, es sei denn das, was Er will. Sein Thronschemel umfasst die Himmel und die Erde, und ihre Bewahrung beschwert Ihn nicht. Und Er ist der Erhabene, der Allgewaltige.",
        english: "Allah! There is no deity except Him, the Ever-Living, the Sustainer of all existence. Neither drowsiness overtakes Him nor sleep. To Him belongs whatever is in the heavens and whatever is on the earth. Who is it that can intercede with Him except by His permission? He knows what is presently before them and what will be after them, and they encompass not a thing of His knowledge except for what He wills. His Kursi extends over the heavens and the earth, and their preservation tires Him not. And He is the Most High, the Most Great.",
        count: 1
    , quickInterval: 17.7, normalInterval: 26.5),
    // 2. Sure Al-Ikhlas
    AdhkarItem(
        arabic: "بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ. قُلْ هُوَ اللَّهُ أَحَدٌ، اللَّهُ الصَّمَدُ، لَمْ يَلِدْ وَلَمْ يُولَدْ، وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ",
        transliteration: "Bismillahir-Rahmanir-Rahim. Qul Huwallahu Ahad. Allahus-Samad. Lam yalid wa lam yulad. Wa lam yakul-lahu kufuwan ahad.",
        german: "Im Namen Allahs, des Allerbarmers, des Barmherzigen. Sprich: Er ist Allah, ein Einziger, Allah, der Überlegene. Er hat nicht gezeugt und ist nicht gezeugt worden, und niemand ist Ihm jemals gleich.",
        english: "In the Name of Allah, the Most Gracious, the Most Merciful. Say: He is Allah, (who is) One, Allah, the Eternal Refuge. He neither begets nor is born, nor is there to Him any equivalent.",
        count: 3
    , quickInterval: 5.04, normalInterval: 9.06),
    // 3. Sure Al-Falaq
    AdhkarItem(
        arabic: "بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ. قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ، مِن شَرِّ مَا خَلَقَ، وَمِن شَرِّ غَاسِقٍ إِذَا وَقَبَ، وَمِن شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ، وَمِن شَرِّ حَاسِدٍ إِذَا حَسَدَ",
        transliteration: "Bismillahir-Rahmanir-Rahim. Qul a'udhu bi Rabbil-falaq. Min sharri ma khalaq. Wa min sharri ghasiqin idha waqab. Wa min sharrin-naffathati fil-'uqad. Wa min sharri hasidin idha hasad.",
        german: "Im Namen Allahs, des Allerbarmers, des Barmherzigen. Sprich: Ich nehme Zuflucht beim Herrn des Frühlichts, vor dem Übel dessen, was Er erschaffen hat, und vor dem Übel der Dunkelheit, wenn sie hereinbricht, und vor dem Übel der Knotenbläserinnen, und vor dem Übel eines Neiders, wenn er neidet.",
        english: "In the Name of Allah, the Most Gracious, the Most Merciful. Say: I seek refuge in the Lord of daybreak, from the evil of that which He created, and from the evil of darkness when it settles, and from the evil of the blowers in knots, and from the evil of an envier when he envies.",
        count: 3
    , quickInterval: 8.4, normalInterval: 11.15),
    // 4. Sure An-Nas
    AdhkarItem(
        arabic: "بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ. قُلْ أَعُوذُ بِرَبِّ النَّاسِ، مَلِكِ النَّاسِ، إِلَٰهِ النَّاسِ، مِن شَرِّ الْوَسْوَاسِ الْخَنَّاسِ، الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ، مِنَ الْجِنَّةِ وَالنَّاسِ",
        transliteration: "Bismillahir-Rahmanir-Rahim. Qul a'udhu bi Rabbin-nas. Malikin-nas. Ilahin-nas. Min sharril-waswasil-khannas. Alladhi yuwaswisu fi sudurin-nas. Minal-jinnati wan-nas.",
        german: "Im Namen Allahs, des Allerbarmers, des Barmherzigen. Sprich: Ich nehme Zuflucht beim Herrn der Menschen, dem König der Menschen, dem Gott der Menschen, vor dem Übel des Einflüsterers, der entweicht und wiederkehrt, der den Menschen in die Brüste einflüstert, von den Dschinn und den Menschen.",
        english: "In the Name of Allah, the Most Gracious, the Most Merciful. Say: I seek refuge in the Lord of mankind, the Sovereign of mankind, the God of mankind, from the evil of the retreating whisperer, who whispers into the breasts of mankind, from among the jinn and mankind.",
        count: 3
    , quickInterval: 7.63, normalInterval: 12.2),
    // 5. Amsayna wa amsal-mulku lillah (Abend)
    AdhkarItem(
        arabic: "أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَذِهِ اللَّيْلَةِ وَخَيْرَ مَا بَعْدَهَا، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَذِهِ اللَّيْلَةِ وَشَرِّ مَا بَعْدَهَا، رَبِّ أَعُوذُ بِكَ مِنَ الْكَسَلِ وَسُوءِ الْكِبَرِ، رَبِّ أَعُوذُ بِكَ مِنْ عَذَابٍ فِي النَّارِ وَعَذَابٍ فِي الْقَبْرِ",
        transliteration: "Amsayna wa amsal-mulku lillah, walhamdulillah. La ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamd, wa Huwa 'ala kulli shay'in Qadir. Rabbi as'aluka khayra ma fi hadhihil-laylah wa khayra ma ba'daha, wa a'udhu bika min sharri ma fi hadhihil-laylah wa sharri ma ba'daha. Rabbi a'udhu bika minal-kasali wa su'il-kibar. Rabbi a'udhu bika min 'adhabin fin-nari wa 'adhabin fil-qabr.",
        german: "Wir haben den Abend erreicht, und die Herrschaft gehört Allah. Alles Lob gebührt Allah. Es gibt keinen Gott außer Allah, dem Einzigen, der keinen Teilhaber hat. Ihm gehört die Herrschaft und Ihm gebührt das Lob, und Er ist über alle Dinge mächtig. Mein Herr, ich bitte Dich um das Gute dieser Nacht und um das Gute, das danach kommt. Und ich suche Zuflucht bei Dir vor dem Übel dieser Nacht und dem Übel, das danach kommt. Mein Herr, ich suche Zuflucht bei Dir vor Faulheit und einem schlechten Alter. Mein Herr, ich suche Zuflucht bei Dir vor der Strafe im Höllenfeuer und der Strafe im Grab.",
        english: "We have reached the evening and at this very time unto Allah belongs all sovereignty, and all praise is for Allah. None has the right to be worshipped except Allah, alone, without partner, to Him belongs all sovereignty and praise and He is over all things omnipotent. My Lord, I ask You for the good of this night and the good of what follows it and I take refuge in You from the evil of this night and the evil of what follows it. My Lord, I take refuge in You from laziness and senility. My Lord, I take refuge in You from torment in the Fire and punishment in the grave.",
        count: 1
    , quickInterval: 17.33, normalInterval: 21.77),
    // 6. Allahumma bika amsayna (Abend)
    AdhkarItem(
        arabic: "اللَّهُمَّ بِكَ أَمْسَيْنَا، وَبِكَ أَصْبَحْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ وَإِلَيْكَ الْمَصِيرُ",
        transliteration: "Allahumma bika amsayna, wa bika asbahna, wa bika nahya, wa bika namutu wa ilaykal-masir.",
        german: "O Allah, durch Dich haben wir den Abend erreicht, und durch Dich haben wir den Morgen erreicht. Durch Dich leben wir, und durch Dich sterben wir, und zu Dir ist die Heimkehr.",
        english: "O Allah, by You we enter the evening and by You we enter the morning, by You we live and by You we die, and to You is the Final Return.",
        count: 1
    , quickInterval: 4.87, normalInterval: 7.07),
    // 7. Sayyidul Istighfar (Abend)
    AdhkarItem(
        arabic: "اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلاَّ أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لاَ يَغْفِرُ الذُّنوبَ إِلاَّ أَنْتَ",
        transliteration: "Allahumma Anta Rabbi la ilaha illa Ant. Khalaqtani wa ana 'abduka, wa ana 'ala 'ahdika wa wa'dika ma-stata't. A'udhu bika min sharri ma sana't. Abu'u laka bi-ni'matika 'alayy, wa abu'u bi-dhanbi fa-ghfir li, fa-innahu la yaghfiru-dh-dhunuba illa Ant.",
        german: "O Allah, Du bist mein Herr. Es gibt keinen Gott außer Dir. Du hast mich erschaffen, und ich bin Dein Diener. Ich halte mich an Deinen Bund und Dein Versprechen, so gut ich kann. Ich suche Zuflucht bei Dir vor dem Übel, das ich begangen habe. Ich bekenne mich zu Deinen Gnaden über mich, und ich bekenne mich zu meiner Sünde. So vergib mir, denn niemand vergibt die Sünden außer Dir.",
        english: "O Allah, You are my Lord, there is none worthy of worship but You. You created me and I am Your slave. I keep Your covenant, and my pledge to You so far as I am able. I seek refuge in You from the evil of what I have done. I admit to Your blessings upon me, and I admit to my misdeeds. Forgive me, for there is none who may forgive sins but You.",
        count: 1,
        linkedTasbihCategory: .istighfar
    , quickInterval: 10.47, normalInterval: 15.47),
    // 8. Allahumma inni amsaytu ushhiduka (Abend)
    AdhkarItem(
        arabic: "اللَّهُمَّ إِنِّي أَمْسَيْتُ أُشْهِدُكَ، وَأُشْهِدُ حَمَلَةَ عَرْشِكَ، وَمَلاَئِكَتِكَ، وَجَمِيعَ خَلْقِكَ، أَنَّكَ أَنْتَ اللَّهُ لَا إِلَهَ إِلاَّ أَنْتَ وَحْدَكَ لاَ شَرِيكَ لَكَ، وَأَنَّ مُحَمَّداً عَبْدُكَ وَرَسُولُكَ",
        transliteration: "Allahumma inni amsaytu ushhiduka, wa ushhidu hamalata 'arshika, wa mala'ikatika, wa jami'a khalqika, annaka Antallahu la ilaha illa Anta wahdaka la sharika lak, wa anna Muhammadan 'abduka wa rasuluk.",
        german: "O Allah, ich habe den Abend erreicht und rufe Dich als Zeugen an, ebenso wie die Träger Deines Thrones, Deine Engel und Deine gesamte Schöpfung, dass Du Allah bist, es gibt keinen Gott außer Dir allein, Du hast keinen Teilhaber, und dass Muhammad Dein Diener und Gesandter ist.",
        english: "O Allah, I have entered the evening calling You to witness, and calling the bearers of Your Throne to witness, Your angels and all of Your creation, that You are Allah, none has the right to be worshipped but You alone, without partner, and that Muhammad is Your servant and Messenger.",
        count: 4
    , quickInterval: 7.87, normalInterval: 10.6),
    // 9. Allahumma ma amsa bi min ni'matin (Abend)
    AdhkarItem(
        arabic: "اللَّهُمَّ مَا أَمْسَى بِي مِنْ نِعْمَةٍ أَوْ بِأَحَدٍ مِنْ خَلْقِكَ فَمِنْكَ وَحْدَكَ لاَ شَرِيكَ لَكَ، فَلَكَ الْحَمْدُ وَلَكَ الشُّكْرُ",
        transliteration: "Allahumma ma amsa bi min ni'matin aw bi-ahadin min khalqika fa-minka wahdaka la sharika lak, fa-lakal-hamdu wa lakash-shukr.",
        german: "O Allah, welche Gnade auch immer mich oder eines Deiner Geschöpfe an diesem Abend erreicht hat, sie ist von Dir allein, Du hast keinen Teilhaber. Dir gebührt alles Lob und Dir gebührt der Dank.",
        english: "O Allah, whatever blessing has been received by me or anyone of Your creation this evening, is from You alone, You have no partner. All praise is for You and thanks is to You.",
        count: 1
    , quickInterval: 5.79, normalInterval: 7.83),
    // 10. Allahumma 'afini fi badani (Abend)
    AdhkarItem(
        arabic: "اللَّهُمَّ عَافِنِي فِي بَدَنِي، اللَّهُمَّ عَافِنِي فِي سَمْعِي، اللَّهُمَّ عَافِنِي فِي بَصَرِي، لاَ إِلَهَ إِلاَّ أَنْتَ. اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْكُفْرِ، وَالفَقْرِ، وَأَعُوذُ بِكَ مِنْ عَذَابِ القَبْرِ، لاَ إِلَهَ إِلاَّ أَنْتَ",
        transliteration: "Allahumma 'afini fi badani, Allahumma 'afini fi sam'i, Allahumma 'afini fi basari, la ilaha illa Ant. Allahumma inni a'udhu bika minal-kufri wal-faqr, wa a'udhu bika min 'adhabil-qabr, la ilaha illa Ant.",
        german: "O Allah, gib mir Gesundheit in meinem Körper. O Allah, gib mir Gesundheit in meinem Gehör. O Allah, gib mir Gesundheit in meinem Augenlicht. Es gibt keinen Gott außer Dir. O Allah, ich suche Zuflucht bei Dir vor dem Unglauben und der Armut. Und ich suche Zuflucht bei Dir vor der Strafe im Grab. Es gibt keinen Gott außer Dir.",
        english: "O Allah, grant my body health. O Allah, grant my hearing health. O Allah, grant my sight health. None has the right to be worshipped but You. O Allah, I take refuge with You from disbelief and poverty, and I take refuge with You from the punishment of the grave. None has the right to be worshipped but You.",
        count: 3
    , quickInterval: 8.25, normalInterval: 12.63),
    // 11. Hasbiyallahu (Abend)
    AdhkarItem(
        arabic: "حَسْبِيَ اللَّهُ لاَ إِلَهَ إِلاَّ هُوَ عَلَيهِ تَوَكَّلتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ",
        transliteration: "Hasbiyallahu la ilaha illa Huwa 'alayhi tawakkaltu wa Huwa Rabbul-'Arshil-'Adheem.",
        german: "Allah genügt mir. Es gibt keinen Gott außer Ihm. Auf Ihn vertraue ich, und Er ist der Herr des gewaltigen Thrones.",
        english: "Allah is sufficient for me. There is none worthy of worship but Him. I have placed my trust in Him, and He is the Lord of the Majestic Throne.",
        count: 7
    , quickInterval: 3.3, normalInterval: 5.04),
    // 12. Allahumma inni as'aluka al-'afwa (Abend)
    AdhkarItem(
        arabic: "اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي الدُّنْيَا وَالآخِرَةِ، اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي دِينِي وَدُنْيَايَ وَأَهْلِي، وَمَالِي، اللَّهُمَّ اسْتُرْ عَوْرَاتِي، وَآمِنْ رَوْعَاتِي، اللَّهُمَّ احْفَظْنِي مِنْ بَينِ يَدَيَّ، وَمِنْ خَلْفِي، وَعَنْ يَمِينِي، وَعَنْ شِمَالِي، وَمِنْ فَوْقِي، وَأَعُوذُ بِعَظَمَتِكَ أَنْ أُغْتَالَ مِنْ تَحْتِي",
        transliteration: "Allahumma inni as'aluka-l-'afwa wal-'afiyata fid-dunya wal-akhirah. Allahumma inni as'aluka-l-'afwa wal-'afiyata fi dini wa dunyaya wa ahli wa mali. Allahumma-stur 'awrati wa amin raw'ati. Allahumma-hfazni min bayni yadayya, wa min khalfi, wa 'an yamini, wa 'an shimali, wa min fawqi, wa a'udhu bi-'adhamatika an ughtala min tahti.",
        german: "O Allah, ich bitte Dich um Vergebung und Wohlergehen im Diesseits und im Jenseits. O Allah, ich bitte Dich um Vergebung und Wohlergehen für meine Religion, mein weltliches Leben, meine Familie und mein Vermögen. O Allah, bedecke meine Blößen und beruhige meine Ängste. O Allah, beschütze mich von vorn, von hinten, von rechts, von links und von oben. Und ich suche Zuflucht bei Deiner Erhabenheit davor, dass ich von unten her meuchlings vernichtet werde.",
        english: "O Allah, I ask You for pardon and well-being in this life and the next. O Allah, I ask You for pardon and well-being in my religious and worldly affairs, and my family and my wealth. O Allah, veil my weaknesses and set at ease my dismay. O Allah, preserve me from the front and from behind and on my right and on my left and from above, and I take refuge with You lest I be swallowed up by the earth.",
        count: 1
    , quickInterval: 15.83, normalInterval: 21.0),
    // 13. Allahumma 'alimal-ghaybi (Abend)
    AdhkarItem(
        arabic: "اللَّهُمَّ عَالِمَ الْغَيْبِ وَالشَّهَادَةِ فَاطِرَ السَّمَوَاتِ وَالْأَرْضِ، رَبَّ كُلِّ شَيْءٍ وَمَلِيكَهُ، أَشْهَدُ أَنْ لاَ إِلَهَ إِلاَّ أَنْتَ، أَعُوذُ بِكَ مِنْ شَرِّ نَفْسِي، وَمِنْ شَرِّ الشَّيْطانِ وَشِـرْكِهِ، وَأَنْ أَقْتَرِفَ عَلَى نَفْسِي سُوءاً، أَوْ أَجُرَّهُ إِلَى مُسْلِمٍ",
        transliteration: "Allahumma 'Alimal-ghaybi wash-shahadati Fatiras-samawati wal-ard, Rabba kulli shay'in wa Malikah. Ash-hadu an la ilaha illa Ant. A'udhu bika min sharri nafsi, wa min sharrish-shaytani wa shirkihi, wa an aqtarifa 'ala nafsi su'an, aw ajurrahu ila Muslim.",
        german: "O Allah, Kenner des Verborgenen und des Offenbaren, Schöpfer der Himmel und der Erde, Herr und König von allem. Ich bezeuge, dass es keinen Gott gibt außer Dir. Ich suche Zuflucht bei Dir vor dem Übel meiner eigenen Seele, vor dem Übel des Satans und seiner Verführung zur Beigesellung (Schirk), und davor, dass ich mir selbst Böses antue oder es über einen Muslim bringe.",
        english: "O Allah, Knower of the unseen and the evident, Maker of the heavens and the earth, Lord of all things and their Sovereign, I bear witness that there is none worthy of worship but You. I seek refuge in You from the evil of my soul and from the evil of Satan and his helpers, and (I seek refuge in You) from bringing evil upon my soul or from harming a Muslim.",
        count: 1
    , quickInterval: 11.2, normalInterval: 14.62),
    // 14. Bismillah-illadhi la yadurru (Abend)
    AdhkarItem(
        arabic: "بِسْم. اللَّهِ الَّذِي لاَ يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلاَ فِي السّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ",
        transliteration: "Bismillahil-ladhi la yadurru ma'as-mihi shay'un fil-ardi wa la fis-sama'i wa Huwas-Sami'ul-'Alim.",
        german: "Im Namen Allahs, mit Dessen Namen nichts auf der Erde oder im Himmel Schaden zufügen kann, und Er ist der Allhörende, der Allwissende.",
        english: "In the Name of Allah, Who with His Name nothing can cause harm in the earth nor in the heavens, and He is the All-Hearing, the All-Knowing.",
        count: 3
    , quickInterval: 4.42, normalInterval: 6.22),
    // 15. Radiytu billahi (Abend)
    AdhkarItem(
        arabic: "رَضِيتُ بِاللَّهِ رَبَّاً، وَبِالْإِسْلاَمِ دِيناً، وَبِمُحَمَّدٍ صلى الله عليه وسلم نَبِيّاً",
        transliteration: "Radiytu billahi Rabban wabil-Islami dinan wa bi-Muhammadin sallallahu 'alayhi wa sallama Nabiyya.",
        german: "Ich bin zufrieden mit Allah als meinem Herrn, mit dem Islam als meiner Religion und mit Muhammad, Allahs Segen und Frieden seien auf ihm, als meinem Propheten.",
        english: "I am pleased with Allah as my Lord, with Islam as my religion and with Muhammad (peace and blessings of Allah be upon him) as my Prophet.",
        count: 3
    , quickInterval: 4.17, normalInterval: 6.4),
    // 16. Ya Hayyu ya Qayyum (Abend)
    AdhkarItem(
        arabic: "يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغيثُ أَصْلِحْ لِي شَأْنِيَ كُلَّهُ وَلاَ تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ",
        transliteration: "Ya Hayyu ya Qayyum bi-rahmatika astaghith, aslih li sha'ni kullahu wa la takilni ila nafsi tarfata 'ayn.",
        german: "O Ewiglebender, O Beständiger, durch Deine Barmherzigkeit rufe ich um Hilfe. Bringe all meine Angelegenheiten in Ordnung und überlasse mich nicht mir selbst, nicht einmal für den Wimpernschlag eines Auges.",
        english: "O Ever Living One, O Sustainer, by Your mercy I call on You to set right all my affairs, do not place me in charge of my soul even for the blinking of an eye.",
        count: 1
    , quickInterval: 5.1, normalInterval: 7.9),
    // 17. Amsayna wa amsal-mulku lillahi rabbil-'alamin
    AdhkarItem(
        arabic: "أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ رَبِّ الْعَالَمِينَ، اللَّهُـمَّ إِنِّي أَسْأَلُكَ خَيْرَ هَذِهِ اللَّيْلَةِ فَتْحَهَا، وَنَصْرَهَا، وَنورَهَا، وَبَرَكَتَهَا، وَهُدَاهَا، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِيهَا وَشَرِّ مَا بَعْدَهَا",
        transliteration: "Amsayna wa amsal-mulku lillahi Rabbil-'alamin. Allahumma inni as'aluka khayra hadhihil-laylah: fathaha, wa nasraha, wa nuraha, wa barakataha, wa hudaha. Wa a'udhu bika min sharri ma fiha wa sharri ma ba'daha.",
        german: "Wir haben den Abend erreicht, und die Herrschaft gehört Allah, dem Herrn der Welten. O Allah, ich bitte Dich um das Gute dieser Nacht: ihren Erfolg, seinen Sieg, ihr Licht, ihren Segen und ihre Rechtleitung. Und ich suche Zuflucht bei Dir vor dem Übel, das darin ist, und dem Übel, das danach kommt.",
        english: "We have reached the evening and at this very time unto Allah, Lord of the worlds, belongs all sovereignty. O Allah, I ask You for the good of this day, its victories, its help, its light, its blessings, and its guidance. I take refuge in You from the evil that is in it and from the evil that follows it.",
        count: 1
    , quickInterval: 8.77, normalInterval: 13.23),
    // 18. Amsayna 'ala fitratil-Islam
    AdhkarItem(
        arabic: "أَمْسَيْنَا عَلَى فِطْرَةِ الْإِسْلاَمِ، وَعَلَى كَلِمَةِ الْإِخْلاَصِ، وَعَلَى دِينِ نَبِيِّنَا مُحَمَّدٍ صلى الله عليه وسلم، وَعَلَى مِلَّةِ أَبِينَا إِبْرَاهِيمَ، حَنِيفاً مُسْلِماً وَمَا كَانَ مِنَ الْمُشرِكِينَ",
        transliteration: "Amsayna 'ala fitratil-Islam, wa 'ala kalimatil-ikhlas, wa 'ala dini Nabiyyina Muhammadin sallallahu 'alayhi wa sallam, wa 'ala millati abina Ibrahima hanifan Musliman wa ma kana minal-mushrikin.",
        german: "Wir haben den Abend erreicht in der natürlichen Veranlagung des Islam, auf dem Wort der reinen Ergebenheit, auf der Religion unseres Propheten Muhammad, Allahs Segen und Frieden seien auf ihm, und der Glaubensgemeinschaft unseres Vaters Ibrahim. Er war rechtgläubig, gottergeben und keiner der Götzendiener.",
        english: "We have entered a new night upon the natural religion of Islam, the word of sincere devotion, the religion of our Prophet Muhammad (peace and blessings of Allah be upon him), and the faith of our father Ibrahim. He was upright (in worshipping Allah), and a Muslim. He was not of those who worship others besides Allah.",
        count: 1
    , quickInterval: 9.1, normalInterval: 11.17),
    // 19. Subhanallahi wa bihamdihi (Abend)
    AdhkarItem(
        arabic: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ",
        transliteration: "Subhanallahi wa bihamdihi.",
        german: "Preis sei Allah, und Ihm gebührt Sein Lob.",
        english: "Glory is to Allah and praise is to Him.",
        count: 100
    , quickInterval: 1.01, normalInterval: 1.92),
    // 20. La ilaha illallah (Abend)
    AdhkarItem(
        arabic: "لاَ إِلَهَ إِلاَّ اللَّهُ، وَحْدَهُ لاَ شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ",
        transliteration: "La ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamdu wa Huwa 'ala kulli shay'in Qadir.",
        german: "Es gibt keinen Gott außer Allah, dem Einzigen, der keinen Teilhaber hat. Ihm gehört die Herrschaft und Ihm gebührt das Lob, und Er ist über alle Dinge mächtig.",
        english: "None has the right to be worshipped but Allah alone, Who has no partner. His is the dominion and His is the praise and He is Able to do all things.",
        count: 10
    , quickInterval: 4.67, normalInterval: 7.52),
    // 21. Astaghfirullah (Abend)
    AdhkarItem(
        arabic: "أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ",
        transliteration: "Astaghfirullaha wa atubu ilayh.",
        german: "Ich bitte Allah um Vergebung und kehre in Reue zu Ihm zurück.",
        english: "I seek the forgiveness of Allah and repent to Him.",
        count: 100,
        linkedTasbihCategory: .istighfar
    , quickInterval: 0.79, normalInterval: 2.67),
    // 22. A'udhu bikalimatillahit-tammati (Abend)
    AdhkarItem(
        arabic: "أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ",
        transliteration: "A'udhu bi-kalimatillahit-tammati min sharri ma khalaq.",
        german: "Ich suche Zuflucht bei den vollkommenen Worten Allahs vor dem Übel dessen, was Er erschaffen hat.",
        english: "I seek refuge in the Perfect Words of Allah from the evil of what He has created.",
        count: 3
    , quickInterval: 2.63, normalInterval: 4.22),
    // 23. Allahumma salli (Abend)
    AdhkarItem(
        arabic: "اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبَيِّنَا مُحَمَّدٍ",
        transliteration: "Allahumma salli wa sallim 'ala Nabiyyina Muhammad.",
        german: "O Allah, sende Segen und Frieden auf unseren Propheten Muhammad.",
        english: "O Allah, send blessings and peace upon our Prophet Muhammad.",
        count: 10,
        linkedTasbihCategory: .salawat
    , quickInterval: 1.56, normalInterval: 3.85)
]

let schlafAdhkar: [AdhkarItem] = [
    // 1. Bismika rabbi wada'tu janbi
    AdhkarItem(
        arabic: "بِاسْمِكَ رَبِّي وَضَعْتُ جَنْبِي، وَبِكَ أَرْفَعُهُ، فَإِن أَمْسَكْتَ نَفْسِي فارْحَمْهَا، وَإِنْ أَرْسَلْتَهَا فَاحْفَظْهَا، بِمَا تَحْفَظُ بِهِ عِبَادَكَ الصَّالِحِينَ",
        transliteration: "Bismika Rabbi wada'tu janbi, wa bika arfa'uh. Fa-in amsakta nafsi farhamha, wa in arsaltaha fahfazha bima tahfazu bihi 'ibadakas-salihin.",
        german: "In Deinem Namen, mein Herr, lege ich mich auf die Seite, und durch Dich erhebe ich mich wieder. Wenn Du meine Seele zurückhältst, erbarme Dich ihrer, und wenn Du sie zurücksendest, beschütze sie, womit Du Deine rechtschaffenen Diener beschützt.",
        english: "In Your Name, my Lord, I lay my side down, and in Your Name I raise it. If You take my soul, have mercy on it, and if You send it back, protect it as You protect Your righteous slaves.",
        count: 1
    , quickInterval: 7.47, normalInterval: 10.3),
    // 2. Allahumma innaka khalaqta nafsi
    AdhkarItem(
        arabic: "اللَّهُمَّ إِنَّكَ خَلَقْتَ نَفْسِي وَأَنْتَ تَوَفَّاهَا، لَكَ مَمَاتُهَا وَمَحْياهَا، إِنْ أَحْيَيْتَهَا فَاحْفَظْهَا، وَإِنْ أَمَتَّهَا فَاغْفِرْ لَهَا. اللَّهُمَّ إِنِّي أَسْأَلُكَ العَافِيَةَ",
        transliteration: "Allahumma innaka khalaqta nafsi wa Anta tawaffaha. Laka mamatuha wa mahyaha. In ahyaytaha fahfazha, wa in amattaha faghfir laha. Allahumma inni as'alukal-'afiyah.",
        german: "O Allah, Du hast meine Seele erschaffen und Du nimmst sie zu Dir. Dir gehört ihr Tod und ihr Leben. Wenn Du sie am Leben lässt, beschütze sie, und wenn Du sie sterben lässt, vergib ihr. O Allah, ich bitte Dich um Wohlergehen.",
        english: "O Allah, You created my soul and You take it back. To You belongs its death and its life. If You keep it alive, protect it, and if You cause it to die, forgive it. O Allah, I ask You for well-being.",
        count: 1
    , quickInterval: 7.4, normalInterval: 11.57),
    // 3. Allahumma qini 'adhabaka
    AdhkarItem(
        arabic: "اللَّهُمَّ قِنِي عَذَابَكَ يَوْمَ تَبْعَثُ عِبَادَكَ",
        transliteration: "Allahumma qini 'adhabaka yawma tab'athu 'ibadak.",
        german: "O Allah, bewahre mich vor Deiner Strafe an dem Tag, an dem Du Deine Diener auferweckst.",
        english: "O Allah, protect me from Your punishment on the day You resurrect Your slaves.",
        count: 3
    , quickInterval: 2.73, normalInterval: 3.07),
    // 4. Bismika Allahumma amutu wa ahya
    AdhkarItem(
        arabic: "بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا",
        transliteration: "Bismika Allahumma amutu wa ahya.",
        german: "In Deinem Namen, O Allah, sterbe ich und lebe ich.",
        english: "In Your Name, O Allah, I die and I live.",
        count: 1
    , quickInterval: 2.07, normalInterval: 2.53),
    // 5. Alhamdulillahil-ladhi at'amana
    AdhkarItem(
        arabic: "الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنَا وَسَقَانَا، وَكَفَانَا، وَآوَانَا، فَكَمْ مِمَّنْ لاَ كَافِيَ لَهُ وَلاَ مُؤْوِيَ",
        transliteration: "Alhamdulillahil-ladhi at'amana wa saqana, wa kafana wa awana. Fakam mimman la kafiya lahu wa la mu'wi.",
        german: "Alles Lob gebührt Allah, Der uns zu essen und zu trinken gab, uns genügen ließ und uns Obdach gab. Denn wie viele gibt es, für die niemand genügt und die kein Obdach haben!",
        english: "All praise is for Allah, Who fed us and gave us drink, and Who is sufficient for us and has sheltered us. For how many have none to suffice them or shelter them!",
        count: 1
    , quickInterval: 6.0, normalInterval: 8.57),
    // 6. Allahumma 'alimal-ghaybi
    AdhkarItem(
        arabic: "اللَّهُمَّ عَالِمَ الغَيْبِ وَالشَّهَادَةِ فَاطِرَ السَّمَوَاتِ وَالْأَرْضِ، رَبَّ كُلِّ شَيْءٍ وَمَلِيكَهُ، أَشْهَدُ أَنْ لاَ إِلَهَ إِلاَّ أَنْتَ، أَعُوذُ بِكَ مِنْ شَرِّ نَفْسِي، وَمِنْ شَرِّ الشَّيْطانِ وَشِرْكِهِ، وَأَنْ أَقْتَرِفَ عَلَى نَفْسِي سُوءاً، أَوْ أَجُرَّهُ إِلَى مُسْلِمٍ",
        transliteration: "Allahumma 'Alimal-ghaybi wash-shahadati Fatiras-samawati wal-ard, Rabba kulli shay'in wa Malikah. Ash-hadu an la ilaha illa Ant. A'udhu bika min sharri nafsi, wa min sharrish-shaytani wa shirkihi, wa an aqtarifa 'ala nafsi su'an, aw ajurrahu ila Muslim.",
        german: "O Allah, Kenner des Verborgenen und des Offenbaren, Schöpfer der Himmel und der Erde, Herr und König von allem. Ich bezeuge, dass es keinen Gott gibt außer Dir. Ich suche Zuflucht bei Dir vor dem Übel meiner eigenen Seele, vor dem Übel des Satans und seiner Verführung zur Beigesellung (Schirk), und davor, dass ich mir selbst Böses antue oder es über einen Muslim bringe.",
        english: "O Allah, Knower of the unseen and the evident, Maker of the heavens and the earth, Lord of all things and their Sovereign, I bear witness that there is none worthy of worship but You. I seek refuge in You from the evil of my soul and from the evil of Satan and his helpers, and (I seek refuge in You) from bringing evil upon my soul or from harming a Muslim.",
        count: 1
    , quickInterval: 10.67, normalInterval: 15.0),
    // 7. Allahumma aslamtu nafsi ilayk
    AdhkarItem(
        arabic: "اللَّهُمَّ أَسْلَمْتُ نَفْسِي إِلَيْكَ، وَفَوَّضْتُ أَمْرِي إِلَيْكَ، وَوَجَّهْتُ وَجْهِي إِلَيْكَ، وَأَلْجَأْتُ ظَهْرِي إِلَيْكَ، رَغْبَةً وَرَهْبَةً إِلَيْكَ، لاَ مَلْجَأَ وَلاَ مَنْجَا مِنْكَ إِلاَّ إِلَيْكَ، آمَنْتُ بِكِتَابِكَ الَّذِي أَنْزَلْتَ، وَبِنَبِيِّكَ الَّذِي أَرْسَلْتَ",
        transliteration: "Allahumma aslamtu nafsi ilayk, wa fawwadtu amri ilayk, wa wajjahtu wajhi ilayk, wa alja'tu dhahri ilayk, raghbatan wa rahbatan ilayk. La malja'a wa la manja minka illa ilayk. Amantu bikitabikal-ladhi anzalt, wa bi-nabiyyikal-ladhi arsalt.",
        german: "O Allah, ich ergebe mich Dir, übergebe meine Angelegenheit an Dich, wende mein Gesicht Dir zu und lehne meinen Rücken an Dich, aus Verlangen nach Dir und aus Furcht vor Dir. Es gibt keine Zuflucht und keine Rettung vor Dir außer bei Dir. Ich glaube an Dein Buch, das Du herabgesandt hast, und an Deinen Propheten, den Du gesandt hast.",
        english: "O Allah, I submit myself to You, entrust my affairs to You, turn my face to You, and lay my back upon You, out of hope in You and fear of You. There is no refuge or escape from You except in You. I believe in Your Book which You have revealed, and in Your Prophet whom You have sent.",
        count: 1
    , quickInterval: 12.3, normalInterval: 19.69),
    // 8. Tasbih vor dem Schlafen
    AdhkarItem(
        arabic: "سُبْحَانَ اللَّهِ (ثلاثاً وثلاثين) وَالْحَمْدُ لِلَّهِ (ثلاثاً وثلاثين) وَاللَّهُ أَكْبَرُ (أربعاً وثلاثينَ)",
        transliteration: "Subhanal-lah (thirty-three times), wal-hamdu lillah (thirty-three times), wal-lahu Akbar (thirty-four times).",
        german: "Verherrlicht sei Allah (dreiunddreißigmal), alles Lob gebührt Allah (dreiunddreißigmal) und Allah ist am größten (vierunddreißigmal).",
        english: "Glory is to Allah (thirty-three times), praise is to Allah (thirty-three times), and Allah is the Most Great (thirty-four times).",
        count: 1
    , quickInterval: 1.7, normalInterval: 2.8),
    // 9. Schutzsuren mit Pusten und Streichen
    AdhkarItem(
        arabic: "يَجْمَعُ كَفَّيْهِ ثُمَّ يَنْفُثُ فِيهِمَا فَيَقْرَأُ فِيهِمَا: بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ ﴿قُلْ هُوَ اللَّهُ أَحَدٌ...﴾ وَ ﴿قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ...﴾ وَ ﴿قُلْ أَعُوذُ بِرَبِّ النَّاسِ...﴾ ثُمَّ يَمْسَحُ بِهِمَا مَا اسْتَطَاعَ مِنْ جَسَدِهِ، يَبْدَأُ بِهِمَا عَلَى رَأْسِهِ وَوَجْهِهِ وَمَا أَقْبَلَ مِنْ جَسَدِهِ",
        transliteration: "Yajma'u kaffayhi thumma yanfuthu fihima fayaqra'u fihima: Bismillahir-Rahmanir-Rahim: Qul Huwallahu Ahad... Qul a'udhu bi Rabbil-falaq... Qul a'udhu bi Rabbin-nas... thumma yamsahu bihima ma-stata'a min jasadihi, yabda'u bihima 'ala ra'sihi wa wajhihi wa ma aqbala min jasadihi.",
        german: "Er führt seine Handflächen zusammen, pustet hinein und rezitiert: Im Namen Allahs, des Allerbarmers, des Barmherzigen: Sprich: Er ist Allah, ein Einziger... Sprich: Ich nehme Zuflucht beim Herrn des Frühlichts... Sprich: Ich nehme Zuflucht beim Herrn der Menschen... Dann streicht er mit ihnen über so viel von seinem Körper, wie er kann, beginnend mit seinem Kopf, seinem Gesicht und der Vorderseite seines Körpers.",
        english: "He would join his hands together, blow into them and recite: In the Name of Allah, the Most Gracious, the Most Merciful: Say: He is Allah, (who is) One... Say: I seek refuge in the Lord of daybreak... Say: I seek refuge in the Lord of mankind... Then he would wipe as much of his body as he could with them, starting with his head, his face, and the front of his body.",
        count: 3
    , quickInterval: 6.88, normalInterval: 29.5),
    // 10. Ayat al-Kursi
    AdhkarItem(
        arabic: "اللَّهُ لاَ إِلَهَ إِلاَّ هُوَ الْحَيُّ الْقَيُّومُ لاَ تَأْخُذُهُ سِنَةٌ وَلاَ نَوْمٌ لَّهُ مَا فِي السَّمَوَاتِ وَمَا فِي الأَرْضِ مَن ذَا الَّذِي يَشْفَعُ عِنْدَهُ إِلاَّ بِإِذْنِهِ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ وَلاَ يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلاَّ بِمَا شَاء وَسِعَ كُرْسِيُّهُ السَّمَوَاتِ وَالْأَرْضَ وَلاَ يَؤُودُهُ حِفْظُهُمَا وَهُوَ الْعَلِيُّ الْعَظِيمُ",
        transliteration: "Allahu la ilaha illa Huwal-Hayyul-Qayyum. La ta'khudhuhu sinatun wa la nawm. Lahu ma fis-samawati wa ma fil-ard. Man dhal-ladhi yashfa'u 'indahu illa bi-idhnih. Ya'lamu ma bayna aydihim wa ma khalfahum. Wa la yuhituna bi-shay'im-min 'ilmihi illa bima sha'. Wasi'a kursiyyuhus-samawati wal-ard, wa la ya'uduhu hifdhuhuma, wa Huwal-'Aliyyul-'Adheem.",
        german: "Allah – es gibt keinen Gott außer Ihm, dem Lebendigen und Beständigen. Ihn überkommt weder Schlummer noch Schlaf. Ihm gehört, was in den Himmeln und was auf der Erde ist. Wer ist es, der bei Ihm Fürsprache einlegen könnte außer mit Seiner Erlaubnis? Er weiß, was vor ihnen und was hinter ihnen liegt; sie aber begreifen nichts von Seinem Wissen, es sei denn das, was Er will. Sein Thronschemel umfasst die Himmel und die Erde, und ihre Bewahrung beschwert Ihn nicht. Und Er ist der Erhabene, der Allgewaltige.",
        english: "Allah! There is no deity except Him, the Ever-Living, the Sustainer of all existence. Neither drowsiness overtakes Him nor sleep. To Him belongs whatever is in the heavens and whatever is on the earth. Who is it that can intercede with Him except by His permission? He knows what is presently before them and what will be after them, and they encompass not a thing of His knowledge except for what He wills. His Kursi extends over the heavens and the earth, and their preservation tires Him not. And He is the Most High, the Most Great.",
        count: 1
    , quickInterval: 17.7, normalInterval: 26.5),
    // 11. Die Anweisung, As-Sajdah und Al-Mulk zu lesen
    AdhkarItem(
        arabic: "يَقْرَأُ ﴿ الم ﴾ تَنْزِيلَ السَّجْدَة ِ، وَتَبَارَكَ الَّذي بِيَدِهِ الْمُلْكُ",
        transliteration: "Yaqra'u Alif-Lam-Mim Tanzilas-Sajdah, wa Tabarakal-ladhi bi-yadihil-Mulk.",
        german: "Es wird empfohlen, vor dem Schlafen die Sure As-Sajdah (Kapitel 32) und die Sure Al-Mulk (Kapitel 67) zu lesen.",
        english: "It is recommended to recite Surah As-Sajdah (Chapter 32) and Surah Al-Mulk (Chapter 67) before sleeping.",
        count: 1
    , quickInterval: 0.0, normalInterval: 0.0)
]

extension AdhkarItem {
    var defaultInterval: TimeInterval {
        let text = self.arabic
        
        // Spezifische Optimierungen für bekannte Adhkar
        if text.contains("سُبْحَانَ اللَّهِ وَبِحَمْدِهِ") {
            return 1.2 // Subhanallahi wa bihamdihi (ca. 50 BPM)
        }
        if text.contains("أَسْتَغْفِرُ") {
            return 1.8 // Astaghfirullah wa atubu ilayh (ca. 33 BPM)
        }
        if text.contains("صَلِّ وَسَلِّمْ") || text.contains("اللَّهُمَّ صَلِّ") {
            return 2.4 // Allahumma salli... (ca. 25 BPM)
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
        return max(1.2, Double(letterCount) * 0.085)
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
        return self.german
    }
}

struct AdhkarTranslations {
    static func getEnglish(for arabic: String) -> String? {
        for (key, val) in translations {
            if arabic.hasPrefix(key) {
                return val
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
