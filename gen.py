#!/usr/bin/env python3
"""PasswordEngine - secure password & passphrase generator.

This is the Python *source* for the portable engine used by the AutoIt GUI.

Key points:
- Uses cryptographically-secure randomness via Python's `secrets`
- Supports password mode (characters) and passphrase mode (words)
- For portable GUI builds (PyInstaller --noconsole), stdout can be unreliable,
  so this engine supports `--out-file` to write JSON output to a file.

Typical usage (engine EXE):
  PasswordEngine.exe --json --mode password --out-file out.json --length 24 --lower --upper --digits --allow-symbols --symbols "\\/!@#$%^&*n" --enforce-each
"""

import argparse
import json
import math
import os
import re
import secrets
import string
from typing import List, Tuple

AMBIGUOUS = set("O0oIl1|`'\"")
SIMILAR_SYMBOLS = set("\\|/`'\"")

FALLBACK_WORDS = [
    "alpha","bravo","cobalt","delta","ember","falcon","gadget","harbor","ivory","jazz",
    "karma","lunar","matrix","nebula","onyx","pixel","quantum","ranger","saffron","tiger",
    "ultra","vector","whiskey","xenon","yonder","zephyr","crypto","socket","router","kernel",
    "cipher","buffer","packet","lambda","python","autoit","orange","atlas","vortex","shadow",
]

def load_wordlist(path: str) -> List[str]:
    if not path or not os.path.exists(path):
        return FALLBACK_WORDS
    words: List[str] = []
    with open(path, "r", encoding="utf-8", errors="ignore") as f:
        for line in f:
            w = line.strip()
            if not w:
                continue
            if re.fullmatch(r"[A-Za-z]{3,20}", w):
                words.append(w.lower())
    return words if words else FALLBACK_WORDS

def entropy_bits_char(length: int, pool_size: int) -> float:
    return 0.0 if length <= 0 or pool_size <= 1 else length * math.log2(pool_size)

def entropy_bits_words(words_count: int, wordlist_size: int) -> float:
    return 0.0 if words_count <= 0 or wordlist_size <= 1 else words_count * math.log2(wordlist_size)

def secure_shuffle(chars: List[str]) -> None:
    for i in range(len(chars) - 1, 0, -1):
        j = secrets.randbelow(i + 1)
        chars[i], chars[j] = chars[j], chars[i]

def pick_required(groups: List[str]) -> List[str]:
    return [secrets.choice(g) for g in groups if g]

def build_pool(args) -> Tuple[str, List[str], int]:
    groups: List[str] = []
    if args.lower:
        groups.append(string.ascii_lowercase)
    if args.upper:
        groups.append(string.ascii_uppercase)
    if args.digits:
        groups.append(string.digits)
    if args.allow_symbols:
        groups.append(args.symbols)

    if not groups:
        raise ValueError("No character sets selected (lower/upper/digits/symbols).")

    exclusions = set()
    if args.exclude_ambiguous:
        exclusions |= AMBIGUOUS
    if args.exclude_similar_symbols:
        exclusions |= SIMILAR_SYMBOLS
    if args.exclude_chars:
        exclusions |= set(args.exclude_chars)
    if args.website_safe:
        exclusions |= set(' \t\r\n"\'`')

    cleaned_groups: List[str] = []
    for g in groups:
        cg = "".join(ch for ch in g if ch not in exclusions)
        cleaned_groups.append(cg)

    required_groups = cleaned_groups if args.enforce_each else []
    pool = "".join(cleaned_groups)
    pool = "".join(dict.fromkeys(pool))

    if len(pool) < 2:
        raise ValueError("Character pool too small after exclusions.")
    return pool, required_groups, len(pool)

def gen_password(args) -> dict:
    pool, required_groups, pool_size = build_pool(args)
    length = args.length

    if args.enforce_each and length < len(required_groups):
        raise ValueError("Length too short to include 1 char from each selected type.")

    chars: List[str] = []
    if args.enforce_each:
        chars.extend(pick_required(required_groups))

    while len(chars) < length:
        chars.append(secrets.choice(pool))

    if args.no_repeats:
        if pool_size < length:
            raise ValueError("No-repeats requires pool_size >= length.")
        sysrand = secrets.SystemRandom()
        chars = list(sysrand.sample(list(pool), length))
        if args.enforce_each:
            for _ in range(50):
                ok = True
                for g in required_groups:
                    if not any(ch in g for ch in chars):
                        ok = False
                        break
                if ok:
                    break
                chars = list(sysrand.sample(list(pool), length))
            else:
                raise ValueError("Could not satisfy enforce-each with no-repeats. Try a longer pool or disable one option.")

    secure_shuffle(chars)
    password = "".join(chars)

    return {
        "mode": "password",
        "value": password,
        "length": length,
        "pool_size": pool_size,
        "entropy_bits": round(entropy_bits_char(length, pool_size), 2),
    }

