# Proposal: Implement User Authentication

## Why

The app currently uses anonymous authentication for all users, allowing unlimited canvas creation with no ownership tracking. This creates several issues:

1. **No accountability**: Anonymous users can create unlimited canvases with no ownership
2. **No access control**: All canvases are public, no privacy
3. **No collaboration**: Cannot invite specific users or track team members
4. **No user identity**: Cannot attribute drawings to specific users

Firebase Authentication with email/password is already enabled in the Firebase Console. We need to implement the authentication UI, update the data schema to support canvas ownership, and enforce access controls.

## What Changes

### Authentication System
- Replace anonymous-only auth with email/password registration and login
- Keep anonymous auth for guest users (browse-only, 1 canvas limit)
- Implement registration flow with username, email, and password confirmation
- Implement login flow with email and password
- Convert guest accounts to member accounts upon registration
- Track canvas creation limits per user (1 for guests, unlimited for registered)

### Canvas Ownership & Access Control
- Add owner tracking to canvas documents (ownerId field)
- Add team member management (teamMembers array field)
- Add privacy controls (isPrivate boolean field)
- Implement canvas sharing via team member invitations
- Enforce private access (only owner + team members can view/edit)
- Keep widget view public (anyone with canvas ID can view published image)

### Schema Changes

**Canvas Document (`canvases/{canvasId}`):**
```
{
  canvasId: string,
  ownerId: string,           // NEW - User ID of canvas creator
  teamMembers: string[],     // NEW - Array of user IDs with access
  isPrivate: boolean,        // NEW - Privacy setting (default: true)
  strokes: array,
  lastUpdated: string,
  version: int,
  imageUrl: string?,
  lastExported: string?
}
```

**User Profile Document (`users/{userId}`):**
```
{
  userId: string,
  username: string,          // Display name chosen during registration
  email: string,
  canvasCount: int,          // Number of canvases owned by this user
  isGuest: boolean,          // True for anonymous, false for registered
  createdAt: string,
  updatedAt: string
}
```

### User Experience Changes

**Guest Users (Anonymous):**
- Can browse and view any canvas by ID
- Can create 1 canvas (enforced in UI and security rules)
- Can draw and publish their 1 canvas
- Prompted to register when attempting to create a second canvas
- Prompted to register when attempting to publish a canvas

**Registered Users:**
- Must create account with username, email, password (confirmed)
- Can create unlimited canvases
- Each canvas they create is private by default
- Can invite other users to their canvas as team members
- Can publish canvases they own or are team member of
- Can view/edit only canvases they own or are team member of

**Account Conversion:**
- When guest registers, their anonymous account converts to member account
- Guest's existing canvas (if any) is assigned to their new user profile
- Username, email, and canvasCount are populated

### Security Rules Updates
- Canvas read: Only owner + team members (isPrivate enforcement)
- Canvas write: Only owner + team members
- User profile read: Authenticated users only
- User profile write: Own profile only
- Canvas creation: Check user's canvasCount limit
- Team member operations: Owner only

## Impact

**Affected specs:**
- `user-authentication` (new) - Registration, login, account management
- `canvas-ownership` (new) - Canvas ownership, team management, access control

**Affected code:**
- `lib/main.dart` - Auth state management, route guards
- `lib/presentation/screens/` - Add login, registration screens
- `lib/presentation/providers/` - Add auth provider, user provider
- `lib/domain/entities/` - Add user entity, update canvas entity
- `lib/domain/repositories/` - Add user repository, update drawing repository
- `lib/data/repositories/` - Implement Firebase user repository, update canvas queries
- `lib/data/models/` - Add user model, update canvas model
- `firestore.rules` - Update security rules for ownership and privacy
- `storage.rules` - Update to check canvas ownership

**Migration impact:**
- All existing canvas data will be deleted (as per requirement)
- Fresh start with new schema
- No backward compatibility needed

## Dependencies

- Firebase Authentication already enabled (email/password provider)
- Firestore and Storage already configured
- No new external packages required (firebase_auth already installed)

## Out of Scope

- Social authentication (Google, Apple Sign In)
- Password reset via email (can be added later)
- Email verification (can be added later)
- User profile editing (username/email changes)
- Canvas transfer (changing owner)
- Team member roles (all team members have equal access)
- Canvas discovery/browsing (finding public canvases)

## Success Criteria

1. Guest users can browse and create 1 canvas without registration
2. Users can register with username, email, and password (confirmed)
3. Users can log in with email and password
4. Guest accounts convert to member accounts upon registration
5. Registered users can create unlimited canvases
6. Canvas owner can invite team members by user ID
7. Only owner + team members can access private canvases
8. Only owner + team members can publish canvases
9. Widget view remains public (anyone with canvas ID can see published image)
10. Security rules enforce all access controls
11. UI prevents guests from creating multiple canvases
12. UI prompts registration when guests try to publish
