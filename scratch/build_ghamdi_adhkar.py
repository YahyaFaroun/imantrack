import os, subprocess, shutil

OUT_DIR = "ImanTrack/Audio/Adhkar"
os.makedirs(OUT_DIR, exist_ok=True)

def encode_audio(in_file, out_file, ss=None, to=None, t=None):
    cmd = ['ffmpeg', '-y']
    if ss is not None:
        cmd.extend(['-ss', str(ss)])
    if to is not None:
        cmd.extend(['-to', str(to)])
    elif t is not None:
        cmd.extend(['-t', str(t)])
    cmd.extend(['-i', in_file, '-vn', '-c:a', 'aac', '-b:a', '64k', '-ar', '44100', out_file])
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    print(f"Created {out_file}: {os.path.getsize(out_file)} bytes")

MORNING_RAW = "scratch/ghamdi_raw/morning.mp3"
SLEEP_RAW = "scratch/ghamdi_raw/sleep_full.mp3"
SAYYID_RAW = "scratch/ghamdi_raw/sayyidul_istighfar.mp3"
ASTAGH_RAW = "scratch/ghamdi_raw/astaghfirullah.mp3"

# 1. Ayat al-Kursi
encode_audio("scratch/ghamdi_002255.mp3", f"{OUT_DIR}/ghamdi_morning_1.m4a")

# 2. Al-Ikhlas
encode_audio("scratch/ghamdi_112.mp3", f"{OUT_DIR}/ghamdi_morning_2.m4a")

# 3. Al-Falaq
encode_audio("scratch/ghamdi_113.mp3", f"{OUT_DIR}/ghamdi_morning_3.m4a")

# 4. An-Nas
encode_audio("scratch/ghamdi_114.mp3", f"{OUT_DIR}/ghamdi_morning_4.m4a")

# 5. Asbahna wa asbahal mulk
encode_audio(MORNING_RAW, f"{OUT_DIR}/ghamdi_morning_5.m4a", ss=244.2, to=296.0)

# 6. Allahumma bika asbahna
encode_audio(MORNING_RAW, f"{OUT_DIR}/ghamdi_morning_6.m4a", ss=296.4, to=307.0)

# 7. Sayyidul Istighfar
encode_audio(SAYYID_RAW, f"{OUT_DIR}/ghamdi_morning_7.m4a", ss=0.3, to=32.0)

# 8. Allahumma inni asbahtu ushhiduk (1 rep)
encode_audio(MORNING_RAW, f"{OUT_DIR}/ghamdi_morning_8.m4a", ss=378.0, to=405.8)

# 9. Allahumma ma asbaha bi
encode_audio(MORNING_RAW, f"{OUT_DIR}/ghamdi_morning_9.m4a", ss=496.2, to=509.9)

# 10. Allahumma 'afini fi badani (1 rep)
encode_audio(MORNING_RAW, f"{OUT_DIR}/ghamdi_morning_10.m4a", ss=509.9, to=535.4)

# 11. Hasbiyallahu (1 rep)
encode_audio(MORNING_RAW, f"{OUT_DIR}/ghamdi_morning_11.m4a", ss=591.7, to=603.8)

# 12. Allahumma inni as'aluka al-'afwa
encode_audio(MORNING_RAW, f"{OUT_DIR}/ghamdi_morning_12.m4a", ss=334.4, to=377.0)

# 13. Allahumma 'alimal ghayb
encode_audio(MORNING_RAW, f"{OUT_DIR}/ghamdi_morning_13.m4a", ss=666.9, to=700.4)

# 14. Bismillahilladhi la yadurru (1 rep)
encode_audio(MORNING_RAW, f"{OUT_DIR}/ghamdi_morning_14.m4a", ss=700.75, to=714.15)

# 15. Radiytu billahi (1 rep)
encode_audio(MORNING_RAW, f"{OUT_DIR}/ghamdi_morning_15.m4a", ss=740.2, to=754.2)

# 16. Ya Hayyu ya Qayyum
encode_audio(MORNING_RAW, f"{OUT_DIR}/ghamdi_morning_16.m4a", ss=782.3, to=799.4)

# 17. Asbahna wa asbahal mulku lillahi rabbil 'alamin
encode_audio(MORNING_RAW, f"{OUT_DIR}/ghamdi_morning_17.m4a", ss=307.0, to=334.0)

# 18. Asbahna 'ala fitratil Islam
encode_audio(MORNING_RAW, f"{OUT_DIR}/ghamdi_morning_18.m4a", ss=307.0, to=334.0)

# 19. SubhanAllahi wa bihamdih (1 rep)
encode_audio(MORNING_RAW, f"{OUT_DIR}/ghamdi_morning_19.m4a", ss=1124.8, to=1129.0)

# 20. La ilaha illallahu wahdahu (1 rep)
encode_audio(MORNING_RAW, f"{OUT_DIR}/ghamdi_morning_20.m4a", ss=799.4, to=814.9)

