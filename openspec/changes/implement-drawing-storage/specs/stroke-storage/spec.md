# Spec: Stroke Storage

## Overview
Persist drawing data as vector strokes in Firebase Firestore to enable editing, synchronization, and canvas restoration.

## ADDED Requirements

### Requirement: Vector-Based Storage Format
Drawing strokes MUST be stored as vector data (coordinate paths) rather than raster images.

#### Scenario: Stroke is saved with full fidelity
**Given** a user draws a stroke with 50 coordinate points
**When** the stroke is saved to storage
**Then** all 50 points are persisted with exact coordinates
**And** the stroke color (RGBA) is stored
**And** the stroke width is stored
**And** the timestamp and user ID are stored

#### Scenario: Canvas is restored from storage
**Given** a canvas with 100 strokes exists in storage
**When** the user reopens the canvas
**Then** all 100 strokes are loaded and rendered
**And** strokes appear in the original draw order
**And** colors and widths match the original drawing

### Requirement: Firestore Data Structure
Canvas data MUST be stored in Firestore with efficient query and sync patterns.

#### Scenario: Canvas document structure
**Given** a canvas with ID "canvas_123"
**When** the canvas is stored in Firestore
**Then** a document exists at `canvases/canvas_123`
**And** the document contains a `strokes` array field
**And** each stroke object has: id, points, color, strokeWidth, timestamp, userId
**And** the document has metadata: version, lastUpdated, strokeCount

#### Scenario: Individual stroke is added
**Given** a canvas exists with 10 strokes
**When** a new stroke is drawn
**Then** Firestore document is updated with array union operation
**And** only the new stroke data is transmitted (not entire canvas)
**And** the version number increments

### Requirement: Serialization and Deserialization
Dart entities MUST convert to/from JSON for Firestore storage.

#### Scenario: Stroke serialization
**Given** a DrawingStroke entity with Offset points
**When** the stroke is serialized to JSON
**Then** Offset objects convert to {x: double, y: double}
**And** Color converts to integer value
**And** DateTime converts to ISO 8601 string or Timestamp

#### Scenario: Stroke deserialization
**Given** JSON stroke data from Firestore
**When** the data is deserialized
**Then** a valid DrawingStroke entity is created
**And** Offset points are reconstructed
**And** Color and DateTime are correctly parsed
**And** invalid data throws a clear error

### Requirement: Stroke Identification
Each stroke MUST have a unique identifier for conflict resolution and deletion.

#### Scenario: Stroke has unique ID
**Given** a user draws a new stroke
**When** the stroke is created
**Then** a UUID is generated for the stroke
**And** the ID is immutable
**And** the ID is used for undo/redo operations

#### Scenario: Duplicate strokes are prevented
**Given** a stroke with ID "stroke_abc" exists
**When** the same stroke data arrives from sync
**Then** the stroke is not duplicated
**And** the existing stroke is preserved

### Requirement: Data Integrity
Storage operations MUST maintain canvas data integrity.

#### Scenario: Concurrent writes are handled
**Given** two users draw strokes simultaneously
**When** both strokes are saved to Firestore
**Then** both strokes are persisted
**And** no data is lost or corrupted
**And** the version field handles optimistic locking

#### Scenario: Storage failure is handled gracefully
**Given** a stroke is being saved
**When** the Firestore write fails (network error)
**Then** the stroke is queued locally
**And** the user sees an offline indicator
**And** the stroke syncs automatically when connection restored

### Requirement: Storage Quotas and Limits
Storage usage MUST stay within reasonable bounds.

#### Scenario: Canvas respects 1000 stroke limit
**Given** a canvas reaches 1000 strokes
**When** attempting to add another stroke
**Then** the operation is rejected before storage write
**And** no Firestore bandwidth is wasted

#### Scenario: Stroke data is optimized
**Given** a stroke with many points
**When** the stroke is saved
**Then** Douglas-Peucker simplification is applied (if needed)
**And** the stored point count is reasonable (<200 points)
**And** visual fidelity is preserved

## Related Capabilities
- **drawing-canvas**: Provides the stroke data to store (depends on drawing-canvas)
- **realtime-sync**: Uses storage as sync foundation (this enables realtime-sync)
- **image-export**: Reads stored strokes for export (this enables image-export)
