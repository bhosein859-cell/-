#!/usr/bin/env python3
"""اصلاح اسکلت اندرویدِ ساخته‌شده توسط `flutter create` در CI.

۱. نام فارسی اپ روی لانچر و مجوز میکروفون در AndroidManifest.xml
۲. فعال‌سازی «core library desugaring» (نیاز برخی افزونه‌ها) در هر دو فرمت
   Groovy (build.gradle) و Kotlin DSL (build.gradle.kts)
"""
from __future__ import annotations

import pathlib
import re
import sys

DESUGAR_LIB = "com.android.tools:desugar_jdk_libs:2.1.4"
APP_DIR = pathlib.Path("android/app")
MANIFEST = APP_DIR / "src/main/AndroidManifest.xml"
APP_LABEL = "گره‌گشا"
RECORD_AUDIO = '<uses-permission android:name="android.permission.RECORD_AUDIO"/>'
SPEECH_QUERY = (
    "        <intent>\n"
    '            <action android:name="android.speech.RecognitionService"/>\n'
    "        </intent>"
)


def patch_manifest() -> bool:
    if not MANIFEST.exists():
        print(f"[!] {MANIFEST} پیدا نشد", file=sys.stderr)
        return False
    text = MANIFEST.read_text(encoding="utf-8")

    # نام نمایشی اپ
    text = re.sub(r'android:label="[^"]*"', f'android:label="{APP_LABEL}"', text, count=1)

    # مجوز میکروفون برای «تایپ صوتی»
    # (متن‌های زائدِ «\n» که از sed قدیمی باقی می‌ماند را هم پاک می‌کنیم)
    text = re.sub(r"\\n\s*(?=<application)", "\n    ", text)
    if "RECORD_AUDIO" not in text:
        text = re.sub(r"(<application)", "    " + RECORD_AUDIO + r"\n    \1", text, count=1)

    # شناسایی گفتار: اندروید ۱۱+ به اعلانِ RecognitionService نیاز دارد
    if "android.speech.RecognitionService" not in text:
        if "</queries>" in text:
            text = text.replace("</queries>", SPEECH_QUERY + "\n    </queries>", 1)
        else:
            text = text.replace("</manifest>", f"    <queries>\n{SPEECH_QUERY}\n    </queries>\n</manifest>", 1)

    MANIFEST.write_text(text, encoding="utf-8")
    print(text)
    return True


def patch_groovy(path: pathlib.Path) -> bool:
    text = path.read_text(encoding="utf-8")

    if "coreLibraryDesugaringEnabled" not in text:
        marker = "compileOptions {"
        if marker not in text:
            print(f"[!] بلوک compileOptions در {path} پیدا نشد", file=sys.stderr)
            return False
        text = text.replace(marker, marker + "\n        coreLibraryDesugaringEnabled true", 1)

    if "coreLibraryDesugaring " not in text:
        text += f"\n\ndependencies {{\n    coreLibraryDesugaring '{DESUGAR_LIB}'\n}}\n"

    path.write_text(text, encoding="utf-8")
    print(text[-500:])
    return True


def patch_kotlin(path: pathlib.Path) -> bool:
    text = path.read_text(encoding="utf-8")

    if "isCoreLibraryDesugaringEnabled" not in text:
        marker = "compileOptions {"
        if marker not in text:
            print(f"[!] بلوک compileOptions در {path} پیدا نشد", file=sys.stderr)
            return False
        text = text.replace(marker, marker + "\n        isCoreLibraryDesugaringEnabled = true", 1)

    if "coreLibraryDesugaring(" not in text:
        text += f'\n\ndependencies {{\n    coreLibraryDesugaring("{DESUGAR_LIB}")\n}}\n'

    path.write_text(text, encoding="utf-8")
    print(text[-500:])
    return True


def drop_template_test() -> None:
    """تست قالبیِ `flutter create` (که به کلاس MyApp اشاره می‌کند) را حذف می‌کند."""
    tmpl = pathlib.Path("test/widget_test.dart")
    if tmpl.exists() and "MyApp" in tmpl.read_text(encoding="utf-8"):
        tmpl.unlink()
        print("[+] test/widget_test.dart قالبی حذف شد")


def main() -> int:
    if not patch_manifest():
        return 1

    drop_template_test()

    done = False
    for path, patcher in ((APP_DIR / "build.gradle.kts", patch_kotlin), (APP_DIR / "build.gradle", patch_groovy)):
        if path.exists():
            print(f"[+] اصلاح {path}")
            if not patcher(path):
                return 1
            done = True
    if not done:
        print("[!] هیچ فایل build.gradle ای پیدا نشد", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
