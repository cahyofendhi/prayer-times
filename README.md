# Prayer Times

PWA web app for Islamic prayer times in Indonesia. Built with Flutter and uses the Indonesian Ministry of Religion calculation method to provide accurate local prayer schedules.

## Features

- **Prayer times** – Imsak, Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha
- **Location** – Current location (GPS) or select by country and city
- **Indonesia** – Province and city picker with search
- **Date** – Pick date with date picker
- **Search** – Search in dialogs for country, province, or city
- **PWA** – Installable on device
- **Riverpod** – State management

## Run locally

```bash
flutter pub get
flutter run -d chrome
```

## Build for web

```bash
flutter build web
```

Output in `build/web`. Deploy to any static hosting (Vercel, Netlify, GitHub Pages, etc.).

## 🚀 Getting Started (Run locally)

### Clone or fork the repository

```bash
git clone https://github.com/cahyofendhi/prayer-times
cd REPO-NAME
```

---

## Deploy so everyone can access it (GitHub Pages)

### 1. Push project to GitHub

If you don’t have a repo yet:

```bash
git init
git add .
git commit -m "Initial commit - Prayer Times"
git branch -M main
git remote add origin https://github.com/USERNAME/REPO-NAME.git
git push -u origin main
```

Replace `USERNAME` and `REPO-NAME` with your GitHub username and repo name.

### 2. Enable GitHub Pages

1. Open the repo on GitHub → **Settings** → **Pages**
2. Under **Build and deployment**:
   - **Source**: choose **GitHub Actions**

### 3. Automatic deploy

Every push to `main` or `master` will:

- Build the Flutter web app
- Deploy to GitHub Pages

To run manually: **Actions** tab → **Deploy to GitHub Pages** → **Run workflow**.

### 4. App URL

After the workflow finishes (a few minutes), the app will be available at:

**`https://USERNAME.github.io/REPO-NAME/`**

Example: repo `cahyofendhi/prayer-times` → **https://cahyofendhi.github.io/prayer-times/**

Share this link so anyone can open it in a browser (desktop and mobile).

### 5. Install as PWA (optional)

Visitors can install the app from the browser (e.g. Chrome install icon in the address bar or menu) to use it like a native app.

---

## APIs

- **Prayer times**: [Aladhan API](https://aladhan.com/prayer-times-api) (method 20 for Indonesia, method 2 for others)
- **Indonesia provinces & cities**: [API Data Location](https://api.datawilayah.com/)

## Project structure

```
lib/
├── main.dart
├── models/
│   ├── prayer_time.dart
│   └── location.dart
├── providers/
│   └── schedule_provider.dart
├── screens/
│   └── home_screen.dart
└── services/
    ├── prayer_api_service.dart
    └── location_api_service.dart
```

## Requirements

- Flutter SDK 3.5+
- Dart 3.5+
