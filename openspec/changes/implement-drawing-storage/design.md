# Design: Implement Drawing Storage

## Architecture Overview

This change implements a three-layer clean architecture for collaborative drawing:

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                    │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────┐ │
│  │  Providers  │  │   Widgets    │  │    Screens     │ │
│  │  (State)    │  │  (Canvas UI) │  │  (Integration) │ │
│  └─────────────┘  └──────────────┘  └────────────────┘ │
└───────────────────────┬─────────────────────────────────┘
                        │
┌───────────────────────┴─────────────────────────────────┐
│                     Domain Layer                         │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────┐ │
│  │  Entities   │  │ Repositories │  │    Services    │ │
│  │  (Pure Dart)│  │ (Interfaces) │  │   (Business)   │ │
│  └─────────────┘  └──────────────┘  └────────────────┘ │
└───────────────────────┬─────────────────────────────────┘
                        │
┌───────────────────────┴─────────────────────────────────┐
│                      Data Layer                          │
│  ┌─────────────┐  ┌──────────────┐                     │
│  │   Models    │  │  Repository  │                     │
│  │   (JSON)    │  │     Impl     │                     │
│  └─────────────┘  └──────────────┘                     │
└───────────────────────┬─────────────────────────────────┘
                        │
                ┌───────┴────────┐
                │  Firebase      │
                │  Firestore +   │
                │  Storage       │
                └────────────────┘
```

## Key Design Decisions

### 1. State Management: Provider Pattern

**Decision**: Use Provider (ChangeNotifier) for state management.

**Rationale**:
- **Simple and performant** for drawing state (frequent updates)
- **No boilerplate** compared to BLoC or Redux
- **Built-in Flutter integration** with Consumer and context.watch
- **Sufficient for this use case** - no complex state orchestration needed

**Alternatives considered**:
- **BLoC**: Too much boilerplate for simple drawing state
- **Riverpod**: Modern but adds complexity for marginal benefit
- **GetX**: Not aligned with Flutter best practices
- **setState**: Not scalable for multi-screen state sharing

**Implementation**:
- `DrawingProvider`: Manages canvas state, undo/redo
- `PresenceProvider`: Manages active user cursors
- Both extend `ChangeNotifier` and use `notifyListeners()`

### 2. Storage Backend: Firebase Firestore

**Decision**: Use Firestore for real-time stroke synchronization.

**Rationale**:
- **Real-time listeners** for instant collaboration
- **Offline support** built-in with local cache
- **Scalable** for MVP and beyond
- **Free tier** sufficient for development
- **Authentication integrated** (Firebase Auth)

**Alternatives considered**:
- **Custom WebSocket backend**: More control but higher complexity
- **Supabase**: Good alternative but less mature Flutter SDK
- **Firebase Realtime DB**: Older, less flexible query model
- **Local-only (Hive/SQLite)**: Doesn't meet multi-device requirement

**Firestore Schema**:
```
canvases/{canvasId}
  ├─ strokes: Array<StrokeObject>
  ├─ version: int
  ├─ lastUpdated: Timestamp
  ├─ imageUrl: string
  └─ metadata: { name, createdAt, ... }

canvases/{canvasId}/active_users/{userId}
  ├─ displayName: string
  ├─ cursorPosition: { x, y } | null
  ├─ cursorColor: int
  └─ lastSeen: Timestamp
