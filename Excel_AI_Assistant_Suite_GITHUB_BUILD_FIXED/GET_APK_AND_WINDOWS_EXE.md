# Tayyor .APK va Windows .EXE olish (eng oson yo'l)

**Muhim:** Bu loyiha Android va Windows uchun **source code**. Tayyor `.apk` va `.exe`ni **men sizning nomingizdan** internetga chiqib build qila olmayman (GitHub/Render kabi hisobingizga kira olmayman).  
Lekin men loyihani shunday tayyorlab qo'ydimki, sizga faqat GitHub'ga yuklash va 2 ta tugmani bosish kifoya — qolganini GitHub Actions o'zi qiladi.

## 1) GitHub'ga yuklang
- GitHub'da yangi repo yarating (Public yoki Private).
- Shu papkadagi hamma fayllarni repo'ga push qiling.

## 2) Android APK build
- Repo → **Actions**
- **Build Android APK** workflow → **Run workflow**
- Tugagach → **Artifacts** dan `android-apk` ni yuklab oling.
  - `app-release.apk` (universal) — ko'p telefonlarda ishlaydi
  - `app-arm64-v8a-release.apk` va boshqalar — mos ABI bo'lsa tanlaysiz

## 3) Windows EXE build
- Repo → **Actions**
- **Build Windows App (Electron)** workflow → **Run workflow**
- Tugagach → **Artifacts** dan `windows-build` ni yuklab oling.
  - Ichida `*-Setup-*.exe` (installer) va `*.exe` (portable) bo'ladi.

## 4) Backend masalasi (asosiy nuqta)
Android/Windows ilova ishlashi uchun backend (FastAPI) server kerak.
Siz backend'ni:
- kompyuteringizda ishga tushirishingiz mumkin, yoki
- bulutga deploy qilishingiz mumkin (`render.yaml` bor).

Ilovalarda backend manzilini ko'rsatish:
- Windows Electron: `BACKEND_URL` environment variable
- Android: ilovada "Backend URL" maydoniga server manzilini yozish
