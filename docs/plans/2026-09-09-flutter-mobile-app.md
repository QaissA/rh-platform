# Alizé Flutter Mobile App Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Ship a Flutter iOS/Android client that matches the Angular Alizé app, talking to the existing API gateway with feature-first clean architecture and Riverpod.

**Architecture:** `mobile/` in this monorepo. Each feature owns `domain` / `data` / `presentation`. Shared kernel under `lib/core`. Presentation depends only on domain; data implements domain repositories with Dio. JWT in secure storage. Action Cable for chat pushes; REST for all writes.

**Tech Stack:** Flutter 3 (Dart 3), flutter_riverpod, go_router, dio, flutter_secure_storage, web_socket_channel, intl, mocktail, pdf/printing.

**Do not commit** unless the user asks. Design: `docs/plans/2026-09-09-flutter-mobile-app-design.md`. Backend must be up (`cd backend && docker compose up`) for manual checks. Android emulator uses `http://10.0.2.2:3000`; iOS simulator uses `http://localhost:3000`.

Copy contracts from `frontend/src/app/core/models.ts` and the Angular services in `frontend/src/app/core/`. Port strings from `frontend/src/assets/i18n/{fr,en,ar}.json`. Visual tokens from `frontend/src/styles.css`.

---

### Task 1: Fix GET /notifications on auth-service

Angular already calls `GET /auth/notifications`. The controller action exists; the route does not.

**Files:**
- Modify: `backend/auth-service/config/routes.rb`
- Test: `backend/auth-service/test/integration/` (add or extend a notifications test)

**Step 1: Write a failing request test**

Create `backend/auth-service/test/integration/notifications_test.rb` if missing:

```ruby
require "test_helper"

class NotificationsTest < ActionDispatch::IntegrationTest
  test "lists notifications for the current user" do
    user = users(:employee)
    get "/notifications", headers: auth_headers(user)
    assert_response :success
    body = JSON.parse(response.body)
    assert_kind_of Array, body
  end
end
```

Match existing test helpers in `backend/auth-service/test/test_helper.rb` (JWT header style used by `conversations_test.rb`). If fixtures/helpers differ, copy the login pattern from that file instead of inventing `auth_headers`.

**Step 2: Run the test — expect fail**

```bash
docker compose exec auth-service bin/rails test test/integration/notifications_test.rb
```

Expected: routing error or 404 for GET `/notifications`.

**Step 3: Add the route**

In `backend/auth-service/config/routes.rb`, next to the existing patch:

```ruby
get "notifications" => "notifications#index"
patch "notifications/:id/read" => "notifications#read"
```

**Step 4: Re-run the test — expect pass**

Same command as step 2. Expected: PASS.

---

### Task 2: Scaffold the Flutter app

**Files:**
- Create: `mobile/` (Flutter project)

**Step 1: Create the project**

From the repo root:

```bash
flutter create --org com.alize --project-name alize_mobile --platforms=android,ios mobile
```

Expected: `mobile/lib/main.dart`, `mobile/pubspec.yaml`, `android/` and `ios/` exist.

**Step 2: Confirm the tool chain**

```bash
cd mobile
flutter doctor
flutter test
```

Expected: `All tests passed!` (the placeholder counter test).

**Step 3: Point the root README at mobile**

Modify `README.md` to add:

```markdown
- Mobile: `mobile/README.md` — `flutter run` (gateway on `:3000`)
```

---

### Task 3: Dependencies and lints

**Files:**
- Modify: `mobile/pubspec.yaml`
- Modify: `mobile/analysis_options.yaml`

**Step 1: Add runtime + test dependencies**

Under `dependencies:`:

```yaml
flutter_riverpod: ^2.6.1
go_router: ^14.8.1
dio: ^5.8.0+1
flutter_secure_storage: ^9.2.4
web_socket_channel: ^3.0.2
intl: ^0.20.2
google_fonts: ^6.2.1
pdf: ^3.11.3
printing: ^5.14.2
path_provider: ^2.1.5
shared_preferences: ^2.5.3
```

Under `dev_dependencies:`:

```yaml
mocktail: ^1.0.4
```

Keep `flutter_lints`. SDK constraint as created by `flutter create`.

**Step 2: Install**

```bash
cd mobile
flutter pub get
```

