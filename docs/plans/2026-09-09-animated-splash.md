# Animated Splash Screen Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the plain `/` placeholder with an animated Alizé splash (wave mark draw + wordmark fade) that exits only after the animation minimum (~2s) and auth resolution.

**Architecture:** Pure Flutter splash on route `/`. `AlizeWaveMark` paints stroke progress via `PathMetric`. `SplashPage` owns animation controllers, watches `authProvider`, and navigates when `animationDone && auth is! AuthUnknown`. Existing `redirectFor` stays unchanged for AuthUnknown-on-`/`. Soft brand-wash background; native Android launch color aligned to paper.

**Tech Stack:** Flutter, Riverpod, go_router, `CustomPainter`, `AnimationController` (no Rive/Lottie).

**Design:** `docs/plans/2026-09-09-animated-splash-design.md`

---

### Task 1: Failing widget test for splash content

**Files:**
- Create: `mobile/test/features/splash/presentation/splash_page_test.dart`
- Create (later): `mobile/lib/features/splash/presentation/pages/splash_page.dart`

**Step 1: Write the failing test**

```dart
import 'package:alize_mobile/core/l10n/i18n.dart';
import 'package:alize_mobile/core/l10n/i18n_provider.dart';
import 'package:alize_mobile/core/theme/alize_theme.dart';
import 'package:alize_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:alize_mobile/features/auth/presentation/providers/auth_state.dart';
import 'package:alize_mobile/features/splash/presentation/pages/splash_page.dart';
import 'package:alize_mobile/features/splash/presentation/widgets/alize_wave_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

class _UnknownAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthUnknown();
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('SplashPage shows wave mark and brand wordmark', (tester) async {
    final i18n = await I18n.load();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          i18nProvider.overrideWith((ref) => I18nController(i18n)),
          authProvider.overrideWith(() => _UnknownAuth()),
        ],
        child: MaterialApp(
          theme: AlizeTheme.light(),
          home: const SplashPage(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(AlizeWaveMark), findsOneWidget);
    expect(find.text(i18n.t('brand')), findsOneWidget);
  });
}
```

Adjust imports if `auth_state.dart` is exported from `auth_providers.dart` (check existing tests).

**Step 2: Run test to verify it fails**

Run: `cd mobile && flutter test test/features/splash/presentation/splash_page_test.dart`

Expected: FAIL (missing `SplashPage` / `AlizeWaveMark`).

**Step 3: Commit the failing test**

```bash
git add mobile/test/features/splash/presentation/splash_page_test.dart
git commit -m "test: add failing splash content widget test"
```

---

### Task 2: Implement AlizeWaveMark painter

**Files:**
- Create: `mobile/lib/features/splash/presentation/widgets/alize_wave_mark.dart`

**Step 1: Implement mark widget**

Match web sidebar SVG paths (viewBox 0 0 24 24):

- Path 1: `M3 14c4-6 8 6 12 0s5-4 6-2`
- Path 2: `M3 19c4-6 8 6 12 0s5-4 6-2`

```dart
import 'dart:ui';

import 'package:flutter/material.dart';

class AlizeWaveMark extends StatelessWidget {
  const AlizeWaveMark({
    super.key,
    required this.progress,
    required this.color,
    this.size = 72,
  });

  /// 0..1 overall draw progress (0–0.5 = first stroke, 0.5–1 = second).
  final double progress;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Alizé',
      child: CustomPaint(
        size: Size.square(size),
        painter: _WavePainter(progress: progress.clamp(0.0, 1.0), color: color),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  static Path get _upper => Path()
    ..moveTo(3, 14)
    ..cubicTo(7, 8, 11, 20, 15, 14)
    ..cubicTo(17, 11, 19, 10, 21, 12);

  static Path get _lower => Path()
    ..moveTo(3, 19)
    ..cubicTo(7, 13, 11, 25, 15, 19)
    ..cubicTo(17, 16, 19, 15, 21, 17);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    canvas.scale(scale);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    _drawPartial(canvas, _upper, (progress * 2).clamp(0.0, 1.0), paint);
    _drawPartial(canvas, _lower, ((progress - 0.5) * 2).clamp(0.0, 1.0), paint);
  }

  void _drawPartial(Canvas canvas, Path path, double t, Paint paint) {
    if (t <= 0) return;
    for (final metric in path.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * t), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
```

Tune cubic control points if needed so the mark matches the SVG visually; prefer parsing with exact SVG path data via a small helper if cubics look off.

**Step 2: Minimal SplashPage stub so content test can pass**

Create `mobile/lib/features/splash/presentation/pages/splash_page.dart` with static mark (`progress: 1`) + brand text, gradient background from `AlizeColors`, no exit logic yet.

**Step 3: Run content test**

Run: `cd mobile && flutter test test/features/splash/presentation/splash_page_test.dart`

Expected: PASS

**Step 4: Commit**

```bash
git add mobile/lib/features/splash mobile/test/features/splash
git commit -m "feat: add AlizeWaveMark and splash page shell"
```

---

### Task 3: Wire splash animations (mark draw + wordmark)

**Files:**
- Modify: `mobile/lib/features/splash/presentation/pages/splash_page.dart`
- Modify: `mobile/test/features/splash/presentation/splash_page_test.dart`

**Step 1: Add animation behavior on SplashPage**

