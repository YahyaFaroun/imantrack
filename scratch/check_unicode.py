# -*- coding: utf-8 -*-
with open('/Users/princepalestine/Desktop/ImanTracker/ImanTracker/ImanTrack/Models/AdhkarData.swift', 'r', encoding='utf-8') as f:
    lines = f.readlines()

line_434 = lines[433].strip() # 0-indexed line 434 is index 433
end_of_line = line_434[-50:]
print(f"End of line 434: '{end_of_line}'")
for char in end_of_line:
    print(f"Char: '{char}' - Name/Code: U+{ord(char):04X}")
