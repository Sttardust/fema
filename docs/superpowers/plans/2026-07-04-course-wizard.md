# FEMA Course-Creation Wizard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Teachers create, manage, and publish courses in-app — live-draft wizard (basics → lessons → review), video lessons with device upload + transcript, text lessons, optional PDF/DOC worksheets — per `docs/superpowers/specs/2026-07-04-course-wizard-design.md`.

**Architecture:** Live draft doc: step 1 creates `courses/{id}` with `status:'draft'`; all edits write through (auto-save). New feature dir `lib/features/teacher/course_editor/` (named to avoid the parked `course_creation/`): a repository over the existing `FirestoreService`, an upload controller over `firebase_storage` + `file_picker`, and three screens. Consumption side (Overview cards, Transcript tab, text-lesson reading card, worksheet row) is wired in the same phase so authored fields render.

**Tech Stack:** Flutter, Riverpod, go_router, firebase_storage, file_picker, url_launcher.

**Branch:** `feat/course-wizard`.

## Design source (Pencil, `design/fema-design/fema-design.pen`)

| Screen | Node | Screen | Node |
|---|---|---|---|
| My Courses | `oOYZm` | Lesson sheet (video mode) | `ieBgI` |
| Wizard — Basics | `dS7Ea` | Lesson sheet (text mode) | `btMMR` |
| Wizard — Lessons | `scFXB` | Review & Publish | `Y8H03` |

Status chips: Published = text `#2BB37A` on `#E6F7F0`; Draft = `#B97F1F` on `#FBF3E2` (same palette as toasts). Step indicator: 3 equal 5px-high radius-3 bars, done/current `AppColors.primary`, upcoming `greyLight`.

---

### Task 1: Model + parser extensions

**Files:**
- Modify: `lib/features/library/domain/models.dart`
- Modify: `lib/features/library/domain/library_provider.dart` (parsing ~lines 23-45)
- Modify: `tool/seed-course.js`
- Test: `test/library/models_test.dart` (create)

- [ ] **Step 1: Failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fema/features/library/domain/models.dart';

void main() {
  test('lesson carries order, transcript, and document fields', () {
    final l = Lesson(
      id: 'x', title: 't', description: 'd',
      order: 3, transcript: 'hello', documentUrl: 'https://x/y.pdf', documentName: 'y.pdf',
    );
    expect(l.order, 3);
    expect(l.transcript, 'hello');
    expect(l.documentName, 'y.pdf');
    expect(l.copyWith(isCompleted: true).order, 3);
  });

  test('course carries objectives and author', () {
    final c = Course(
      id: 'c', title: 't', description: 'd', subject: CourseSubject.math,
      grade: 'Grade 9', thumbnailUrl: '', lessons: const [],
      learningObjectives: const ['a', 'b'], authorName: 'Ms. Hanna',
    );
    expect(c.learningObjectives, ['a', 'b']);
    expect(c.authorName, 'Ms. Hanna');
  });
}
```

Run: `flutter test test/library/models_test.dart` → FAIL (missing params).

- [ ] **Step 2: Extend models** — `Lesson`: add `final int order;` (default 0), `final String? transcript;`, `final String? documentUrl;`, `final String? documentName;` (constructor + carry through `copyWith`). `Course`: add `final List<String> learningObjectives;` (default `const []`), `final String? authorName;`.

- [ ] **Step 3: Extend parsing** in `library_provider.dart`:

```dart
          order: l['order'] ?? 0,
          transcript: l['transcript'],
          documentUrl: l['documentUrl'],
          documentName: l['documentName'],
```

for lessons, and for courses:

```dart
          learningObjectives: List<String>.from(data['learningObjectives'] ?? const []),
          authorName: data['authorName'] as String?,
```

After mapping lessons, sort client-side, preserving fetch position for legacy docs without `order`:

```dart
        final indexed = lessonsData.asMap().entries.map((e) => (e.key, /* built Lesson */)).toList();
        indexed.sort((a, b) {
          final ao = a.$2.order != 0 || b.$2.order != 0 ? a.$2.order : a.$1;
          final bo = a.$2.order != 0 || b.$2.order != 0 ? b.$2.order : b.$1;
          return ao.compareTo(bo);
        });
