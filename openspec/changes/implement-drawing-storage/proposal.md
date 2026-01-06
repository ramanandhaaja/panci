# Proposal: Implement Drawing Storage

## Overview
Implement collaborative drawing functionality with vector-based stroke storage, real-time synchronization, and PNG export for iOS widget integration.

## Problem Statement
Currently, the drawing canvas screen (`lib/presentation/screens/drawing_canvas_screen.dart`) is a placeholder showing only "Drawing canvas will be here" text. The app needs:

1. **Actual drawing capability** - Users cannot draw on the canvas
2. **Stroke persistence** - No storage mechanism for drawing data
3. **Multi-user collaboration** - No real-time sync between users
4. **Widget integration** - No canvas export to PNG for iOS widgets
5. **Drawing controls** - Missing undo/redo functionality

The project's core value proposition (shared canvas displayed in iOS widgets) cannot be realized without implementing the drawing and storage layer.

## Goals
1. Enable users to draw on a collaborative canvas using touch gestures
2. Store drawing data as vector strokes (not raster images) for editing and replay
3. Synchronize strokes across multiple users in real-time using Firebase
4. Implement undo/redo with proper multi-user handling
5. Export canvas to PNG for iOS widget display
6. Support live user presence (show cursors of active users)
7. Apply stroke smoothing for professional-looking drawings

## Non-Goals (Deferred to Future Changes)
- Advanced drawing tools (layers, selection, transformation)
- Offline-first architecture with conflict resolution
- Drawing replay/animation features
- Canvas versioning/branching
- iOS WidgetKit native implementation (depends on this change)
- Multi-canvas management UI improvements

## Context & Dependencies

### Current State
- **UI layer exists**: Color picker, brush size selector, and placeholder canvas screen
- **Domain layer partial**: `CanvasEntity` exists for canvas metadata but no drawing data structures
- **No backend integration**: Firebase dependencies not added yet
- **No state management**: No Provider setup in app

### Dependencies
- Requires Firebase project setup (external)
- Depends on `add-ui-screen-layouts` change (already complete)
- Blocks future `ios-widget-integration` change

### Related Project Context
From `openspec/project.md`:
- Project mandate: "Users draw on a shared canvas in the Flutter app. When they finish, the canvas is rendered to an image, uploaded to the backend, and other users' iOS widgets automatically refresh"
- Architecture pattern: Clean separation (UI → Service → Data)
- Canvas export to PNG is critical path requirement
- Original spec stated "Undo/redo out of scope" but user has requested it

## Proposed Solution

### Architecture Overview
Implement clean architecture with three layers:

1. **Domain Layer** - Pure Dart entities and interfaces
   - `DrawingStroke` entity: Vector path with color, width, timestamp, userId
   - `DrawingData` entity: Complete canvas state with stroke list
   - `ActiveUser` entity: Live presence tracking
   - Repository interfaces for drawing persistence

2. **Data Layer** - Firebase implementation
   - JSON serialization models
   - Firebase Firestore repository implementation
   - Real-time listeners for stroke synchronization

3. **Presentation Layer** - UI and state management
   - Provider-based state management
   - Custom painters for rendering strokes and cursors
   - Gesture detection for drawing input
   - Export service for PNG generation

### Key Technical Decisions

**Storage Format**: Vector strokes (not raster)
- Enables undo/redo and editing
- Smaller storage footprint
- Canvas can scale to any resolution

**State Management**: Provider pattern
- Lightweight and appropriate for drawing state
- Good performance for frequent updates
- Easy to test and reason about

**Canvas Size**: Fixed 2000x2000 pixels
- Consistent across all devices
- Scaled to fit screen using FittedBox
- Optimized for widget display

**Stroke Limit**: 1000 strokes maximum
- Prevents performance degradation
- Reasonable for detailed drawings
- Warning shown at 900 strokes

**Smoothing**: Catmull-Rom spline interpolation
- Natural-looking curves
- Applied in batches of 4 points
- Original points preserved for undo accuracy

**Live Presence**: Real-time cursor broadcasting
- 100ms update throttling
- Fade out after 3s inactivity
- Colored cursor dots with user initials

### Implementation Phases

**Phase 1: Core Drawing (Local Only)**
- Domain entities and local state management
- Canvas painter and gesture detection
- Undo/redo functionality
- No backend integration yet

**Phase 2: Data Models & Serialization**
- JSON serialization for all entities
- Unit tests for roundtrip conversion

**Phase 3: Firebase Setup & Persistence**
- Add Firebase dependencies
- Repository implementation
- Basic save/load operations

**Phase 4: Real-time Synchronization**
- Firestore listeners for live updates
- Multi-user stroke broadcasting
- Offline queue handling

**Phase 5: Image Export**
- RepaintBoundary for canvas capture
- PNG generation and compression
- Firebase Storage upload

**Phase 6: Widget Integration**
- Platform channel setup
- App Groups configuration
- Widget refresh trigger

**Phase 7: Live Presence & Polish**
- Cursor broadcasting
- Connection status indicator
- Performance optimization

## Risks & Mitigations

### Risk: Performance degradation with many strokes
**Mitigation**:
- 1000 stroke limit enforced
- Efficient CustomPainter with shouldRepaint optimization
- Stroke simplification using Douglas-Peucker algorithm

### Risk: Network latency affecting drawing experience
**Mitigation**:
- Local drawing is immediate (optimistic updates)
- Sync happens asynchronously in background
- Offline queue for disconnected scenarios

### Risk: Firestore costs with frequent cursor updates
**Mitigation**:
- 100ms throttling on cursor broadcasts
- Cursors stored in ephemeral collection with TTL
- Option to disable live cursors if costs are concern

### Risk: Multi-user conflicts (simultaneous edits)
**Mitigation**:
- Stroke-level granularity (each stroke is atomic)
- Version field for optimistic locking
- Last-write-wins for MVP (acceptable trade-off)

## Success Criteria
- [ ] User can draw smoothly with <50ms input latency
- [ ] Strokes persist to Firestore and reload on app restart
- [ ] Multiple users see each other's strokes within 500ms
- [ ] Undo/redo works correctly for user's own strokes
- [ ] Canvas exports to PNG (<500KB file size)
- [ ] Live cursors display for active users
- [ ] App handles offline/online transitions gracefully
- [ ] Performance acceptable on iPhone 12+ devices

## Open Questions
None - all decisions confirmed with user during planning phase.

## Estimated Effort
- **Phase 1**: 1 unit (Core drawing local-only)
- **Phase 2**: 0.5 units (Serialization)
- **Phase 3**: 1 unit (Firebase setup)
- **Phase 4**: 1 unit (Real-time sync)
- **Phase 5**: 0.5 units (Image export)
- **Phase 6**: 0.5 units (Widget integration)
- **Phase 7**: 0.5 units (Polish)

**Total**: 5.5 units (1 unit ≈ 1-2 hours focused development)

## References
- Approved implementation plan: `/Users/nandha/.claude/plans/lucky-foraging-crystal.md`
- Existing canvas screen: `lib/presentation/screens/drawing_canvas_screen.dart`
- Project context: `openspec/project.md`
- Firebase Flutter docs: https://firebase.google.com/docs/flutter/setup