Expected: `Changed X dependencies!` with no version solving errors. If a constraint fails, use the latest compatible version `flutter pub add` prints — do not pin yanked packages.

**Step 3: Tighten analysis_options.yaml**

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    prefer_const_constructors: true
    avoid_print: true

analyzer:
  exclude:
    - "**/*.g.dart"
```

---

### Task 4: Folder skeleton and delete the counter app

**Files:**
- Create empty `.gitkeep` or barrel files under `mobile/lib/core/` and `mobile/lib/features/`
- Replace: `mobile/lib/main.dart`
- Delete: `mobile/lib/counter` leftovers if any; replace `mobile/test/widget_test.dart`

**Step 1: Create directories**

```
mobile/lib/core/config
mobile/lib/core/error
mobile/lib/core/network
mobile/lib/core/storage
mobile/lib/core/theme
mobile/lib/core/l10n
mobile/lib/core/router
mobile/lib/core/widgets
mobile/lib/features/auth/domain/entities
mobile/lib/features/auth/domain/repositories
mobile/lib/features/auth/domain/usecases
mobile/lib/features/auth/data/models
mobile/lib/features/auth/data/datasources
mobile/lib/features/auth/data/repositories
mobile/lib/features/auth/presentation/providers
mobile/lib/features/auth/presentation/pages
mobile/lib/features/auth/presentation/widgets
```

Also create the same three-layer layout (even if empty) for: `dashboard`, `leave`, `team`, `chat`, `documents`, `documents_rh`, `dossiers`, `notifications`, `settings`, `admin_users`, `admin_teams`, `admin_business_units`, `admin_projects`.

**Step 2: Replace main.dart with a Riverpod host**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: AlizeApp()));
}

class AlizeApp extends StatelessWidget {
  const AlizeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Alizé',
      home: Scaffold(body: Center(child: Text('Alizé'))),
    );
  }
}
```

**Step 3: Fix widget_test.dart** so it pumps `AlizeApp` and finds `Alizé`.

**Step 4: Run tests**

```bash
cd mobile
flutter test
```

Expected: PASS.

---

### Task 5: Failure and Result

**Files:**
- Create: `mobile/lib/core/error/failures.dart`
- Create: `mobile/lib/core/error/result.dart`
- Test: `mobile/test/core/error/result_test.dart`

**Step 1: Write the failing test**

```dart
import 'package:alize_mobile/core/error/failures.dart';
import 'package:alize_mobile/core/error/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ok unwraps data', () {
    const r = Result.ok(7);
    expect(r.isOk, isTrue);
    expect(r.data, 7);
  });

  test('err unwraps failure', () {
    const r = Result<int>.err(Failure.unauthorized());
    expect(r.isOk, isFalse);
    expect(r.failure, isA<UnauthorizedFailure>());
  });
}
```

**Step 2: Run test — expect fail** (`target Result not found`)

```bash
flutter test test/core/error/result_test.dart
```

**Step 3: Implement**

`mobile/lib/core/error/failures.dart`:

```dart
sealed class Failure {
  const Failure();
  const factory Failure.network() = NetworkFailure;
  const factory Failure.unauthorized() = UnauthorizedFailure;
  const factory Failure.notFound() = NotFoundFailure;
  const factory Failure.validation(String message) = ValidationFailure;
  const factory Failure.server({int? status, String? message}) = ServerFailure;
}

class NetworkFailure extends Failure {
  const NetworkFailure();
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure();
}

class NotFoundFailure extends Failure {
  const NotFoundFailure();
}

class ValidationFailure extends Failure {
  const ValidationFailure(this.message);
  final String message;
}

class ServerFailure extends Failure {
  const ServerFailure({this.status, this.message});
  final int? status;
  final String? message;
}
```

`mobile/lib/core/error/result.dart`:

```dart
import 'failures.dart';

class Result<T> {
  const Result._({this.data, this.failure});
  const Result.ok(T data) : this._(data: data);
  const Result.err(Failure failure) : this._(failure: failure);

  final T? data;
  final Failure? failure;

  bool get isOk => failure == null;
}
```

**Step 4: Re-run test — expect PASS.**

---

### Task 6: AppConfig

**Files:**
- Create: `mobile/lib/core/config/app_config.dart`
- Test: `mobile/test/core/config/app_config_test.dart`

**Step 1: Write the test**

