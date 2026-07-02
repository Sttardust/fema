# FEMA MVP — Scope & Design

**Date:** 2026-07-02
**Status:** Approved (pending spec review)

## Goal

Trim FEMA from many parallel features to a stable, operational MVP, then layer the
deferred features back in. "Operational" means: shipped to the Play Store internal
testing track (or APK sideload) for a small pilot group, with crash reporting in place.

## Core loop

1. **Students learn** — students (and unauthenticated guests) browse the course
   library and watch video lessons. Content is seeded directly in Firestore by
   admins; there is no in-app authoring in the MVP.
2. **Teachers manage classrooms** — teachers create classes, enroll students, and
   take attendance.

## Roles

- **Student** and **Teacher** are selectable at onboarding.
- **Admin** exists for control but is provisioned manually via Firebase custom
  claims (never self-service — consistent with existing `firestore.rules`). Admins
  keep the existing admin route guard and admin home.
- **Parent** is deferred entirely.

## MVP surface

| Area | Screens / behavior |
|---|---|
| Auth | Email + password sign-in/up, phone OTP, guest browsing of published courses |
| Onboarding | Role picker (Student / Teacher). Students pick a grade (needed for content filtering); teachers go straight to teacher home. All other onboarding steps (subjects, goals, quiz, child profiles) are dropped from the MVP |
| Student | Home → Library catalog → Course details → Lesson player (real video) |
| Teacher | Teacher home → Class management (classes, students, attendance) |
| Shared | Profile + account management (delete account stays — store compliance) |

## Hidden for MVP (code stays, entry points removed)

- Parent onboarding + child security screen
- Course-creation wizard — PR10 work is committed on
  `feat/pr10-course-creation-basics` and parked unmerged
- Content editor screen
- Notifications screen and entry points
- Mock-only player UI: Bookmark/Download chips and the "Ask the teacher" chat FAB

## Video playback

- Add `video_player` + `chewie`; replace the mocked player area in
  `video_player_screen.dart` with a real streaming player (tabs/navigation shell
  is redesigned per the visual redesign below).
- Videos hosted in **Firebase Storage**; lesson docs carry the download URL in the
  existing `videoUrl` field. No model change.
- Seeding workflow (documented in README): upload video to Storage → copy download
  URL → paste into the lesson doc in the Firestore console (or run a seed script).

## Data model & rules

- Firestore collections unchanged: `users`, `courses`/`lessons`,
  `classes`/`students`/`attendance`.
- Remove the `firestore.rules` reference to the non-existent `adminInviteUser`
  Cloud Function.
- Storage rules: read access for published lesson videos (authenticated + guest);
  no client writes.

## Visual redesign (Pencil)

All MVP screens are redesigned in Pencil and implemented in Flutter, superseding
the earlier Figma-based look.

- **Design file:** `~/.pencil/documents/2081a41d-010b-4f2e-b028-bc948c09956a/pencil-new.pen`
- **Brand:** primary `#4B0082` (indigo). Flat fills only — no gradients.
- **Palette tokens:** `primary`, `primary-dark #38005F`, `primary-light #7A42B5`,
  `primary-soft #EFE7F8`, `bg #F5F2FA`, `surface #FFFFFF`, `text-primary #211936`,
  `text-secondary #8B84A0`, `stroke-soft #E7E2F1`, subject tints
  `subject-1..4` (`#4B0082`, `#6D35A6`, `#8F5BC4`, `#B187DD`).
- **Typography:** Figtree everywhere (headings 700–800, body 400–600).
- **Language:** lavender background, white rounded cards (16–24 px radius) with
  soft shadows, pill chips and buttons, floating capsule tab bar.
- **Screens designed (10):** Home, Library, Course Details, Lesson Player, Sign In,
  Verify Phone (OTP), Choose Role, Teacher Home, Class Management, Profile.
- Small screens not individually mocked (Sign Up, grade picker, Students tab of
  class management, course Overview tab, account management) are derived from the
  same tokens and card/chip/button patterns during implementation.
- Flutter theme (`lib/core/theme/`) is rebuilt from these tokens so screens
  reference theme values, not hard-coded colors.

## Stabilization

- Router: verify guards/redirects for the trimmed role set + guest mode; no
  dead-ends into hidden routes.
- Error and empty states on every Firestore-backed screen (offline,
  permission-denied, empty library, empty class list).
- `flutter analyze` clean; unit tests for kept domain logic; widget tests for the
  critical paths: auth → onboarding → home; browse → play video; create class →
  mark attendance.

## Release engineering (Android internal/beta)

- Release signing config, proper `applicationId`, versioning.
- App Check: Play Integrity for release builds (debug provider stays for dev).
- Crashlytics for field crash reporting.
- Upload to Play internal testing track.

## Sequence

1. ~~Park PR10 branch; branch `feat/mvp-scope` from `main`~~ (done)
2. **Trim PR** — hide out-of-scope entry points, trim onboarding roles
3. ~~Pencil design phase~~ (done — screens above)
4. **Implement redesign + real video** — screen by screen; player redesign lands
   together with real video so that screen is rebuilt once
5. **Stabilize** — guards, error/empty states, tests, analyze clean
6. **Release** — signing, App Check, Crashlytics, Play internal track

## Deferred backlog (post-MVP, rough order)

1. Course-creation wizard (resume PR10)
2. Notifications
3. Parent flows (onboarding, child security)
4. Bookmarks, downloads, "Ask the teacher" chat
5. iOS beta
