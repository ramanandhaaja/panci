# Canvas Preview Implementation

## Overview
This document describes the implementation for displaying actual drawing canvas images on the home page instead of dummy placeholder images.

## What Was Changed

### 1. Created Drawing Preview Painter
**File**: `/lib/presentation/widgets/drawing_preview_painter.dart`

A new `DrawingPreviewPainter` class that renders actual drawing strokes in thumbnail/preview format:
- Scales strokes from 2000x2000 canvas size to preview size
- Handles empty canvases with a subtle placeholder
- Efficiently renders strokes with proper scaling
- Maintains stroke colors, widths, and shapes

**Key Features:**
- Scales coordinates proportionally to fit preview size
- Handles single-point strokes (dots) correctly
- Shows empty state for canvases with no strokes
- Implements `shouldRepaint` for performance optimization

### 2. Created Canvas Preview Provider
**File**: `/lib/presentation/providers/canvas_preview_provider.dart`

Two Riverpod providers for fetching drawing data:

#### `canvasPreviewProvider` (FutureProvider)
- Loads canvas data once for initial display
- Used for static previews that don't need real-time updates

#### `canvasPreviewStreamProvider` (StreamProvider)
- Subscribes to real-time canvas updates
- Used for live previews that update as users draw
- **Currently used in the home screen for real-time updates**

**Why StreamProvider?**
- Shows live updates as users draw on canvases
- Provides better user experience with real-time synchronization
- Automatically updates when canvases are modified

### 3. Created Canvas List Provider
**File**: `/lib/presentation/providers/canvas_list_provider.dart`

Providers for fetching the list of canvases from Firebase:

#### `canvasListProvider` (StreamProvider)
- Queries Firestore for canvas documents
- Orders by `lastUpdated` timestamp (most recent first)
- Limits to 10 most recent canvases
- Converts Firestore data to `CanvasEntity` domain objects
- Determines canvas state based on stroke count
- Generates human-readable canvas names
- Marks canvases as "active" if updated in last 5 minutes

#### `mostRecentCanvasProvider` (Provider)
- Extracts the most recent canvas from the list
- Used for the "Active Canvas" card on home screen

#### `recentCanvasesProvider` (Provider)
- Returns all canvases except the most recent
- Used for the "Recent Canvases" list on home screen

**Canvas State Determination:**
- `empty`: 0 strokes
- `minimal`: 1-9 strokes
- `sketch`: 10-49 strokes
- `geometric`: 50-199 strokes
- `organic`: 200+ strokes

### 4. Updated Canvas Cards
**File**: `/lib/presentation/widgets/canvas_cards.dart`

Modified both `ActiveCanvasCard` and `RecentCanvasCard`:

**Changes:**
- Converted from `StatelessWidget` to `ConsumerWidget` (Riverpod)
- Added `WidgetRef ref` parameter to build methods
- Fetches real drawing data using `canvasPreviewStreamProvider`
- Uses `.when()` method to handle async states:
  - `data`: Renders `DrawingPreviewPainter` with actual strokes
  - `loading`: Shows small circular progress indicator
  - `error`: Falls back to dummy painters from `CanvasPainterFactory`

**Graceful Degradation:**
- If Firebase data fails to load, falls back to dummy painters
- Ensures app never crashes due to missing data
- Provides visual feedback during loading

### 5. Updated Home Screen
**File**: `/lib/presentation/screens/home_screen.dart`

**Changes:**
- Converted from `StatelessWidget` to `ConsumerWidget`
- Replaced sample data with real Firebase data:
  - `SampleCanvasData.getMostRecentCanvas()` → `ref.watch(mostRecentCanvasProvider)`
  - `SampleCanvasData.getRecentCanvases()` → `ref.watch(recentCanvasesProvider)`
- Added import for `canvas_list_provider.dart`

### 6. Updated Canvas Entity
**File**: `/lib/domain/entities/canvas_entity.dart`

**Changes:**
- Updated documentation for `state` field to clarify it's a fallback
- No breaking changes to the interface

## Architecture Decisions

### Clean Architecture Compliance
All changes follow clean architecture principles:

**Domain Layer** (`/lib/domain/`):
- No changes needed - existing entities are sufficient
- `CanvasEntity` remains pure Dart with no framework dependencies

**Data Layer** (`/lib/data/`):
- Reused existing `FirebaseDrawingRepository`
- No new repository implementations needed

**Presentation Layer** (`/lib/presentation/`):
- Created providers for state management
- Created custom painter for rendering
- Updated widgets to consume providers
- All Firebase queries isolated in providers

**Dependency Flow:**
- Presentation → Domain (correct: inward)
- Presentation → Data (via providers only)
- Domain has no dependencies (correct)

### Performance Considerations

