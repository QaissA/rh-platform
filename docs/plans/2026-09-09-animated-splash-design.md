# Alizé animated splash screen (design)

Elegant Flutter splash that replaces the plain `/` “Alizé” placeholder while auth hydrates.

## Decisions

| Choice | Decision |
|---|---|
| Style | Brand mark + wordmark (wave draws, then name fades up) |
| Exit rule | Animation finished **and** auth resolved; never shorter than the animation (~2s) |
| Background | Soft brand wash (paper → brand tint; dark equivalents) |
| Implementation | Pure Flutter: `CustomPainter` + `AnimationController` (no Rive/Lottie) |
| Native | Align Android/iOS launch background colors to the wash to avoid a white flash |

## Flow

1. Cold start → native launch screen (static wash).
2. Flutter mounts → router stays on `/` while `AuthUnknown`.
3. Splash plays (~2.0s minimum):
   - Wave mark stroke-draw (~1.1s)
   - Wordmark fade + slight rise (~0.6s)
   - Short hold (~0.3s)
4. When animation complete **and** `authProvider` is no longer `AuthUnknown`, fade out (~250ms) then navigate via existing redirect targets:
   - signed out → `/login`
   - signed in → `/dashboard`
   - must change password → `/change-password`
5. If auth is already resolved before the animation ends, wait for the minimum duration, then exit.
6. If auth is slow, hold on the finished splash (no spinner in v1).

## Visual composition

- Full-bleed soft wash gradient using Alizé tokens (`paper` → `brandTint`).
- Center stack:
  - Wave mark matching the web sidebar SVG (two stroke paths).
  - Wordmark from `i18n.t('brand')` (“Alizé”).
- Light/dark follow current theme.
- Reduce-motion: skip stroke draw; show static mark + wordmark; still respect a short minimum (~800ms).

## Components

| Piece | Responsibility |
|---|---|
| `SplashPage` | Controllers, auth watch, exit gate, navigation |
| `AlizeWaveMark` | `CustomPainter` drawing a fraction of the wave paths |
| Router `/` | Builds `SplashPage` instead of plain text |
| Native launch assets | Background color/tint aligned to splash wash |

## Non-goals

- Rive / Lottie packages
- Sound
- Skip / tap-to-dismiss
- Loading spinner on long auth (v1)

## Testing

- Splash shows mark + brand text.
- Auth resolves immediately → still on splash until min duration (fake async).
- After min + `AuthSignedOut` → toward login; `AuthSignedIn` → dashboard.
- Existing `AuthUnknown` splash widget test updated to assert `SplashPage`.
