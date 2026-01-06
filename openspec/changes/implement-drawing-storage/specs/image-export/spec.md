# Spec: Image Export

## Overview
Export the collaborative canvas to a PNG image for iOS widget display and sharing.

## ADDED Requirements

### Requirement: Canvas to PNG Conversion
The canvas must be rendered to a PNG image with full fidelity.

#### Scenario: Canvas exports to PNG
**Given** a canvas with 50 colored strokes
**When** the user triggers export
**Then** a PNG image is generated
**And** all strokes are visible in the image
**And** colors and line widths match the on-screen rendering
**And** the image dimensions are 2000x2000 pixels

#### Scenario: Export preserves visual quality
**Given** a complex drawing with fine details
**When** exported to PNG
**Then** the image quality is high (no visible compression artifacts)
**And** details remain crisp and clear
**And** the file size is under 500KB (with compression if needed)

### Requirement: RepaintBoundary Capture
The canvas widget must use RepaintBoundary for image capture.

#### Scenario: RepaintBoundary captures canvas
**Given** the DrawingCanvasWidget is wrapped in RepaintBoundary
**When** the export process runs
**Then** the boundary's RenderRepaintBoundary is accessed
**And** `toImage()` is called with pixelRatio 1.0 (or appropriate value)
**And** the captured image matches the visible canvas

### Requirement: Firebase Storage Upload
Exported PNG images must be uploaded to Firebase Storage for widget access.

#### Scenario: PNG uploads to Firebase Storage
**Given** a PNG has been generated
**When** the upload process starts
**Then** the image uploads to path `canvases/{canvasId}/latest.png`
**And** the upload shows progress to the user
**And** a download URL is returned on success

#### Scenario: Upload failure is handled
**Given** a PNG export succeeded
**When** the Firebase Storage upload fails (network error)
**Then** an error message is shown to the user
**And** the user can retry the upload
**And** the local PNG is retained for retry

### Requirement: Metadata Update
After successful export and upload, Firestore metadata must be updated with the image URL.

#### Scenario: Canvas metadata includes image URL
**Given** a PNG has been uploaded to Storage
**When** the upload completes
**Then** the Firestore document `canvases/{canvasId}` is updated
**And** the `imageUrl` field contains the download URL
**And** the `lastExported` timestamp is set
**And** other users can access the image URL

### Requirement: "Done" Button Integration
The existing "Done" button must trigger export and upload.

#### Scenario: User completes drawing
**Given** the user has drawn on the canvas
**When** the user taps the "Done" button
**Then** a confirmation dialog appears ("Finish Drawing?")
**And** if confirmed, the export process starts
**And** a loading indicator shows "Exporting canvas..."
**And** on success, the user navigates back to the home screen

#### Scenario: Export process shows progress
**Given** the user has tapped "Done"
**When** the export and upload are in progress
**Then** a progress dialog shows the current step:
  - "Rendering image..." (PNG generation)
  - "Uploading to cloud..." (Storage upload)
  - "Finalizing..." (Firestore update)
**And** the user cannot dismiss the dialog (must complete)

### Requirement: Image Compression
Large images must be compressed to meet file size targets.

#### Scenario: Large canvas is compressed
**Given** a canvas exports to a 2MB PNG
**When** compression is applied
**Then** the file size is reduced to under 500KB
**And** visual quality remains acceptable
**And** the compression algorithm is efficient (<1s for 2000x2000 image)

### Requirement: Widget Refresh Trigger
After export and upload, the iOS widget must be notified to refresh.

#### Scenario: Widget refresh is triggered
**Given** the PNG has been uploaded and metadata updated
**When** the export process completes
**Then** the WidgetRefreshService is called
**And** the image is saved to the App Group shared container
**And** the platform channel invokes `WidgetCenter.reloadTimelines()`
**And** the iOS widget updates (with WidgetKit timing)

#### Scenario: Widget displays exported image
**Given** the widget refresh has been triggered
**When** the widget's TimelineProvider runs
**Then** the widget reads the image from the shared container
**And** the widget displays the latest canvas rendering
**And** if the image is unavailable, a placeholder is shown

## Related Capabilities
- **stroke-storage**: Provides the strokes to render (depends on stroke-storage)
- **drawing-canvas**: Renders the visual canvas for capture (depends on drawing-canvas)
- **iOS widget** (future change): Consumes the exported image (this enables widget)