- `TickerProviderStateMixin`
- One controller ~2000ms (or two staggered controllers)
- Intervals: mark 0–0.55, wordmark 0.45–0.75, hold to 1.0
- Curves: `Curves.easeOutCubic` for mark, `Curves.easeOut` for wordmark
- Respect `MediaQuery.disableAnimationsOf(context)` → jump to progress 1, shorter hold (~800ms total)
- Soft wash: `LinearGradient` top-left paper → bottom-right brandTint
- Wordmark: `Opacity` + `Transform.translate` (12px → 0)

**Step 2: Test that mark progress advances after pump**

```dart
testWidgets('wave mark animates from empty toward drawn', (tester) async {
  // pump SplashPage with AuthUnknown
  await tester.pump(); // frame 0
  final before = tester.widget<AlizeWaveMark>(find.byType(AlizeWaveMark));
  expect(before.progress, lessThan(0.2));

  await tester.pump(const Duration(milliseconds: 600));
  final mid = tester.widget<AlizeWaveMark>(find.byType(AlizeWaveMark));
  expect(mid.progress, greaterThan(before.progress));
});
```

**Step 3: Run tests — PASS — Commit**

```bash
git commit -m "feat: animate splash wave mark and wordmark"
```

---

### Task 4: Exit gate (min duration + auth ready)

**Files:**
- Modify: `mobile/lib/features/splash/presentation/pages/splash_page.dart`
- Modify: `mobile/test/features/splash/presentation/splash_page_test.dart`

**Step 1: Write failing navigation tests**

Use `GoRouter` with `/`, `/login`, `/dashboard` like other feature tests. Auth notifier that starts `AuthUnknown` then flips to `AuthSignedOut` / `AuthSignedIn` after a short delay **or** immediately via a controllable notifier.

```dart
testWidgets('stays on splash until min duration even if auth ready early', ...)
testWidgets('after min duration + signed out goes to login', ...)
testWidgets('after min duration + signed in goes to dashboard', ...)
```

Rules under test:
- `canExit = animationCompleted && auth is! AuthUnknown`
- Then ~250ms fade, then `context.go(target)` where target comes from same logic as `redirectFor` (or call `redirectFor` helper with auth + current path `/`).

**Important:** Do **not** change `redirectFor` AuthUnknown behavior (must stay on `/`). Splash itself navigates once ready.

**Step 2: Implement exit in SplashPage**

```dart
void _tryExit() {
  if (!mounted || _exiting) return;
  final auth = ref.read(authProvider);
  if (!_animationDone || auth is AuthUnknown) return;
  _exiting = true;
  // run exit fade, then:
  final target = redirectFor(auth: auth, path: '/') ?? '/dashboard';
  // if redirectFor returns null for AuthUnknown only; for signed states on '/'
  // it returns '/dashboard' or stays null for login path cases —
  // for signed out on '/', redirectFor returns '/login'
  context.go(target);
}
```

Verify against `redirectFor` in `app_router.dart`:
- `AuthSignedOut` + `/` → `/login`
- `AuthSignedIn` + `/` → `/dashboard`
- mustChangePassword → `/change-password`

Listen: `ref.listen(authProvider, ...)`, and on animation status completed call `_tryExit()`.

**Step 3: Run splash tests — PASS — Commit**

```bash
git commit -m "feat: gate splash exit on animation and auth"
```

---

### Task 5: Router uses SplashPage

**Files:**
- Modify: `mobile/lib/core/router/app_router.dart` (route `/`)
- Modify: `mobile/test/widget_test.dart`
- Modify: `mobile/test/core/router/router_redirect_test.dart` (AuthUnknown splash assertion)

**Step 1: Change `/` builder**

```dart
GoRoute(
  path: '/',
  builder: (context, state) => const SplashPage(),
),
```

**Step 2: Update widget_test**

```dart
expect(find.byType(SplashPage), findsOneWidget);
expect(find.text('Alizé'), findsWidgets);
```

**Step 3: Update router_redirect_test AuthUnknown case similarly**

**Step 4: Run**

```bash
cd mobile && flutter test test/widget_test.dart test/core/router/router_redirect_test.dart test/features/splash/
```

Expected: PASS

**Step 5: Commit**

```bash
git commit -m "feat: route splash page at app root"
```

---

### Task 6: Native Android launch background color

**Files:**
- Create: `mobile/android/app/src/main/res/values/colors.xml` (if missing)
- Modify: `mobile/android/app/src/main/res/drawable/launch_background.xml`
- Modify: `mobile/android/app/src/main/res/drawable-v21/launch_background.xml`
- Modify: `mobile/android/app/src/main/res/values-night/styles.xml` / night drawable if present

**Step 1: Set launch color to Alizé paper `#F4F2F8`**

```xml
<!-- colors.xml -->
<color name="launch_background">#F4F2F8</color>
```

```xml
<item android:drawable="@color/launch_background" />
```

Night: dark paper `#09080D`.

**Step 2: Commit**

```bash
git commit -m "feat: align Android launch background with splash wash"
```

(iOS LaunchScreen storyboard color optional; do if quick, else skip.)

---

### Task 7: Full verification

**Step 1: Run focused + broader tests**

```bash
cd mobile && flutter test test/features/splash/ test/widget_test.dart test/core/router/router_redirect_test.dart
```

Expected: all PASS

**Step 2: Manual check on emulator**

Hot restart: see wave draw → Alizé → fade to login/dashboard. No white flash from native launch.

**Step 3: Final commit if any polish leftovers**

```bash
git commit -m "chore: polish splash after verification"
```

---

## Execution notes

- Prefer TDD order: fail → implement → pass → commit per task.
- Do not add packages.
- Keep redirects for AuthUnknown unchanged so splash can own the exit.
- Brand string always from `i18n.t('brand')`.
