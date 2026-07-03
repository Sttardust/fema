# FEMA MVP Redesign + Video Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the approved Pencil designs (indigo `#4B0082`, Figtree, flat fills) across every MVP screen and add real video playback, per `docs/superpowers/specs/2026-07-02-fema-mvp-design.md`.

**Architecture:** Token-first: Task 1 rewrites `AppColors`/`AppTextStyles` (every screen retints immediately since all screens reference them). Task 2 adds a small shared UI kit matching the Pencil components (pill buttons/fields, soft cards, capsule tab bar). Screen tasks then rebuild each screen's build method against its Pencil design. Video playback is a self-contained foundation task consumed by the player screen task.

**Tech Stack:** Flutter, Riverpod, go_router, google_fonts (Figtree), video_player + chewie, Firebase Storage URLs in `lesson.videoUrl`.

**Branch:** `feat/mvp-redesign` (created from `main`).

---

## Design source of truth

Pencil file: `/Users/semere/.pencil/documents/2081a41d-010b-4f2e-b028-bc948c09956a/pencil-new.pen`

Implementers with Pencil MCP access can pull any screen with
`get_screenshot(nodeId: <id>)` and exact specs with `batch_get(nodeIds: [<id>], readDepth: 4)`.
If MCP is unavailable, the specs tables in each task carry the required values.

| Screen | Pencil node | Screen | Pencil node |
|---|---|---|---|
| Home | `E2DPE8` | Welcome | `Rl4cO` |
| Library | `e2FRcG` | Sign Up | `nuqcl` |
| Course Details (Curriculum) | `rdG23` | Phone Sign In | `UyJIS` |
| Course Details (Overview) | `e6wIuU` | Grade Selection | `VDY0Y` |
| Lesson Player | `sTmiY` | Search | `BXzER` |
| Sign In | `XHjr2` | Account Management | `da4uL` |
| Verify Phone (OTP) | `wVEO0` | Class Mgmt (Students) | `UDNea` |
| Choose Role | `JbBAd` | Course Overview | `e6wIuU` |
| Teacher Home | `w7IkO` | Admin Home | `ntKit` |
| Class Mgmt (Attendance) | `Sd3Po` | Profile | `ErO0O` |

**Design tokens (canonical values):**

| Token | Value | Token | Value |
|---|---|---|---|
| primary | `#4B0082` | text-primary | `#211936` |
| primary-dark | `#38005F` | text-secondary | `#8B84A0` |
| primary-light | `#7A42B5` | stroke-soft | `#E7E2F1` |
| primary-soft | `#EFE7F8` | subject-1..4 | `#4B0082` `#6D35A6` `#8F5BC4` `#B187DD` |
| bg | `#F5F2FA` | danger | `#C0392B` / bg `#FDF2F2` |
| surface | `#FFFFFF` | font | Figtree (headings 700–800, body 400–600) |

**Recurring shapes:** cards radius 18–24 + shadow `#1C1633` at 5% blur 18 y6; buttons/fields height 54 radius 27 (full pill); chips radius 18 padding 9×14; primary button shadow `#4B0082` at 25% blur 22 y10; floating capsule tab bar 56 tall radius 28, inset 16 sides / 12 bottom, active tab on `primary-soft` capsule.

---

### Task 1: Design tokens — colors + Figtree

**Files:**
- Modify: `lib/core/theme/app_colors.dart`
- Modify: `lib/core/theme/app_text_styles.dart`

- [ ] **Step 1: Rewrite AppColors** (keep the class name and all existing member NAMES so hidden screens still compile; change values, add new members):

