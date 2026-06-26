# Daphnex CRM Mobile

Daphnex CRM Mobile is the Android Flutter client for the Daphnex CRM WordPress
plugin. It connects to the live Daphnex CRM REST API, authenticates with secure
Bearer tokens, and provides mobile access to day-to-day CRM workflows.

## Current Production Configuration

- App name: `Daphnex CRM`
- Android package name: `com.daphnex.crm`
- Version name: `1.1.0`
- Version code: `2`
- Minimum Android version: Android 6.0 / API 23
- Target Android version: Android 15 / API 35
- Compile Android SDK: API 36
- Production API default: `https://daphnex.co.uk/wp-json/daphnex-crm/v1/`

Google Play currently requires new apps and app updates to target Android 15
API 35 or higher. The Android Gradle config sets `targetSdk = 35` explicitly.

## Current Features

- Live WordPress administrator login
- Secure Bearer token authentication
- Encrypted Android Keystore-backed token storage
- Dashboard metrics and shortcuts
- Clients list and client profile
- Reminders list, creation, and completion
- Jobs / projects
- Invoices
- Invoice PDF viewing
- Invoice PDF download
- Payment link opening
- Documents
- Notifications
- Revenue screen
- Loading, empty, retry, and unreachable-API states
- Session restoration and secure local logout

## Requirements

- Flutter stable 3.35.1 or later
- Dart 3.9 or later
- Android SDK with API 36 installed for compilation
- Android build-tools
- Daphnex CRM WordPress plugin 0.9.3 or later
- A private Android upload keystore before publishing to Google Play

## Installation

```powershell
flutter pub get
flutter analyze
flutter test
flutter run
```

## API Configuration

The central API configuration is in:

```text
lib/core/config/api_config.dart
```

Override the API URL without editing source code:

```powershell
flutter run --dart-define=DAPHNEX_CRM_API_URL=https://example.com/wp-json/daphnex-crm/v1/
```

For release builds, pass the production API explicitly when needed:

```powershell
flutter build appbundle --release --dart-define=DAPHNEX_CRM_API_URL=https://daphnex.co.uk/wp-json/daphnex-crm/v1/
```

Android cleartext traffic is not enabled in the release manifest. Use HTTPS for
production.

## Android Release Signing

Release signing is configured in `android/app/build.gradle.kts` and reads
private values from:

```text
android/key.properties
```

`android/key.properties`, `*.jks`, and `*.keystore` are ignored by git. Do not
commit signing passwords, keystore files, or Play Console credentials.

### Generate Your Private Upload Keystore

Run this on your own computer and keep the keystore private:

```powershell
keytool -genkey -v -keystore "$env:USERPROFILE\upload-keystore.jks" -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Recommended storage:

```text
C:\Users\<you>\Android\keystores\daphnex-crm-upload-keystore.jks
```

Back this file up securely. If the upload keystore is lost, future app updates
may require Google Play signing key recovery steps.

### Create android/key.properties

Create this file locally only:

```properties
storePassword=your-private-store-password
keyPassword=your-private-key-password
keyAlias=upload
storeFile=C:\\Users\\<you>\\Android\\keystores\\daphnex-crm-upload-keystore.jks
```

Use double backslashes in Windows paths. Do not commit this file.

## Release Builds

Unsigned release builds can be used for local production checks when
`android/key.properties` is absent. Signed release builds are produced
automatically after `android/key.properties` and the private keystore exist.

Build the release APK:

```powershell
flutter build apk --release
```

APK output:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Build the release Android App Bundle:

```powershell
flutter build appbundle --release
```

AAB output:

```text
build/app/outputs/bundle/release/app-release.aab
```

If OneDrive locks generated Gradle intermediates, build outside the synced
folder without moving the project:

```powershell
$env:DAPHNEX_BUILD_DIR = "$env:LOCALAPPDATA\Temp\daphnex-crm-mobile-build"
flutter build appbundle --release
```

## Google Play Store Preparation

### Store Listing

- App name: `Daphnex CRM`
- Short description: `Manage Daphnex CRM clients, jobs, invoices, documents, and reminders from Android.`
- Full description:

```text
Daphnex CRM is the mobile companion for the Daphnex CRM WordPress platform.
The app helps authorised Daphnex administrators manage live CRM activity from
Android, including clients, client profiles, reminders, jobs, invoices,
documents, notifications, revenue summaries, invoice PDFs, downloads, and
payment links.