```

(Adapt to the file's actual mapping structure — the requirement: lessons with `order` sort by it; a batch with all-zero/absent `order` keeps fetch order. Simplest correct: `sort by (order, fetchIndex)` using a stable sort — Dart's `List.sort` is not stable, so sort the indexed pairs by `(order, index)` tuple comparison.)

- [ ] **Step 4: Seed parity** — in `tool/seed-course.js` add `order: <0-based index>` and a 1-2 sentence `transcript` per lesson; keep idempotent shape.

- [ ] **Step 5: Verify** — model test passes; `flutter analyze` clean; `flutter test` all pass (52+2); `node --check tool/seed-course.js`.

- [ ] **Step 6: Commit** — `git add lib/features/library/domain test/library tool/seed-course.js && git commit -m "feat(wizard): lesson order/transcript/document and course objectives/author fields"`

---

### Task 2: Storage rules + service delete methods

**Files:**
- Modify: `storage.rules`
- Modify: `lib/core/services/firestore_service.dart`

- [ ] **Step 1: Replace `storage.rules`** with:

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Published-course media is world-readable (guest mode). Teachers write
    // only inside their own uid folder, with type and size limits.
    match /lesson-videos/{uid}/{courseId}/{fileName} {
      allow read: if true;
      allow write: if request.auth != null
                   && request.auth.uid == uid
                   && request.resource.contentType.matches('video/.*')
                   && request.resource.size <= 500 * 1024 * 1024;
      allow delete: if request.auth != null && request.auth.uid == uid;
    }
    // Legacy console-seeded videos (flat path) stay readable.
    match /lesson-videos/{fileName} {
      allow read: if true;
      allow write: if false;
    }
    match /lesson-docs/{uid}/{courseId}/{fileName} {
      allow read: if true;
      allow write: if request.auth != null
                   && request.auth.uid == uid
                   && (request.resource.contentType == 'application/pdf'
                       || request.resource.contentType == 'application/msword'
                       || request.resource.contentType == 'application/vnd.openxmlformats-officedocument.wordprocessingml.document')
                   && request.resource.size <= 25 * 1024 * 1024;
      allow delete: if request.auth != null && request.auth.uid == uid;
    }
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

Note: in Storage rules, `allow write` covers create/update/delete unless delete is split out; the explicit `allow delete` (without the contentType checks, which don't exist on delete) is required so teachers can remove/replace files. Validate with `firebase deploy --only storage --dry-run` (expected to fail with "Storage not set up" until the console step — report, don't block).

- [ ] **Step 2: Service deletes** — add to `firestore_service.dart`:

```dart
  Future<void> deleteLesson(String courseId, String lessonId) async {
    await _db.collection('courses').doc(courseId).collection('lessons').doc(lessonId).delete();
  }

  Future<void> deleteCourse(String courseId) async {
    final lessons = await _db.collection('courses').doc(courseId).collection('lessons').get();
    for (final doc in lessons.docs) {
      await doc.reference.delete();
    }
    await _db.collection('courses').doc(courseId).delete();
  }
```

- [ ] **Step 3: Verify + commit** — `flutter analyze` clean, `flutter test` passes. `git add storage.rules lib/core/services/firestore_service.dart && git commit -m "feat(wizard): teacher upload storage rules and course/lesson deletes"`

---

### Task 3: Course editor repository

**Files:**
- Create: `lib/features/teacher/course_editor/domain/course_editor_repository.dart`
- Test: `test/teacher/course_editor_repository_test.dart` (create)

Thin orchestration over `FirestoreService`; the pure logic (order assignment, payload building) is separated into static helpers so it unit-tests without Firebase.

- [ ] **Step 1: Failing tests** for the pure helpers:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fema/features/teacher/course_editor/domain/course_editor_repository.dart';

void main() {
  test('nextOrder appends after the max existing order', () {
    expect(CourseEditorRepository.nextOrder([0, 1, 2]), 3);
    expect(CourseEditorRepository.nextOrder([]), 0);
    expect(CourseEditorRepository.nextOrder([5, 2]), 6);
  });

  test('reorderPayload renumbers 0..n-1 in the new sequence', () {
    expect(CourseEditorRepository.reorderPayload(['b', 'a', 'c']),
        {'b': 0, 'a': 1, 'c': 2});
  });

  test('draftPayload shapes the create document', () {
    final p = CourseEditorRepository.draftPayload(
      title: 'T', description: 'D', subject: 'science', grade: 'Grade 10',
      ownerId: 'uid1', authorName: 'Ms. H', learningObjectives: ['x'],
    );
    expect(p['status'], 'draft');
    expect(p['rating'], 0);
    expect(p['totalStudents'], 0);
    expect(p['thumbnailUrl'], '');
    expect(p['authorName'], 'Ms. H');
    expect(p['learningObjectives'], ['x']);
  });
}
```

