# Student360 — سامانه هوشمند برنامه‌ریزی درسی دانشگاهی

سامانه کامل زمان‌بندی و برنامه‌ریزی درسی دانشگاه با **بک‌اند FastAPI** و **فرانت‌اند React 18 (Vite)**، فارسی و راست‌به‌چپ.

## امکانات اصلی

- مدیریت موجودی دروس، اساتید، کلاس‌ها و سالن‌ها
- سبد انتخاب واحد (Baskets) و گردش‌کار چندمرحله‌ای (Workflow) تولید برنامه
- **مطلوبیت‌های تدریس اساتید** (رتبه‌بندی درس‌های مطلوب هر استاد + آپلود اکسل)
- **مطلوبیت‌های زمانی اساتید** (روزها و بازه‌های ساعتی مطلوب با سطح اولویت)
- موتور بهینه‌سازی مبتنی بر Google OR-Tools (CP-SAT) با گزارش گام‌به‌گام
- تخصیص هوشمند استاد و سالن، تاریخچه نسخه‌های برنامه و بازخورد وزن‌دهی

## اجرای نسخه پرتیبل (بدون نصب پایتون) — پیشنهادی

از صفحه [Releases](https://github.com/hjalilvand2004-coder/Student360/releases) فایل `Student360-Portable-Windows.zip` را دانلود کنید:

1. فایل را Extract کنید.
2. روی `start_student360.bat` دوبار کلیک کنید.
3. مرورگر به‌صورت خودکار روی `http://127.0.0.1:8000` باز می‌شود.

همه‌چیز (پایتون داخلی، کتابخانه‌ها، فرانت‌اند و دیتابیس SQLite) داخل بسته است. برای انتقال به سیستم دیگر، کل پوشه را کپی کنید.

## اجرای توسعه‌دهنده (Dev)

### بک‌اند (Python 3.11+)

```bash
cd backend
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

دیتابیس پیش‌فرض SQLite است (`backend/university_scheduler.db`). برای PostgreSQL مقدار `DATABASE_URL` را تنظیم کنید.

- مستندات API: `http://127.0.0.1:8000/docs`

### فرانت‌اند (Node 18+)

```bash
cd frontend
npm install
npm run dev
```

فرانت‌اند روی `http://localhost:5173` اجرا می‌شود و درخواست‌های `/api` به‌صورت خودکار به پورت 8000 منتقل می‌شوند (پروکسی Vite).

## ساخت نسخه پرتیبل

بیلد به‌صورت خودکار با GitHub Actions انجام می‌شود:

- ورک‌فلو: `.github/workflows/build-portable.yml`
- محرک: پوش تگ `v*` یا اجرای دستی (workflow_dispatch)
- مراحل: بیلد فرانت‌اند ← دانلود پایتون Embeddable 3.11 ← نصب کتابخانه‌ها ← مونتاژ بسته ← تست import ← انتشار ریلیز

برای ساخت محلی روی ویندوز:

```powershell
cd frontend && npm ci && npm run build && cd ..
powershell -File scripts/build_portable.ps1
```

خروجی: `build/Student360-Portable/`

## ساختار پروژه

```
Student360/
├── backend/           # FastAPI + SQLAlchemy + OR-Tools
│   ├── app/api/       # روت‌های REST
│   ├── app/models/    # مدل‌های دیتابیس
│   ├── app/services/  # سرویس‌ها و موتور زمان‌بندی
│   └── launch_portable.py   # راه‌انداز نسخه پرتیبل
├── frontend/          # React 18 + Vite + Recharts
├── portable/          # قالب‌های بسته پرتیبل (bat و راهنما)
├── scripts/           # اسکریپت ساخت بسته پرتیبل
└── .github/workflows/ # CI ساخت و انتشار ریلیز
```