```dart
import 'package:flutter/material.dart';

class AppColors {
  // Brand — indigo, from the Pencil MVP design system.
  static const Color primary = Color(0xFF4B0082);
  static const Color primaryLight = Color(0xFF7A42B5);
  static const Color primaryDark = Color(0xFF38005F);
  static const Color primarySoft = Color(0xFFEFE7F8);

  // Selection state used on role cards, grade tiles, chips.
  static const Color selectionFill = primarySoft;
  static const Color selectionBorder = primary;

  // Legacy accents kept for hidden (non-MVP) screens; muted to palette tints.
  static const Color secondary = Color(0xFF8F5BC4);
  static const Color accent = Color(0xFFB187DD);
  static const Color childrenModeBg = primarySoft;

  // Neutrals
  static const Color splashBg = Color(0xFFF5F2FA);
  static const Color background = Color(0xFFF5F2FA);
  static const Color surface = Colors.white;
  static const Color textBody = Color(0xFF211936);
  static const Color textHeadline = Color(0xFF211936);
  static const Color grey = Color(0xFF8B84A0);
  static const Color greyLight = Color(0xFFE7E2F1);

  // Subject thumbnail tints (flat fills, no gradients)
  static const List<Color> subjectTints = [
    Color(0xFF4B0082),
    Color(0xFF6D35A6),
    Color(0xFF8F5BC4),
    Color(0xFFB187DD),
  ];

  // Semantic
  static const Color success = Color(0xFF2BB37A);
  static const Color error = Color(0xFFC0392B);
  static const Color errorSoft = Color(0xFFFDF2F2);
  static const Color warning = Color(0xFFE5A63C);

  // Card shadow: #1C1633 at 5%
  static const Color cardShadow = Color(0x0D1C1633);
  // Primary button shadow: #4B0082 at 25%
  static const Color primaryShadow = Color(0x404B0082);
}
```

- [ ] **Step 2: Switch AppTextStyles to Figtree** — in `app_text_styles.dart`, replace every `GoogleFonts.poppins(` with `GoogleFonts.figtree(` (keep sizes/weights/colors as-is for now; screen tasks override locally where the design differs). Headline styles get `fontWeight: FontWeight.w800` for `headlineLarge` and `w700` for medium/small.

- [ ] **Step 3: Verify** — `flutter analyze` → no new issues; `flutter test` → all pass. Run the app briefly (`flutter run`) if a device is available: every screen should already show indigo + Figtree.

- [ ] **Step 4: Commit** — `git add lib/core/theme && git commit -m "feat(redesign): indigo palette and Figtree typography tokens"`

---

### Task 2: Shared UI kit

**Files:**
- Create: `lib/core/widgets/pill_button.dart`
- Create: `lib/core/widgets/pill_text_field.dart`
- Create: `lib/core/widgets/soft_card.dart`
- Create: `lib/core/widgets/capsule_tab_bar.dart`
- Test: `test/core/widgets/ui_kit_test.dart`

- [ ] **Step 1: Write failing smoke test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fema/core/widgets/pill_button.dart';
import 'package:fema/core/widgets/soft_card.dart';
import 'package:fema/core/widgets/capsule_tab_bar.dart';

