# Spec: Live Presence

## Overview
Show real-time cursors of active users on the collaborative canvas to create an engaging multi-user experience.

## ADDED Requirements

### Requirement: Active User Tracking
The system must track which users are currently viewing and drawing on each canvas.

#### Scenario: User joins canvas
**Given** a user opens a canvas
**When** the canvas screen initializes
**Then** the user is added to the active users collection
**And** the user's presence data is stored in Firestore: `canvases/{canvasId}/active_users/{userId}`
**And** presence includes: userId, displayName, cursorColor, lastSeen

#### Scenario: User leaves canvas
**Given** a user is active on a canvas
**When** the user navigates away or closes the app
**Then** the user's presence document is removed
**And** other users no longer see their cursor
**And** the cleanup happens within 5 seconds

#### Scenario: Inactive user detection
**Given** a user's app is backgrounded or frozen
**When** no cursor updates occur for 3 seconds
**Then** the user's cursor fades out on other devices
**And** the user is marked as inactive
**And** the cursor is removed from rendering

### Requirement: Cursor Position Broadcasting
Users must broadcast their cursor position to other active users.

#### Scenario: User draws on canvas
**Given** the user is touching the canvas
**When** the finger moves
**Then** cursor position updates are sent to Firestore
**And** updates are throttled to 100ms intervals (10 updates/second max)
**And** the cursor position is stored as `{x: double, y: double}`

#### Scenario: User stops drawing
**Given** the user lifts their finger from the canvas
**When** no touch input is detected
**Then** the cursor position is set to null
**And** the cursor no longer renders on other devices
**And** the user remains in the active users list

### Requirement: Cursor Visualization
Other users' cursors must be rendered on the local canvas in real-time.

#### Scenario: Other users' cursors are shown
**Given** User A and User B are on the same canvas
**When** User A moves their finger
**Then** User B sees a cursor dot at User A's position
**And** the cursor dot uses User A's assigned color
**And** the cursor shows User A's initials or avatar inside
**And** the cursor position updates smoothly (interpolated if needed)

#### Scenario: Multiple cursors are distinguished
**Given** 3 users are drawing simultaneously
**When** viewing the canvas
**Then** each user's cursor has a unique color
**And** colors are assigned deterministically (based on userId hash)
**And** cursors do not overlap confusingly
**And** all cursors are visible above the drawing strokes

#### Scenario: Cursor rendering performance
**Given** 5 users are active with moving cursors
**When** rendering the canvas
**Then** cursor updates do not degrade drawing performance
**And** the canvas maintains 60 FPS
**And** cursor rendering uses a separate overlay layer

### Requirement: Presence State Management
The app must manage presence state efficiently.

#### Scenario: Presence provider subscribes to updates
**Given** the PresenceProvider initializes
**When** the canvas opens
**Then** a Firestore listener subscribes to `active_users` collection
**And** incoming presence updates trigger UI repaints
**And** stale users (>3s since last update) are filtered out

#### Scenario: Local cursor updates
**Given** the user is drawing
**When** onPanUpdate events fire
**Then** the local cursor position updates in the provider
**And** the position is debounced/throttled before Firestore write
**And** the provider notifies the CursorPainter to repaint

### Requirement: Network Efficiency
Cursor updates must be efficient to avoid excessive Firestore usage.

#### Scenario: Cursor updates are throttled
**Given** the user draws rapidly
**When** cursor position changes 60 times per second (60 FPS)
**Then** only 10 updates per second are sent to Firestore
**And** intermediate positions are skipped
**And** the latest position is always sent

#### Scenario: Idle cursors stop updates
**Given** a user's cursor is idle (not moving)
**When** no new position updates occur
**Then** no Firestore writes are made
**And** the last known position is retained
**And** bandwidth is preserved

### Requirement: User Identification
Users must have identifiable display names or avatars for their cursors.

#### Scenario: User has display name
**Given** a user is authenticated
**When** their cursor appears
**Then** their display name (or initials) is shown
**And** if no name exists, a placeholder (e.g., "User 1") is used

#### Scenario: Anonymous users are handled
**Given** a user signed in anonymously
**When** joining a canvas
**Then** a generated name like "Guest_abc12" is assigned
**And** the name is consistent for the session
**And** the cursor color is deterministic based on userId

### Requirement: Cursor Color Assignment
Each user must have a unique, visually distinct cursor color.

#### Scenario: Cursor color is assigned
**Given** a user joins a canvas
**When** their presence is initialized
**Then** a color is selected from a predefined palette
**And** the color is deterministic (hash of userId)
**And** colors are visually distinct (sufficient contrast)

#### Scenario: Color conflicts are minimized
**Given** 10 users are on the same canvas
**When** cursor colors are assigned
**Then** no two adjacent users have identical colors
**And** the palette has at least 12 distinct colors

## Related Capabilities
- **realtime-sync**: Uses same Firestore infrastructure (parallel capability)
- **drawing-canvas**: Cursors overlay on the drawing canvas (depends on drawing-canvas)
- **stroke-storage**: No direct dependency, but uses Firestore (parallel capability)
