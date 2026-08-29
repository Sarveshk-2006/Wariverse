# WariVerse AI — Flutter Mobile Client

The production mobile application for **WariVerse AI**, translating the web ecosystem into a mobile-native, touch-optimized, role-aware experience for Varkari pilgrims, volunteers, police/security, medical staff, NGO coordinators, and command center admins.

---

## 🚀 Quick Start

### 1. Prerequisites
- Flutter SDK (v3.22.0 or higher)
- Dart SDK (v3.4.0 or higher)
- Android Studio / Xcode for emulators or physical device deployment

### 2. Running Locally

#### Android Emulator (Default)
Connecting to local FastAPI server on host machine via `http://10.0.2.2:8000`:
```bash
cd apps/mobile
flutter run
```

#### iOS Simulator
Connecting to local FastAPI server via `http://127.0.0.1:8000`:
```bash
flutter run --dart-define=PLATFORM=ios
```

#### Physical Device over Local Network (LAN)
Replace `192.168.1.X` with your machine's LAN IP:
```bash
flutter run --dart-define=API_URL=http://192.168.1.100:8000
```

#### Production Backend Mode
```bash
flutter run --dart-define=API_URL=https://api.wariverse.app
```

---

## 🏛 Architecture & Key Features

- **Sacred Saffron Design System** (`lib/core/theme/`): Custom color palette, Plus Jakarta Sans typography, elevated cards, and status chips matching the web design 1:1.
- **Hybrid Network Layer** (`lib/services/api_service.dart`): Automatic REST & WebSocket connectivity to FastAPI backend with zero-downtime offline mock fallback.
- **Role-Aware Operational Dashboards** (`lib/features/roles/`): Seamless switching between 6 roles (Varkari Pilgrim, Volunteer, Police, Medical, NGO, Command Admin) with centralized permission enforcement.
- **Interactive Live Map** (`lib/features/map/`): OpenStreetMap tiles, crowd heat zones, Wari route polylines, service marker filters, and bottom sheet details.
- **One-Tap Emergency SOS System** (`lib/features/sos/`): Dual-mode (REST + WebSocket) safety workflow with responder tracking and offline relay support.
- **Services & Pilgrim Utilities** (`lib/features/services/`): Search, filter, and detail cards for Annadan Food, Water, Sanitation, Medical Camps, Shelters, and Footcare Wellness.
- **Lost & Found Recovery** (`lib/features/lost_found/`): Missing person registry, identification cards, and report modal.
- **Pilgrim Community Feed** (`lib/features/community/`): Verified updates, route/safety warnings, and upvotes.

---

## 🧪 Testing & Verification

### Static Analysis
```bash
flutter analyze
```

### Full Test Suite Execution
```bash
flutter test
```

### Release Build Generation
```bash
# Android APK
flutter build apk --release

# Android App Bundle (Play Store)
flutter build appbundle --release
```

---

## 🔐 Environment & Security

- **API Base URL Configuration**: Managed dynamically via `EnvConfig`.
- **Offline Fallback**: Enabled by default if FastAPI backend is unreachable or during network drops on the pilgrimage route.
- **Role Capabilities**: Centralized role checks ensure pilgrims cannot trigger administrative or security controls.