Access is protected by secure Bearer token authentication and encrypted local
token storage. The app is intended for authorised Daphnex CRM users only.
```

### Required Assets

- High-resolution app icon: 512 x 512 PNG
- Feature graphic: 1024 x 500 PNG or JPG
- Phone screenshots: at least 2, recommended 4-8
- Tablet screenshots: provide if tablet layouts are supported and tested
- Privacy policy URL: required because the app handles login credentials and CRM
  client/business data

### Data Safety Guidance

Prepare answers for:

- Account login data: collected for authentication
- Personal info / contact info: displayed from CRM client records
- Financial info: invoice totals, outstanding balances, and payment links
- Files and docs: document metadata and authenticated downloads
- Data encryption in transit: yes, HTTPS production API
- Data deletion: handled through the Daphnex CRM backend/admin process
- Data sharing: do not list third-party sharing unless the production backend or
  analytics stack adds it

### Permissions Used

- `android.permission.INTERNET`: required for live CRM API communication

The app does not request camera, location, contacts, microphone, SMS, or phone
permissions.

### Play Console Release Flow

1. Create the app in Google Play Console.
2. Enable Play App Signing.
3. Upload the signed AAB from `build/app/outputs/bundle/release/app-release.aab`.
4. Complete the store listing and upload required graphics/screenshots.
5. Add the privacy policy URL.
6. Complete App Content, Data Safety, content rating, target audience, and ads
   declarations.
7. Start with Internal Testing.
8. Promote to Closed Testing after internal QA passes.
9. Promote to Production only after login, dashboard, clients, reminders, jobs,
   invoices, documents, notifications, revenue, PDFs, downloads, and payment
   links are verified against the production API.

## Final QA Checklist

- Login succeeds with a production CRM administrator account
- Dashboard loads live metrics
- Clients list and client profile load
- Reminders list/create/complete work
- Jobs / projects load
- Invoices load
- Invoice PDF view opens
- Invoice PDF download saves/opens correctly
- Payment link opens externally
- Documents load and downloads are authenticated
- Notifications load and read state works
- Revenue screen displays live values
- Logout clears the local token
- Fresh app launch restores valid sessions
- Expired sessions return to login

## Architecture

```text
lib/
  core/
    config/          API URL and app/company information
    errors/          Stable API exception type
    storage/         Android encrypted token storage
    theme/           Daphnex Material theme
    widgets/         Reusable loading/error/empty/brand widgets
  features/
    about/
    auth/
    clients/
    dashboard/
    documents/
    invoices/
    jobs/
    more/
    navigation/
    notifications/
    reminders/
    revenue/
    settings/
  models/            Typed API response/request models
  repositories/      Live data access and dashboard fallback policy
  services/          HTTP/Bearer API client and mock fixtures
  app.dart
  main.dart
```

UI widgets depend on the `CrmApi` abstraction rather than making HTTP calls
directly. Authentication, JSON parsing, secure storage, fallback rules, and API
transport stay outside the presentation layer.

## Security Notes

- Tokens use `flutter_secure_storage` and Android Keystore-backed protection.
- HTTP request bodies and tokens are not logged.
- HTTP `401` clears the locally stored token.
- Production uses HTTPS.
- Android release signing credentials are never committed.

## Future Roadmap

- Replace temporary launcher icon artwork with final approved Daphnex brand
  assets.
- Add richer tablet-specific layouts if tablet support becomes a release target.
- Add push notifications when the CRM backend provides a push notification
  service.
- Add deeper offline/error recovery if field use requires it.
