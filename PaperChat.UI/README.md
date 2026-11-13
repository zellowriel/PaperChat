# PaperChat Flutter UI

Flutter client for PaperChat. The screens are Views, `AppViewModel` owns
application state and use cases, repositories isolate Firebase Auth and the
PaperChat REST API, and `PaperChatApi` handles HTTP details.

## Firebase setup

Create a Firebase project, enable **Authentication > Email/Password**, and
register the Web app `PaperChat Web` and Android app with package ID
`com.paperchat_mobile`. The Web client config is in
`lib/core/firebase_config.dart`, so Chrome does not need additional Firebase
defines. For native builds, supply the platform's Firebase config at run time:

```powershell
flutter run `
  --dart-define=FIREBASE_API_KEY=<api-key> `
  --dart-define=FIREBASE_APP_ID=<app-id-for-this-platform> `
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=<sender-id> `
  --dart-define=FIREBASE_PROJECT_ID=<project-id> `
  --dart-define=FIREBASE_AUTH_DOMAIN=<project-id>.firebaseapp.com
```

The app ID can differ between Android, iOS, and Web. Firebase API keys and app
IDs are client configuration, not service-account credentials. Never include a
service-account private key in the Flutter app.

Firebase Analytics is initialized with the same Firebase project. It records
`question_asked` when a question is submitted and `pdf_uploaded` after a PDF
upload succeeds. These events contain no question text, PDF title, or author
information.

New accounts receive an email verification link before signing in. The backend
uses the verified Firebase ID token to connect an existing PaperChat account
with the same email, preserving its document library.

## Backend

The backend remains the source of truth for user profiles, PDFs, reading
progress, and chat data. Firebase ID tokens are sent as bearer tokens for
protected API calls. Configure the backend with `Firebase:ProjectId` (for
example, the environment variable `Firebase__ProjectId`) and apply
`PaperChat.Backend/database/03_add_firebase_uid.sql` before deploying the new
backend.

Set the API endpoint with `API_URL` (the legacy `API_BASE_URL` is also
supported). Docker Compose publishes the API on
port `8080`; Android Studio emulators reach the host through `10.0.2.2`:

```powershell
flutter run --dart-define=API_URL=http://10.0.2.2:8080
```

For direct `dotnet run`, use the configured local API port (for example
`http://10.0.2.2:5016`). Debug Android builds allow HTTP for local testing;
release builds should use HTTPS.

For a physical phone or another emulator such as LDPlayer, either use the
computer's LAN IP when both devices share a trusted network, or start a
temporary tunnel with `ngrok http 8080` and set `API_URL` to its HTTPS URL.
The client sends ngrok's browser-warning bypass header for ngrok URLs so Web
requests reach the API instead of the interstitial page.
`API_URL` is compiled into the app, so rebuild the app after changing it.
Ngrok is not required for an Android Studio emulator. For a UI-only portrait
demo, set the emulator to portrait and install the APK; no tunnel or backend
connection is needed.
