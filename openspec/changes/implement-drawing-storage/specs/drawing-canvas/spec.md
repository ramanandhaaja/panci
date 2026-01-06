# Spec: Drawing Canvas

## Overview
Enable users to draw on a collaborative canvas using touch gestures with smooth, natural-looking strokes.

## ADDED Requirements

### Requirement: Interactive Canvas Widget
The system SHALL enable users to draw freehand strokes on a canvas using touch gestures.

#### Scenario: User draws a simple stroke
**Given** the drawing canvas screen is open
**When** the user touches the canvas and drags their finger
**Then** a smooth line appears following their finger movement
**And** the line uses the currently selected color and brush size
**And** the drawing responds with <50ms input latency

#### Scenario: User draws multiple strokes
**Given** the user has drawn one stroke
**When** the user lifts their finger and starts a new stroke
**Then** the previous stroke remains visible
**And** the new stroke appears as a separate path
**And** both strokes can be individually managed (undo/redo)

### Requirement: Fixed Canvas Dimensions
The canvas MUST have consistent dimensions across all devices to ensure collaborative drawings look the same for everyone.

#### Scenario: Canvas renders on different screen sizes
**Given** the canvas is 2000x2000 pixels
**When** the app runs on different device screen sizes
**Then** the canvas scales proportionally to fit the screen
**And** the aspect ratio remains 1:1 (square)
**And** drawing coordinates map correctly regardless of screen size

### Requirement: Stroke Smoothing
Strokes MUST be smoothed to create natural-looking curves rather than jagged lines.

#### Scenario: User draws a curved line slowly
**Given** the user draws a curve at low speed
**When** the stroke is rendered
**Then** the line appears smooth without visible angles or jaggedne ss
**And** Catmull-Rom spline interpolation is applied
**And** the smoothed stroke maintains the general shape of the input

#### Scenario: User draws quick gestures
**Given** the user draws rapid strokes
**When** the strokes are rendered
**Then** smoothing is applied without introducing lag
**And** the visual result feels responsive

### Requirement: Undo/Redo Functionality
The system SHALL provide undo and redo functionality for drawing actions.

#### Scenario: User undoes last stroke
**Given** the user has drawn 3 strokes
**When** the user taps the undo button
**Then** the most recent stroke disappears
**And** the undo button remains enabled if more strokes exist
**And** the redo button becomes enabled

#### Scenario: User redoes undone stroke
**Given** the user has undone 2 strokes
**When** the user taps the redo button
**Then** the most recently undone stroke reappears
**And** the redo button remains enabled if more undone actions exist

#### Scenario: User draws after undo
**Given** the user has undone some strokes
**When** the user draws a new stroke
**Then** the redo stack is cleared (no longer can redo)
**And** the new stroke becomes the latest in history

### Requirement: Stroke Limit Enforcement
The canvas MUST enforce a maximum of 1000 strokes to maintain performance.

#### Scenario: User approaches stroke limit
**Given** the canvas has 900 strokes
**When** the user views the canvas
**Then** a warning indicator shows "900/1000 strokes"
**And** the user can continue drawing

#### Scenario: User reaches stroke limit
**Given** the canvas has 1000 strokes
**When** the user attempts to draw a new stroke
**Then** drawing is disabled
**And** a message indicates the canvas is full
**And** the user can still undo to make room for new strokes

### Requirement: Visual Feedback
The canvas SHALL provide clear visual feedback for user interactions.

#### Scenario: User selects different colors
**Given** the color picker is available
**When** the user selects a new color
**Then** subsequent strokes use the new color
**And** existing strokes retain their original colors

#### Scenario: User changes brush size
**Given** the brush size selector is available
**When** the user selects a different brush size
**Then** subsequent strokes use the new width
**And** a visual preview shows the selected size

## Related Capabilities
- **stroke-storage**: Drawing data must persist (depends on this)
- **realtime-sync**: Strokes must sync across devices (depends on this)
- **live-presence**: User cursors overlay on canvas (complements this)
