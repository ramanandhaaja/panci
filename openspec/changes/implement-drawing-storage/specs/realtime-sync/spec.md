# Spec: Real-time Synchronization

## Overview
Synchronize drawing strokes across multiple devices in real-time using Firestore listeners, enabling collaborative drawing.

## ADDED Requirements

### Requirement: Real-time Stroke Broadcasting
When a user draws a stroke, it MUST appear on other users' devices within acceptable latency.

#### Scenario: Stroke syncs to other devices
**Given** User A and User B are viewing the same canvas
**When** User A draws a stroke
**Then** User B sees the stroke within 500ms
**And** the stroke appears with correct color and width
**And** the stroke is attributed to User A (userId field)

#### Scenario: Multiple strokes sync in order
**Given** User A draws strokes 1, 2, 3 in sequence
**When** the strokes sync to User B
**Then** User B sees them in order: 1, 2, 3
**And** timestamps preserve the draw order
**And** no strokes are skipped or duplicated

### Requirement: Firestore Real-time Listeners
The app MUST subscribe to Firestore snapshot listeners for live updates.

#### Scenario: App subscribes to canvas updates
**Given** a user opens a canvas
**When** the DrawingProvider initializes
**Then** a Firestore snapshot listener is established
**And** the listener streams updates to the canvas document
**And** incoming strokes trigger UI updates

#### Scenario: Listener handles updates efficiently
**Given** the listener is active
**When** a new stroke is added to Firestore
**Then** only the delta (new stroke) is processed
**And** the entire canvas is not re-downloaded
**And** the UI repaints only affected areas

### Requirement: Multi-User Collaboration
Multiple users MUST be able to draw simultaneously without conflicts.

#### Scenario: Two users draw at the same time
**Given** User A and User B are on the same canvas
**When** both users draw different strokes simultaneously
**Then** both strokes are saved to Firestore
**And** both users see both strokes
**And** no strokes overwrite each other

#### Scenario: User identifies stroke ownership
**Given** multiple users have drawn on the canvas
**When** viewing the canvas
**Then** strokes can be attributed to their creators (userId)
**And** (optional) strokes show different colors per user
**And** undo only affects the current user's strokes

### Requirement: Offline Support
The app MUST handle offline scenarios gracefully and sync when connection is restored.

#### Scenario: User draws while offline
**Given** the device loses network connection
**When** the user draws strokes
**Then** strokes are rendered locally immediately
**And** strokes are queued for later sync
**And** an offline indicator is shown

#### Scenario: User reconnects after offline drawing
**Given** the user drew 5 strokes while offline
**When** network connection is restored
**Then** queued strokes upload to Firestore
**And** other users see the offline-drawn strokes
**And** the offline indicator disappears

#### Scenario: Conflicting offline changes
**Given** User A and User B both draw offline on the same canvas
**When** both reconnect and sync
**Then** all strokes from both users are merged
**And** strokes are ordered by timestamp
**And** no strokes are lost (last-write-wins at stroke level)

### Requirement: Connection Status Visibility
Users MUST know if they are connected and syncing properly.

#### Scenario: Connection status indicator
**Given** the user is viewing the canvas
**When** the Firestore connection is active
**Then** a "Connected" indicator shows (green)
**And** strokes sync in real-time

#### Scenario: Disconnection indicator
**Given** the user is viewing the canvas
**When** the Firestore connection drops
**Then** the indicator changes to "Offline" (gray)
**And** the user can still draw (queued locally)

### Requirement: Sync Performance
Synchronization MUST not degrade user experience.

#### Scenario: High-frequency drawing sync
**Given** a user draws rapidly (10 strokes/second)
**When** strokes are synced to Firestore
**Then** sync operations are batched or throttled
**And** the app remains responsive (no UI lag)
**And** Firestore write costs are reasonable

#### Scenario: Large canvas load time
**Given** a canvas with 1000 strokes
**When** a user opens the canvas
**Then** strokes load within 2 seconds
**And** progressive rendering is used if needed
**And** the user can start drawing before all strokes load

### Requirement: Data Consistency
Canvas state MUST remain consistent across all devices.

#### Scenario: Version conflicts are detected
**Given** two devices have different versions of the canvas
**When** both attempt to write strokes
**Then** the version field detects the conflict
**And** optimistic locking prevents data loss
**And** conflicting strokes are merged intelligently

## Related Capabilities
- **stroke-storage**: Provides the storage layer for sync (depends on stroke-storage)
- **drawing-canvas**: Provides local strokes to sync (depends on drawing-canvas)
- **live-presence**: Complements sync with user cursors (parallel capability)