```

**Trade-offs**:
- ✅ Real-time sync "for free"
- ✅ Offline support
- ✅ Fast to implement
- ❌ Vendor lock-in to Firebase
- ❌ Firestore costs can scale with usage
- ❌ Stroke array has size limits (~1MB document)

**Mitigation for array limits**:
- 1000 stroke limit enforced in code
- Average stroke size ~500 bytes → 500KB total
- Well below 1MB Firestore document limit

### 3. Drawing Representation: Vector Strokes

**Decision**: Store drawings as vector paths (list of coordinate points), not raster images.

**Rationale**:
- **Enables undo/redo** (can remove individual strokes)
- **Smaller storage** than raster for typical drawings
- **Scalable** to any resolution
- **Editable** (future feature: stroke manipulation)

**Alternatives considered**:
- **Raster (pixel array)**: Can't undo individual strokes, large file size
- **SVG**: More complex to render in Flutter, harder to sync incrementally
- **Canvas operations log**: Difficult to optimize and query

**Stroke Data Structure**:
```dart
class DrawingStroke {
  final String id;  // UUID for identification
  final List<Offset> points;  // Vector path
  final Color color;
  final double strokeWidth;
  final DateTime timestamp;
  final String userId;
}
```

**Trade-offs**:
- ✅ Perfect for undo/redo
- ✅ Efficient storage
- ✅ Smooth rendering with CustomPainter
- ❌ More complex than raster for export
- ❌ Requires stroke simplification for long strokes

### 4. Stroke Smoothing: Catmull-Rom Splines

**Decision**: Apply Catmull-Rom spline interpolation to raw touch points.

**Rationale**:
- **Natural curves** instead of jagged polylines
- **Proven algorithm** widely used in drawing apps
- **Configurable tension** (can adjust smoothness)
- **Incremental application** (works on point batches)

**Alternatives considered**:
- **No smoothing**: Results in jagged, unprofessional-looking strokes
- **Bézier curves**: More complex, requires control point calculation
- **Gaussian blur post-processing**: Smooths raster, not vector

**Implementation**:
- Applied in batches of 4 points (Catmull-Rom requirement)
- Original points preserved for undo accuracy
- Smoothing happens before Firestore save (reduces point count)

### 5. Canvas Dimensions: Fixed 2000x2000

**Decision**: Use a fixed 2000x2000 pixel canvas, scaled to fit device screens.

**Rationale**:
- **Consistent across devices** - collaboration requires same coordinate space
- **Optimized for widget** - 2000px is high-res for iOS widget display
- **Prevents aspect ratio issues** - square canvas scales uniformly
- **Performance balance** - not too large (4K) or too small (1080p)

**Alternatives considered**:
- **Device screen size**: Different devices see different canvases (bad UX)
- **Infinite canvas**: Complex to implement, widget needs fixed size
- **4000x4000**: Too large, slow export, large PNG files

**Scaling Strategy**:
- Canvas wrapped in `FittedBox(fit: BoxFit.contain)`
- Touch coordinates transformed from screen space to canvas space
- Export renders at full 2000x2000 resolution

### 6. Undo/Redo: Stack-Based History

**Decision**: Use dual-stack pattern (undo stack + redo stack).

**Rationale**:
- **Simple and intuitive** - proven pattern for undo/redo
- **Efficient** - O(1) operations
- **Clear ownership** - only undo own strokes in multi-user scenario

**Implementation**:
```dart
// Undo
undoStack.add(strokes.removeLast());
redoStack.clear(); // New action clears redo

// Redo
strokes.add(redoStack.removeLast());
```

**Multi-user consideration**:
- **MVP**: Allow undoing any stroke (last-write-wins)
- **Future**: Filter undo to only current user's strokes

**Trade-offs**:
- ✅ Simple implementation
- ✅ Low memory overhead
- ❌ Full canvas history not preserved (no "rewind" feature)
- ❌ Multi-user undo needs careful UX design

### 7. Image Export: RepaintBoundary + Firebase Storage

**Decision**: Use RepaintBoundary to capture canvas as PNG, upload to Firebase Storage.

**Rationale**:
- **RepaintBoundary** is Flutter's built-in mechanism for offscreen rendering
- **Firebase Storage** integrates seamlessly with Firestore
- **PNG format** widely supported, good compression for drawings

**Export Pipeline**:
1. RepaintBoundary wraps canvas widget
2. On "Done": `boundary.toImage()` → `toByteData(PNG)` → Uint8List
3. Optional: Compress PNG if >500KB
4. Upload to Storage: `canvases/{id}/latest.png`
5. Update Firestore with download URL
6. Trigger iOS widget refresh via platform channel

**Alternatives considered**:
- **SVG export**: Not natively supported by iOS widgets
- **Canvas screenshot**: Lower quality than RepaintBoundary
- **Server-side rendering**: Unnecessary complexity for MVP

### 8. Live Presence: Cursor Broadcasting

**Decision**: Broadcast cursor positions via ephemeral Firestore subcollection.

**Rationale**:
- **Real-time engagement** - users see each other drawing
- **Lightweight** - cursors separate from stroke data
- **Firestore TTL** - auto-cleanup of stale cursors

**Throttling Strategy**:
- Update frequency: 10 updates/second (100ms throttle)
- Idle timeout: 3 seconds (cursor fades out)
- Cleanup: Presence document deleted on leave

**Network Cost Mitigation**:
- Cursor writes: ~10 per second per active user
- Assuming 3 concurrent users × 10 writes/s = 30 writes/s
- 30 writes/s × 3600s = 108,000 writes/hour
- Firestore free tier: 20,000 writes/day → Need paid plan for active collab

**Trade-off**:
- ✅ Engaging multi-user experience
- ❌ Increases Firestore costs
- **Mitigation**: Make cursors optional, disable for cost-sensitive users

## Security Considerations

### Firestore Security Rules

**MVP Rules** (permissive for development):
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /canvases/{canvasId} {
      allow read: if true;  // Public read
      allow write: if request.auth != null;  // Authenticated write
    }
    match /canvases/{canvasId}/active_users/{userId} {
      allow read: if true;
      allow write: if request.auth.uid == userId;  // Own presence only
    }
  }
}
```

