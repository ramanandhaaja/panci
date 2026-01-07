# Capability: UI Screens

## ADDED Requirements

### Requirement: Canvas Join/Create Screen
The application SHALL provide a screen for users to join existing canvases or create new ones.

#### Scenario: Display join canvas form
- **WHEN** user opens the canvas join/create screen
- **THEN** a text input field for canvas ID is displayed
- **AND** a "Join Canvas" button is displayed
- **AND** a "Create New Canvas" button is displayed

#### Scenario: Navigate to drawing screen on join
- **WHEN** user taps "Join Canvas" with valid canvas ID
- **THEN** navigate to the drawing canvas screen
- **AND** display the entered canvas ID

#### Scenario: Navigate to drawing screen on create
- **WHEN** user taps "Create New Canvas"
- **THEN** navigate to the drawing canvas screen
- **AND** display a placeholder canvas ID

#### Scenario: Show validation error for empty input
- **WHEN** user taps "Join Canvas" with empty canvas ID
- **THEN** display error message indicating canvas ID is required

### Requirement: Drawing Canvas Screen
The application SHALL provide a screen with a drawing surface and drawing controls.

#### Scenario: Display drawing canvas layout
- **WHEN** user opens the drawing canvas screen
- **THEN** a canvas container occupying most of screen space is displayed
- **AND** an app bar showing canvas ID and "Done" button is displayed
- **AND** a bottom toolbar with drawing controls is displayed

#### Scenario: Display color picker
- **WHEN** drawing canvas screen is displayed
- **THEN** a color picker widget showing available colors is visible in the toolbar
- **AND** user can visually identify the currently selected color

#### Scenario: Display brush size selector
- **WHEN** drawing canvas screen is displayed
- **THEN** a brush size selector showing size options is visible in the toolbar
- **AND** user can visually identify the currently selected brush size

#### Scenario: Handle done button tap
- **WHEN** user taps the "Done" button
- **THEN** show a confirmation dialog or navigate back to previous screen

### Requirement: Canvas Management/Home Screen
The application SHALL provide a home screen for managing canvas sessions.

#### Scenario: Display home screen layout
- **WHEN** user opens the home screen
- **THEN** an active canvas section is displayed
- **AND** a button to navigate to join/create screen is displayed
- **AND** a placeholder for canvas preview image is displayed

#### Scenario: Navigate to join/create screen
- **WHEN** user taps the join/create navigation button
- **THEN** navigate to the canvas join/create screen

### Requirement: Navigation Structure
The application SHALL provide navigation between screens following Material Design patterns.

#### Scenario: Configure named routes
- **WHEN** the application starts
- **THEN** named routes for home, join/create, and drawing screens are registered
- **AND** the home screen is set as the initial route

#### Scenario: Navigate between screens
- **WHEN** user navigates from one screen to another
- **THEN** smooth transition animation is applied
- **AND** back button navigation works correctly

### Requirement: UI Theme and Styling
The application SHALL apply consistent Material Design theme across all screens.

#### Scenario: Apply app-wide theme
- **WHEN** the application renders any screen
- **THEN** consistent color scheme is applied
- **AND** consistent typography is applied
- **AND** Material Design 3 components are used

#### Scenario: Responsive layout
- **WHEN** screen is displayed on different device sizes
- **THEN** UI adapts to available screen space
- **AND** all interactive elements remain accessible

### Requirement: Code Organization
The application SHALL organize UI code following Flutter best practices.

#### Scenario: Screen files location
- **WHEN** examining the codebase
- **THEN** all screen widgets are located in `lib/screens/` directory
- **AND** each screen is in its own file

#### Scenario: Reusable widgets location
- **WHEN** examining the codebase
- **THEN** reusable UI components are located in `lib/widgets/` directory
- **AND** each widget is in its own file

#### Scenario: Remove demo code
- **WHEN** examining `lib/main.dart`
- **THEN** default Flutter demo code is removed
- **AND** only production application code remains
