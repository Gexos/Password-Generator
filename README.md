# Strong Password Generator (Portable)

A simple, portable Windows app to generate strong passwords and passphrases locally (offline).

If you just want to **use** it, go to the **Releases** page of this repo and download the latest ZIP.

---

## What this app does

You can generate:

**1) Passwords (characters)**
- Choose length
- Choose sets: lowercase / uppercase / digits / symbols
- Use your own symbol list (supports `\ / ! @ # $ % ^ & *` and more)
- Options like “enforce 1 of each type”, “website-safe”, “exclude ambiguous”

**2) Passphrases (words)**
- Choose number of words (ex: 4–6)
- Choose a separator (ex: `-` or `_`)
- Optional random capitalization
- Optional append digits and/or one symbol
- Uses a `wordlist.txt` file (one word per line)

Everything is generated on your PC. No internet. No accounts.

---

## Quick start (users)

### 1) Download
1. Open the **Releases** page (right side on GitHub)
2. Download the latest **ZIP**
3. Extract it anywhere (Desktop is fine)

### 2) Run
Double-click:

- `PasswordGen.exe`

### 3) Generate + copy
- Pick **Password** or **Passphrase**
- Set your options
- Click **Generate**
- Click **Copy** to copy to clipboard

---

## Important: keep these files together

Inside the extracted folder you will see something like:

- `PasswordGen.exe`
- `PasswordEngine.exe`
- `_internal\`  (folder)
- `wordlist.txt` (optional but recommended)
- `HELP.txt` (optional)

**Do not delete `_internal\`.**  
If `_internal\` is missing, the engine can’t run and Generate may appear to “do nothing”.

---

## Recommended settings (practical)

### Passwords (characters)
- **General use:** 16–24 characters  
- Enable:
  - Lower + Upper + Digits
  - Symbols (if the website allows it)
  - **Enforce 1 of each selected** (helps with strict website rules)

If a website rejects your password:
- turn on **Website-safe mode**
- or remove specific symbols from the symbols box

### Passphrases (words)
- **Good default:** 4–6 words
- Separator: `-` is easy to read and type
- For extra strength:
  - append 2 digits
  - append 1 symbol

---

## Wordlist (wordlist.txt)

Passphrase strength depends heavily on the size/quality of the wordlist.

Format:
- plain text
- one word per line

Example:
```
alpha
bravo
charlie
delta
```

Bigger list = stronger passphrases (thousands of words is ideal).

---

## Privacy & security notes

- Uses cryptographically secure randomness (CSPRNG) in the engine.
- Does not send data online.
- Does not store generated passwords.

Clipboard note:
- After you press **Copy**, the password stays in clipboard until you copy something else.
- If you want an “auto-clear clipboard after X seconds” feature, open an Issue.

---

## Troubleshooting

### Generate does nothing / no output
Most common causes:
1) `PasswordEngine.exe` is missing
2) `_internal\` folder is missing
3) Antivirus quarantined the engine

Fix:
- Make sure `PasswordGen.exe`, `PasswordEngine.exe`, and `_internal\` are in the same folder.
- Check Windows Security → **Protection history** and restore files if quarantined.

### Antivirus / SmartScreen warnings
Portable packaged apps can trigger false positives on some systems.
If you downloaded from Releases:
- verify hashes (if provided)
- restore from Protection history if needed

---

## Questions / support
If you’re stuck, open an Issue and include:
- your Windows version (10/11)
- whether you use the x64 build
- the exact message shown in the app (if any)
- whether Windows Security quarantined anything