void main() {
  testWidgets('ui kit renders', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(children: [
          PillButton(label: 'Continue', onPressed: () {}),
          PillButton.outlined(label: 'Browse as guest', onPressed: () {}),
          const SoftCard(child: Text('card')),
        ]),
        bottomNavigationBar: CapsuleTabBar(
          currentIndex: 0,
          onTap: (_) {},
          items: const [
            CapsuleTabItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
            CapsuleTabItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
          ],
        ),
      ),
    ));
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('card'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
  });
}
```

Run: `flutter test test/core/widgets/ui_kit_test.dart` → FAIL (files missing).

- [ ] **Step 2: Implement the kit**

`pill_button.dart` — 54-high, radius 27; filled (primary bg, white 700 label, `AppColors.primaryShadow` blur 22 offset y10) and `.outlined` variant (surface bg, `AppColors.greyLight` 1px border, textBody 600 label). Signature:

```dart
class PillButton extends StatelessWidget {
  const PillButton({super.key, required this.label, required this.onPressed, this.icon, this.enabled = true})
      : _outlined = false;
  const PillButton.outlined({super.key, required this.label, required this.onPressed, this.icon, this.enabled = true})
      : _outlined = true;
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool enabled;
  final bool _outlined;
  // build(): SizedBox(height: 54, width: double.infinity) wrapping Material+InkWell
  // (borderRadius 27) with optional 18px icon + 8 gap + label. Disabled state:
  // greyLight fill, grey label, no shadow.
}
```

`pill_text_field.dart` — 54-high pill container (surface fill, greyLight 1px border, radius 27, padding h20) with 18px leading icon (grey) + `TextField` (decoration collapsed, hint in grey). Props: `hint`, `icon`, `controller`, `obscureText`, `keyboardType`, `focused` (focused → primary 1.5px border).

`soft_card.dart`:

```dart
class SoftCard extends StatelessWidget {
  const SoftCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.radius = 18, this.onTap});
  // Container: surface fill, BorderRadius.circular(radius),
  // boxShadow [BoxShadow(color: AppColors.cardShadow, blurRadius: 18, offset: Offset(0, 6))],
  // wrapped in InkWell when onTap != null.
}
```

`capsule_tab_bar.dart` — floating capsule per the Pencil design: outer Padding (16 sides, 12 bottom) inside SafeArea; 56-high container, radius 28, `Colors.white.withValues(alpha: 0.7)` fill, cardShadow blur 24 y8; children = expanded items; active item gets a `primarySoft` radius-22 capsule, primary filled icon + 10px 600 label; inactive grey outline icon + 10px 500 label. `CapsuleTabItem({icon, activeIcon, label})`.

- [ ] **Step 3: Test passes** — `flutter test test/core/widgets/ui_kit_test.dart` → PASS; `flutter analyze` clean.

- [ ] **Step 4: Commit** — `git add lib/core/widgets test/core/widgets && git commit -m "feat(redesign): shared pill/card/capsule UI kit"`

---

### Task 3: Auth screens — Welcome, Sign In, Sign Up, Phone Sign In, OTP

**Files:**
- Modify: `lib/features/onboarding/presentation/fema_intro_screen.dart` (Welcome, node `Rl4cO`)
- Modify: `lib/features/auth/presentation/email_login_screen.dart` (Sign In, node `XHjr2`)
- Modify: `lib/features/auth/presentation/email_signup_screen.dart` (Sign Up, node `nuqcl`)
- Modify: `lib/features/auth/presentation/phone_login_screen.dart` + `phone_signup_screen.dart` (node `UyJIS`)
- Modify: `lib/features/auth/presentation/otp_screen.dart` (node `wVEO0`)

For each screen: keep ALL existing logic (controllers, providers, navigation, validation) and rebuild only the visual tree to match the Pencil node. Use `Scaffold(backgroundColor: AppColors.background)` and the Task-2 kit.

- [ ] **Step 1: Welcome (`Rl4cO`)** — centered 200px `primarySoft` circle containing 120px primary circle with white graduation-cap icon (56); headline "Learn anywhere, anytime" (26/800 centered); sub copy (14, grey, 1.55 height); page dots (active = 20×6 radius-3 primary bar, inactive 6px greyLight circles); `PillButton` "Get started" → existing signup navigation; `PillButton.outlined` "Browse as guest" → existing guest navigation; footer "Already have an account? **Sign in**" (link primary 700).
- [ ] **Step 2: Sign In (`XHjr2`)** — 64px radius-20 primary logo tile (graduation-cap), "Welcome to FEMA" 24/800, sub copy, `PillTextField` email (mail icon) + password (lock icon, obscure), right-aligned "Forgot password?" (13/600 primary), `PillButton` "Sign in", "or" divider (1px greyLight lines + 12px grey label), `PillButton.outlined` with smartphone icon "Continue with phone", "Browse as guest →" text row, footer "New here? **Create an account**".
- [ ] **Step 3: Sign Up (`nuqcl`)** — 40px circular surface back button (chevron-left, cardShadow); "Create your account" 24/800 + sub; fields: name (user icon), email (mail), password (lock); terms line (12 grey); `PillButton` "Create account"; divider; `PillButton.outlined` "Sign up with phone"; footer "Already have an account? **Sign in**".
- [ ] **Step 4: Phone Sign In (`UyJIS`)** — back button; "Continue with phone" 24/800 + sub; row: fixed country pill (🇪🇹 +251, surface, greyLight border, radius 27, h54, padding h16) + expanded `PillTextField` for the number (focused border primary 1.5); `PillButton` "Send code"; info note card (`primarySoft` radius 16 padding 14: 16px primary info icon + 12.5px textBody copy). Apply to both phone_login and phone_signup screens (same layout, different titles/actions — keep existing distinctions).
- [ ] **Step 5: OTP (`wVEO0`)** — back button; "Verify your number" 24/800; sub shows masked number; 6 equal-width 58-high radius-16 code boxes (surface, greyLight border; focused box primary 1.5 border; entered digits 20/700) — keep the existing OTP input logic, restyle the boxes; "Didn't get the code? **Resend in 0:42**" row; `PillButton` "Verify".
- [ ] **Step 6: Verify** — `flutter analyze` clean; `flutter test` all pass; `flutter run`: walk welcome → sign in → phone → OTP visually against the Pencil screenshots.
- [ ] **Step 7: Commit** — `git commit -m "feat(redesign): auth screens in indigo design system"` (add the five files).

---

### Task 4: Onboarding — Choose Role + Grade Selection

**Files:**
- Modify: `lib/features/onboarding/presentation/role_selection_screen.dart` (node `JbBAd`)
- Modify: `lib/features/onboarding/presentation/grade_selection_screen.dart` (node `VDY0Y`)
- Test: existing `test/onboarding/role_selection_screen_test.dart` must keep passing

- [ ] **Step 1: Choose Role (`JbBAd`)** — "Who are you?" 24/800 + sub copy; two role cards (radius 20 padding 18): 52px radius-16 icon tile + title 16/700 + desc 12.5 grey + trailing 22px state icon (circle-check primary when selected, circle greyLight otherwise). Selected card: `primarySoft` fill + primary 1.5 border, icon tile primary with white icon; unselected: surface + cardShadow, icon tile `primarySoft` with primary icon. Student icon: backpack; Teacher: co_present/podium equivalent (Material `Icons.co_present_outlined`). `PillButton` "Continue" (disabled until selection — keep `_isSubmitting` guard).
- [ ] **Step 2: Grade Selection (`VDY0Y`)** — back button; "What grade are you in?" 24/800 + sub; "PRIMARY EDUCATION" / "SECONDARY EDUCATION" section labels (12/600 grey, uppercase); 3-column grid of 52-high radius-16 grade tiles (surface + greyLight border; selected: primary fill, white 700 label); `PillButton` "Continue" (existing `_finishWithGrade` logic + guard unchanged; parental modal restyled: radius 16, `PillButton` for "I Understand").
- [ ] **Step 3: Verify** — analyze clean, `flutter test` passes (role test asserts labels which are unchanged).
- [ ] **Step 4: Commit** — `git commit -m "feat(redesign): onboarding role and grade screens"`.

---

### Task 5: Student Home + Search

**Files:**
- Modify: `lib/features/home/presentation/home_screen.dart` (shell + `_StudentHomePage`, node `E2DPE8`)
- Modify: `lib/features/home/presentation/search_screen.dart` (node `BXzER`)

- [ ] **Step 1: Home shell** — replace the box-shadow bottom bar with `CapsuleTabBar` (Home/`My Courses`→label "Library"/Profile per node `E2DPE8`'s tab bar). Body backgrounds `AppColors.background`. Keep `IndexedStack` + `homeTabProvider` wiring and the guest banner logic (restyle banner as `primarySoft` note card).
- [ ] **Step 2: `_StudentHomePage` (`E2DPE8`)** top-to-bottom: header row (46px primary circle avatar with initial 18/700 white; "Hi, {firstName} 👋" 18/700 + "What will you learn today?" 13 grey); search pill (52h radius 26 surface + cardShadow, search icon + hint) navigating to `/home/search`; **continue-learning card** (primary fill radius 24 padding 20, `#4B0082` 20% shadow blur 28 y12): white-20% "CONTINUE LEARNING" badge pill, course title 18/700 white, white-24% progress track 6h radius 3 with white fill + "12 of 24 lessons" 12 white-80%, trailing 52px white circle play button (primary play icon) — bind to the user's most recent course from existing providers, hide the card when none; subject chips row (horizontally scrollable: All active primary fill white label, others surface + greyLight border grey label); "Popular courses" 17/700 + "See all" 13/600 primary; 2-column grid of course cards (SoftCard radius 20 padding 12: full-width 88h radius-14 flat tint thumb from `AppColors.subjectTints[i % 4]` with centered white 30px subject icon, title 14/600 2-line, meta row circle-play 14px + "N lessons" 12 grey) — bind to existing published-course providers.
- [ ] **Step 3: Search (`BXzER`)** — back button + active search pill (primary 1.5 border, primary search icon, live query text); results label "N RESULTS" (12/600 grey); result rows = horizontal SoftCards (60px radius-14 tint thumb + title 14/600 + "Grade N · M lessons" 12 grey + chevron); "RECENT SEARCHES" section: history icon + query + x rows (keep existing search state logic).
- [ ] **Step 4: Verify** — analyze, tests, `flutter run` visual pass on home/search incl. guest mode.
- [ ] **Step 5: Commit** — `git commit -m "feat(redesign): student home and search"`.

