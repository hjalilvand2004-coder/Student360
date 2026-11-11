# launch_portable.py
# راه‌انداز نسخه پرتیبل — Student360
# این اسکریپت مسیر دیتابیس و فرانت‌اند را نسبت به پوشه بسته تنظیم می‌کند،
# سرور را روی یک پورت آزاد بالا می‌آورد و مرورگر را به‌صورت خودکار باز می‌کند.

import os
import sys
import socket
import threading
import time
import webbrowser

# ───────────────────────────────────────────────
# تعیین ریشه بسته پرتیبل:
# ساختار بسته:
#   Student360-Portable/
#   ├── runtime/   (پایتون داخلی)
#   ├── app/       (کد بک‌اند — این فایل داخل همین پوشه است)
#   ├── web/       (فرانت‌اند ساخته‌شده)
#   ├── data/      (دیتابیس SQLite)
#   └── start_student360.bat
# ───────────────────────────────────────────────
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
APP_DIR = os.path.join(ROOT, "app")
WEB_DIR = os.path.join(ROOT, "web")
DATA_DIR = os.path.join(ROOT, "data")


def preflight():
    """بررسی‌های پیش‌از-اجرا با پیام‌های واضح فارسی؛ در صورت مشکل با کد 1 خارج می‌شود."""
    problems = []

    if not os.path.isfile(os.path.join(APP_DIR, "app", "main.py")):
        problems.append(f"پوشه بک‌اند پیدا نشد: {APP_DIR}")
    if not os.path.isfile(os.path.join(WEB_DIR, "index.html")):
        problems.append(f"فایل‌های فرانت‌اند پیدا نشدند: {WEB_DIR}")
    if not os.path.isfile(os.path.join(APP_DIR, "requirements.txt")):
        problems.append(f"فایل requirements.txt پیدا نشد: {APP_DIR}")

    temp_marker = os.environ.get("TEMP", "").lower()
    root_lower = ROOT.lower()
    if temp_marker and root_lower.startswith(temp_marker):
        problems.append(
            "به نظر می‌رسد این فایل از داخل خود ZIP اجرا شده است.\n"
            "   ابتدا کل فایل ZIP را Extract کنید (راست‌کلیک ← Extract All)،\n"
            "   سپس داخل پوشه‌ی استخراج‌شده فایل start_student360.bat را اجرا کنید."
        )

    if problems:
        print("\n" + "=" * 62)
        print("  ❌ بسته پرتیبل کامل نیست و نمی‌تواند اجرا شود:")
        print("=" * 62)
        for index, problem in enumerate(problems, 1):
            print(f"  {index}. {problem}")
        print("-" * 62)
        print("  راهنمای صحیح اجرا:")
        print("   1) از صفحه Releases گیت‌هاب، فایل Student360-Portable-Windows.zip")
        print("      (حدود 280 مگابایت) را دانلود کنید — نه فایل Source code (zip).")
        print("   2) کل ZIP را Extract کنید و وارد پوشه‌ی Student360-Portable شوید.")
        print("   3) روی start_student360.bat دوبار کلیک کنید.")
        print("   4) پوشه را در مسیر قابل‌نوشتار قرار دهید (مثلاً دسکتاپ یا D:\\)،")
        print("      نه داخل C:\\Program Files و نه یکپارچه با OneDrive.")
        print("=" * 62)
        try:
            input("\nبرای بستن، Enter بزنید...")
        except EOFError:
            pass
        sys.exit(1)


preflight()

try:
    os.makedirs(DATA_DIR, exist_ok=True)
    # تست قابل‌نوشتار بودن مسیر برای دیتابیس و فایل‌های آپلودی
    probe = os.path.join(DATA_DIR, ".write_test")
    with open(probe, "w") as probe_file:
        probe_file.write("ok")
    os.remove(probe)
except (PermissionError, OSError) as exc:
    print("\n" + "=" * 62)
    print(f"  ❌ پوشه بسته قابل‌نوشتن نیست ({ROOT}): {exc}")
    print("  لطفاً بسته را در یک مسیر معمولی مثل دسکتاپ یا D:\\ Extract کنید،")
    print("  نه داخل Program Files یا پوشه‌های سیستمی.")
    print("=" * 62)
    try:
        input("\nبرای بستن، Enter بزنید...")
    except EOFError:
        pass
    sys.exit(1)

os.chdir(ROOT)  # تا مسیرهای نسبی (مثل فایل‌های آپلودی) داخل بسته بمانند

DB_PATH = os.path.join(DATA_DIR, "university_scheduler.db")
os.environ["DATABASE_URL"] = "sqlite:///" + DB_PATH.replace("\\", "/")
os.environ["FRONTEND_DIST"] = WEB_DIR
os.environ["PYTHONIOENCODING"] = "utf-8"

# اضافه کردن پوشه app به مسیر پایتون برای import ماژول app
sys.path.insert(0, APP_DIR)


def find_free_port(start: int = 8000, end: int = 8020) -> int:
    """اولین پورت آزاد در بازه مشخص را پیدا می‌کند."""
    for port in range(start, end):
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
            try:
                sock.bind(("127.0.0.1", port))
                return port
            except OSError:
                continue
    raise RuntimeError("پورت آزادی در بازه 8000 تا 8020 پیدا نشد. لطفاً برنامه‌های دیگر را ببندید.")


PORT = find_free_port()
URL = f"http://127.0.0.1:{PORT}"


def open_browser_when_ready(server_ref):
    """صبر می‌کند تا سرور بالا بیاید، سپس مرورگر را باز می‌کند."""
    deadline = time.time() + 60
    while time.time() < deadline:
        if getattr(server_ref, "started", False):
            time.sleep(0.6)
            try:
                webbrowser.open(URL)
                print(f"\n✅ مرورگر باز شد: {URL}")
            except Exception as exc:  # noqa: BLE001
                print(f"\n⚠️ باز شدن خودکار مرورگر ناموفق بود ({exc}). لطفاً دستی باز کنید: {URL}")
            return
        time.sleep(0.25)
    print(f"\n⚠️ مرورگر خودکار باز نشد. لطفاً دستی باز کنید: {URL}")


def main():
    print("=" * 62)
    print("  سامانه هوشمند برنامه‌ریزی درسی — Student360 (نسخه پرتیبل)")
    print("=" * 62)
    print(f"  آدرس برنامه : {URL}")
    print(f"  دیتابیس     : {DB_PATH}")
    print(f"  فرانت‌اند    : {WEB_DIR}")
    print("  برای خروج، این پنجره را ببندید یا Ctrl+C بزنید.")
    print("=" * 62)

    try:
        import uvicorn  # noqa: PLC0415
        from app.main import app  # noqa: PLC0415
    except Exception as exc:  # noqa: BLE001
        print(f"\n❌ خطا در بارگذاری برنامه: {exc}")
        import traceback
        traceback.print_exc()
        input("\nبرای بستن، Enter بزنید...")
        sys.exit(1)

    config = uvicorn.Config(
        app,
        host="127.0.0.1",
        port=PORT,
        log_level="warning",
        access_log=False,
    )
    server = uvicorn.Server(config)

    threading.Thread(target=open_browser_when_ready, args=(server,), daemon=True).start()

    try:
        server.run()
    except KeyboardInterrupt:
        print("\n🛑 سرور توسط کاربر متوقف شد.")
    finally:
        print("🛑 سرور خاموش شد. می‌توانید این پنجره را ببندید.")


if __name__ == "__main__":
    main()
