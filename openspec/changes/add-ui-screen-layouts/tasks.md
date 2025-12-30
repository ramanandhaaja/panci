# Implementation Tasks

## 1. Screen Structure Setup
- [x] 1.1 Create `lib/screens/` directory
- [x] 1.2 Create `lib/widgets/` directory for reusable components
- [x] 1.3 Update `lib/main.dart` to set up navigation and theme

## 2. Canvas Join/Create Screen
- [x] 2.1 Create `lib/screens/canvas_join_screen.dart`
- [x] 2.2 Add text input field for canvas ID
- [x] 2.3 Add "Join Canvas" button
- [x] 2.4 Add "Create New Canvas" button
- [x] 2.5 Add basic validation UI (show errors for empty input)
- [x] 2.6 Add navigation to drawing screen (placeholder transition)

## 3. Drawing Canvas Screen
- [x] 3.1 Create `lib/screens/drawing_canvas_screen.dart`
- [x] 3.2 Add canvas container (placeholder for drawing surface)
- [x] 3.3 Add app bar with canvas ID display and "Done" button
- [x] 3.4 Create color picker widget in `lib/widgets/color_picker.dart`
- [x] 3.5 Create brush size selector widget in `lib/widgets/brush_size_selector.dart`
- [x] 3.6 Add drawing controls toolbar at bottom
- [x] 3.7 Add "Done" button action (show dialog or navigate back)

## 4. Canvas Management/Home Screen
- [x] 4.1 Create `lib/screens/home_screen.dart`
- [x] 4.2 Add active canvas display section
- [x] 4.3 Add navigation button to join/create screen
- [x] 4.4 Add placeholder for canvas preview image
- [x] 4.5 Add basic layout with Material Design components

## 5. Navigation and Theme
- [x] 5.1 Configure MaterialApp with routes
- [x] 5.2 Set up named routes for all screens
- [x] 5.3 Apply consistent theme (colors, typography)
- [x] 5.4 Test navigation flow between all screens

## 6. Testing and Polish
- [x] 6.1 Manual test navigation flow: home → join → drawing → back
- [x] 6.2 Verify responsive layout on different screen sizes
- [x] 6.3 Ensure Material Design guidelines followed
- [x] 6.4 Remove default Flutter demo code
- [x] 6.5 Run `flutter analyze` and fix any issues