# 21. SubhanAllahi wa bihamdihi 'adada (1 rep)
encode_audio(MORNING_RAW, f"{OUT_DIR}/ghamdi_morning_21.m4a", ss=1035.9, to=1050.7)

# 22. Allahumma inni as'aluka 'ilman nafi'an
encode_audio(MORNING_RAW, f"{OUT_DIR}/ghamdi_morning_22.m4a", ss=953.5, to=963.9)

# 23. Astaghfirullah wa atubu ilayh
encode_audio(ASTAGH_RAW, f"{OUT_DIR}/ghamdi_morning_23.m4a", ss=0.5, to=12.0)

# 24. A'udhu bi kalimatillahi tammati (1 rep)
encode_audio(MORNING_RAW, f"{OUT_DIR}/ghamdi_morning_24.m4a", ss=1086.4, to=1096.2)

# 25. Allahumma salli (1 rep)
encode_audio(MORNING_RAW, f"{OUT_DIR}/ghamdi_morning_25.m4a", ss=963.9, to=977.2)

# Evening Adhkar (1 to 23)
evening_map = {
    1: 1, 2: 2, 3: 3, 4: 4, 5: 5, 6: 6, 7: 7, 8: 8, 9: 9, 10: 10,
    11: 11, 12: 12, 13: 13, 14: 14, 15: 15, 16: 16, 17: 17, 18: 18,
    19: 19, 20: 20, 21: 23, 22: 24, 23: 25
}
for ev_num, m_num in evening_map.items():
    src = f"{OUT_DIR}/ghamdi_morning_{m_num}.m4a"
    dst = f"{OUT_DIR}/ghamdi_evening_{ev_num}.m4a"
    shutil.copy2(src, dst)
    print(f"Created {dst} from {src}")

# Sleep Adhkar
# 1. Schutzsuren (Al-Ikhlas + Al-Falaq + An-Nas concatenated)
cmd = [
    'ffmpeg', '-y',
    '-i', 'scratch/ghamdi_112.mp3',
    '-i', 'scratch/ghamdi_113.mp3',
    '-i', 'scratch/ghamdi_114.mp3',
    '-filter_complex', '[0:a][1:a][2:a]concat=n=3:v=0:a=1[outa]',
    '-map', '[outa]',
    '-c:a', 'aac', '-b:a', '64k', '-ar', '44100',
    f"{OUT_DIR}/ghamdi_sleep_1.m4a"
]
subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
print("Created sleep_1")

# 2. Ayat al-Kursi
encode_audio("scratch/ghamdi_002255.mp3", f"{OUT_DIR}/ghamdi_sleep_2.m4a")

# 3. Baqarah 285-286 concatenated
cmd = [
    'ffmpeg', '-y',
    '-i', 'scratch/ghamdi_002285.mp3',
    '-i', 'scratch/ghamdi_002286.mp3',
    '-filter_complex', '[0:a][1:a]concat=n=2:v=0:a=1[outa]',
    '-map', '[outa]',
    '-c:a', 'aac', '-b:a', '64k', '-ar', '44100',
    f"{OUT_DIR}/ghamdi_sleep_3.m4a"
]
subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
print("Created sleep_3")

# 4. Bismika rabbi wada'tu janbi
encode_audio(SLEEP_RAW, f"{OUT_DIR}/ghamdi_sleep_4.m4a", ss=410.5, to=430.0)

# 5. Allahumma innaka khalaqta nafsi
encode_audio(SLEEP_RAW, f"{OUT_DIR}/ghamdi_sleep_5.m4a", ss=430.0, to=453.5)

# 6. Allahumma qini 'adhabaka (1 rep)
encode_audio(SLEEP_RAW, f"{OUT_DIR}/ghamdi_sleep_6.m4a", ss=453.5, to=460.2)

# 7. Bismika Allahumma amutu wa ahya
encode_audio(SLEEP_RAW, f"{OUT_DIR}/ghamdi_sleep_7.m4a", ss=473.5, to=479.5)

# 8. Tasbih vor dem Schlafen
encode_audio("scratch/test_sleep_tasbih.m4a", f"{OUT_DIR}/ghamdi_sleep_8.m4a")

# 9. Allahumma rabbi as-samawatis-sab'i
encode_audio(SLEEP_RAW, f"{OUT_DIR}/ghamdi_sleep_9.m4a", ss=480.7, to=535.4)

# 10. Alhamdulillahil-ladhi at'amana
encode_audio(SLEEP_RAW, f"{OUT_DIR}/ghamdi_sleep_10.m4a", ss=535.4, to=550.2)

# 11. Allahumma 'alimal ghayb
encode_audio(SLEEP_RAW, f"{OUT_DIR}/ghamdi_sleep_11.m4a", ss=550.2, to=582.0)

# 13. Allahumma aslamtu nafsi ilayk
encode_audio(SLEEP_RAW, f"{OUT_DIR}/ghamdi_sleep_13.m4a", ss=582.0, to=625.0)

print("\n--- ALL SAAD AL-GHAMDI ADHKAR FILES PRODUCED SUCCESSFULLY! ---")