---

### Task 6: Library + Course Details

**Files:**
- Modify: `lib/features/library/presentation/library_screen.dart` (node `e2FRcG`)
- Modify: `lib/features/library/presentation/course_details_screen.dart` (nodes `rdG23` Curriculum / `e6wIuU` Overview)

- [ ] **Step 1: Library (`e2FRcG`)** — "Library" 22/700 title; search pill; subject chips; vertical list of row cards (as Search results style). Bind to existing course providers; keep guest access.
- [ ] **Step 2: Course Details** — top nav: 40px circular back + "Course details" 16/600 + 40px circular bookmark (visual only if bookmark logic absent — omit if dead, per trim rules omit: **omit the bookmark button**, node design allows it); **banner** (primary radius 24 padding 20, primary shadow): 52px white-16% radius-16 subject icon tile, course title 20/700 white, meta row (circle-play "N lessons" · clock "H h M m" · graduation-cap "Grade N", 12 white-80%); **segmented control** (48h radius 24 surface + cardShadow, 4px inner padding): Overview | Curriculum, active segment primary fill white 13/600 label — wire to the EXISTING tab state; **Curriculum tab (`rdG23`)**: lesson rows radius 16 (current lesson: `primarySoft` fill + primary 1.5 border, 36px primary number circle white text; others: surface + soft shadow, `background` number circle grey text; locked lessons trailing lock icon grey, others circle-play primary); **Overview tab (`e6wIuU`)**: SoftCard "About this course" + 13/1.55 grey body; SoftCard "What you'll learn" with circle-check primary bullets; SoftCard teacher row (44px `primarySoft` avatar circle with primary initial + name 14/600 + "Physics teacher · ..." 12 grey); bottom `PillButton` with play icon "Continue learning" → existing continue action.
- [ ] **Step 3: Verify + Commit** — analyze/tests/visual; `git commit -m "feat(redesign): library and course details"`.

