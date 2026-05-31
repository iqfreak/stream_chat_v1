# Stream Chat V1 — Code Review & Fixes

This document lists the problems found during a full review of the codebase and
the changes made to fix them. It is grouped by severity.

> Note: the project was reviewed and patched outside a Flutter toolchain. Before
> relying on it, run:
>
> ```bash
> flutter pub get
> flutter analyze
> flutter run
> ```

---

## Critical bugs (broke core features)

### 1. Attachments were broken for all recipients
**File:** `lib/services/stream_chat_service.dart`, `lib/screens/chat/chat_screen.dart`

Picked files were sent using the **local device path** as the attachment URL
(`assetUrl: a.url` where `a.url` was `file.path`). The file was never uploaded
to Stream's CDN, so images/files rendered on the *sender's* device but appeared
as broken images/links for everyone else.

**Fix:** `sendMessageWithAttachment` now builds `Attachment` objects with an
`AttachmentFile` (path + size). The Stream SDK uploads these to the CDN on send,
so recipients receive a real CDN URL.

### 2. Thread replies displayed as empty bubbles
**Files:** `lib/screens/chat/thread_screen.dart`, `lib/services/stream_chat_service.dart`

The thread screen rendered `parent.threadReplies`, which were **placeholder
objects** (empty text, fake IDs) created only to show the reply *count*. The real
`getThreadReplies()` existed in the service but was never called.

**Fix:** added `loadThread()` / `threadReplies()` / `_reloadThread()` in the
service. The thread screen now fetches the real replies on open and refreshes
live when new replies arrive (handled in the event listener and after sending).

### 3. @Mentions were not implemented
**Files:** `lib/screens/chat/chat_screen.dart`, `lib/services/stream_chat_service.dart`, `lib/screens/notifications/notifications_screen.dart`, `lib/services/models.dart`

There was no `@` autocomplete in the message input, and **every** incoming
message produced a notification labelled "mentioned you in…", which was
misleading.

**Fix:**
- Added an `@mention` autocomplete list above the chat input that filters
  channel members as you type and inserts `@username`.
- `sendMessage` now resolves `@handles` against channel members and passes
  real `mentionedUsers` to Stream.
- Notifications now carry an `isMention` flag and the notification list shows
  "mentioned you" vs "messaged you" with the correct icon.

### 4. Notification toggles did nothing
**Files:** `lib/screens/settings/settings_screen.dart`, `lib/providers/app_state.dart`, `lib/services/stream_chat_service.dart`

Settings used local `setState` booleans; `AppState` had matching but unused
setters. Neither was persisted nor checked anywhere.

**Fix:** the two preferences now live in the service, are persisted with
`SharedPreferences`, and actually gate whether an in-app notification is created
(mentions respect "Mentions", other messages respect "Push Notifications").

---

## High-impact issues

### 5. No session restore (forced re-login every launch)
**Files:** `lib/screens/splash/splash_screen.dart`, `lib/services/stream_chat_service.dart`

The splash screen always navigated to `/login`, even though the current user ID
was saved. **Fix:** added `tryRestoreSession()` which silently reconnects the
saved user on startup; the splash routes to `/channels` if it succeeds.

### 6. Theme & language reset on every restart
**Files:** `lib/providers/app_state.dart`, `lib/screens/splash/splash_screen.dart`

`AppState` never persisted theme or locale. **Fix:** both are now saved to and
loaded from `SharedPreferences` (`AppState.load()` is called from the splash).

### 7. Custom avatars broke across devices
**Files:** `lib/widgets/user_avatar.dart`, `lib/services/stream_chat_service.dart`

Picked avatars were stored as a local device path, so other users saw a blank
colored circle. **Fix:**
- `UserAvatar` now falls back to the user's initials when an image fails to load
  (instead of showing an empty circle).
- `updateUserAvatar` uploads local images to the Stream CDN when a channel is
  available, so they become visible to other users.
- **Known limitation:** at registration the user has no channel yet, so a
  registration-time avatar stays local until it is re-saved from Settings/Edit
  Profile (once at least one chat exists). Documented here intentionally.

---

## Polish & correctness

### 8. Redundant "📷 Photo" caption under images
**File:** `lib/screens/chat/chat_screen.dart`
The bubble used `displayText` (a list-preview helper that returns "📷 Photo"),
so an image with no caption showed the image **and** a "📷 Photo" line. Now the
bubble shows only the real text.

### 9. `stream_chat_flutter` was a transitive-only dependency
**File:** `pubspec.yaml`
`main.dart` imports `package:stream_chat_flutter/...` but it wasn't a direct
dependency (lint risk / fragile). Added it explicitly.

### 10. Deprecated `withOpacity`
8 usages across `chat_screen.dart`, `edit_profile_screen.dart`, and
`settings_sub_screens.dart` were replaced with `withValues(alpha: …)`.

### 11. Router auth redirect was fragile
**File:** `lib/router/app_router.dart`
Added `refreshListenable: appState` so the auth redirect re-evaluates when login
state changes.

### 12. Avatar crash on empty name
**File:** `lib/widgets/user_avatar.dart`
`_avatarColor()` called `name.codeUnitAt(0)` which threw on empty names; now
guarded.

---

## Still recommended (not changed)

- **API secret in the client.** `lib/config/stream_config.dart` hardcodes the
  Stream **API secret** and the JWT is generated on-device. This is fine for a
  local demo but is a real security risk — the SRS itself states tokens should be
  generated server-side in production. For a graded demo, leave it; for anything
  real, move token generation behind a small server.
- **Forwarding drops attachments.** The Forward action only forwards text. To
  forward media you would re-attach the original attachment payload.
- **Push notifications (FCM).** The SRS mentions Firebase Cloud Messaging, but the
  app implements **in-app** notifications only (no `firebase_messaging`
  dependency). True OS-level push would require adding Firebase + server-side
  token registration.
- **Message search** only returns results for channels already loaded locally;
  results in unloaded channels are skipped.