```dart
import 'package:alize_mobile/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses dart-define override', () {
    expect(
      AppConfig.baseUrlFrom(define: 'https://api.example.com'),
      'https://api.example.com',
    );
  });

  test('android emulator default is 10.0.2.2', () {
    expect(
      AppConfig.baseUrlFrom(define: '', hostIsAndroid: true),
      'http://10.0.2.2:3000',
    );
  });

  test('elsewhere default is localhost', () {
    expect(
      AppConfig.baseUrlFrom(define: '', hostIsAndroid: false),
      'http://localhost:3000',
    );
  });
}
```

**Step 2: Run — expect fail.**

**Step 3: Implement**

```dart
import 'dart:io';
import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig({required this.apiBaseUrl});

  final String apiBaseUrl;

  static AppConfig get current => AppConfig(
        apiBaseUrl: baseUrlFrom(
          define: const String.fromEnvironment('API_BASE_URL'),
          hostIsAndroid: !kIsWeb && Platform.isAndroid,
        ),
      );

  static String baseUrlFrom({
    required String define,
    required bool hostIsAndroid,
  }) {
    if (define.isNotEmpty) return define;
    return hostIsAndroid ? 'http://10.0.2.2:3000' : 'http://localhost:3000';
  }

  String get wsBaseUrl =>
      apiBaseUrl.replaceFirst(RegExp(r'^http'), 'ws');
}
```

**Step 4: Re-run — expect PASS.**

---

### Task 7: Map Dio errors to Failure

**Files:**
- Create: `mobile/lib/core/network/error_mapper.dart`
- Test: `mobile/test/core/network/error_mapper_test.dart`

**Step 1: Write tests** covering `DioExceptionType.connectionError` → `NetworkFailure`, status 401 → `UnauthorizedFailure`, 404 → `NotFoundFailure`, 422 → `ValidationFailure` (use `error` string from JSON body if present), other 4xx/5xx → `ServerFailure`.

**Step 2: Run — expect fail.**

**Step 3: Implement `mapDio(DioException e)`** in `error_mapper.dart`. Read `e.response?.data` when it is a `Map` with `error` or `errors`.

**Step 4: Re-run — expect PASS.**

---

### Task 8: Dio client + auth interceptor

**Files:**
- Create: `mobile/lib/core/network/session_reader.dart` (typedef / abstract `String? token()`)
- Create: `mobile/lib/core/network/dio_client.dart`
- Test: `mobile/test/core/network/dio_client_test.dart`

**Step 1: Write a test** that uses Dio `Adapter` / `http_mock_adapter` **or** a `Interceptor` unit test: given a token, the request has `Authorization: Bearer …`. Given 401, a callback `onUnauthorized` is invoked.

Keep this as a pure interceptor test — do not boot Flutter binding unless needed.

```dart
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.token, required this.onUnauthorized});
  final String? Function() token;
  final void Function() onUnauthorized;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final t = token();
    if (t != null && t.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $t';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) onUnauthorized();
    handler.next(err);
  }
}
```

**Step 2–4:** TDD as usual. Factory:

```dart
Dio createDio({required AppConfig config, required AuthInterceptor interceptor}) {
  final dio = Dio(BaseOptions(
    baseUrl: config.apiBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 20),
    headers: {'Accept': 'application/json'},
  ));
  dio.interceptors.add(interceptor);
  return dio;
}
```

Provider comes later (needs session). For now export the factory.

---

### Task 9: Secure session store

**Files:**
- Create: `mobile/lib/core/storage/session_store.dart`
- Test: `mobile/test/core/storage/session_store_test.dart`

Use an abstract `SessionStore` so tests do not need the platform plugin:

```dart
abstract class SessionStore {
  Future<void> save({required String token, required String userJson});
  Future<String?> readToken();
  Future<String?> readUserJson();
  Future<void> clear();
}
```

`SecureSessionStore` wraps `FlutterSecureStorage` with keys `alize.token` and `alize.user`.

`MemorySessionStore` for tests.

**Step 1:** Test save/read/clear on `MemorySessionStore`.

**Step 2–4:** Implement both classes. Do not call `FlutterSecureStorage` from tests.

---

### Task 10: Port i18n dictionaries