---

### Task 7: Video playback foundation

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/features/library/domain/lesson_video_controller.dart`
- Test: `test/library/lesson_video_controller_test.dart`

- [ ] **Step 1: Add packages**

```yaml
  video_player: ^2.9.2
  chewie: ^1.8.5
```

Run `flutter pub get`.

- [ ] **Step 2: Failing test** — controller state mapping only (no platform channels):

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fema/features/library/domain/lesson_video_controller.dart';

void main() {
  test('rejects empty or non-http video urls', () {
    expect(LessonVideoController.isPlayableUrl(null), false);
    expect(LessonVideoController.isPlayableUrl(''), false);
    expect(LessonVideoController.isPlayableUrl('notaurl'), false);
    expect(LessonVideoController.isPlayableUrl('https://firebasestorage.googleapis.com/v0/b/x/o/y.mp4?alt=media'), true);
  });
}
```

- [ ] **Step 3: Implement `LessonVideoController`** — thin wrapper owning `VideoPlayerController.networkUrl` + `ChewieController`:

```dart
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../core/theme/app_colors.dart';

class LessonVideoController {
  LessonVideoController(this.url);
  final String url;
  VideoPlayerController? _video;
  ChewieController? chewie;

  static bool isPlayableUrl(String? url) =>
      url != null && (Uri.tryParse(url)?.hasScheme ?? false) &&
      (url.startsWith('http://') || url.startsWith('https://'));

  Future<void> initialize() async {
    _video = VideoPlayerController.networkUrl(Uri.parse(url));
    await _video!.initialize();
    chewie = ChewieController(
      videoPlayerController: _video!,
      autoPlay: false,
      allowFullScreen: true,
      allowMuting: true,
      materialProgressColors: ChewieProgressColors(
        playedColor: AppColors.primary,
        handleColor: AppColors.primary,
        bufferedColor: AppColors.primaryLight,
        backgroundColor: AppColors.greyLight,
      ),
    );
  }

  void dispose() {
    chewie?.dispose();
    _video?.dispose();
  }
}
```

