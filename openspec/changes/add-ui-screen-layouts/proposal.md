# Change: Add UI Screen Layouts

## Why
The application currently has only the default Flutter demo scaffold. We need to implement the core UI screens for the shared canvas app to enable users to create/join canvases, draw on the canvas, and manage their canvas sessions. This change focuses purely on UI layout and navigation without backend integration.

## What Changes
- Add canvas join/create screen with UI for entering canvas ID or creating new canvas
- Add drawing canvas screen with drawing surface and basic drawing controls (color picker, brush size, done button)
- Add canvas management/home screen showing active canvas and basic navigation
- Implement navigation structure between screens
- Add UI components: color picker widget, brush size selector, canvas preview placeholder
- Update main.dart to integrate new screen structure with Material Design theme

**Note**: This change creates UI layouts only. Backend integration, actual drawing functionality, image export, and widget communication are out of scope for this proposal.

## Impact
- Affected specs: `ui-screens` (new capability)
- Affected code:
  - `lib/main.dart` - Updated app root and navigation
  - `lib/screens/` - New directory with screen widgets
  - `lib/widgets/` - New directory with reusable UI components
  - No backend services or platform channels in this change