**Files:**
- Create: `mobile/assets/i18n/fr.json`, `en.json`, `ar.json` (copy from `frontend/src/assets/i18n/`)
- Modify: `mobile/pubspec.yaml` assets
- Create: `mobile/lib/core/l10n/i18n.dart`
- Test: `mobile/test/core/l10n/i18n_test.dart`

**Step 1: Copy JSON files** verbatim. Register in pubspec:

```yaml
flutter:
  assets:
    - assets/i18n/fr.json
    - assets/i18n/en.json
    - assets/i18n/ar.json
```

**Step 2: Test lookup + interpolate + Arabic RTL**

Load JSON from a string in the test (do not depend on `rootBundle` for the unit test). `t('nav.leave')` → French `Congés`. `t('common.userN', {'id': 3})` interpolates `{{id}}`. `dir` for `ar` is `rtl`.

Mirror `frontend/src/app/core/i18n.service.ts`: nested key lookup, fallback to `fr`, then to the key itself.

**Step 3: Implement `I18n` class** with `lang`, `t`, `setLang`, `dir`, `locale` (`fr-FR` / `en-GB` / `ar`). Persist lang via `SharedPreferences` key `alize.lang` in a thin wrapper; unit-test the lookup without prefs.

**Step 4:** `flutter test test/core/l10n/i18n_test.dart` PASS.

---

### Task 11: Auth entity + login use case (TDD)

**Files:**
- Create: `mobile/lib/features/auth/domain/entities/user.dart`
- Create: `mobile/lib/features/auth/domain/entities/session.dart`
- Create: `mobile/lib/features/auth/domain/repositories/auth_repository.dart`
- Create: `mobile/lib/features/auth/domain/usecases/login.dart`
- Test: `mobile/test/features/auth/domain/login_test.dart`

**Step 1: Failing test** with a `mocktail` `MockAuthRepository`.

`User` fields match `frontend/src/app/core/models.ts`: `id`, `email`, `role`, `teamId`, `businessUnitId`, `projectId`, `firstName`, `lastName`, `jobTitle`, `pendingJobTitle`, `mustChangePassword`.

```dart
class Login {
  Login(this._repo);
  final AuthRepository _repo;
  Future<Result<Session>> call(String email, String password) =>
      _repo.login(email: email, password: password);
}
```

Test: repository `ok` → use case returns session; repository `err` → same error.

**Step 2–4:** Implement entity + abstract repo + use case. Run test PASS.

Also add `ChangePassword` use case (`current`, `next` → `Result<User>`) with a second test file.

---

### Task 12: Auth DTO, datasource, repository impl

**Files:**
- Create: `mobile/lib/features/auth/data/models/user_dto.dart`
- Create: `mobile/lib/features/auth/data/datasources/auth_remote.dart`
- Create: `mobile/lib/features/auth/data/repositories/auth_repository_impl.dart`
- Test: `mobile/test/features/auth/data/auth_repository_impl_test.dart`

**JSON keys stay snake_case** as the gateway sends them (`first_name`, `must_change_password`, `team_id`, …).

`AuthRemote`:

| Method | HTTP |
|---|---|
| login | `POST /auth/login` body `{email, password}` → `{ token, user }` |
| me | `GET /auth/me` |
| changePassword | `PATCH /auth/password` `{ current_password, new_password }` |

`AuthRepositoryImpl`: on login success, `sessionStore.save`. On `UnauthorizedFailure` from `me`, `sessionStore.clear`. Map Dio via `mapDio`.

Mock `AuthRemote` and `SessionStore` in the test — do not hit the network.

---

### Task 13: AuthNotifier + providers

**Files:**
- Create: `mobile/lib/features/auth/presentation/providers/auth_providers.dart`
- Test: `mobile/test/features/auth/presentation/auth_notifier_test.dart`

**State:**

```dart
sealed class AuthState {
  const AuthState();
}
class AuthUnknown extends AuthState { const AuthUnknown(); }
class AuthSignedOut extends AuthState { const AuthSignedOut(); }
class AuthSignedIn extends AuthState {
  const AuthSignedIn(this.session);
  final Session session;
  bool get mustChangePassword => session.user.mustChangePassword;
}
```

`AuthNotifier` (extends `AsyncNotifier<AuthState>` or `Notifier<AuthState>`):

1. `build`: read token+user from store; if missing → `AuthSignedOut`; else hydrate without calling network.
2. `login(email, password)`
3. `logout()` clears store
4. `changePassword(...)` updates stored user JSON
5. `onUnauthorized()` from Dio interceptor → `logout`

