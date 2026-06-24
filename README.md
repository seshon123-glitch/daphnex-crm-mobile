# Daphnex CRM Mobile

An Android-first Flutter client for the Daphnex CRM WordPress plugin. The app
uses the live HTTPS Daphnex CRM REST API by default while retaining mock
fixtures only as a clearly labelled dashboard fallback.

## Live features

- WordPress administrator login through `POST /login`
- Encrypted Android Keystore storage for the 12-hour Bearer token
- Live dashboard metrics, clients, profiles, activity, and reminders/tasks
- Invoices, jobs/projects, documents and notifications modules
- Dashboard shortcut cards for Clients, Tasks, Reminders, Invoices, Jobs /
  Projects, Documents, Notifications, and Turnover / Revenue
- Local client search and filtering
- Reminder creation and completion with success/error feedback
- Invoice PDF buttons prepared for a future backend PDF endpoint
- Loading, empty, retry, and unreachable-API states
- Session restoration and secure local logout

## Requirements

- Flutter stable 3.35.1 or later
- Dart 3.9 or later
- Android SDK and build-tools
- Android 6.0/API 23 or later
- Daphnex CRM WordPress plugin 0.9.1 or later

## Branding

Phase 4A adds a professional Daphnex blue/white theme, Android launcher icon,
splash background, reusable in-app logo mark and branded login/about/settings
sections. The current logo is a clean temporary Daphnex `D` placeholder. Replace
the generated Android launcher icons and `DaphnexLogoMark` implementation with
the final company logo artwork when approved brand assets are available.

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
│   ├── config/          # API URL and app/company information
│   ├── errors/          # Stable API exception type
│   ├── storage/         # Android encrypted token storage
│   ├── theme/           # Daphnex Material theme
│   └── widgets/         # Reusable loading/error/empty/brand widgets
├── features/
│   ├── about/
│   ├── auth/
│   ├── clients/
│   ├── dashboard/
│   ├── documents/
│   ├── invoices/
│   ├── jobs/
│   ├── more/
│   ├── navigation/
│   ├── notifications/
│   ├── reminders/
│   ├── revenue/
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

## Future API integration notes

- Tasks currently map to the existing Reminders API until a dedicated task API
  is added to the CRM backend.
- Turnover / Revenue currently displays live dashboard invoice values such as
  outstanding invoice amount and unpaid invoice count. Paid/completed turnover
  totals should be connected when a dedicated turnover API becomes available.
- Invoice detail now includes `View PDF Invoice` and `Download PDF Invoice`
  placeholders. The backend still needs a secure invoice PDF endpoint that
  generates PDFs using Daphnex letterhead before the buttons can perform a real
  download.