Run → FAIL.

- [ ] **Step 2: Implement** — class `CourseEditorRepository` with `final FirestoreService _service;` and a Riverpod provider `courseEditorRepositoryProvider` mirroring how `courseRepositoryProvider`/`firestoreServiceProvider` are wired in `library_provider.dart` (read it first). API:

```dart
  static int nextOrder(Iterable<int> existingOrders) =>
      existingOrders.isEmpty ? 0 : (existingOrders.reduce((a, b) => a > b ? a : b) + 1);

  static Map<String, int> reorderPayload(List<String> lessonIdsInNewOrder) =>
      { for (var i = 0; i < lessonIdsInNewOrder.length; i++) lessonIdsInNewOrder[i]: i };

  static Map<String, dynamic> draftPayload({required String title, required String description,
      required String subject, required String grade, required String ownerId,
      String? authorName, List<String> learningObjectives = const []}) => {
    'title': title, 'description': description, 'subject': subject, 'grade': grade,
    'ownerId': ownerId, 'status': 'draft', 'thumbnailUrl': '', 'rating': 0,
    'totalStudents': 0, 'authorName': authorName, 'learningObjectives': learningObjectives,
  };

  Future<String> createDraft({...same params}) => _service.saveCourse(draftPayload(...));
  Future<void> updateBasics(String courseId, {title, description, subject, grade, learningObjectives})
      => _service.saveCourse({'id': courseId, ...only-provided-fields});
  Future<void> saveLesson(String courseId, {String? lessonId, required String title,
      required String description, required int durationMinutes, required int order,
      String? videoUrl, String? transcript, String? contentHtml,
      String? documentUrl, String? documentName}) => _service.saveLesson(courseId, {...});
  Future<void> applyReorder(String courseId, Map<String, int> orders) async {
    for (final e in orders.entries) {
      await _service.saveLesson(courseId, {'id': e.key, 'order': e.value});
    }
  }
  Future<void> deleteLesson(String courseId, String lessonId) => _service.deleteLesson(courseId, lessonId);
  Future<void> setStatus(String courseId, bool published) =>
      _service.updateCourseStatus(courseId, published ? 'published' : 'draft');
  Future<void> deleteCourse(String courseId) => _service.deleteCourse(courseId);
```

(`saveLesson` via merge-set means partial maps like the reorder write are safe.)

- [ ] **Step 3: Tests pass; analyze clean. Commit** — `git add lib/features/teacher/course_editor test/teacher/course_editor_repository_test.dart && git commit -m "feat(wizard): course editor repository with order/draft helpers"`

---

### Task 4: Upload controller (video + document)

**Files:**
- Modify: `pubspec.yaml` — add `file_picker: ^8.1.4` and `url_launcher: ^6.3.1` (nearest resolvable; report)
- Create: `lib/features/teacher/course_editor/domain/lesson_upload_controller.dart`
- Test: `test/teacher/lesson_upload_controller_test.dart` (create)

- [ ] **Step 1: Failing tests** for pure path/validation helpers:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fema/features/teacher/course_editor/domain/lesson_upload_controller.dart';

