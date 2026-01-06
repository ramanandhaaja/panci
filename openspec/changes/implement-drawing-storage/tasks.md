# Tasks: Implement Drawing Storage

## Phase 1: Core Drawing (Local Only) ✅ COMPLETED

### 1.1 Create Domain Entities
- [x] Create `lib/domain/entities/drawing_stroke.dart`
  - Immutable class with points, color, strokeWidth, timestamp, userId
  - copyWith, equality, hashCode, toString methods
- [x] Create `lib/domain/entities/drawing_data.dart`
  - canvasId, strokes list, lastUpdated, version, strokeCount
  - Methods: addStroke, removeStroke, canAddStroke (checks limit)
- [x] Create `lib/domain/entities/active_user.dart`
  - userId, displayName, cursorPosition, lastSeen, cursorColor
- [x] **Validation**: Run `flutter analyze` - no errors ✅

### 1.2 Create Stroke Smoothing Service
- [x] Create `lib/domain/services/stroke_smoother.dart`
  - Implement Catmull-Rom spline interpolation
  - Method: `List<Offset> smoothPoints(List<Offset> rawPoints)`
  - Handle edge cases (< 4 points)
- [x] **Validation**: Write unit test for smoothing algorithm ✅

### 1.3 Create Drawing Provider
- [x] Create `lib/presentation/providers/drawing_provider.dart`
  - Extends ChangeNotifier
  - State: currentDrawing, undoStack, redoStack, currentStroke, isDrawing
  - Methods: startStroke, addPoint, endStroke, undo, redo, clear
  - Enforce 1000 stroke limit
- [x] **Validation**: Unit test for undo/redo logic ✅

### 1.4 Implement Canvas Painter
- [x] Create `lib/presentation/widgets/canvas_painter.dart`
  - CustomPainter that renders all strokes from DrawingData
  - Efficient shouldRepaint logic (compare stroke count)
  - Draw each stroke path with Paint objects
- [x] **Validation**: Visual test - strokes render correctly ✅

### 1.5 Implement Drawing Canvas Widget
- [x] Create `lib/presentation/widgets/drawing_canvas_widget.dart`
  - Wrap CustomPaint in RepaintBoundary (for future export)
  - GestureDetector with onPanStart, onPanUpdate, onPanEnd
  - Use Provider to access DrawingProvider
  - Fixed 2000x2000 canvas in FittedBox
- [x] **Validation**: Can draw strokes, they appear on screen ✅

### 1.6 Update Drawing Screen
- [x] Modify `lib/presentation/screens/drawing_canvas_screen.dart`
  - Replace placeholder Container with DrawingCanvasWidget
  - Add undo button (calls provider.undo())
  - Add redo button (calls provider.redo())
  - Add clear button with confirmation dialog
  - Show stroke count indicator (e.g., "23/1000")
  - Show warning banner at 900 strokes
- [x] **Validation**: Full drawing experience works locally ✅

### 1.7 Setup Provider in App
- [x] Add `provider: ^6.1.2` to `pubspec.yaml`
- [x] Modify `lib/main.dart`
  - Wrap MaterialApp with MultiProvider
  - Add DrawingProvider to providers list
  - Pass canvasId to provider initialization
- [x] **Validation**: `flutter run` - app starts without errors ✅

### 1.8 Test Core Drawing
- [x] Manual test: Draw complex shape ✅
- [x] Manual test: Undo last 5 strokes ✅
- [x] Manual test: Redo 3 strokes ✅
- [x] Manual test: Draw until 1000 limit reached ✅
- [x] Manual test: Hot reload preserves state ✅
- [x] **Validation**: All tests pass, drawing feels smooth ✅

---

## Phase 2: Data Models & Serialization ✅ COMPLETED

### 2.1 Create Data Models
- [x] Create `lib/data/models/drawing_stroke_model.dart`
  - toJson, fromJson methods
  - toEntity, fromEntity methods
  - Handle Offset serialization (x, y)
  - Handle Color serialization (int value)
- [x] Create `lib/data/models/drawing_data_model.dart`
  - toJson, fromJson for complete canvas
  - List<DrawingStroke> serialization
- [x] Create `lib/data/models/active_user_model.dart`
  - toJson, fromJson for presence data
- [x] **Validation**: `flutter analyze` - no errors ✅

### 2.2 Add Serialization Tests
- [x] Create `test/data/models/drawing_stroke_model_test.dart`
  - Test JSON roundtrip (toJson → fromJson → equals original)
  - Test entity conversion (toEntity → fromEntity)
  - 13 tests covering all edge cases ✅
- [x] Create `test/data/models/drawing_data_model_test.dart`
  - Test complete canvas serialization
  - 19 tests covering multiple strokes, empty canvas, order preservation ✅
- [x] Create `test/data/models/active_user_model_test.dart`
  - 27 tests covering null/non-null cursor, coordinates, colors ✅
- [x] **Validation**: `flutter test` - all 59 tests pass ✅

---

## Phase 3: Firebase Setup & Persistence ✅ COMPLETED

