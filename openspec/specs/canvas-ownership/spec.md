# canvas-ownership Specification

## Purpose
TBD - created by archiving change implement-user-authentication. Update Purpose after archive.
## Requirements
### Requirement: Canvas Creation with Ownership

The system SHALL assign ownership to canvases when they are created.

#### Scenario: Registered user creates canvas
**Given** a registered user with userId "user123" and canvasCount 2
**When** the user taps "Create New Canvas"
**And** the user enters canvas name "My Drawing"
**And** confirms creation
**Then** the system SHALL generate a unique canvasId
**And** the system SHALL create a canvas document at `/canvases/{canvasId}` with:
  - `canvasId`: generated ID
  - `ownerId`: "user123"
  - `teamMembers`: [] (empty array)
  - `isPrivate`: true
  - `strokes`: []
  - `lastUpdated`: current timestamp
  - `version`: 0
  - `imageUrl`: null
  - `lastExported`: null
**And** the system SHALL increment the user's `canvasCount` from 2 to 3
**And** the system SHALL navigate to the drawing canvas screen

#### Scenario: Guest user creates their first canvas
**Given** a guest user with userId "guest456" and canvasCount 0
**When** the user creates a canvas
**Then** the system SHALL create the canvas with `ownerId`: "guest456"
**And** the system SHALL increment `canvasCount` from 0 to 1
**And** the system SHALL set `isPrivate`: true

### Requirement: Canvas Access Control

The system SHALL enforce private access to canvas data based on ownership and team membership.

#### Scenario: Owner accesses their private canvas
**Given** a canvas with ownerId "user123" and isPrivate true
**When** user "user123" attempts to load the canvas
**Then** the system SHALL allow access
**And** the system SHALL load the canvas strokes from Firestore
**And** the system SHALL display the drawing canvas screen

#### Scenario: Team member accesses canvas
**Given** a canvas with ownerId "user123" and teamMembers ["user456", "user789"]
**When** user "user456" attempts to load the canvas
**Then** the system SHALL verify "user456" is in the teamMembers array
**And** the system SHALL allow access
**And** the system SHALL load the canvas strokes

#### Scenario: Non-member attempts to access private canvas
**Given** a canvas with ownerId "user123" and teamMembers ["user456"]
**When** user "user999" attempts to load the canvas by entering the canvas ID
**Then** the system SHALL check if "user999" is owner or in teamMembers
**And** the system SHALL deny access
**And** the system SHALL display error "You do not have permission to access this canvas"
**And** the system SHALL NOT load any canvas data

#### Scenario: Guest attempts to access private canvas
**Given** a canvas with ownerId "user123"
**When** a guest user attempts to load the canvas
**Then** the system SHALL deny access
**And** the system SHALL display error "This canvas is private. Please register and request access from the owner."

### Requirement: Team Member Management

The system SHALL allow canvas owners to invite and remove team members.

#### Scenario: Owner invites team member
**Given** a canvas owned by "user123" with empty teamMembers
**And** the owner is viewing the canvas
**When** the owner taps "Invite Team Member"
**And** enters user ID "user456"
**And** confirms the invitation
**Then** the system SHALL verify that "user456" exists in `/users/user456`
**And** the system SHALL add "user456" to the canvas's teamMembers array
**And** the system SHALL update the canvas document in Firestore with teamMembers: ["user456"]
**And** the system SHALL display success message "user456 added to team"

#### Scenario: Owner removes team member
**Given** a canvas owned by "user123" with teamMembers ["user456", "user789"]
**When** the owner selects "user456" from the team list
**And** taps "Remove from Team"
**And** confirms the removal
**Then** the system SHALL remove "user456" from the teamMembers array
**And** the system SHALL update Firestore with teamMembers: ["user789"]
**And** the system SHALL display "user456 removed from team"

#### Scenario: Non-owner attempts to invite team member
**Given** a canvas owned by "user123"
**And** "user456" is a team member (not owner)
**When** "user456" attempts to invite "user789"
**Then** the system SHALL check if "user456" is the owner
**And** the system SHALL deny the operation
**And** the system SHALL display error "Only the canvas owner can invite team members"

#### Scenario: Owner invites non-existent user
**Given** a canvas owned by "user123"
**When** the owner attempts to invite user ID "nonexistent999"
**Then** the system SHALL query `/users/nonexistent999`
**And** Firestore SHALL return no document
**And** the system SHALL display error "User not found. Please check the user ID."
**And** the system SHALL NOT add to teamMembers

### Requirement: Canvas Drawing Permissions

The system SHALL enforce drawing permissions based on ownership and team membership.

#### Scenario: Owner draws on their canvas
**Given** a canvas owned by "user123"
**And** user "user123" has loaded the canvas
**When** the user draws a stroke
**Then** the system SHALL allow the stroke operation
**And** the system SHALL save the stroke to Firestore with userId "user123"
**And** the system SHALL update the canvas version
**And** the stroke SHALL appear in real-time for all team members viewing the canvas