Wire:

```dart
final sessionStoreProvider = Provider<SessionStore>((_) => SecureSessionStore());
final appConfigProvider = Provider((_) => AppConfig.current);
final dioProvider = Provider<Dio>((ref) { /* createDio + interceptor that calls authNotifier.onUnauthorized */ });
final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepositoryImpl(...));
final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
```

Avoid a circular provider: interceptor should call a `SessionController` object created once in `main` after `ProviderScope`, or use `Ref` with `ref.read(authProvider.notifier).onUnauthorized()` **after** the first frame. Simplest: `AuthInterceptor.onUnauthorized` sets a `Provider<void Function()>` that `AuthNotifier` registers in `build`.

Test with `MemorySessionStore` and a fake repository. No Flutter widgets yet.

---

### Task 14: Theme tokens

**Files:**
- Create: `mobile/lib/core/theme/alize_colors.dart`
- Create: `mobile/lib/core/theme/alize_theme.dart`
- Create: `mobile/lib/core/theme/theme_controller.dart`

Port from `frontend/src/styles.css`:

Light: paper `#F4F2F8`, surface `#FFFFFF`, ink `#0E0B14`, brand `#460CAD`, ok `#2F8F5B`, warn `#B77E12`, bad `#BB5245`, radius 14.

Dark: paper `#09080D`, surface `#141220`, brand `#8B5CF6`, …

`ThemeController`: `light` / `dark` / `system`. Persist `alize.theme` in SharedPreferences (same as Angular). `AlizeTheme.light()` / `dark()` return `ThemeData` with `ColorScheme.fromSeed` overridden by exact Alizé colors, `useMaterial3: true`, shape `RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))`.

Google Fonts: IBM Plex Sans for UI, IBM Plex Serif for the login headline only. If `google_fonts` fetch is undesirable in tests, fall back to `fontFamily: 'Roboto'` when `kDebugMode` tests run — or use `GoogleFonts.config.allowRuntimeFetching = false` in tests.

---

### Task 15: Login page

**Files:**
- Create: `mobile/lib/features/auth/presentation/pages/login_page.dart`
- Test: `mobile/test/features/auth/presentation/login_page_test.dart`

Match `frontend/src/app/features/login/`: email + password, error on 401 / offline, demo chips that fill `employee@rh.local` / `manager@rh.local` / `rh@rh.local` / `admin@rh.local` + `password`, lang switcher.

Widget test: pump with `ProviderScope` overrides (`authRepositoryProvider` → fake that returns `Result.ok(session)`). Enter credentials, tap submit, expect `AuthSignedIn`. Second test: fake `Result.err(Failure.unauthorized())` shows `login.badCredentials`.

Do not call a real gateway in tests.

---

### Task 16: Forced change-password page

**Files:**
- Create: `mobile/lib/features/auth/presentation/pages/change_password_page.dart`

Rules from Angular: min length 8, confirm match, `PATCH /auth/password`. If `AuthNotifier` still holds the temp password from login (in-memory only, never stored), reuse it so the user only types the new password (see `AuthService.changePasswordForced`).

Widget test: `mustChangePassword: true` session; submit valid password; fake repo returns user with `mustChangePassword: false`.

---

### Task 17: go_router + shell + role redirects

**Files:**
- Create: `mobile/lib/core/router/app_router.dart`
- Create: `mobile/lib/core/router/roles.dart`
- Create: `mobile/lib/features/dashboard/presentation/pages/home_page.dart` (placeholder)
- Create: `mobile/lib/core/widgets/app_shell.dart`
- Modify: `mobile/lib/app.dart` + `main.dart`
- Test: `mobile/test/core/router/router_redirect_test.dart`

`roles.dart`:

```dart
bool isAdmin(String role) => role == 'admin';
bool isRh(String role) => role == 'rh' || role == 'admin';
bool isManager(String role) =>
    role == 'manager' || role == 'rh' || role == 'admin';
```

Redirects (same as Angular):

| Condition | Go to |
|---|---|
| no session, location not `/login` | `/login` |
| session + `mustChangePassword`, location not `/change-password` | `/change-password` |
| session + password already changed, location `/change-password` | `/dashboard` |
| session on `/login` | `/dashboard` |
| not manager on `/validation-conges` | `/dashboard` |
| not rh on `/documents-rh` or `/dossiers` | `/dashboard` |
| not admin on `/business-units`, `/projets`, `/equipes`, `/utilisateurs` | `/dashboard` |