- [ ] **Step 4: Tests pass, analyze clean.** Document the seeding workflow in `README.md` (## Content seeding): upload MP4 to Firebase Storage → copy download URL → set `videoUrl` on the lesson doc.

- [ ] **Step 5: Storage rules** — there is no `storage.rules` yet. Create it and register in `firebase.json`:

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Lesson videos are seeded by admins from the console; clients only read.
    match /lesson-videos/{video=**} {
      allow read: if true;   // published-course videos are world-readable (guest mode)
      allow write: if false; // uploads happen via the Firebase console only
    }
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

In `firebase.json`, add alongside the firestore entry:

```json
  "storage": {
    "rules": "storage.rules"
  },
```

Validate with `firebase deploy --only storage --dry-run` (skip gracefully if Storage isn't enabled on the project yet — note it in the report; enabling Storage in the console is an operational step for the release phase).

- [ ] **Step 6: Commit** — `git add pubspec.yaml pubspec.lock lib/features/library/domain/lesson_video_controller.dart test/library storage.rules firebase.json README.md && git commit -m "feat(video): video_player/chewie foundation, url validation, storage rules"`.

---

### Task 8: Lesson Player — redesign + real video

**Files:**
- Modify: `lib/features/library/presentation/video_player_screen.dart` (node `sTmiY`)

- [ ] **Step 1: Rebuild per `sTmiY`** — top nav (back circle, "Lesson N of M" 16/600, ellipsis circle); **video area**: 16:9 radius-20 clipped container — when `LessonVideoController.isPlayableUrl(lesson.videoUrl)`: `Chewie(controller: ...)` (init in `initState` from the selected lesson, dispose properly, re-init on lesson change); loading → centered `CircularProgressIndicator(color: AppColors.primary)` on `#211936`; error/no-url → dark placeholder with white 56px circle play-disabled icon + "Video unavailable" 12 white-70%; below: title 19/700, "Course · Grade" 13 grey; tabs as chips (Notes/Transcript/Up next — active primary fill) driving the EXISTING TabBarView content (restyle the existing tabs, keep their content wiring); Notes content in a SoftCard with primary-dot bullets; bottom Previous (`PillButton.outlined` chevron-left) / Next (`PillButton` chevron-right) row — keep existing prev/next lesson logic.
- [ ] **Step 2: Verify** — analyze/tests; on a device with a seeded Storage URL: video initializes, plays, seeks, fullscreens; lesson without URL shows the unavailable state (no crash); prev/next swaps videos without leaking controllers (watch for `setState after dispose` errors in logs).
- [ ] **Step 3: Commit** — `git commit -m "feat(redesign): lesson player with real video playback"`.

---

### Task 9: Teacher screens — Teacher Home + Class Management

**Files:**
- Modify: `lib/features/teacher/presentation/teacher_home_screen.dart` (node `w7IkO`)
- Modify: `lib/features/teacher/presentation/class_management_screen.dart` (nodes `Sd3Po` attendance / `UDNea` students)

- [ ] **Step 1: Teacher Home (`w7IkO`)** — header (avatar initial circle primary, "Hi, {name} 👋" 18/700, "Here's your teaching overview" 13 grey); 3 stat SoftCards (34px `primarySoft` radius-11 icon tile, value 19/800, label 11.5 grey) bound to existing class/student counts (attendance % may be a placeholder "—" if no metric exists — bind only real data); **attendance CTA** (primary radius 20 padding 18 card: white-16% clipboard icon tile, "Take today's attendance" 15/700 white + next-class subline 12 white-80%, arrow-right) → navigates to class management; "Your classes" section header + class row cards (48px tint radius-14 school icon tile, name 14/600, "N students · schedule" 12 grey, chevron); replace bottom bar with `CapsuleTabBar` (Home/Classes/Profile).
- [ ] **Step 2: Class Management** — top nav (back, class name 17/700 + "N students · schedule" 12 grey, 40px primary circle plus-button → existing add flows); **segmented Students | Attendance** (same control as Task 6) wired to existing tab/view state; **Attendance view (`Sd3Po`)**: date row (calendar icon primary + "Wed, Jul 2" 14/600, "N of M marked" 12 grey), student rows (40px `primarySoft` avatar with primary initial, name 14/600, "Roll no. NN" 11.5 grey, trailing 24px toggle icon — circle-check primary when present, circle-x greyLight when absent; tap toggles via existing attendance logic), `PillButton` "Save attendance"; **Students view (`UDNea`)**: same rows with trailing ellipsis-vertical menu (existing actions), `PillButton` "Add student".
- [ ] **Step 3: Verify + Commit** — analyze/tests/visual; `git commit -m "feat(redesign): teacher home and class management"`.

---

### Task 10: Profile + Account Management + Admin Home

**Files:**
- Modify: `lib/features/profile/presentation/profile_screen.dart` (node `ErO0O`)
- Modify: `lib/features/profile/presentation/account_management_screen.dart` (node `da4uL`)
- Modify: the admin home screen under `lib/features/home/presentation/` (node `ntKit` — locate the admin screen the `/admin/*` routes point to)

- [ ] **Step 1: Profile (`ErO0O`)** — "Profile" 22/700; identity SoftCard (72px primary circle avatar 26/800 white initial, name 18/700, email 13 grey, role badge pill `primarySoft` radius 14 "Student · Grade 9" 12/600 primary); "ACCOUNT" and "APP" group labels (12/600 grey) over grouped SoftCards of nav rows (34px `primarySoft` icon tile + label 14/500 + chevron): Edit profile / Account & security; Language / Help & support / About FEMA; sign-out outlined row (surface, `#F1D7D7` border, log-out icon + "Sign out" 14/600 in `AppColors.error`) — keep all existing tap handlers.
- [ ] **Step 2: Account Management (`da4uL`)** — top nav back + "Account & security" 17/700; "SECURITY" group (Change password / Email with value subline / Phone number with masked value); "DANGER ZONE" label in error color; danger SoftCard (`#F1D7D7` border): "Delete account" 14/600, explanation 12.5 grey (mention authored-content anonymization), full-width 46h radius-23 `errorSoft` button with trash icon + "Delete my account" 14/600 error — wire to the EXISTING delete-account flow (Cloud Function call + confirmation dialog; restyle the dialog radius 16 with PillButtons).
- [ ] **Step 3: Admin Home (`ntKit`)** — header (46px primary circle shield-check icon, "Admin console" 18/700, "FEMA platform overview" 13 grey); 3 stat SoftCards (Students/Teachers/Courses — bind to real counts if a provider exists, else static placeholders clearly marked TODO-free: bind what exists, hide what doesn't); "MANAGEMENT" group card rows (Manage users / Manage courses / Analytics / Platform settings) pointing at the existing admin routes; `primarySoft` info note: "Admin accounts are provisioned via the bootstrap script. Content is seeded from the Firebase console in the MVP."
- [ ] **Step 4: Verify + Commit** — analyze/tests/visual; `git commit -m "feat(redesign): profile, account management, admin home"`.

---

### Task 11: Full verification pass

- [ ] **Step 1:** `flutter analyze` → No issues found (info-level lints in hidden screens acceptable; none in redesigned files).
- [ ] **Step 2:** `flutter test` → all pass.
- [ ] **Step 3:** `flutter build apk --debug` → builds.
- [ ] **Step 4: Visual QA against Pencil** — side-by-side each screen vs `get_screenshot` of its node (or exported PNGs): colors exact (#4B0082 family), Figtree everywhere (no Poppins leftovers — grep `GoogleFonts.poppins` → zero hits in lib/), no gradients (`grep -rn "LinearGradient\|RadialGradient" lib/` → only hits in hidden/unreachable screens, none in MVP screens), capsule tab bars on home/teacher/profile tabs.
- [ ] **Step 5: Flows** — guest browse → course → player; student signup → grade → home → search → watch seeded video; teacher → classes → attendance toggle → save; profile → account management; deep-link `/admin/management` as admin.
- [ ] **Step 6:** Push and open PR (`gh pr create`) titled "MVP redesign: indigo design system + real video playback".