#### Scenario: Team member draws on canvas
**Given** a canvas owned by "user123" with teamMembers ["user456"]
**And** user "user456" has loaded the canvas
**When** "user456" draws a stroke
**Then** the system SHALL allow the stroke operation
**And** the system SHALL save the stroke with userId "user456"
**And** the stroke SHALL sync to all authorized viewers

#### Scenario: Non-member attempts to draw
**Given** a canvas owned by "user123"
**When** user "user999" (not owner or team member) attempts to save a stroke
**Then** the Firestore security rules SHALL reject the write operation
**And** the system SHALL receive a permission-denied error
**And** the system SHALL display "You do not have permission to edit this canvas"

### Requirement: Canvas Publishing Permissions

The system SHALL enforce publishing permissions based on ownership and team membership.

#### Scenario: Owner publishes canvas
**Given** a canvas owned by "user123"
**And** the owner has drawn strokes on the canvas
**When** the owner taps "Publish"
**And** confirms the publish action
**Then** the system SHALL generate a PNG image from the canvas
**And** the system SHALL upload the PNG to Firebase Storage at `canvases/{canvasId}/latest.png`
**And** the system SHALL update the canvas document with the imageUrl
**And** the system SHALL update lastExported timestamp
**And** the published image SHALL be publicly accessible via the imageUrl

#### Scenario: Team member publishes canvas
**Given** a canvas owned by "user123" with teamMembers ["user456"]
**And** user "user456" has drawn on the canvas
**When** "user456" taps "Publish"
**Then** the system SHALL verify "user456" is owner or team member
**And** the system SHALL allow the publish operation
**And** the system SHALL generate and upload the PNG

#### Scenario: Non-member attempts to publish canvas
**Given** a canvas owned by "user123"
**When** user "user999" attempts to publish the canvas
**Then** the system SHALL deny the operation before generating PNG
**And** the system SHALL display error "You do not have permission to publish this canvas"

### Requirement: Widget Public View

The system SHALL allow public read access to published canvas images for widget display.

#### Scenario: Anyone views published image via widget
**Given** a canvas with published imageUrl "https://storage.googleapis.com/.../canvas_abc.png"
**When** any user (guest or registered) accesses the imageUrl directly
**Then** Firebase Storage rules SHALL allow public read access
**And** the PNG image SHALL be returned
**And** the system SHALL NOT require authentication for image download
**And** the widget SHALL display the image even for users not on the team

#### Scenario: Widget fetches latest canvas image
**Given** a canvas ID "canvas_abc123" shared with a widget user
**When** the widget loads
**And** the widget queries `/canvases/canvas_abc123` for the imageUrl field
**Then** Firestore rules SHALL allow reading only the imageUrl field for public access
**And** the widget SHALL NOT be able to read the strokes array
**And** the widget SHALL download and display the image from the imageUrl

### Requirement: Canvas Deletion

The system SHALL allow canvas owners to delete their canvases and update canvas count.

#### Scenario: Owner deletes canvas
**Given** a canvas owned by "user123"
**And** the owner's canvasCount is 5
**When** the owner taps "Delete Canvas"
**And** confirms deletion
**Then** the system SHALL delete the canvas document from `/canvases/{canvasId}`
**And** the system SHALL delete the canvas image from Firebase Storage (if exists)
**And** the system SHALL decrement the owner's canvasCount from 5 to 4
**And** the system SHALL navigate back to home screen

#### Scenario: Team member cannot delete canvas
**Given** a canvas owned by "user123" with teamMembers ["user456"]
**When** team member "user456" attempts to delete the canvas
**Then** the system SHALL check if "user456" is the owner
**And** the system SHALL deny the operation
**And** the system SHALL display error "Only the owner can delete this canvas"

### Requirement: Firestore Security Rules

The system SHALL enforce all ownership and privacy rules at the database level.

#### Scenario: Security rules enforce canvas read access
**Given** Firestore security rules are deployed
**And** a canvas with ownerId "user123" and teamMembers ["user456"]
**When** user "user789" attempts to read `/canvases/{canvasId}` directly via SDK
**Then** Firestore SHALL evaluate the rule:
```
allow read: if request.auth.uid == resource.data.ownerId ||
            request.auth.uid in resource.data.teamMembers;
```
**And** the read SHALL be denied for "user789"
**And** Firebase SDK SHALL throw a permission-denied exception

#### Scenario: Security rules enforce canvas write access
**Given** Firestore security rules are deployed
**When** user "user999" attempts to update a canvas they don't own
**Then** Firestore SHALL evaluate ownership rules
**And** the write SHALL be denied
**And** Firestore SHALL reject the operation

#### Scenario: Security rules validate canvas structure
**Given** a user attempts to create a canvas
**When** the canvas document is missing the ownerId field
**Then** Firestore SHALL validate required fields:
```
request.resource.data.keys().hasAll(['canvasId', 'ownerId', 'teamMembers', 'isPrivate', 'strokes', 'lastUpdated', 'version'])
```
**And** the write SHALL be denied
**And** Firestore SHALL return a validation error