void main() {
  test('storage paths are uid-scoped per spec', () {
    expect(LessonUploadController.videoPath(uid: 'u1', courseId: 'c1', lessonId: 'l1'),
        'lesson-videos/u1/c1/l1.mp4');
    expect(LessonUploadController.documentPath(uid: 'u1', courseId: 'c1', lessonId: 'l1', fileName: 'w s.pdf'),
        'lesson-docs/u1/c1/l1-w_s.pdf');
  });

  test('document extension gate', () {
    expect(LessonUploadController.isAllowedDocument('a.pdf'), true);
    expect(LessonUploadController.isAllowedDocument('a.docx'), true);
    expect(LessonUploadController.isAllowedDocument('a.doc'), true);
    expect(LessonUploadController.isAllowedDocument('a.exe'), false);
  });
}
```

Run → FAIL.

- [ ] **Step 2: Implement** — static helpers exactly as tested (`documentPath` sanitizes the file name: spaces → `_`, keep extension). Instance API over `FirebaseStorage`:

```dart
class LessonUploadController {
  // static videoPath/documentPath/isAllowedDocument as above

  UploadTask startVideoUpload({required String uid, required String courseId,
      required String lessonId, required File file}) =>
    FirebaseStorage.instance.ref(videoPath(uid: uid, courseId: courseId, lessonId: lessonId))
        .putFile(file, SettableMetadata(contentType: 'video/mp4'));

  UploadTask startDocumentUpload({... , required File file, required String fileName}) =>
    FirebaseStorage.instance.ref(documentPath(...))
        .putFile(file, SettableMetadata(contentType: _mimeFor(fileName)));