Shell: `NavigationBar` items Home `/dashboard`, Leave `/conges`, Team `/equipe`, Messages `/messages`, More `/more`. Top bar: title from `page.*.title`, lang switcher, theme toggle, notification bell (stub until Task 22).

`More` is a list of `ListTile`s: Documents, Settings, and role-gated RH/admin links. This replaces the Angular sidebar on a phone.

Wire `MaterialApp.router` in `AlizeApp`, `themeMode` from `themeControllerProvider`, `locale` + `Directionality` from i18n.

**Router tests** use `GoRouter` with a fake `AuthState` override and `tester.pumpWidget`; `expect(router.state.uri.path, ...)`.

---

### Task 18: Leave feature (balance, list, create)

**Files:** under `mobile/lib/features/leave/`
- Domain entities: `LeaveBalance`, `LeaveRequest`, `NewLeaveRequest`, `LeaveStatus` (`pending`, `pending_hr`, `approved`, `rejected`)
- `LeaveRepository` + impl
- Use cases: `GetBalance`, `GetMyRequests`, `CreateLeaveRequest`, `GetTeamRequests`, `ApproveLeave`, `RejectLeave`
- Presentation: `leave_page.dart` (list + form), providers
- Tests: repository mapping + create use case

HTTP (from `leave.service.ts`):

| Call | Path |
|---|---|
| balance | `GET /leave/balance` |
| mine | `GET /leave/requests` |
| create | `POST /leave/requests` `{start_date, end_date, reason?}` |
| team queue | `GET /leave/requests/team?status=` |
| approve | `PATCH /leave/requests/:id/approve` |
| reject | `PATCH /leave/requests/:id/reject` `{comment?}` |

UI: remaining days meter, two-step tracker like `step-tracker.ts` (Manager → RH), new-request form. Status chips from Angular `LEAVE_STATUS_CHIP`.

Widget test: fake repo with one pending request renders the range and status label from i18n `status.leave.pending`.

---

### Task 19: Team + schedule

**Files:** `mobile/lib/features/team/`

HTTP:

| Call | Path |
|---|---|
| my team | `GET /auth/teams/mine` |
| schedule | `GET /leave/schedule?start=&end=` |
| declare | `POST /leave/presences` `{start_date, end_date?, status}` status `on_site` \| `remote` |

Entities match `TeamMember`, `ScheduleEntry`, `PresenceStatus`. Calendar: a simple month grid (do not take a FullCalendar dependency). Tapping a day declares presence for the current user. Holiday comes from the API (approved leaves), not a client fake.

Port `PeopleService` as `PeopleDirectory` in `core` or `team/domain`: rh/admin load `GET /auth/users`, others use `teams/mine`. Used by dashboard and leave-review names.

---

### Task 20: Role-based dashboard

**Files:** `mobile/lib/features/dashboard/presentation/pages/home_page.dart`

Follow `docs/plans/2026-09-08-role-based-work-home-design.md` and `frontend/src/app/features/dashboard/dashboard.ts`:

- **Employee:** remaining days, next confirmed leave or CTA, last 3 leaves with step chips, document ready vs pending, team today from schedule, quick actions.
- **Manager:** pending leave queue with approve/refuse on the card; who is out this week.
- **RH/Admin:** `pending_hr` queue; document inbox count + 3 latest; who is out today.

One next action per widget. Skeleton loaders. Empty states with a CTA. Approve/reject calls the same leave use cases, then refresh. Failures snackbar.

No fake `presence(id)`, no hardcoded public holiday.

---

### Task 21: Employee documents

**Files:** `mobile/lib/features/documents/`

HTTP from `document.service.ts`:

| Call | Path |
|---|---|
| mine | `GET /admin-docs/requests` |
| create | `POST /admin-docs/requests` `{doc_type, note?}` |
| show | `GET /admin-docs/requests/:id` |
| cancel | `PATCH /admin-docs/requests/:id/cancel` |

Doc types and templates: copy `frontend/src/app/core/document-templates.ts`. Status board: pending/processing vs ready (design doc). Detail route `/documents/:id`. Ready docs open preview (layout from `document-preview.html`; PDF generation in Task 28).