**Production Rules** (future):
- Canvas read: User is in `participants` array
- Canvas write: User is in `participants` array
- Rate limiting: Max 100 writes/minute per user

### Authentication

**MVP**: Anonymous authentication
- Simple, no signup required
- Sufficient for demo/testing
- Generates unique UID per device

**Future**: Email/Social login
- Persistent identity across devices
- User profiles and avatars
- Stroke attribution with real names

## Performance Optimizations

### 1. CustomPainter Efficiency
- **shouldRepaint** logic: Only repaint if stroke count changes
- **Path caching**: Reuse Paint objects for same color/width
- **Clip regions**: Only paint visible strokes (if canvas is zoomable)

### 2. Stroke Simplification
- **Douglas-Peucker algorithm** reduces point count
- Apply before Firestore save (reduces bandwidth)
- Target: <200 points per stroke

### 3. Firestore Query Optimization
- **Single document** for canvas (not subcollection of strokes)
- **Array operations** for incremental updates
- **Index-free queries** (no complex filtering)

### 4. Image Compression
- PNG compression level: 6 (balance speed/size)
- Fallback: JPEG with 85% quality if PNG >500KB
- Target: <500KB for 2000x2000 canvas

## Testing Strategy

### Unit Tests
- Domain entities: Serialization, equality, copyWith
- Services: Stroke smoothing algorithm
- Providers: Undo/redo logic, stroke limit enforcement

### Widget Tests
- CustomPainter renders strokes correctly
- GestureDetector captures touch events
- UI buttons trigger correct provider methods

### Integration Tests
- End-to-end drawing flow (draw → save → load)
- Multi-device sync simulation
- Export → upload → widget refresh flow

### Manual Testing
- Real device testing (physical iPhone/iPad)
- Multi-user collaboration (2-3 devices)
- Network conditions (offline, slow connection)
- Performance profiling (DevTools)

## Rollout Plan

### Phase 1: Local Drawing (No Backend)
- **Goal**: Prove drawing experience
- **Success**: Users can draw, undo, redo locally
- **Risk**: Low (no external dependencies)

### Phase 2: Persistence (Firestore Save/Load)
- **Goal**: Drawings persist across sessions
- **Success**: Canvas restores on app restart
- **Risk**: Medium (Firebase setup required)

### Phase 3: Real-time Sync
- **Goal**: Multi-device collaboration
- **Success**: Strokes sync <500ms
- **Risk**: Medium (network latency, conflicts)

### Phase 4: Image Export + Widget
- **Goal**: iOS widget displays canvas
- **Success**: Widget shows latest canvas image
- **Risk**: High (platform channels, App Groups)

### Phase 5: Live Presence
- **Goal**: See other users' cursors
- **Success**: Cursors appear in real-time
- **Risk**: Medium (Firestore costs)

### Phase 6: Polish + Optimization
- **Goal**: Production-ready quality
- **Success**: All performance targets met
- **Risk**: Low (incremental improvements)

## Open Architectural Questions

### None - All decisions confirmed with user during planning

Previously open questions that were resolved:
- ✅ Stroke smoothing: Yes, Catmull-Rom
- ✅ Stroke limit: 1000 strokes
- ✅ Canvas size: Fixed 2000x2000
- ✅ Live cursors: Yes, show live presence
- ✅ Backend: Firebase (can swap via repository pattern)

## Future Considerations (Out of Scope for This Change)

### Potential Future Changes
- **Layers**: Support multiple drawing layers
- **Selection tool**: Select and transform strokes
- **Stroke styling**: Dashed lines, gradients, textures
- **Pressure sensitivity**: Apple Pencil support
- **Canvas zoom/pan**: Infinite canvas exploration
- **Replay animation**: Animate stroke playback
- **Conflict resolution**: CRDT-based sync (vs. last-write-wins)
- **Offline-first architecture**: Full local-first sync

### Technical Debt to Monitor
- **Firestore costs**: Monitor write volume, optimize if needed
- **Document size limits**: If 1000 strokes approach 1MB, migrate to subcollection
- **Presence cleanup**: Ensure stale users are removed reliably
- **Image storage costs**: Firebase Storage pricing for many canvases

## References
- Flutter CustomPaint: https://api.flutter.dev/flutter/widgets/CustomPaint-class.html
- Firestore best practices: https://firebase.google.com/docs/firestore/best-practices
- Catmull-Rom splines: https://en.wikipedia.org/wiki/Centripetal_Catmull%E2%80%93Rom_spline
- Douglas-Peucker algorithm: https://en.wikipedia.org/wiki/Ramer%E2%80%93Douglas%E2%80%93Peucker_algorithm
- Provider package: https://pub.dev/packages/provider