  static Future<void> deleteByUrl(String downloadUrl) async {
    try { await FirebaseStorage.instance.refFromURL(downloadUrl).delete(); }
    on FirebaseException catch (_) {/* already gone — fine */}
  }
}
```

`_mimeFor`: `.pdf`→`application/pdf`, `.doc`→`application/msword`, `.docx`→the openxml type. Picking files happens in the UI layer via `FilePicker.platform.pickFiles(type: FileType.video)` / `(type: FileType.custom, allowedExtensions: ['pdf','doc','docx'])` — the controller only takes the picked `File`. Progress/cancel come from the returned `UploadTask` (`snapshotEvents`, `.cancel()`) consumed by the sheet UI in Task 7.

- [ ] **Step 3: `flutter pub get`; tests pass; analyze clean. Commit** — `git add pubspec.yaml pubspec.lock lib/features/teacher/course_editor test/teacher && git commit -m "feat(wizard): upload controller with uid-scoped storage paths"`

---

### Task 5: My Courses screen + teacher home wiring

**Files:**
- Create: `lib/features/teacher/course_editor/presentation/my_courses_screen.dart` (Pencil `oOYZm`)
- Modify: `lib/routes/app_router.dart`
- Modify: `lib/features/teacher/presentation/teacher_home_screen.dart`
- Test: `test/teacher/my_courses_screen_test.dart` (create)

- [ ] **Step 1: Screen** — Scaffold bg `AppColors.background`; `CircleIconButton` back (canPop→pop else go('/teacher/home')); "My courses" 17/700 + "N courses · M drafts" 12 grey subtitle; 40h primary pill "New course" (+ icon) → `context.push('/teacher/course/new')`. Body: `teacherCoursesProvider` via `.when` — rows: `SoftCard(radius 18, padding 12)` with 56px `subjectTint(subject)` radius-14 tile + `subjectIcon`, title 14/600, meta "N lessons · Grade X" 11.5 grey, status chip (colors in the design-source table above), trailing `PopupMenuButton` (Edit → push `/teacher/course/{id}`; Publish/Unpublish → `setStatus` + `ref.invalidate(teacherCoursesProvider)`; Delete → confirm dialog (radius 16, destructive style per the app's delete-account dialog) → `deleteCourse` + storage cleanup of its lesson files (loop lessons, `deleteByUrl` for videoUrl/documentUrl) + invalidate). Loading → centered spinner; error → `ErrorStateView(onRetry: invalidate)`; empty → `EmptyStateView(icon: Icons.school_outlined, message: 'No courses yet', action: PillButton('New course', → new))`.
- [ ] **Step 2: Routes** — under the teacher section of app_router.dart add `/teacher/courses` → `MyCoursesScreen()`. (Wizard routes come in Task 6; don't add yet.)
- [ ] **Step 3: Teacher home** — "My courses" section header gains "See all" 13/600 primary → `context.push('/teacher/courses')`; when the teacher has zero courses, show a compact SoftCard CTA row ("Create your first course" + chevron) → `/teacher/course/new` (replaces the section being hidden).
- [ ] **Step 4: Widget test** — override `teacherCoursesProvider` with 2 fixture courses (1 draft, 1 published; reuse fixture style from test/library/video_player_screen_test.dart): assert titles render, both chip labels render ('Draft', 'Published'), empty override renders 'No courses yet'. Pump inside MaterialApp + ProviderScope (no router needed — don't tap navigation).
- [ ] **Step 5: Verify + commit** — analyze clean; full `flutter test`; `git add lib test && git commit -m "feat(wizard): my courses management screen"`

---

### Task 6: Wizard shell + Basics step

**Files:**
- Create: `lib/features/teacher/course_editor/presentation/course_wizard_screen.dart` (shell + step indicator)
- Create: `lib/features/teacher/course_editor/presentation/basics_step.dart` (Pencil `dS7Ea`)
- Modify: `lib/routes/app_router.dart`
- Test: `test/teacher/basics_step_test.dart` (create)

- [ ] **Step 1: Routes** — `/teacher/course/new` and `/teacher/course/:courseId`, both building `CourseWizardScreen(courseId: state.pathParameters['courseId'])` (null for new). Existing `/teacher/*` guard covers them. IMPORTANT: register `/teacher/courses` BEFORE `/teacher/course/:courseId`? Not needed — different segments (`courses` vs `course`), no conflict.
- [ ] **Step 2: Shell** — `CourseWizardScreen` (ConsumerStatefulWidget): holds `_step` (0..2) and `_courseId` (null until created). Header: `CircleIconButton` back — step>0 → previous step; step==0 → canPop?pop:go('/teacher/courses'). Title: course title once known else "New course" 17/700; under it the "Saved as draft" tick row (12px green check + 11.5 grey text) shown once `_courseId != null`. Step indicator per design-source note. Steps render as an `IndexedStack` (keeps field state): `BasicsStep`, `LessonsStep` (Task 7), `ReviewStep` (Task 8) — for THIS task stub Lessons/Review as `Center(Text('...'))` placeholders replaced by their tasks (acceptable single-plan staging, the stubs are unreachable releases-wise until the branch completes).
- [ ] **Step 3: BasicsStep** — fields per Pencil `dS7Ea`: label 12.5/600 + `PillTextField`-style boxes (multiline description = 110h radius-16 TextField maxLines 4; dropdowns for subject/grade = 52h pill `DropdownButtonFormField` styled flat (or a bottom-sheet picker — match visual; simplest: `DropdownButtonHideUnderline` inside the pill container) — subjects: Math/Science/English/Social Studies/Amharic/Other mapping to the lowercase enum strings; grades: Grade 1..12); objectives editor: existing rows (14px primary check icon + text 13 + remove ×) + "Add objective" 36h primary-soft pill that appends an inline editable row; cap 5 (hide add button at cap). Continue `PillButton` enabled iff title.trim().isNotEmpty && subject != null && grade != null; `_isSubmitting` guard. On continue: if `_courseId == null` → `createDraft(...)` with `authorName` from `currentUserProfileProvider`'s profile fullName (read once; fallback null) → store id, show tick; else `updateBasics(...)`. Then `setState(_step = 1)`. Edit mode (`courseId` given): prefill by reading the course from `teacherCoursesProvider` (or a direct fetch via repository if not present); show existing values.
- [ ] **Step 4: Widget test** — pump `BasicsStep` standalone (give it callbacks/fake notifier: design BasicsStep to take `onContinue(BasicsData)` callback + optional initial data so it tests without Firebase): assert Continue disabled initially; enter title + pick subject + grade → enabled; objectives add/remove rows work; the callback receives the typed data on tap.
- [ ] **Step 5: Verify + commit** — analyze clean; full test suite; `git add lib test && git commit -m "feat(wizard): wizard shell and basics step with draft creation"`

---

### Task 7: Lessons step + lesson sheet

**Files:**
- Create: `lib/features/teacher/course_editor/presentation/lessons_step.dart` (Pencil `scFXB`)
- Create: `lib/features/teacher/course_editor/presentation/lesson_sheet.dart` (Pencil `ieBgI` / `btMMR`)
- Modify: `lib/features/teacher/course_editor/presentation/course_wizard_screen.dart` (replace stub)
- Test: `test/teacher/lessons_step_test.dart` (create)

- [ ] **Step 1: Lessons list** — stream/fetch the course's lessons (add a small `courseLessonsProvider(courseId)` family in course_editor domain reading via FirestoreService.getLessons + the Task-1 sort). Render `ReorderableListView` (buildDefaultDragHandles false; leading `Icons.drag_indicator` in a `ReorderableDragStartListener`): row = radius-16 surface card: 32px primarySoft number circle (order+1), title 13.5/600, status line (video: green `Icons.check_circle` "Video · mm:ss"; text lesson: primary `Icons.article_outlined` "Text lesson"; neither: amber `Icons.cloud_upload_outlined` "No content yet"; plus a paperclip suffix when documentUrl != null), overflow menu (Edit → open sheet prefilled; Delete → confirm → `deleteLesson` + `deleteByUrl` cleanup + refresh). onReorder → `applyReorder(courseId, reorderPayload(newIdSequence))` + refresh. "Add lesson" 52h primary-soft pill → sheet. Continue `PillButton` enabled iff ≥1 lesson → `_step = 2`.
- [ ] **Step 2: Lesson sheet** — `showModalBottomSheet` (isScrollControlled, radius top 24, handle bar): Video|Text segmented (44h, radius 22, active segment primary); shared fields title/description/duration; **Video mode**: upload zone per Pencil `ieBgI` (idle: primarySoft card, cloud-upload tile, "Upload video" + "MP4 up to 500 MB" → picks via `FilePicker.platform.pickFiles(type: FileType.video)` → uploading: filename, "N MB · uploading P%", white track + primary fill progress, cancel × calls `task.cancel()` → done: green check + tap to replace [replace deletes old via `deleteByUrl` first]) + Transcript multiline field (84h); **Text mode**: "Lesson content" multiline field (150h, stored to `contentHtml`); **both modes**: "Attach worksheet (PDF/DOC, optional)" 48h outlined row → `FilePicker` custom [pdf,doc,docx] → uploads via `startDocumentUpload` with its own inline progress → attached chip (primarySoft, file icon + "name · size" + remove × which `deleteByUrl`s and clears fields). Save lesson `PillButton`: requires title; video upload in-flight blocks save ("Uploading…" disabled label); writes via `repository.saveLesson` with `order = nextOrder(existing)` for new lessons. Mounted-guard every async continuation; the sheet owns its upload task lifecycle (cancel on dispose if in flight).
- [ ] **Step 3: Widget test** — pump `LessonsStep` with the lessons provider overridden to 3 fixtures (video w/ transcript, text, empty): assert rows render correct status lines and paperclip; Continue enabled; empty override → Continue disabled and "Add lesson" present. (Sheet upload flows are not widget-testable without Firebase — assert the sheet opens and mode toggle swaps the upload zone for the content field.)
- [ ] **Step 4: Verify + commit** — analyze; full suite; `git add lib test && git commit -m "feat(wizard): lessons step with reorder, typed lesson sheet, uploads"`

---

### Task 8: Review & Publish step

**Files:**
- Create: `lib/features/teacher/course_editor/presentation/review_step.dart` (Pencil `Y8H03`)
- Modify: `course_wizard_screen.dart` (replace stub)
- Test: extend `test/teacher/lessons_step_test.dart` pattern in `test/teacher/review_step_test.dart` (create)

- [ ] **Step 1: Build per Pencil `Y8H03`** — summary SoftCard (56px subjectTint tile + title + "Subject · Grade"); checklist SoftCard rows (green check / amber alert 17px + 13.5 text): "N lessons added" (amber + 'Add at least one lesson' when 0), "Videos on X of N lessons", "Transcripts on X of Y video lessons", "Description written" — informational except ≥1 lesson gates Publish; status SoftCard: "Course status" 14/600 + Draft/Published chip, helper copy 12.5 grey, `PillButton` Publish course (globe icon) ↔ Unpublish (outlined variant when published) via `setStatus` (+ invalidate providers, success toast SnackBar "Course published"), secondary 48h outlined "Save as draft & exit" (save icon) → `context.go('/teacher/courses')`; danger "Delete course" 48h dangerBorder row → confirm dialog ("Students will lose access" when published) → `deleteCourse` + storage cleanup → go('/teacher/courses').
- [ ] **Step 2: Widget test** — pump ReviewStep with fixture course/lessons via overrides or constructor data: checklist copy for 0-lesson case renders + Publish disabled; with 2 lessons Publish enabled; 'Save as draft & exit' present.
- [ ] **Step 3: Verify + commit** — `git commit -m "feat(wizard): review and publish step"` (add lib test).

---

### Task 9: Consumption wiring (authored fields render)

**Files:**
- Modify: `lib/features/library/presentation/course_details_screen.dart` (Overview tab)
- Modify: `lib/features/library/presentation/video_player_screen.dart`

- [ ] **Step 1: Overview cards** — in the Overview tab (built in the redesign; About card exists): render "What you'll learn" SoftCard (title 14/600 + rows of `Icons.check_circle_outline` 16 primary + text 13 grey 1.5) only when `course.learningObjectives.isNotEmpty`; render teacher SoftCard (44px primarySoft circle w/ primary initial + name 14/600 + "Course teacher" 12 grey) only when `course.authorName?.isNotEmpty == true`. Matches Pencil node `e6wIuU`'s designed cards.
- [ ] **Step 2: Player** — Transcript tab: replace its current placeholder content with `lesson.transcript` rendered as 13.5/1.6 grey selectable text inside the existing SoftCard wrapper; fallback `EmptyStateView(icon: Icons.subtitles_outlined, message: 'No transcript yet')` (compact). Text lessons (`videoUrl == null && contentHtml != null`): instead of the dark video box show a reading SoftCard (radius 20, padding 16, `contentHtml` as plain text 14/1.6 textBody, scrollable within the existing layout) — keep "Video unavailable" ONLY for lessons with neither video nor content. Worksheet: when `lesson.documentUrl != null` add a row under the lesson head (primarySoft radius-16 padding-12: paperclip 16 primary + `documentName` 13/600 primary + `Icons.open_in_new` 14) → `launchUrl(Uri.parse(lesson.documentUrl!), mode: LaunchMode.externalApplication)`.
- [ ] **Step 3: Update `test/library/video_player_screen_test.dart`** — add: text-lesson fixture renders its body text (not "Video unavailable"); transcript fixture renders in Transcript tab after tab switch; worksheet fixture renders the documentName row.
- [ ] **Step 4: Verify + commit** — analyze; full suite; `git add lib test && git commit -m "feat(wizard): render objectives, author, transcript, text lessons, worksheets"`

---

### Task 10: Full verification + PR

- [ ] **Step 1:** `flutter analyze` → "No issues found!". `flutter test` → all pass (report total; expect ~60+).
- [ ] **Step 2:** `flutter build apk --release` → succeeds.
- [ ] **Step 3: Re-seed parity check** — `node --check tool/seed-course.js`; optionally run the seed (service account at `tool/service-account.json`) to confirm `order`/`transcript` fields write and the app still renders seeded content.
- [ ] **Step 4: Flow reasoning pass** — teacher: home → My courses → New course → basics (draft created) → lessons (add video w/ transcript + text lesson + worksheet) → review → publish → visible in student library; edit existing; unpublish; delete w/ cleanup. Student: overview shows objectives + teacher; player shows transcript/reading card/worksheet. Deep-link safety on new routes (guards + canPop fallbacks).
- [ ] **Step 5:** Push and open PR titled "Course-creation wizard: teacher authoring with uploads, transcripts, and worksheets".