---

### Task 22: Chat (REST + Action Cable)

**Files:** `mobile/lib/core/network/action_cable_client.dart`, `mobile/lib/features/chat/`

**Action Cable subscribe** (gateway identifies via query token):

Connect `WebSocketChannel` to `${config.wsBaseUrl}/cable?token=$jwt`.

On open send:

```json
{"command":"subscribe","identifier":"{\"channel\":\"ChatChannel\"}"}
```

Parse welcome/ping/confirm; on `message` with `type == message`, forward the payload to `ChatRepository`.

REST (from `chat.service.ts`):

| Call | Path |
|---|---|
| list | `GET /auth/conversations` |
| directory | `GET /auth/directory` |
| open | `POST /auth/conversations` `{user_id}` |
| history | `GET /auth/conversations/:id/messages` |
| send | `POST /auth/conversations/:id/messages` JSON `{body}` or multipart `body` + `file` |
| read | `POST /auth/conversations/:id/read` |
| file | `GET /auth{attachment.url}` with Bearer (blob) |

Unread total = sum of `unread_count`. Start cable on login, stop on logout (same as Angular `AuthService.startChat`).

UI: conversation list, thread, composer, attach file, image preview from authenticated GET. Directory picker to start a 1:1.

Unit-test JSON parsing of a cable frame and unread sum. Widget-test list with two fake conversations.

If the socket fails, do not fail `send`; REST is enough.

---

### Task 23: Notifications bell + queue badges

**Files:** `mobile/lib/features/notifications/`

HTTP:

| Call | Path |
|---|---|
| list | `GET /auth/notifications` |
| read | `PATCH /auth/notifications/:id/read` |

Poll every 20s while the shell is visible (`AppLifecycleState.resumed`). `InboxBadge`: managers poll `GET /leave/requests/team?status=pending` (rh: `pending_hr`, admin: both); rh/admin also poll document inbox and count `pending` + `processing`. Show counts on More / validation / documents-rh destinations.

Tapping a notification marks read and `goRouter.go(n.link)` when `link` is a known path.

---

### Task 24: Settings + signature pad

**Files:** `mobile/lib/features/settings/`

HTTP from `profile.service.ts` + password:

| Call | Path |
|---|---|
| profile | `GET /auth/profile` |
| update | `PATCH /auth/profile` address / `pending_job_title` / `signature_png` |
| password | `PATCH /auth/password` |

Signature: `CustomPaint` + pointer drawing, export PNG base64 the way Angular does (`signature_png`). If `signature_locked`, show the stored image and no pad (RH unlock is on the dossier screen).

Lang + theme already in the shell; settings can repeat them.

---

### Task 25: Manager / RH leave validation

**Files:** `mobile/lib/features/leave/presentation/pages/leave_review_page.dart`

Route `/validation-conges`, `isManager` only. Split queues visually: manager sees `pending`, rh sees `pending_hr`, admin sees both (same as Angular `validation-conges.ts`). In-row approve / refuse with optional comment. Refresh badges after success.

---

### Task 26: RH documents inbox + edit

**Files:** `mobile/lib/features/documents_rh/`

HTTP:

| Call | Path |
|---|---|
| inbox | `GET /admin-docs/requests/inbox` optional `?status=` |
| update | `PATCH /admin-docs/requests/:id` `{fields, status, decision_comment}` |
| reject | `PATCH /admin-docs/requests/:id/reject` `{comment?}` |

Fill template fields from `TEMPLATE_FIELDS`. Mark ready when fields complete. Match `documents-rh-edit.ts` status transitions.

---

### Task 27: RH dossiers

**Files:** `mobile/lib/features/dossiers/`

HTTP:

| Call | Path |
|---|---|
| list | `GET /auth/users` (rh directory, no salary/IBAN/signature on index — trust the API) |
| dossier | `GET /auth/users/:id` |
| update | `PATCH /auth/users/:id` |
| job title | `POST /auth/users/:id/job-title/accept` or `/reject` |
| unlock signature | `POST /auth/users/:id/signature/unlock` |

Confidential fields: salary (cents → display euros), IBAN, contract type, hired_on. Never log these.

---

### Task 28: Admin org CRUD

**Files:** `admin_business_units`, `admin_projects`, `admin_teams`, `admin_users`

