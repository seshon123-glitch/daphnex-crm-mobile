# Daphnex CRM Mobile

An Android-first Flutter client for the Daphnex CRM WordPress plugin. Phase 2C
uses the live HTTPS Daphnex CRM REST API by default while retaining mock
fixtures only as a clearly labelled dashboard fallback.

## Live features

- WordPress administrator login through `POST /login`
- Encrypted Android Keystore storage for the 12-hour Bearer token
- Live dashboard metrics, clients, profiles, activity, and reminders
- Local client search and filtering
- Reminder creation and completion with success/error feedback
- Loading, empty, retry, and unreachable-API states
- Session restoration and secure local logout

## Requirements

- Flutter stable 3.35.1 or later
- Dart 3.9 or later
- Android SDK and build-tools
- Android 6.0/API 23 or later
- Daphnex CRM WordPress plugin 0.9.0 or later

## API configuration

The central configuration is in `lib/core/config/api_config.dart`. Its live
HTTPS default is:

```text
https://daphnex.co.uk/wp-json/daphnex-crm/v1/
```

Override it without editing source code:

```powershell
flutter run --dart-define=DAPHNEX_CRM_API_URL=https://example.com/wp-json/daphnex-crm/v1/
```

For a LocalWP development API:

```powershell
flutter run --dart-define=DAPHNEX_CRM_API_URL=http://192.168.1.20/wp-json/daphnex-crm/v1/
```

Android cleartext traffic is not enabled in the release manifest. Use HTTPS for
production and only pass an HTTP LocalWP URL during controlled development.

## LocalWP access from Android

`daphnex-crm.local` resolves on the Windows host but normally not inside Android.
Choose one of these development setups:

1. Android emulator: map `daphnex-crm.local` to emulator host gateway
   `10.0.2.2` in the emulator's DNS/hosts configuration.
2. Physical device: map `daphnex-crm.local` to the Windows computer's LAN IP,
   keep both devices on the same network, and allow LocalWP through the firewall.
3. Configure LocalWP/reverse proxy to answer on a reachable LAN IP, then pass
   that full API URL using `--dart-define=DAPHNEX_CRM_API_URL=...`.

The hostname must still route to the correct LocalWP virtual host. A simple IP
replacement may require configuring the proxy's host name as well. Confirm from
the Android browser that `/wp-json/daphnex-crm/v1/dashboard` returns JSON `401`
before launching the app; that response proves routing works.

## Setup and verification

```powershell
flutter pub get
flutter analyze
flutter test
flutter run
```

Build APKs:

```powershell
flutter build apk --debug
flutter build apk --release
```

Outputs are written to `build/app/outputs/flutter-apk/`.

If OneDrive locks generated Gradle intermediates, build outside the synced
folder without moving the project:

```powershell
$env:DAPHNEX_BUILD_DIR = "$env:LOCALAPPDATA\Temp\daphnex-crm-mobile-build"
flutter build apk --release
```

The Android build script uses the normal `build/` directory when that variable
is absent.

## Architecture

```text
lib/
├── core/
│   ├── config/          # Environment-switchable API URL
│   ├── errors/          # Stable API exception type
│   ├── storage/         # Android encrypted token storage
│   ├── theme/           # Daphnex Material theme
│   └── widgets/         # Reusable loading/error/empty states
├── features/
│   ├── auth/
│   ├── clients/
│   ├── dashboard/
│   ├── navigation/
│   ├── reminders/
│   └── settings/
├── models/              # Typed API response/request models
├── repositories/        # Live data access and dashboard fallback policy
├── services/            # HTTP/Bearer API client and mock fixtures
├── app.dart
└── main.dart
```

UI widgets depend on the `CrmApi` abstraction rather than making HTTP calls.
This keeps authentication, JSON parsing, secure storage, fallback rules, and
future production changes outside the presentation layer.

## Security notes

- Tokens use `flutter_secure_storage` and Android Keystore-backed AES-GCM/RSA
  protection; they are never written to plain preferences.
- HTTP request bodies and tokens are not logged.
- HTTP `401` clears the locally stored token.
- Dashboard fallback use is explicitly logged with `debugPrint` and shown in UI.
- Production uses HTTPS and Android cleartext traffic is disabled by default.