### 3.1 Add Firebase Dependencies
- [ ] Add to `pubspec.yaml`:
  - `firebase_core: ^3.8.1`
  - `cloud_firestore: ^5.5.0`
  - `firebase_storage: ^12.3.6`
  - `firebase_auth: ^5.3.3`
  - `uuid: ^4.5.1`
- [ ] Run `flutter pub get`
- [ ] Run `cd ios && pod install` (ensure Firebase pods install)
- [ ] **Validation**: Build succeeds

### 3.2 Configure Firebase Project
- [ ] Create Firebase project in console (external task)
- [ ] Download `google-services.json` (Android)
- [ ] Download `GoogleService-Info.plist` (iOS)
- [ ] Add files to respective platform folders
- [ ] Initialize Firebase in `main.dart` (await Firebase.initializeApp())
- [ ] **Validation**: App connects to Firebase (check logs)

### 3.3 Create Repository Interface
- [ ] Create `lib/domain/repositories/drawing_repository.dart`
  - Abstract interface with methods:
    - `Future<DrawingData> loadCanvas(String canvasId)`
    - `Future<void> saveStroke(String canvasId, DrawingStroke stroke)`
    - `Future<void> removeStroke(String canvasId, String strokeId)`
    - `Stream<DrawingData> watchCanvas(String canvasId)`
- [ ] **Validation**: Interface compiles

### 3.4 Implement Firebase Repository
- [ ] Create `lib/data/repositories/drawing_repository_impl.dart`
  - Implement DrawingRepository
  - Firestore collection: `canvases/{canvasId}`
  - Document structure: { strokes: [], version: int, ... }
  - loadCanvas: fetch document, deserialize
  - saveStroke: array union operation
  - watchCanvas: snapshot listener
- [ ] **Validation**: Can save and load canvas from Firestore

### 3.5 Setup Firestore Security Rules
- [ ] Create/update Firestore rules:
  ```
  rules_version = '2';
  service cloud.firestore {
    match /databases/{database}/documents {
      match /canvases/{canvasId} {
        allow read: if true;  // MVP: public read
        allow write: if request.auth != null;  // Authenticated writes
      }
    }
  }
  ```
- [ ] Deploy rules to Firebase
- [ ] **Validation**: Rules enforce authentication

---

## Phase 4: Real-time Synchronization

### 4.1 Setup Anonymous Authentication
- [ ] Enable Anonymous Auth in Firebase Console
- [ ] Add sign-in logic to `main.dart` or auth service
  - `await FirebaseAuth.instance.signInAnonymously()`
- [ ] **Validation**: User gets authenticated UID

### 4.2 Connect Provider to Repository
- [ ] Modify DrawingProvider constructor to accept DrawingRepository
- [ ] In endStroke: call repository.saveStroke()
- [ ] In undo/redo: call repository.removeStroke()
- [ ] Subscribe to repository.watchCanvas() stream
  - Update local state when remote strokes arrive
  - Merge remote strokes preserving order
- [ ] **Validation**: Local strokes persist to Firestore

### 4.3 Handle Multi-User Updates
- [ ] Filter incoming strokes to avoid duplicates
  - Track stroke IDs (use UUID for each stroke)
  - Only add if stroke ID not in current list
- [ ] Attribute strokes to users (userId field)
- [ ] Sort strokes by timestamp for consistent ordering
- [ ] **Validation**: Two devices see each other's strokes

### 4.4 Implement Offline Queue
- [ ] Create local queue for pending strokes (SharedPreferences or Hive)
- [ ] On network error: queue stroke locally
- [ ] On reconnect: flush queue to Firestore
- [ ] Show connection status indicator in UI
- [ ] **Validation**: Draw offline, reconnect, strokes sync

### 4.5 Test Multi-Device Sync
- [ ] Manual test: Draw on device A, see on device B
- [ ] Manual test: Draw on both devices simultaneously
- [ ] Manual test: Disconnect device, reconnect, verify sync
- [ ] **Validation**: Sync latency <500ms on good network

---

## Phase 5: Image Export

### 5.1 Implement Export Service
- [ ] Create `lib/domain/services/canvas_export_service.dart`
  - Method: `Future<Uint8List> exportToPng(GlobalKey repaintKey)`
  - Capture RepaintBoundary: `findRenderObject()` → `toImage()`
  - Convert to PNG: `toByteData(format: ImageByteFormat.png)`
  - Optional compression (target <500KB)
- [ ] **Validation**: Can generate PNG from canvas

### 5.2 Add Export Button to UI
- [ ] Add "Export" or "Share" button to drawing screen app bar
- [ ] On tap: call export service, show loading indicator
- [ ] Display success/error snackbar
- [ ] **Validation**: Button exports PNG successfully

### 5.3 Upload to Firebase Storage
- [ ] Modify export flow to upload PNG
  - Storage path: `canvases/{canvasId}/latest.png`
  - Get download URL after upload
- [ ] Update Firestore document with imageUrl field
- [ ] **Validation**: PNG accessible via download URL

