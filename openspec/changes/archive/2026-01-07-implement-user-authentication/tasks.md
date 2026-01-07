# Tasks: Implement User Authentication

## Phase 1: Data Migration & Cleanup

### 1.1 Backup and Clear Existing Data
- [ ] Export existing Firestore data for reference (optional backup)
- [ ] Delete all documents in `/canvases` collection via Firebase Console
- [ ] Delete all documents in `/users` collection (if exists)
- [ ] Verify collections are empty
- [ ] **Validation**: Firestore collections are clean

## Phase 2: Domain Layer - Entities & Repositories

### 2.1 Create User Entity
- [ ] Create `lib/domain/entities/user.dart`
  - Immutable class with: userId, username, email, canvasCount, isGuest, createdAt, updatedAt
  - Add copyWith, equality, hashCode, toString methods
- [ ] **Validation**: `flutter analyze` - no errors

### 2.2 Update Canvas Entity
- [ ] Modify `lib/domain/entities/drawing_data.dart`
  - Add `ownerId` field (String)
  - Add `teamMembers` field (List<String>)
  - Add `isPrivate` field (bool, default: true)
  - Update copyWith to include new fields
  - Update equality to include new fields
- [ ] **Validation**: Existing tests still pass, `flutter test`

### 2.3 Create User Repository Interface
- [ ] Create `lib/domain/repositories/user_repository.dart`
  - Abstract interface with methods:
    - `Future<User> createUser({userId, username, email, isGuest})`
    - `Future<User> getUserProfile(String userId)`
    - `Future<void> updateUser(User user)`
    - `Future<void> incrementCanvasCount(String userId)`
    - `Future<void> decrementCanvasCount(String userId)`
    - `Future<void> convertGuestToMember({userId, username, email})`
- [ ] **Validation**: Interface compiles

### 2.4 Update Drawing Repository Interface
- [ ] Modify `lib/domain/repositories/drawing_repository.dart`
  - Add `Future<bool> checkCanvasAccess(String canvasId, String userId)`
  - Add `Future<void> addTeamMember(String canvasId, String userId)`
  - Add `Future<void> removeTeamMember(String canvasId, String userId)`
  - Update loadCanvas signature to include userId parameter (optional, for access check)
- [ ] **Validation**: Interface compiles

## Phase 3: Data Layer - Models & Repositories

### 3.1 Create User Data Model
- [ ] Create `lib/data/models/user_model.dart`
  - Implement toJson, fromJson methods
  - Implement toEntity, fromEntity conversion
  - Handle DateTime serialization (ISO strings)
- [ ] Create `test/data/models/user_model_test.dart`
  - Test JSON roundtrip
  - Test entity conversion
  - At least 10 tests covering all fields
- [ ] **Validation**: `flutter test` - all user model tests pass

### 3.2 Update Canvas Data Model
- [ ] Modify `lib/data/models/drawing_data_model.dart`
  - Add ownerId, teamMembers, isPrivate to toJson/fromJson
  - Update toEntity, fromEntity to handle new fields
  - Provide defaults: teamMembers=[], isPrivate=true
- [ ] Update `test/data/models/drawing_data_model_test.dart`
  - Add tests for new ownership fields
  - Test default values
  - At least 5 new tests
- [ ] **Validation**: `flutter test` - canvas model tests pass

### 3.3 Implement Firebase User Repository
- [ ] Create `lib/data/repositories/firebase_user_repository.dart`
  - Implement UserRepository interface
  - Collection path: `/users/{userId}`
  - Implement createUser (create Firestore document)
  - Implement getUserProfile (read document, convert to entity)
  - Implement updateUser (update document)
  - Implement incrementCanvasCount (use FieldValue.increment(1))
  - Implement decrementCanvasCount (use FieldValue.increment(-1))
  - Implement convertGuestToMember (update isGuest, username, email)
  - Add error handling and logging
- [ ] **Validation**: Manual test - create user, read profile

### 3.4 Update Firebase Drawing Repository
- [ ] Modify `lib/data/repositories/firebase_drawing_repository.dart`
  - Update loadCanvas to accept userId, check ownership before loading
  - Implement checkCanvasAccess:
    - Read canvas document
    - Return true if userId == ownerId OR userId in teamMembers
  - Implement addTeamMember:
    - Use Firestore `arrayUnion` to add userId to teamMembers
    - Verify user exists first
  - Implement removeTeamMember:
    - Use Firestore `arrayRemove` to remove userId from teamMembers
  - Update saveStroke to verify access before saving
