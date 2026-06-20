# Daphnex CRM Mobile

An Android-first Flutter CRM learning application. Phase 1 is a polished,
offline MVP powered entirely by mock data; it does not connect to the Daphnex
CRM WordPress plugin or any production service.

## Features

- Mock email/password login
- Dashboard with business summary metrics
- Searchable client list and detailed client activity profiles
- Reminders that can be added and marked complete
- Profile, theme placeholder, version, and logout settings
- Material 3 interface with Daphnex blue-and-white branding

## Requirements

- Flutter stable 3.35.1 or later
- Dart 3.9 or later
- Android Studio with Android SDK, platform-tools, and build-tools
- Android emulator or a physical device with USB debugging enabled

Check the environment:

```powershell
flutter doctor -v
flutter devices
```

## Setup and run

```powershell
flutter pub get
flutter analyze
flutter test
flutter run
```

The demo login is pre-filled. Any non-empty password and syntactically valid
email address are accepted.

## Android builds

```powershell
flutter build apk --debug
flutter build apk --release
```

Build outputs are written to `build/app/outputs/flutter-apk/`. The current
release configuration uses the debug signing key for local learning builds;
configure a private upload keystore before publishing to Google Play.

## Project structure

```text
lib/
├── core/theme/          # Shared colours and Material theme
├── features/
│   ├── auth/            # Mock login
│   ├── clients/         # Client list, search, and profile
│   ├── dashboard/       # CRM summary
│   ├── navigation/      # Bottom navigation shell
│   ├── reminders/       # Mutable local reminder list
│   └── settings/        # Profile, preferences, and logout
├── models/              # Client, activity, and reminder models
├── services/            # Mock authentication and CRM data sources
├── app.dart             # Application state and root routing
└── main.dart            # Flutter entry point
```

## Future integration

The service layer is the intended boundary for future CRM REST authentication
and data calls. Mock fixtures can be replaced with repositories backed by an
HTTP client without coupling screens to the backend. Future phases can add:

- Secure token storage and authenticated REST API calls
- Push notification registration and reminder delivery
- Camera permissions and QR code scanning
- Loyalty accounts, rewards, balances, and redemption flows
- Persistent local caching and offline synchronisation

Comments in the mock services identify the first API replacement points.
