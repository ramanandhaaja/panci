# user-authentication Specification

## Purpose
TBD - created by archiving change implement-user-authentication. Update Purpose after archive.
## Requirements
### Requirement: Guest User Access

The system SHALL allow users to access the app without registration as anonymous guest users.

#### Scenario: Guest user browses canvases
**Given** a user opens the app for the first time
**When** the app initializes
**Then** the system SHALL automatically sign in the user anonymously using Firebase Authentication
**And** the system SHALL create a guest user profile with `isGuest: true`
**And** the system SHALL allow the user to browse and view any canvas by entering a canvas ID
**And** the system SHALL allow the user to create exactly 1 canvas
**And** the system SHALL NOT allow the user to invite team members

#### Scenario: Guest attempts to create second canvas
**Given** a guest user has already created 1 canvas
**When** the user attempts to create a second canvas
**Then** the system SHALL display a registration prompt dialog
**And** the dialog SHALL explain "Register to create unlimited canvases"
**And** the dialog SHALL provide options to "Register Now" or "Cancel"
**And** the system SHALL NOT create the second canvas until registration is complete

#### Scenario: Guest attempts to publish canvas
**Given** a guest user has drawn on their canvas
**When** the user taps the "Publish" button
**Then** the system SHALL display a registration prompt dialog
**And** the dialog SHALL explain "Register to publish your canvas"
**And** the system SHALL provide options to "Register Now" or "Cancel"
**And** the system SHALL NOT publish the canvas until registration is complete

### Requirement: User Registration

The system SHALL provide email/password registration with username and password confirmation.

#### Scenario: New user registers successfully
**Given** a user is on the registration screen
**When** the user enters a valid username "JohnDoe"
**And** the user enters a valid email "john@example.com"
**And** the user enters a password "SecurePass123" in the password field
**And** the user enters the same password "SecurePass123" in the confirm password field
**And** the user taps "Register"
**Then** the system SHALL validate that the username is not empty
**And** the system SHALL validate that the email matches a valid email format
**And** the system SHALL validate that both password fields match
**And** the system SHALL create a Firebase Authentication user with the email and password
**And** the system SHALL create a Firestore user profile document at `/users/{userId}` with:
  - `userId`: Firebase Auth UID
  - `username`: "JohnDoe"
  - `email`: "john@example.com"
  - `canvasCount`: 0
  - `isGuest`: false
  - `createdAt`: current timestamp
  - `updatedAt`: current timestamp
**And** the system SHALL navigate to the home screen

#### Scenario: Registration validation - password mismatch
**Given** a user is on the registration screen
**When** the user enters password "Password123"
**And** the user enters confirm password "Password456"
**And** the user taps "Register"
**Then** the system SHALL display an error "Passwords do not match"
**And** the system SHALL NOT create a user account

#### Scenario: Registration validation - invalid email
**Given** a user is on the registration screen
**When** the user enters email "invalid-email"
**And** the user enters matching passwords
**And** the user taps "Register"
**Then** the system SHALL display an error "Please enter a valid email address"
**And** the system SHALL NOT create a user account

#### Scenario: Registration validation - email already exists
**Given** a user is on the registration screen
**When** the user enters email "existing@example.com" that already has an account
**And** the user enters matching passwords
**And** the user taps "Register"
**Then** Firebase SHALL return an "email-already-in-use" error
**And** the system SHALL display an error "This email is already registered. Please login instead."

### Requirement: Guest to Member Conversion

The system SHALL convert guest accounts to registered member accounts when guests register.

#### Scenario: Guest converts to member account
**Given** a guest user has created 1 canvas
**And** the guest's canvas ID is "canvas_abc123"
**When** the guest completes registration with username "Jane", email "jane@example.com", password "Pass123"
**Then** the system SHALL use Firebase `linkWithCredential()` to link the email/password to the existing anonymous account
**And** the system SHALL preserve the same Firebase Auth UID
**And** the system SHALL update the user profile document with:
  - `username`: "Jane"
  - `email`: "jane@example.com"
  - `isGuest`: false
  - `updatedAt`: current timestamp
**And** the system SHALL preserve the existing `canvasCount` value
**And** the canvas "canvas_abc123" SHALL remain owned by the same userId
**And** the user SHALL now be able to create additional canvases

### Requirement: User Login

The system SHALL provide email/password login for registered users.

#### Scenario: User logs in successfully
**Given** a registered user with email "john@example.com" and password "SecurePass123"
**When** the user enters email "john@example.com"
**And** the user enters password "SecurePass123"
**And** the user taps "Login"
**Then** the system SHALL authenticate via Firebase `signInWithEmailAndPassword()`
**And** the system SHALL load the user profile from `/users/{userId}`
**And** the system SHALL navigate to the home screen
**And** the system SHALL display the user's canvases (where user is owner or team member)

#### Scenario: Login fails with wrong password
**Given** a registered user with email "john@example.com"
**When** the user enters email "john@example.com"
**And** the user enters wrong password "WrongPass"
**And** the user taps "Login"
**Then** Firebase SHALL return "wrong-password" error
**And** the system SHALL display error "Invalid email or password"
**And** the system SHALL NOT navigate away from login screen

#### Scenario: Login fails with unregistered email
**Given** an email "nonexistent@example.com" that has no account
**When** the user enters email "nonexistent@example.com"
**And** the user enters any password
**And** the user taps "Login"
**Then** Firebase SHALL return "user-not-found" error
**And** the system SHALL display error "No account found with this email. Please register."

### Requirement: Authentication State Management

The system SHALL maintain authentication state throughout the app lifecycle.

#### Scenario: App preserves authentication on restart
**Given** a user is logged in as "john@example.com"
**When** the user closes and reopens the app
**Then** the system SHALL automatically restore the Firebase Auth session
**And** the system SHALL load the user profile from Firestore
**And** the system SHALL navigate directly to the home screen
**And** the system SHALL NOT show login screen

#### Scenario: User logs out
**Given** a logged-in user
**When** the user taps "Logout" in the settings menu
**Then** the system SHALL call `FirebaseAuth.instance.signOut()`
**And** the system SHALL clear cached user profile data
**And** the system SHALL sign in anonymously as a new guest
**And** the system SHALL navigate to the home screen in guest mode

### Requirement: Canvas Creation Limit Enforcement

The system SHALL enforce canvas creation limits based on user type.

#### Scenario: Guest canvas limit enforced in UI
**Given** a guest user has `canvasCount: 1`
**When** the home screen loads
**Then** the "Create New Canvas" button SHALL be disabled
**And** a tooltip SHALL display "Register to create unlimited canvases"
**When** the user taps the disabled button
**Then** the system SHALL show the registration prompt dialog

#### Scenario: Registered user has unlimited canvases
**Given** a registered user with `isGuest: false` and `canvasCount: 5`
**When** the home screen loads
**Then** the "Create New Canvas" button SHALL be enabled
**When** the user taps "Create New Canvas"
**Then** the system SHALL allow canvas creation
**And** the system SHALL increment `canvasCount` to 6