### 5.4 Integrate with "Done" Button
- [ ] Modify existing "Done" button behavior
  - Before: just navigate back
  - After: export PNG → upload → update Firestore → navigate back
- [ ] Show progress dialog during export/upload
- [ ] **Validation**: "Done" button exports and uploads

---

## Phase 6: Widget Integration (Platform Channels)

### 6.1 Create Widget Refresh Service
- [ ] Create `lib/services/widget_refresh_service.dart`
  - MethodChannel: `com.example.panci/widget_refresh`
  - Method: `Future<void> refreshWidget(String imagePath)`
  - Call native Swift code to reload widget
- [ ] **Validation**: Service compiles

### 6.2 Configure iOS App Groups
- [ ] In Xcode: Add App Groups capability
  - Group ID: `group.com.example.panci`
  - Add to main app target
- [ ] Create widget extension target (if not exists)
- [ ] Add App Groups to widget target
- [ ] **Validation**: Entitlements file shows App Group

### 6.3 Save Image to Shared Container
- [ ] After PNG export, save to App Group:
  - Use `path_provider` to get app group path
  - Save image as `canvas_{id}.png`
- [ ] Update shared UserDefaults with metadata (canvasId, timestamp)
- [ ] **Validation**: File exists in shared container

### 6.4 Implement Native Widget Code
- [ ] Create Swift widget extension (separate task, not Flutter code)
- [ ] TimelineProvider reads image from App Group
- [ ] Widget displays canvas image
- [ ] Handle missing image (show placeholder)
- [ ] **Note**: This is iOS native development, not covered in this change

### 6.5 Test Widget Refresh
- [ ] Manual test on physical device (required for widgets)
- [ ] Draw → Done → Verify widget updates
- [ ] Check widget refresh timing (may have delay due to WidgetKit)
- [ ] **Validation**: Widget shows latest canvas

---

## Phase 7: Live Presence & Polish

### 7.1 Create Presence Provider
- [ ] Create `lib/presentation/providers/presence_provider.dart`
  - Track Map<userId, ActiveUser>
  - Method: updateCursor(Offset position)
  - Throttle updates to 100ms
- [ ] Subscribe to Firestore collection: `canvases/{canvasId}/active_users`
- [ ] Broadcast local cursor position
- [ ] **Validation**: Presence data syncs to Firestore

### 7.2 Implement Cursor Painter
- [ ] Create `lib/presentation/widgets/cursor_painter.dart`
  - CustomPainter for rendering user cursors
  - Draw colored circles at cursor positions
  - Show user initials/avatar inside circle
  - Fade out cursors after 3s inactivity
- [ ] **Validation**: Cursors render correctly

### 7.3 Integrate Cursors into Canvas
- [ ] Modify DrawingCanvasWidget to stack cursor painter on top
- [ ] Update cursor position on onPanUpdate
- [ ] Assign unique color to current user
- [ ] **Validation**: See other users' cursors in real-time

### 7.4 Add Connection Status
- [ ] Create connection listener (Firestore connection state)
- [ ] Show indicator in app bar: "Connected" / "Offline"
- [ ] Change color: green = connected, gray = offline
- [ ] **Validation**: Indicator reflects actual connection

### 7.5 Performance Optimization
- [ ] Profile drawing performance with DevTools
- [ ] Optimize CustomPainter repaints
- [ ] Implement stroke simplification (Douglas-Peucker)
  - Reduce points while preserving shape
  - Apply before saving to Firestore
- [ ] Batch Firestore writes if needed
- [ ] **Validation**: <50ms drawing latency, 60 FPS

### 7.6 Final Polish
- [ ] Add haptic feedback on stroke start/end
- [ ] Improve loading states (skeleton screens)
- [ ] Add error handling for all Firebase operations
- [ ] Show participant count in UI
- [ ] Add tooltips to buttons
- [ ] **Validation**: Complete user experience review

### 7.7 Final Testing
- [ ] Test all phases end-to-end on physical device
- [ ] Test with 2-3 users drawing simultaneously
- [ ] Test offline → online transition
- [ ] Test edge cases (empty canvas, 1000 stroke limit)
- [ ] Performance test with complex drawing
- [ ] **Validation**: All success criteria met

---

## Validation Checkpoints

After each phase, ensure:
- [ ] `flutter analyze` shows no errors
- [ ] Existing tests pass: `flutter test`
- [ ] Manual testing confirms expected behavior
- [ ] Git commit with descriptive message
- [ ] Update this tasks.md to mark completed items

## Dependencies Between Tasks
- Phase 2 depends on Phase 1 (entities must exist before models)
- Phase 3 requires Phase 2 (models needed for Firestore)
- Phase 4 requires Phase 3 (repository must exist)
- Phase 5 can run parallel to Phase 4
- Phase 6 depends on Phase 5 (needs PNG export)
- Phase 7 can start after Phase 4 (needs sync infrastructure)

## Parallel Work Opportunities
- While waiting for pod install (Phase 3.1), work on Phase 2
- Phase 5 (export) and Phase 7 (presence) can be developed in parallel
- UI polish (Phase 7.6) can happen continuously