HTTP from the Angular admin services:

| Resource | Base |
|---|---|
| BUs | `/auth/business-units` GET/POST/PATCH/DELETE |
| projects | `/auth/projects` GET (`?business_unit_id=`) POST/PATCH/DELETE |
| teams | `/auth/teams` GET/GET:id/POST/PATCH/DELETE |
| users | `/auth/users` GET/POST/PATCH/DELETE, `POST /:id/reset-password` |

Create-user response includes `temporary_password` once — show a copyable dialog (Angular `CreatedUser`). Reset password same. Role/team/BU/project fields on edit.

Phone UI: list + detail form, not a dense desktop table. Same validations as the web forms.

---

### Task 29: Document PDF preview / share

**Files:** `mobile/lib/features/documents/data/document_pdf.dart`

Port the HTML templates in `frontend/src/app/core/document-file.ts` to `pdf` widgets (`pw.Page`, `pw.Text`). Share/print via `printing`. Trigger from document detail when status is `ready`.

Golden/unit test: given a `work_certificate` fields map, `buildPdf` returns non-empty bytes.

---

### Task 30: Android / iOS local HTTP + permissions

**Files:**
- `mobile/android/app/src/debug/AndroidManifest.xml` — `android.permission.INTERNET` (release too), debug uses cleartext
- `mobile/android/app/src/debug/res/xml/network_security_config.xml` allowing `10.0.2.2` and `localhost`
- `mobile/ios/Runner/Info.plist` — debug ATS exception for localhost HTTP (`NSAllowsLocalNetworking` is enough on recent iOS)
- Camera/files: add photo/file permissions only if the chat picker needs them (`NSPhotoLibraryUsageDescription`, Android `READ_MEDIA_IMAGES` / `READ_EXTERNAL_STORAGE` as required by the file picker you choose)

Do not enable cleartext in **release**.

---

### Task 31: README and runbook

**Files:**
- Create: `mobile/README.md`
- Modify: root `README.md` (if not done in Task 2)

Include:

```bash
cd backend && docker compose up --build
cd mobile
flutter pub get
# Android emulator
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
# iOS simulator
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

Demo users table (same as backend README). Architecture sketch (feature-first, Riverpod, gateway only). How to add a feature (domain → data → presentation, no Dio in widgets).

---

### Task 32: Manual verification

With gateway up, on an emulator or device:

1. Login employee → dashboard numbers, request leave, request a document, open team calendar, send a chat message to another seeded user (second session or web).
2. Login manager → validation queue, approve one leave, badge decrements.
3. Login rh → confirm leave, fill a document, open a dossier, accept a job title.
4. Login admin → create a user, copy temp password, log in as that user, forced change-password, then admin CRUD for a BU/project/team.
5. Toggle FR/EN/AR (RTL on AR) and light/dark.
6. Kill the app, relaunch: session still present (secure storage).
7. Stop the gateway: login shows offline copy; in-app calls show a snackbar, not a crash.

Fix anything that fails before calling the app done.

---

## Angular service → Flutter repository map

| Angular | Flutter |
|---|---|
| `AuthService` | `AuthRepository` + `AuthNotifier` |
| `LeaveService` | `LeaveRepository` |
| `ScheduleService` | `ScheduleRepository` (team feature) |
| `TeamService` | `TeamRepository` |
| `DocumentService` | `DocumentRepository` |
| `ChatService` + `CableService` | `ChatRepository` + `ActionCableClient` |
| `NotificationService` | `NotificationRepository` |
| `InboxBadgeService` | `InboxBadgeNotifier` |
| `ProfileService` | `ProfileRepository` |
| `PeopleService` | `PeopleDirectory` |
| `UserAdminService` | `AdminUserRepository` |
| `TeamAdminService` | `AdminTeamRepository` |
| `BusinessUnitAdminService` | `AdminBusinessUnitRepository` |
| `ProjectAdminService` | `AdminProjectRepository` |
| `I18nService` | `I18n` |
| `ThemeService` | `ThemeController` |

## Layer rules (do not violate)

- Widgets import `presentation/providers` and domain entities only.
- `data/models` know JSON. `domain/entities` do not have `fromJson`.
- One Dio instance. Feature datasources take `Dio` in the constructor.
- No `print` of IBAN, salary, signature, or JWT.
