import os
import json

arb_dir = "lib/l10n"
new_keys = {
    "gameSudokuScore": "Score: {score}",
    "@gameSudokuScore": {
        "placeholders": {
            "score": {}
        }
    },
    "gameSudokuMistakes": "Mistakes: {mistakes}/3",
    "@gameSudokuMistakes": {
        "placeholders": {
            "mistakes": {}
        }
    },
    "gameSudokuStreak": "Streak {streak}",
    "@gameSudokuStreak": {
        "placeholders": {
            "streak": {}
        }
    },
    "gameSudokuLevelEasy": "Easy",
    "@gameSudokuLevelEasy": {},
    "gameSudokuLevelMedium": "Medium",
    "@gameSudokuLevelMedium": {},
    "gameSudokuLevelHard": "Hard",
    "@gameSudokuLevelHard": {},
    "gameSudokuLevelExpert": "Expert",
    "@gameSudokuLevelExpert": {},
    "gameSudokuUndo": "Undo",
    "@gameSudokuUndo": {},
    "gameSudokuErase": "Erase",
    "@gameSudokuErase": {},
    "gameSudokuPencil": "Pencil",
    "@gameSudokuPencil": {},
    "gameSudokuFastPencil": "Fast Pencil",
    "@gameSudokuFastPencil": {},
    "gameSudokuHint": "Hint",
    "@gameSudokuHint": {}
}

for filename in os.listdir(arb_dir):
    if filename.endswith(".arb") and filename != "app_en.arb":
        filepath = os.path.join(arb_dir, filename)
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        updated = False
        for k, v in new_keys.items():
            if k not in data:
                data[k] = v
                updated = True
        
        if updated:
            with open(filepath, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
            print(f"Updated {filename}")
