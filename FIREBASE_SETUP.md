# Firebase Setup Guide for Panci

This guide will help you complete the Firebase setup for Phase 3 (Firebase Setup & Persistence).

## Prerequisites

- Flutter SDK installed
- Firebase account created at https://console.firebase.google.com
- FlutterFire CLI installed: `dart pub global activate flutterfire_cli`

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click "Add project" or select an existing project
3. Follow the setup wizard:
   - Enter project name (e.g., "Panci Canvas")
   - Enable/disable Google Analytics (optional)
   - Click "Create project"

## Step 2: Enable Firebase Services

### Enable Cloud Firestore

1. In Firebase Console, go to **Build > Firestore Database**
2. Click "Create database"
3. Choose a location (select one close to your users)
4. Start in **production mode** (we'll deploy custom rules later)
5. Click "Enable"

### Enable Firebase Authentication

1. In Firebase Console, go to **Build > Authentication**
2. Click "Get started"
3. Go to "Sign-in method" tab
4. Enable "Anonymous" authentication:
   - Click on "Anonymous"
   - Toggle "Enable"
   - Click "Save"

### Enable Firebase Storage (Optional for Phase 3, Required for Phase 6)

1. In Firebase Console, go to **Build > Storage**
2. Click "Get started"
3. Accept the default security rules
4. Choose a storage location (same as Firestore)
5. Click "Done"

## Step 3: Generate Firebase Configuration

Run the FlutterFire configuration command:

```bash
cd /Users/nandha/Documents/flutter_code/panci
flutterfire configure
```

This will:
- Link your Flutter app to your Firebase project
- Generate `lib/firebase_options.dart` file
- Configure iOS, Android, and Web platforms

**Important:** Select the Firebase project you created in Step 1.

## Step 4: Deploy Firestore Security Rules

The security rules file has already been created at `firestore.rules`.

### Option A: Using Firebase Console (Recommended for first-time)

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Navigate to **Firestore Database > Rules**
4. Copy the contents of `firestore.rules`
5. Paste into the rules editor
6. Click "Publish"

### Option B: Using Firebase CLI

1. Install Firebase CLI if not already installed:
   ```bash
   npm install -g firebase-tools
   ```

2. Login to Firebase:
   ```bash
   firebase login
   ```

3. Initialize Firebase in the project (if not already done):
   ```bash
   cd /Users/nandha/Documents/flutter_code/panci
   firebase init firestore
   ```
   - Select your Firebase project
   - Accept default file names (firestore.rules and firestore.indexes.json)

4. Deploy the rules:
   ```bash
   firebase deploy --only firestore:rules
   ```

## Step 5: Verify Installation

1. Check that `lib/firebase_options.dart` exists:
   ```bash
   ls -la /Users/nandha/Documents/flutter_code/panci/lib/firebase_options.dart
   ```

2. Run the app to verify Firebase initialization:
   ```bash
   cd /Users/nandha/Documents/flutter_code/panci
   flutter run
   ```

3. Check the console logs for:
   - "Firebase initialized successfully"
   - "Signed in anonymously with user ID: ..."

## Step 6: Test Drawing Persistence

1. Create a new canvas or join an existing one
2. Draw some strokes on the canvas
3. Check Firebase Console > Firestore Database
4. You should see:
   - Collection: `canvases`
   - Document: `{canvasId}`
   - Fields: `canvasId`, `strokes`, `lastUpdated`, `version`

5. Close the app and reopen it
6. Join the same canvas ID
7. Your strokes should be restored from Firebase

## Step 7: Test Real-Time Synchronization

1. Open the app on two devices (or two browser tabs if running on web)
2. Join the same canvas ID on both devices
3. Draw on one device
4. The strokes should appear in real-time on the other device

## Troubleshooting

### Error: "Firebase not initialized"

- Ensure `flutterfire configure` was run successfully
- Check that `lib/firebase_options.dart` exists
- Verify the import in `lib/main.dart`

### Error: "Permission denied" when writing to Firestore

- Verify Anonymous Authentication is enabled
- Check that security rules are deployed correctly
- Ensure the app signed in anonymously (check console logs)

### Error: "No Firebase App '[DEFAULT]' has been created"

- Ensure `Firebase.initializeApp()` is called in `main()` before `runApp()`
- Check that `WidgetsFlutterBinding.ensureInitialized()` is called first

### Strokes not persisting

- Open Firebase Console > Firestore Database
- Check if documents are being created
- Review console logs for error messages
- Verify network connectivity

### Real-time updates not working

- Check that `subscribeToCanvas()` is being called
- Verify Firestore rules allow read access
- Check console logs for stream errors

## Architecture Overview

The Firebase integration follows clean architecture principles:

```
lib/
├── domain/
│   └── repositories/
│       └── drawing_repository.dart          # Repository interface
│
├── data/
│   ├── models/
│   │   ├── drawing_data_model.dart          # JSON serialization
│   │   └── drawing_stroke_model.dart        # JSON serialization
│   └── repositories/
│       ├── firebase_drawing_repository.dart # Firestore implementation
│       └── repository_provider.dart         # Riverpod provider
│
└── presentation/
    └── providers/
        └── drawing_provider.dart            # State management + Firebase integration
```

## Key Implementation Details

### Optimistic Updates

The app uses optimistic updates for a responsive UI:
1. Local state is updated immediately when user draws
2. Firebase save happens asynchronously in the background
3. If save fails, error is logged (TODO: implement retry/rollback)

### Real-Time Synchronization

- Uses Firestore `snapshots()` stream for real-time updates
- Updates are ignored when user is actively drawing to avoid interruptions
- Prevents infinite loops with `_isUpdatingFromRemote` flag

### Offline Support

- Firestore SDK provides built-in offline persistence
- Offline writes are queued and synced when connection is restored
- Connection status indicator shows online/offline state (basic implementation)

## Next Steps

After completing Phase 3, you can proceed to:

- **Phase 4:** Canvas Management (creation, joining, listing)
- **Phase 5:** QR Code Integration (camera scanning, QR generation)
- **Phase 6:** Image Export (export canvas as PNG/JPG)
- **Phase 7:** Multiplayer Features (active users, cursors, presence)

## Additional Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev)
- [Cloud Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [Firebase Anonymous Authentication](https://firebase.google.com/docs/auth/web/anonymous-auth)