- [ ] **Validation**: Manual test - access control works

## Phase 4: Firestore Security Rules

### 4.1 Update Firestore Rules
- [ ] Modify `firestore.rules`
  - Add helper function: `isOwnerOrTeamMember(userId)`
  - Update `/canvases/{canvasId}` rules:
    - `allow read: if isOwnerOrTeamMember(request.auth.uid)`
    - `allow create: if isAuthenticated() && request.resource.data.ownerId == request.auth.uid && isValidCanvas()`
    - `allow update: if isOwnerOrTeamMember(request.auth.uid) && isValidCanvas()`
    - `allow delete: if request.auth.uid == resource.data.ownerId`
  - Update `isValidCanvas()` to require ownerId, teamMembers, isPrivate fields
  - Add `/users/{userId}` rules:
    - `allow read: if isAuthenticated()`
    - `allow create, update: if request.auth.uid == userId`
  - Add canvas count validation for guests:
    - Check `get(/databases/$(database)/documents/users/$(request.auth.uid)).data.canvasCount < 1` for isGuest==true
- [ ] **Validation**: Deploy rules, test in Firestore Rules Playground

### 4.2 Deploy Security Rules
- [ ] Run `firebase deploy --only firestore:rules`
- [ ] Verify deployment success in Firebase Console
- [ ] **Validation**: Rules active in production

### 4.3 Update Storage Rules
- [ ] Modify `storage.rules`
  - Keep read: public (for widgets)
  - Update write rules to check canvas ownership:
    - Extract canvasId from path
    - Check if request.auth.uid is owner or team member
  - Add comment explaining widget public access
- [ ] Deploy: `firebase deploy --only storage`
- [ ] **Validation**: Storage rules deployed

## Phase 5: Presentation Layer - Providers

### 5.1 Create Auth Provider
- [ ] Create `lib/presentation/providers/auth_provider.dart`
  - StateNotifier<AuthState> with states: loading, authenticated, unauthenticated
  - Method: `signInAnonymously()` - auto-create guest user profile
  - Method: `registerWithEmail(username, email, password)` - create auth user + profile
  - Method: `convertGuestToMember(username, email, password)` - link credential
  - Method: `loginWithEmail(email, password)` - sign in
  - Method: `logout()` - sign out, then sign in anonymously
  - Listen to `FirebaseAuth.instance.authStateChanges()`
  - Auto-load user profile when auth state changes
- [ ] Create provider registration in main.dart (Riverpod)
- [ ] **Validation**: Provider compiles

### 5.2 Create User Provider
- [ ] Create `lib/presentation/providers/user_provider.dart`
  - StateNotifier<User?> for current user profile
  - Method: `loadUserProfile(userId)` - fetch from repository
  - Method: `updateCanvasCount(increment)` - local + remote update
  - Computed property: `canCreateCanvas` (checks isGuest and canvasCount)
  - Computed property: `needsRegistration` (isGuest && canvasCount >= 1)
- [ ] **Validation**: Provider compiles

### 5.3 Update Drawing Provider
- [ ] Modify `lib/presentation/providers/drawing_provider.dart`
  - Add userId parameter to loadCanvas call
  - Add access check before loading canvas
  - Show error dialog if access denied
  - Prevent drawing if user lacks access
- [ ] **Validation**: Provider compiles

## Phase 6: Presentation Layer - Screens

### 6.1 Create Login Screen
- [ ] Create `lib/presentation/screens/auth/login_screen.dart`
  - Email text field (with validation)
  - Password text field (obscured)
  - "Login" button (calls authProvider.loginWithEmail)
  - "Don't have an account? Register" link → navigate to register screen
  - Loading indicator during login
  - Error display (wrong password, user not found)
  - "Continue as Guest" button → sign in anonymously
- [ ] **Validation**: Screen renders, navigation works

### 6.2 Create Registration Screen
- [ ] Create `lib/presentation/screens/auth/register_screen.dart`
  - Username text field (required, non-empty)
  - Email text field (email validation)
  - Password text field (obscured, min length 6)
  - Confirm Password text field (must match password)
  - "Register" button (calls authProvider.registerWithEmail or convertGuestToMember)
  - "Already have an account? Login" link
  - Loading indicator during registration
  - Error display (email already exists, weak password)
  - Client-side validation before submission