def maybe_capitalize(word: str) -> str:
    return word[0].upper() + word[1:] if word else word

def gen_passphrase(args) -> dict:
    words = load_wordlist(args.wordlist)
    n = args.words
    if n <= 0:
        raise ValueError("Words count must be > 0.")

    chosen = [secrets.choice(words) for _ in range(n)]
    if args.capitalize:
        chosen = [maybe_capitalize(w) if secrets.randbelow(2) else w for w in chosen]

    phrase = args.separator.join(chosen)

    extras = ""
    if args.append_digits > 0:
        extras += "".join(secrets.choice(string.digits) for _ in range(args.append_digits))

    if args.append_symbol and args.symbols:
        sym_pool = args.symbols
        if args.exclude_ambiguous:
            sym_pool = "".join(ch for ch in sym_pool if ch not in AMBIGUOUS)
        if args.exclude_similar_symbols:
            sym_pool = "".join(ch for ch in sym_pool if ch not in SIMILAR_SYMBOLS)
        if args.website_safe:
            sym_pool = "".join(ch for ch in sym_pool if ch not in set(' \t\r\n"\'`'))
        sym_pool = "".join(dict.fromkeys(sym_pool))
        if len(sym_pool) < 1:
            raise ValueError("Symbol pool is empty for append-symbol after exclusions.")
        extras += secrets.choice(sym_pool)

    if extras:
        phrase = phrase + (args.separator if args.separator else "") + extras

    bits = entropy_bits_words(n, len(words))
    if args.append_digits > 0:
        bits += args.append_digits * math.log2(10)
    if args.append_symbol and args.symbols:
        bits += math.log2(max(2, len(set(args.symbols))))

    return {
        "mode": "passphrase",
        "value": phrase,
        "words": n,
        "wordlist_size": len(words),
        "entropy_bits": round(bits, 2),
        "used_wordlist": os.path.basename(args.wordlist) if args.wordlist else "fallback",
    }

def write_output(out: dict, out_file: str, as_json: bool) -> None:
    payload = json.dumps(out, ensure_ascii=False) if as_json else out.get("value", "")
    if out_file:
        with open(out_file, "w", encoding="utf-8", newline="\n") as f:
            f.write(payload)
    else:
        print(payload)

def main() -> None:
    p = argparse.ArgumentParser(description="PasswordEngine - strong passwords & passphrases")

    p.add_argument("--mode", choices=["password", "passphrase"], default="password")
    p.add_argument("--out-file", type=str, default="", help="Write output here (recommended for GUI/portable builds)")
    p.add_argument("--json", action="store_true", help="Output JSON")

    # Password options
    p.add_argument("--length", type=int, default=24)
    p.add_argument("--lower", action="store_true")
    p.add_argument("--upper", action="store_true")
    p.add_argument("--digits", action="store_true")
    p.add_argument("--allow-symbols", action="store_true")
    p.add_argument("--symbols", type=str, default=r"\\/!@#$%^&*()-_=+[]{};:,.?~")
    p.add_argument("--exclude-ambiguous", action="store_true")
    p.add_argument("--exclude-similar-symbols", action="store_true")
    p.add_argument("--exclude-chars", type=str, default="")
    p.add_argument("--enforce-each", action="store_true")
    p.add_argument("--no-repeats", action="store_true")
    p.add_argument("--website-safe", action="store_true")

    # Passphrase options
    p.add_argument("--words", type=int, default=5)
    p.add_argument("--separator", type=str, default="-")
    p.add_argument("--wordlist", type=str, default="")
    p.add_argument("--capitalize", action="store_true")
    p.add_argument("--append-digits", type=int, default=0)
    p.add_argument("--append-symbol", action="store_true")

    args = p.parse_args()

    # Defaults + guardrails
    if args.mode == "password":
        if not (args.lower or args.upper or args.digits or args.allow_symbols):
            args.lower = args.upper = args.digits = True
        args.length = max(4, min(256, args.length))
    else:
        args.words = max(2, min(20, args.words))
        args.append_digits = max(0, min(10, args.append_digits))

    try:
        out = gen_password(args) if args.mode == "password" else gen_passphrase(args)
        write_output(out, args.out_file, args.json)
    except Exception as e:
        write_output({"error": str(e)}, args.out_file, True)
        raise

if __name__ == "__main__":
    main()
