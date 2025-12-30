# Project Context

## Purpose
Build an MVP for a shared canvas app where multiple users can see the RESULT of a drawing (not real-time stroke progress). The canvas is shown inside an iOS home screen widget and updates whenever someone finishes a drawing.

**Core Concept**: Users draw on a shared canvas in the Flutter app. When they finish, the canvas is rendered to an image, uploaded to the backend, and other users' iOS widgets automatically refresh to display the latest canvas state.

## Tech Stack
- **Flutter** (iOS-first, Android optional) - Main app for drawing and canvas management
- **Native iOS WidgetKit** (Swift) - Home screen widget display
- **Firebase** (Firestore or Realtime DB) OR simple REST backend - Canvas metadata and image storage
- **APNs silent push** OR app-triggered widget refresh - Update notification mechanism
- **App Groups** - Data sharing between Flutter app and native iOS widget
- **Platform Channels** - Flutter-to-Swift communication for widget updates

## Project Conventions

### Code Style
- **Flutter**: Follow standard Dart/Flutter conventions
  - Use `flutter analyze` for linting
  - Prefer composition over inheritance
  - Use meaningful variable names
- **Swift**: Follow Swift API design guidelines
  - Use SwiftLint for code style
  - Leverage modern Swift features (async/await, structured concurrency)

### Architecture Patterns
- **Flutter App**:
  - Clean separation: UI layer → Service layer → Data layer
  - Drawing canvas as standalone widget
  - Canvas service handles export to PNG
  - Backend service manages upload/download
  - Widget refresh service triggers native updates

- **iOS Widget**:
  - TimelineProvider pattern (WidgetKit standard)
  - Read image from App Group shared container
  - Simple timeline with single entry (latest canvas)

- **Data Flow**:
  1. User draws → Tap "Done"
  2. Canvas rendered to PNG in Flutter
  3. Image uploaded to backend (Firebase Storage or REST)
  4. Metadata updated (canvasId, updatedAt, imageUrl)
  5. Other users notified (poll/listener/push)
  6. App downloads latest image
  7. Image saved to App Group storage
  8. WidgetCenter.reloadTimelines() called via platform channel
  9. Widget reads image from App Group and displays

### Testing Strategy
- **MVP Focus**: Manual testing for core flows
- **Critical paths to test**:
  - Drawing and export to PNG
  - Upload/download image
  - App Group file sharing
  - Widget refresh trigger
  - Canvas join/create flow