- [ ] **Validation**: Screen renders, validation works

### 6.3 Update Home Screen
- [ ] Modify `lib/presentation/screens/home_screen.dart`
  - Show username in app bar (from userProvider)
  - Disable "Create Canvas" button if `!canCreateCanvas`
  - Show tooltip on disabled button: "Register to create unlimited canvases"
  - Show "Register Now" dialog when guest taps disabled create button
  - Add "Logout" option in menu (only for registered users)
  - Guest mode indicator in UI ("Guest Mode" chip)
- [ ] **Validation**: UI updates based on auth state

### 6.4 Update Drawing Canvas Screen
- [ ] Modify `lib/presentation/screens/drawing_canvas_screen.dart`
  - Add "Team" menu option in app bar (owner only)
  - Team menu shows: "Invite Member", "Manage Team"
  - Disable "Publish" button for guests
  - Show "Register to publish" dialog when guest taps Publish
  - Load canvas with access check
  - Show "Access Denied" error if user lacks permission
- [ ] **Validation**: Access control enforced in UI

### 6.5 Create Team Management Screen
- [ ] Create `lib/presentation/screens/team_management_screen.dart`
  - Show canvas owner
  - List all team members (username from user profiles)
  - "Invite Member" button (owner only)
  - "Remove" button next to each team member (owner only)
  - Invite dialog: enter user ID, verify, add to team
  - Show error if user not found
  - Show success snackbar on add/remove
- [ ] **Validation**: Team operations work

## Phase 7: Navigation & Route Guards

### 7.1 Update App Navigation
- [ ] Modify `lib/main.dart`
  - Add route guards based on auth state
  - If unauthenticated: show login screen
  - If guest: allow home screen with limitations
  - If registered: full access
  - Auto-navigate to home on successful login/register
- [ ] Create route guard helper
- [ ] **Validation**: Navigation flow works correctly

### 7.2 Create Registration Prompt Dialog
- [ ] Create `lib/presentation/widgets/registration_prompt_dialog.dart`
  - Reusable dialog widget
  - Title and message (customizable)
  - "Register Now" button → navigate to register screen
  - "Cancel" button → dismiss
- [ ] Use in home screen (create canvas limit)
- [ ] Use in drawing screen (publish limit)
- [ ] **Validation**: Dialog shows in correct scenarios

## Phase 8: Canvas Creation Flow Update

### 8.1 Update Canvas Creation
- [ ] Modify canvas creation logic in home screen
  - Pass current userId as ownerId
  - Set teamMembers to empty array
  - Set isPrivate to true
  - Call userProvider.incrementCanvasCount() after creation
- [ ] **Validation**: New canvases have ownership fields

### 8.2 Update Canvas Deletion
- [ ] Add canvas deletion feature
  - Only owner can delete
  - Confirmation dialog
  - Delete canvas document
  - Delete image from Storage (if exists)
  - Call userProvider.decrementCanvasCount()
- [ ] **Validation**: Canvas count updates correctly

## Phase 9: Widget Integration Update

### 9.1 Update Widget Image Access
- [ ] Verify Storage rules allow public read for images
- [ ] Verify widget can fetch imageUrl from Firestore (public read for imageUrl only)
- [ ] Update widget code to handle auth (if needed)
- [ ] **Validation**: Widget still works for public viewing

## Phase 10: Testing & Validation

### 10.1 Unit Tests
- [ ] Test user entity serialization
- [ ] Test user repository methods
- [ ] Test canvas access check logic
- [ ] Test team member add/remove
- [ ] Test canvas count increment/decrement
- [ ] **Validation**: All unit tests pass

### 10.2 Manual Testing - Guest Flow
- [ ] Open app as new user (guest mode)
- [ ] Create 1 canvas successfully
- [ ] Verify "Create Canvas" button is disabled
- [ ] Tap disabled button → see registration prompt
- [ ] Draw on canvas
- [ ] Tap "Publish" → see registration prompt
- [ ] Complete registration
- [ ] Verify guest's canvas is now owned by registered account
- [ ] Verify can now create unlimited canvases
- [ ] **Validation**: Guest to member conversion works