**Efficient Rendering:**
- Preview painter scales strokes once during paint
- Uses CustomPaint for hardware-accelerated rendering
- Implements `shouldRepaint` to minimize redraws

**Data Loading:**
- Stream providers automatically manage subscriptions
- Firestore queries limited to 10 most recent canvases
- Uses Firestore's built-in caching and offline persistence

**Real-time Updates:**
- Only subscribes to canvases shown on screen
- Automatic cleanup when widgets dispose
- Prevents memory leaks with proper provider lifecycle

## How It Works

### Flow Diagram

```
User opens Home Screen
       ↓
HomeScreen widget builds
       ↓
Watches canvasListProvider (StreamProvider)
       ↓
Provider queries Firestore: collection('canvases').orderBy('lastUpdated')
       ↓
Converts Firestore docs to List<CanvasEntity>
       ↓
mostRecentCanvasProvider extracts first canvas
recentCanvasesProvider extracts remaining canvases
       ↓
ActiveCanvasCard displays mostRecentCanvas
       ↓
Watches canvasPreviewStreamProvider(canvasId)
       ↓
Provider subscribes to Firestore: doc('canvases/{canvasId}')
       ↓
Loads DrawingData with all strokes
       ↓
DrawingPreviewPainter renders strokes in preview size
       ↓
Real-time updates: Firestore emits new data → Provider updates → Widget rebuilds
```

### Data Transformation

```
Firestore Document
{
  canvasId: "abc123",
  strokes: [{id, points, color, width}, ...],
  lastUpdated: "2026-01-06T10:30:00Z",
  version: 42
}
       ↓
DrawingDataModel.fromJson()
       ↓
DrawingData (domain entity)
       ↓
DrawingPreviewPainter
       ↓
Scaled strokes rendered on screen
```

## Testing the Implementation

### Manual Testing Steps

1. **Create a canvas with drawings:**
   - Open the app
   - Create or join a canvas
   - Draw some strokes
   - Press "Done" to return to home

2. **Verify preview shows actual drawing:**
   - Home screen should show the real drawing
   - Not the dummy geometric/sketch shapes
   - Preview should update in real-time if you open the canvas again

3. **Test multiple canvases:**
   - Create multiple canvases with different drawings
   - Home screen should list them all
   - Each preview should show its unique drawing

4. **Test empty canvas:**
   - Create a canvas but don't draw anything
   - Preview should show empty state (subtle placeholder)

5. **Test real-time updates:**
   - Open a canvas from the home screen
   - Draw something
   - Return to home (don't press Done, just back button)
   - Preview should update to show new strokes

### Edge Cases Handled

1. **No canvases exist**: Shows "No active canvas" card
2. **Canvas load fails**: Falls back to dummy painter
3. **Network offline**: Uses Firestore cache, shows last known data
4. **Canvas deleted**: Provider handles gracefully, removes from list
5. **Empty canvas**: Shows subtle placeholder instead of blank
6. **Single stroke**: Renders correctly as a dot
7. **Many strokes**: Efficiently renders all strokes in preview

## Future Improvements

### Potential Enhancements

1. **Thumbnail Caching:**
   - Generate and cache thumbnail images in Firebase Storage
   - Reduces rendering load for canvases with many strokes
   - Implementation: RepaintBoundary + toImage() + upload

2. **Active User Count:**
   - Track active users per canvas in Firestore
   - Show real participant count instead of default "1"
   - Implementation: Active users collection with presence detection

3. **Canvas Metadata:**
   - Store canvas name in Firestore (user-editable)
   - Store creation timestamp for better sorting
   - Store creator user ID for ownership

4. **Lazy Loading:**
   - Load more canvases on scroll (pagination)
   - Virtual scrolling for large canvas lists
   - Implementation: Firestore cursor pagination

5. **Preview Quality Settings:**
   - User preference for preview detail level
   - Balance between performance and visual quality
   - Implementation: Stroke simplification algorithms

## Files Created/Modified

### Created Files
- `/lib/presentation/widgets/drawing_preview_painter.dart` (115 lines)
- `/lib/presentation/providers/canvas_preview_provider.dart` (47 lines)
- `/lib/presentation/providers/canvas_list_provider.dart` (137 lines)

### Modified Files
- `/lib/presentation/widgets/canvas_cards.dart`
- `/lib/presentation/screens/home_screen.dart`
- `/lib/domain/entities/canvas_entity.dart`

### Total Lines of Code
- New code: ~300 lines
- Modified code: ~50 lines
- Total impact: ~350 lines

## Conclusion

The implementation successfully replaces dummy placeholder images with actual drawing previews on the home screen. It follows clean architecture principles, maintains performance, handles edge cases gracefully, and provides real-time updates for a better user experience.

The solution is production-ready with proper error handling, efficient rendering, and follows Flutter/Dart best practices.
