# Design: User Authentication & Canvas Ownership

## Architecture Overview

This change introduces user identity and ownership tracking while maintaining the existing drawing and real-time sync functionality. The architecture follows clean architecture principles with clear separation between authentication, authorization, and canvas data management.

### System Components

```
┌─────────────────────────────────────────────────────────────┐
│                     Presentation Layer                       │
│  ┌────────────────┐  ┌────────────────┐  ┌───────────────┐ │
│  │ Login Screen   │  │ Register Screen│  │ Canvas Screen │ │
│  └────────┬───────┘  └────────┬───────┘  └───────┬───────┘ │
│           │                   │                   │          │
│  ┌────────▼───────────────────▼───────────────────▼───────┐ │
│  │              Riverpod Providers                         │ │
│  │  - AuthProvider (login state, current user)            │ │
│  │  - UserProvider (profile, canvas count)                │ │
│  │  - DrawingProvider (enhanced with ownership checks)    │ │
│  └────────┬────────────────────────────────────────────────┘ │
└───────────┼──────────────────────────────────────────────────┘
            │
┌───────────▼──────────────────────────────────────────────────┐
│                      Domain Layer                             │
│  ┌──────────────────┐  ┌──────────────────┐                 │
│  │  User Entity     │  │  Canvas Entity   │                 │
│  │  - userId        │  │  - ownerId       │                 │
│  │  - username      │  │  - teamMembers   │                 │
│  │  - email         │  │  - isPrivate     │                 │
│  │  - isGuest       │  │  - strokes       │                 │
│  │  - canvasCount   │  │  - imageUrl      │                 │
│  └──────────────────┘  └──────────────────┘                 │
│                                                               │
│  ┌──────────────────┐  ┌──────────────────┐                 │
│  │  User Repository │  │  Drawing Repo    │                 │
│  │  Interface       │  │  Interface       │                 │
│  └──────────────────┘  └──────────────────┘                 │
└───────────┬──────────────────────────────────────────────────┘
            │
┌───────────▼──────────────────────────────────────────────────┐
│                       Data Layer                              │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │         Firebase User Repository                         │ │
│  │  - createUser()      - getUserProfile()                  │ │
│  │  - updateUser()      - convertGuestToMember()           │ │
│  │  - incrementCanvasCount()                                │ │
│  └──────────────────────────────────────────────────────────┘ │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │      Firebase Drawing Repository (Enhanced)              │ │
│  │  - checkCanvasAccess()  - addTeamMember()               │ │
│  │  - loadCanvas() (with ownership check)                   │ │
│  │  - saveStroke() (with permission check)                  │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                               │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │              Firebase Authentication                      │ │
│  │  - signInAnonymously()                                   │ │
│  │  - createUserWithEmailAndPassword()                      │ │
│  │  - signInWithEmailAndPassword()                          │ │
│  │  - linkWithCredential() (guest to member conversion)     │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                               │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │              Cloud Firestore                              │ │
│  │  /users/{userId}                                         │ │
│  │  /canvases/{canvasId}                                    │ │
│  └──────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────┘
```

## Key Design Decisions

### 1. Guest vs. Registered User Model

**Decision**: Keep anonymous authentication for guests, use linkWithCredential() to convert to registered users.

**Rationale**:
- Allows friction-free onboarding (browse without account)
- Firebase linkWithCredential() preserves the same userId during conversion
- Existing canvas ownership transfers seamlessly (same userId)
- No need for complex data migration or orphaned canvases

**Implementation**:
```dart
// Guest creation (automatic)
await FirebaseAuth.instance.signInAnonymously();
await createUserProfile(userId: uid, isGuest: true);

// Guest to member conversion
final credential = EmailAuthProvider.credential(email: email, password: password);
await currentUser.linkWithCredential(credential);
await updateUserProfile(userId: uid, username: username, email: email, isGuest: false);
```

### 2. Canvas Creation Limits

**Decision**: Enforce limits in both UI and security rules.

**Rationale**:
- UI enforcement provides immediate feedback (better UX)
- Security rules enforcement prevents bypass via API calls
- Track canvasCount in user profile document for fast checks

**Implementation**:
- UI: Check `userProvider.canvasCount` before showing "Create Canvas" flow
- UI: Show "Register to create more" dialog when guest at limit
- Security rules: Validate `get(/databases/$(database)/documents/users/$(request.auth.uid)).data.canvasCount < 1` for guests
- Backend: Increment canvasCount on canvas creation, decrement on deletion

### 3. Canvas Privacy Model

**Decision**: Private by default, public widget view.

**Rationale**:
- Canvas data (strokes) is private: Only owner + team members
- Published images are public: Anyone with canvas ID can view via widget
- Balances privacy with widget sharing functionality
- Widget URL (imageUrl in Firestore) is not secret, can be shared

**Implementation**:
```javascript
// Firestore rules
allow read: if isOwnerOrTeamMember(request.auth.uid);
allow write: if isOwnerOrTeamMember(request.auth.uid);

// Firebase Storage rules (images)
allow read: if true; // Public for widget viewing
allow write: if canvasOwnerOrTeamMember(request.auth.uid, canvasId);
```