### 10.3 Manual Testing - Registration & Login
- [ ] Register new user with username, email, password
- [ ] Verify password confirmation validation
- [ ] Verify email format validation
- [ ] Logout
- [ ] Login with correct credentials
- [ ] Try login with wrong password → see error
- [ ] Try login with unregistered email → see error
- [ ] **Validation**: Auth flows work correctly

### 10.4 Manual Testing - Canvas Ownership
- [ ] Create canvas as user A
- [ ] Invite user B to canvas
- [ ] User B can view and draw on canvas
- [ ] User C (not on team) cannot access canvas
- [ ] User B cannot delete canvas (only owner)
- [ ] User A deletes canvas successfully
- [ ] **Validation**: Ownership and permissions enforced

### 10.5 Manual Testing - Team Management
- [ ] Owner invites team member by user ID
- [ ] Verify team member can view canvas
- [ ] Team member draws on canvas
- [ ] Owner removes team member
- [ ] Verify removed member cannot access canvas anymore
- [ ] Team member cannot invite others (owner only)
- [ ] **Validation**: Team operations work correctly

### 10.6 Manual Testing - Canvas Limits
- [ ] Guest creates 1 canvas
- [ ] Guest cannot create 2nd canvas
- [ ] Guest registers
- [ ] Now can create multiple canvases
- [ ] Canvas count increments on create
- [ ] Canvas count decrements on delete
- [ ] **Validation**: Limits enforced correctly

### 10.7 Manual Testing - Widget View
- [ ] Publish canvas as registered user
- [ ] Share canvas ID with guest user
- [ ] Guest can view published image via widget
- [ ] Guest cannot access canvas strokes
- [ ] Widget loads image without auth
- [ ] **Validation**: Widget public view works

### 10.8 Security Rules Testing
- [ ] Use Firestore Rules Playground to test:
  - Guest can create 1 canvas
  - Guest cannot create 2 canvases
  - Owner can read their canvas
  - Team member can read canvas
  - Non-member cannot read canvas
  - Only owner can delete canvas
  - Only owner/team can write strokes
- [ ] **Validation**: All security rules enforced

## Phase 11: Documentation & Cleanup

### 11.1 Update Documentation
- [ ] Update README with authentication setup instructions
- [ ] Document guest vs. registered user differences
- [ ] Document team member invitation process
- [ ] Add screenshots of login/register screens
- [ ] **Validation**: Documentation complete

### 11.2 Code Cleanup
- [ ] Remove any debug logging
- [ ] Ensure proper error handling everywhere
- [ ] Add comments to complex auth logic
- [ ] Run `flutter analyze` - fix all warnings
- [ ] Run `flutter test` - all tests pass
- [ ] **Validation**: Code quality checks pass

### 11.3 Final Testing
- [ ] Test complete user journey: guest → register → create → invite → publish
- [ ] Test on physical iOS device
- [ ] Test widget refresh with authenticated users
- [ ] Verify security rules in production
- [ ] **Validation**: All success criteria met

---

## Dependencies Between Tasks

- Phase 2 (Entities) must complete before Phase 3 (Models)
- Phase 3 (Repositories) must complete before Phase 5 (Providers)
- Phase 4 (Security Rules) can run parallel to Phase 3
- Phase 5 (Providers) must complete before Phase 6 (Screens)
- Phase 6 (Screens) must complete before Phase 7 (Navigation)
- Phase 8 (Canvas Flow) depends on Phases 2-5
- Phase 9 (Widget) can run parallel to Phase 8
- Phase 10 (Testing) should follow all implementation phases

## Parallel Work Opportunities

- While waiting for Firestore rules deployment (Phase 4.2), work on Providers (Phase 5)
- Data Models (Phase 3.1, 3.2) can be developed in parallel
- Login and Register screens (Phase 6.1, 6.2) can be developed in parallel
- Unit tests can be written alongside implementation
- Widget integration updates (Phase 9) can happen anytime after Phase 4

## Estimated Complexity

- **Phase 1**: Low (data cleanup)
- **Phase 2-3**: Medium (entities, models, repositories)
- **Phase 4**: Medium (security rules require careful validation)
- **Phase 5-6**: High (complex state management and UI flows)
- **Phase 7-8**: Medium (navigation and canvas flow updates)
- **Phase 9**: Low (minor widget updates)
- **Phase 10**: High (comprehensive testing)
- **Phase 11**: Low (documentation and cleanup)

**Total Estimated Tasks**: 80+ tasks across 11 phases
