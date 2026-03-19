# FEMA

Flutter client for FEMA learning flows, including authentication, onboarding, library access, notifications, and teacher tooling.

## Structure

- `lib/core`: shared theme, constants, widgets, and backend services
- `lib/features`: feature-oriented UI and state
- `lib/routes`: app routing and access control

## Backend Notes

The app currently uses Firebase Authentication and Cloud Firestore.

Required platform setup:

- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`

Without valid Firebase platform configuration, the app can still render, but authentication and Firestore-backed flows will not work correctly.

## Current Routing Rules

- Unauthenticated users are redirected to `'/welcome'` for protected routes
- Authenticated users without a saved Firestore profile are redirected into onboarding
- Authenticated users with a completed profile are redirected to `'/home'`

## Development

Useful commands:

```bash
flutter pub get
flutter analyze
flutter test
```

## Security

Child usernames may be stored in Firestore as profile metadata. Child passwords are not persisted in Firestore or exposed in the parent security UI.
