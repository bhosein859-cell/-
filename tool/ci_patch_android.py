#!/usr/bin/env python3
"""اصلاح اسکلت اندرویدِ ساخته‌شده توسط `flutter create` در CI.

برخی افزونه‌ها (مثل flutter_local_notifications) به «core library desugaring»
نیاز دارند؛ این اسکریپت هر دو فرمت Groovy (build.gradle) و Kotlin DSL
(build.gradle.kts) را پشتیبانی می‌کند.
"""
from __future__ import annotations

import pathlib
import sys

DESUGAR_LIB = "com.android.tools:desugar_jdk_libs:2.1.4"
APP_DIR = pathlib.Path("android/app")


def patch_groovy(path: pathlib.Path) -> bool:
    text = path.read_text(encoding="utf-8")
    changed = False

    if "coreLibraryDesugaringEnabled" not in text:
        marker = "compileOptions {"
        if marker not in text:
            print(f"[!] بلوک compileOptions در {path} پیدا نشد", file=sys.stderr)
            return False
        text = text.replace(
            marker,
            marker + "\n        coreLibraryDesugaringEnabled true",
            1,
        )
        changed = True

    if "coreLibraryDesugaring " not in text and f"'{DESUGAR_LIB}'" not in text:
        text += (
            "\n\ndependencies {\n"
            f"    coreLibraryDesugaring '{DESUGAR_LIB}'\n"
            "}\n"
        )
        changed = True

    if changed:
        path.write_text(text, encoding="utf-8")
    return True


def patch_kotlin(path: pathlib.Path) -> bool:
    text = path.read_text(encoding="utf-8")
    changed = False

    if "isCoreLibraryDesugaringEnabled" not in text:
        marker = "compileOptions {"
        if marker not in text:
            print(f"[!] بلوک compileOptions در {path} پیدا نشد", file=sys.stderr)
            return False
        text = text.replace(
            marker,
            marker + "\n        isCoreLibraryDesugaringEnabled = true",
            1,
        )
        changed = True

    if "coreLibraryDesugaring(" not in text and f'"{DESUGAR_LIB}"' not in text:
        text += (
            "\n\ndependencies {\n"
            f'    coreLibraryDesugaring("{DESUGAR_LIB}")\n'
            "}\n"
        )
        changed = True

    if changed:
        path.write_text(text, encoding="utf-8")
    return True


def main() -> int:
    candidates = [
        (APP_DIR / "build.gradle.kts", patch_kotlin),
        (APP_DIR / "build.gradle", patch_groovy),
    ]
    done = False
    for path, patcher in candidates:
        if path.exists():
            print(f"[+] اصلاح {path}")
            if not patcher(path):
                return 1
            print(path.read_text(encoding="utf-8")[-600:])
            done = True
    if not done:
        print("[!] هیچ فایل build.gradle ای پیدا نشد", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