### Git Workflow
- Feature branches for new capabilities
- Commit messages should be descriptive
- Test on physical iOS device (widgets don't work in simulator reliably)

## Domain Context

### Canvas Model
- **canvasId**: Unique identifier for shared canvas
- **updatedAt**: Timestamp of last update
- **imageUrl**: URL to latest canvas PNG
- **metadata**: Optional (creator, canvas name, etc.)

### iOS Widget Constraints
- Widgets are **snapshot-based**, NOT real-time
- Widgets display static content (images, text)
- Widgets cannot show animated drawing strokes
- Updates are triggered, not continuous
- Widget refreshes have rate limits (WidgetKit decides actual refresh timing)
- Widgets run in separate process from main app
- Data sharing requires App Groups entitlement

### User Experience
- **In-app**: Smooth drawing experience with canvas tools
- **Widget**: Shows the RESULT (final canvas image) only
- **Update latency**: Acceptable delay (seconds to minutes) between drawing completion and widget refresh
- **No real-time collaboration**: Users take turns drawing; no stroke-by-stroke sync

## Important Constraints

### Technical Constraints
1. **iOS widgets are snapshot-based** - No real-time stroke rendering in widget
2. **Widget only displays latest canvas image** - Binary state: old image or new image
3. **Drawing and sync happen in main app only** - Widget is read-only display
4. **Updates propagate AFTER drawing is completed** - Not during drawing
5. **App Groups required** - For Flutter app ↔ Widget data sharing
6. **Platform channels required** - For Flutter to call Swift widget refresh APIs

### Out of Scope (MVP)
- Stroke-by-stroke live collaboration
- Widget user interaction (tapping widget to draw)
- Conflict resolution (simultaneous drawings)
- Undo/redo
- Multiple layers
- Advanced drawing tools
- User authentication (can use anonymous auth)
- Android widgets

### Performance Constraints
- Canvas export to PNG should be fast (<1s for typical canvas)
- Image file size should be reasonable (compress if needed)
- Widget updates should not drain battery (rely on WidgetKit's scheduling)

## Functional Requirements

### 1. Canvas Management
- Users can create a new shared canvas (generates unique canvasId)
- Users can join an existing canvas via canvasId
- Canvas state is persisted in backend

### 2. Drawing Experience
- Freehand drawing on canvas in Flutter
- Simple drawing tools (color, brush size)
- "Done" button to finalize and share drawing

### 3. Export and Upload Flow
When user taps "Done":
1. Canvas widget captures current drawing state
2. Render canvas to PNG image (Flutter's `toImage()` → `toByteData()`)
3. Upload PNG to backend storage
4. Update canvas metadata (updatedAt timestamp, imageUrl)
5. Trigger notifications/updates for other users

### 4. Sync and Widget Refresh Flow
For other users:
1. App receives update via:
   - Polling (simple, works for MVP)
   - Realtime listener (Firestore)
   - APNs silent push (production-ready)
2. App downloads latest canvas image
3. App saves image to App Group shared container
4. App calls `WidgetCenter.reloadTimelines()` via platform channel
5. Widget reads image from App Group in `getTimeline()`
6. Widget displays updated canvas image

### 5. iOS Widget
- Widget extension reads latest canvas image from App Group
- Widget TimelineProvider creates timeline with single entry
- Widget UI displays the canvas image
- Widget shows placeholder if no image available
- Widget shows canvasId or canvas name

## External Dependencies

### Backend Services
- **Firebase** (recommended for MVP):
  - Firebase Storage - Canvas PNG image storage
  - Firestore - Canvas metadata (canvasId, updatedAt, imageUrl)
  - Firebase Auth - Anonymous authentication
  - Optional: Cloud Functions for notifications

- **Alternative: REST API**:
  - Simple backend with image upload endpoint
  - Canvas metadata API
  - Webhook or polling for updates

### Native iOS Integration
- **WidgetKit** - iOS 14+ widget framework
- **App Groups** - Shared container between app and widget
- **UserDefaults (App Group)** - Optional metadata sharing
- **FileManager** - File I/O for shared images

### Flutter Packages
- `flutter/services` - Platform channels
- `path_provider` - File system access
- Firebase packages (if using Firebase):
  - `firebase_core`
  - `cloud_firestore`
  - `firebase_storage`
  - `firebase_auth`
- `image` - Image processing/compression (optional)
- Drawing packages (e.g., `flutter_drawing_board`, or custom)

## Deliverables

### 1. Flutter App Structure
- Canvas drawing screen with drawing tools
- Canvas export service (render to PNG)
- Backend sync service (upload/download)
- Canvas management (create/join)
- Widget refresh trigger via platform channel

### 2. iOS WidgetKit Code
- Widget extension target in Xcode
- TimelineProvider implementation
- Image loading from App Group
- Widget UI layout (canvas image display)
- App Group configuration

### 3. Data Model
- Canvas schema (Firestore or REST)
- Image storage structure
- Shared data format (App Group)

### 4. Documentation
- Clear explanation of data flow diagram
- Setup instructions (App Groups, entitlements)
- How to test the widget on device
- Backend configuration steps

### 5. Code Quality
- Minimal but production-correct code
- Clear separation of concerns
- Error handling for network/storage failures
- Graceful degradation (show old image if update fails)

## Assumptions
- One canvas = one shared image (no layers, no history)
- Anonymous authentication is acceptable
- Focus on clarity over advanced features
- iOS-first (Android can be added later)
- Users understand widgets update with delay, not instantly
- Basic drawing tools sufficient (color, brush size)
- Single active canvas per user at a time
