# FEMA Course-Creation Wizard — Design

**Date:** 2026-07-04
**Status:** Approved (pending spec review)

## Goal

Teachers author, manage, and publish courses in-app — replacing console seeding as
the content pipeline. Supersedes the parked `feat/pr10-course-creation-basics`
concept, rebuilt on the indigo design system.

## Approach (decided)

**Live draft document.** Completing wizard step 1 creates the real
`courses/{id}` doc with `status: 'draft'`; every later edit writes through
immediately (auto-save, "Saved as draft" tick in the wizard header). Editing an
existing course opens the same wizard against its doc — one codepath for
create and edit. Drafts are owner-only per existing rules; abandoned drafts
appear in My Courses where the teacher can delete them.

## Scope decisions

| Decision | Choice |
|---|---|
| Lesson video | Upload from device to Firebase Storage, with progress + cancel + retry |
| Publishing | Teacher publishes directly (Publish/Unpublish toggle); no approval queue |
| Management | Full: edit course, add/edit/reorder/delete lessons, unpublish, delete course |
| Thumbnails | Not in v1 — flat subject tints continue to render course art |
| `language` field | Dropped (model has no field; nothing filters by it) |

## Data model

- `courses/{id}`: existing fields; wizard writes `title`, `description`,
  `subject` (lowercase enum string), `grade`, `ownerId`, `status`
  (`draft`/`published`), and initializes `thumbnailUrl: ''`, `rating: 0`,
  `totalStudents: 0`.
- `lessons/{id}` gains **`order` (int, 0-based)**. `getLessons` sorts
  client-side by `order` with fallback to fetch position, so seeded lessons
  without the field keep working. The seed script adds `order` for parity.
- Delete course = delete each lesson doc, delete Storage videos under the
  course's folder, then delete the course doc (client-side loop).

## Video upload

- Storage path: `lesson-videos/{uid}/{courseId}/{lessonId}.mp4`.
- New `storage.rules` block: write allowed iff `request.auth.uid == uid`,
  `request.resource.contentType.matches('video/.*')`, and size ≤ 500 MB.
  Public read stays (published-course playback incl. guests).
- Client: `image_picker` `pickVideo` (gallery) → `firebase_storage` `putFile`
  upload task → progress stream drives a progress bar with cancel; success
  stores the download URL in the lesson's `videoUrl`. Replacing a video
  deletes the old object first. Failure → error toast + retry affordance.
- Ops prerequisite: Storage enabled on `fema-b608b` (RELEASE.md §3a). Until
  then uploads fail with a clear error toast; the wizard remains usable for
  text/draft work.

## Screens (designed in fema-design.pen, teacher journey row)

| Screen | Route | Pencil node |
|---|---|---|
| My Courses | `/teacher/courses` | `oOYZm` |
| Wizard — Basics | `/teacher/course/new` (creates doc) · `/teacher/course/:id` (edit) | `dS7Ea` |
| Wizard — Lessons | step 2 of the wizard | `scFXB` |
| Add/Edit Lesson sheet | bottom sheet over step 2 | `ieBgI` |
| Wizard — Review & Publish | step 3 of the wizard | `Y8H03` |

- **My Courses**: back nav, "N courses · M drafts" subtitle, "New course" pill,
  course rows with tint thumb + Published (green) / Draft (amber) chip +
  overflow menu (Edit, Unpublish/Publish, Delete). Empty state: "No courses
  yet" + New course CTA. Teacher home's "My courses" section gets a "See all" →
  this screen and a create CTA.
- **Wizard shell**: back button (auto-saved, always safe), 3-segment step
  indicator, "STEP N OF 3" label, "Saved as draft" tick after first save.
- **Basics**: title field, subject dropdown, grade dropdown, description
  multiline; Continue disabled until title + subject + grade are set; Continue
  creates the doc (first time) and advances.
- **Lessons**: reorderable rows (drag handle; `ReorderableListView`), each with
  number tile, title, video status line (green check "Video · mm:ss" / amber
  "No video yet"), overflow (Edit, Delete). "Add lesson" soft button opens the
  sheet. Continue requires ≥ 1 lesson.
- **Lesson sheet**: title, description, duration (minutes), upload zone
  (`primarySoft` card: idle "Upload video · MP4 up to 500 MB" → uploading
  filename + % + progress track + cancel → done: green check + duration).
  Save lesson writes the lesson doc.
- **Review & Publish**: summary card, readiness checklist (lessons count,
  videos uploaded, description written — informational; only ≥1 lesson blocks
  publishing), status card with Draft/Published chip + Publish/Unpublish
  button, danger "Delete course" row (confirm dialog per design system).

## Rules & routing

- `firestore.rules`: course/lesson owner-write rules already exist
  (`courses` create by teacher, update/delete by owner; `lessons` write by
  course owner) — no Firestore rule change expected; verify during
  implementation.
- `storage.rules`: add the teacher-upload block above.
- Router: `/teacher/courses`, `/teacher/course/new`, `/teacher/course/:id`
  under the existing `/teacher` role guard. Redirect matrix untouched
  (prefix-guarded already).

## Error handling

- Draft writes ride Firestore's offline persistence; the "Saved" tick reflects
  the local write.
- Upload errors surface as toasts with retry; cancel cleans up the upload task.
- Deleting a published course warns that students lose access (confirm dialog).

## Testing

- Unit: draft repository (order assignment on add/reorder, publish/unpublish
  transitions, delete cascade ordering), upload-state mapping.
- Widget (provider overrides, no Firebase): basics validation gates Continue;
  lessons list renders order + video states; My Courses chips.
- Existing 52-test suite stays green.