### 4. Team Member Management

**Decision**: Simple array-based team members, owner-only invite.

**Rationale**:
- MVP simplicity: No complex roles or permissions
- Array queries work well for small teams (<10 members)
- Owner has full control (invite, remove)
- All team members have equal edit rights

**Schema**:
```json
{
  "ownerId": "user123",
  "teamMembers": ["user456", "user789"],
  "isPrivate": true
}
```

**Access check**:
```javascript
function isOwnerOrTeamMember(userId) {
  return resource.data.ownerId == userId ||
         userId in resource.data.teamMembers;
}
```

### 5. Registration Flow UX

**Decision**: Two-step registration with password confirmation.

**Rationale**:
- Password confirmation prevents typos
- Username + email provides clear identity
- Username is immutable (no updates in MVP)
- Email validation can be added later without breaking changes

**Flow**:
1. User enters username (display name)
2. User enters email
3. User enters password (twice for confirmation)
4. Client validates: username non-empty, email format, passwords match
5. Create Firebase Auth user
6. Create Firestore user profile
7. Link anonymous credential if guest conversion

### 6. Canvas Access Enforcement

**Decision**: Repository layer checks permissions before operations.

**Rationale**:
- Security rules are final defense
- Repository checks provide better error messages
- Repository checks reduce unnecessary Firestore reads
- Clean architecture: authorization logic in data layer

**Implementation**:
```dart
@override
Future<DrawingData> loadCanvas(String canvasId) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;

  // Check access first
  final hasAccess = await checkCanvasAccess(canvasId, userId);
  if (!hasAccess) {
    throw PermissionDeniedException('You do not have access to this canvas');
  }

  // Load canvas data
  final docSnapshot = await _getCanvasRef(canvasId).get();
  // ...
}
```

## Data Model Changes

### User Entity (New)

```dart
class User {
  final String userId;
  final String username;
  final String email;
  final int canvasCount;
  final bool isGuest;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### Canvas Entity (Modified)

```dart
class DrawingData {
  final String canvasId;
  final String ownerId;              // NEW
  final List<String> teamMembers;    // NEW
  final bool isPrivate;              // NEW
  final List<DrawingStroke> strokes;
  final DateTime lastUpdated;
  final int version;
  final String? imageUrl;
  final DateTime? lastExported;
}
```

## Migration Strategy

**Decision**: Delete all existing data (as per requirement).

**Steps**:
1. Backup existing data (optional, for reference)
2. Delete all documents in `/canvases` collection
3. Delete all documents in `/users` collection (if exists)
4. Update Firestore security rules
5. Update Firebase Storage rules
6. Deploy updated application code

**Rationale**:
- Clean slate avoids complex data migration logic
- Ensures all canvases have proper ownership from day one
- MVP phase: limited production data to lose
- Simpler than writing migration scripts

## Security Considerations

### Authentication Security
- Passwords hashed by Firebase (bcrypt)
- Email/password validated client-side before submission
- No password reset in MVP (can add Firebase password reset later)
- Anonymous users have limited privileges (1 canvas, no team invites)

### Authorization Security
- Firestore rules enforce ownerId and teamMembers checks
- Repository layer provides secondary validation
- Canvas IDs are not secret (shareable for widgets)
- Image URLs are public (Storage rules allow read)

### Data Privacy
- User profiles readable only by authenticated users
- Canvas strokes readable only by owner + team members
- Published images (Storage) publicly readable
- No PII exposed in canvas documents

## Testing Strategy

### Unit Tests
- User entity serialization
- Canvas entity with ownership fields
- Repository permission checks
- Guest conversion logic

### Integration Tests
- Registration flow (username, email, password)
- Login flow
- Guest to member conversion
- Canvas creation with ownership
- Team member add/remove
- Permission denied scenarios

### Manual Tests
- Guest creates 1 canvas
- Guest prompted to register for 2nd canvas
- Register as new user
- Login as existing user
- Invite team member
- Team member can view/edit canvas
- Non-member cannot access private canvas
- Widget view works for anyone with canvas ID

## Performance Considerations

### Canvas Access Checks
- Cache canvas ownership in memory (AuthProvider)
- Reduce repeated Firestore reads for same canvas
- Use Firestore offline persistence

### Canvas Count Updates
- Increment on create, decrement on delete
- Use FieldValue.increment() for atomic updates
- No need for complex aggregation queries

### Team Member Queries
- Small team size (<10) makes array queries efficient
- Consider `array-contains` query for user's canvases
- Index on ownerId and teamMembers

## Future Enhancements (Out of Scope)

1. **Password Reset**: Firebase password reset email flow
2. **Email Verification**: Verify email before allowing canvas publish
3. **Profile Editing**: Allow username/email updates
4. **Team Roles**: Owner, editor, viewer permissions
5. **Canvas Transfer**: Change canvas owner
6. **Canvas Discovery**: Browse public canvases
7. **Social Auth**: Google/Apple Sign In
8. **Team Invites by Email**: Invite non-users by email
