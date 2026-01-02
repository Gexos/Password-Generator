# Strong Password Generator (Portable) — AutoIt UI + PasswordEngine

A portable Windows password generator with two modes:
- **Password mode**: strong random character passwords (length, rules, symbols, exclusions, etc.)
- **Passphrase mode**: multi-word passphrases (separator, capitalization, append digits/symbol)

The UI is written in **AutoIt** and calls a small engine compiled from **Python** (cryptographically secure randomness via `secrets`).

No installation required for end users.

## Features

### Password mode (characters)
- Length (4–256)
- Lowercase / Uppercase / Digits / Symbols toggles
- Custom symbol set (supports `\ / ! @ # $ % ^ & *` and more)
- Enforce “at least 1 of each selected type”
- Exclude ambiguous characters (O/0, l/1, quotes, etc.)
- Exclude similar symbols (\, /, |, quotes, etc.)
- Website-safe mode (avoids common problematic characters)
- Optional “no repeats”
- Entropy estimate (rough but useful)

### Passphrase mode (words)
- Word count (2–20)
- Custom separator
- Uses `wordlist.txt` (one word per line)
- Optional random capitalization
- Optional append digits
- Optional append 1 symbol
- Entropy estimate

## Download / Portable usage
The portable ZIP contains:
- `PasswordGen.exe` (AutoIt GUI)
- `PasswordEngine.exe` + `_internal\` (engine runtime, required)
- `wordlist.txt` (recommended for passphrases)

Important: if `_internal\` is missing, the engine will not run.

## Build (developers)

### Requirements
- Windows
- Python 3.x (dev machine only)
- AutoIt + Aut2Exe
- PyInstaller

### 1) Build the engine (Python → EXE)
From the repo folder:

```bat
py -3 -m pip install pyinstaller
py -3 -m PyInstaller --noconsole --clean --onedir --name PasswordEngine gen.py

