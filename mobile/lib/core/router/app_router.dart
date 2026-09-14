import 'package:alize_mobile/core/router/roles.dart';
import 'package:alize_mobile/core/widgets/app_shell.dart';
import 'package:alize_mobile/features/admin_business_units/presentation/pages/admin_business_unit_form_page.dart';
import 'package:alize_mobile/features/admin_business_units/presentation/pages/admin_business_units_page.dart';
import 'package:alize_mobile/features/admin_projects/presentation/pages/admin_project_form_page.dart';
import 'package:alize_mobile/features/admin_projects/presentation/pages/admin_projects_page.dart';
import 'package:alize_mobile/features/admin_teams/presentation/pages/admin_team_form_page.dart';
import 'package:alize_mobile/features/admin_teams/presentation/pages/admin_teams_page.dart';
import 'package:alize_mobile/features/admin_users/presentation/pages/admin_user_form_page.dart';
import 'package:alize_mobile/features/admin_users/presentation/pages/admin_users_page.dart';
import 'package:alize_mobile/features/auth/presentation/pages/change_password_page.dart';
import 'package:alize_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:alize_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:alize_mobile/features/chat/presentation/pages/messages_page.dart';
import 'package:alize_mobile/features/dashboard/presentation/pages/home_page.dart';
import 'package:alize_mobile/features/documents/presentation/pages/document_detail_page.dart';
import 'package:alize_mobile/features/documents/presentation/pages/documents_page.dart';
import 'package:alize_mobile/features/documents_rh/presentation/pages/documents_rh_edit_page.dart';
import 'package:alize_mobile/features/documents_rh/presentation/pages/documents_rh_page.dart';
import 'package:alize_mobile/features/dossiers/presentation/pages/dossier_edit_page.dart';
import 'package:alize_mobile/features/dossiers/presentation/pages/dossiers_page.dart';
import 'package:alize_mobile/features/leave/presentation/pages/leave_page.dart';
import 'package:alize_mobile/features/leave/presentation/pages/leave_review_page.dart';
import 'package:alize_mobile/features/more/presentation/pages/more_page.dart';
import 'package:alize_mobile/features/settings/presentation/pages/settings_page.dart';
import 'package:alize_mobile/features/team/presentation/pages/team_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

bool _matches(String path, String route) =>
    path == route || path.startsWith('$route/');

String _normalize(String path) {
  if (path.isEmpty) return '/';
  if (path.length > 1 && path.endsWith('/')) {
    return path.substring(0, path.length - 1);
  }
  return path;
}

/// Role and session redirects, matching the Angular guards.
String? redirectFor({required AuthState auth, required String path}) {
  final location = _normalize(path);
  if (auth is AuthUnknown) return null;

  if (auth is AuthSignedOut) {
    return location == '/login' ? null : '/login';
  }

  final signedIn = auth as AuthSignedIn;
  if (signedIn.mustChangePassword) {
    return location == '/change-password' ? null : '/change-password';
  }
  if (location == '/change-password') return '/dashboard';
  if (location == '/login' || location == '/') return '/dashboard';

  final role = signedIn.session.user.role;
  if (_matches(location, '/validation-conges') && !isManager(role)) {
    return '/dashboard';
  }
  if ((_matches(location, '/documents-rh') || _matches(location, '/dossiers')) &&
      !isRh(role)) {
    return '/dashboard';
  }
  if ((_matches(location, '/business-units') ||
          _matches(location, '/projets') ||
          _matches(location, '/equipes') ||
          _matches(location, '/utilisateurs')) &&
      !isAdmin(role)) {
    return '/dashboard';
  }
  return null;
}

int _routeId(GoRouterState state) =>
    int.tryParse(state.pathParameters['id'] ?? '') ?? 0;

GoRouter createAppRouter({
  required AuthState Function() readAuth,
  Listenable? refreshListenable,
  String initialLocation = '/',
}) {
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      return redirectFor(auth: readAuth(), path: state.uri.path);
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Alizé')),
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/change-password',
        builder: (context, state) => const ChangePasswordPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/conges',
                builder: (context, state) => const LeavePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/equipe',
                builder: (context, state) => const TeamPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/messages',
                builder: (context, state) => const MessagesPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/more',
                builder: (context, state) => const MorePage(),
              ),
              GoRoute(
                path: '/documents',
                builder: (context, state) => const DocumentsPage(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) {
                      final id =
                          int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
                      return DocumentDetailPage(id: id);
                    },
                  ),
                ],
              ),
              GoRoute(
                path: '/parametres',
                builder: (context, state) => const SettingsPage(),
              ),
              GoRoute(
                path: '/validation-conges',
                builder: (context, state) => const LeaveReviewPage(),
              ),
              GoRoute(
                path: '/documents-rh',
                builder: (context, state) => const DocumentsRhPage(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) {
                      final id =
                          int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
                      return DocumentsRhEditPage(id: id);
                    },
                  ),
                ],
              ),
              GoRoute(
                path: '/dossiers',
                builder: (context, state) => const DossiersPage(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) {
                      final id =
                          int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
                      return DossierEditPage(id: id);
                    },
                  ),
                ],
              ),
              GoRoute(
                path: '/business-units',
                builder: (context, state) => const AdminBusinessUnitsPage(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) =>
                        const AdminBusinessUnitFormPage(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) =>
                        AdminBusinessUnitFormPage(id: _routeId(state)),
                  ),
                ],
              ),
              GoRoute(
                path: '/projets',
                builder: (context, state) => const AdminProjectsPage(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => const AdminProjectFormPage(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) =>
                        AdminProjectFormPage(id: _routeId(state)),
                  ),
                ],
              ),
              GoRoute(
                path: '/equipes',
                builder: (context, state) => const AdminTeamsPage(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => const AdminTeamFormPage(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) =>
                        AdminTeamFormPage(id: _routeId(state)),
                  ),
                ],
              ),
              GoRoute(
                path: '/utilisateurs',
                builder: (context, state) => const AdminUsersPage(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => const AdminUserFormPage(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) =>
                        AdminUserFormPage(userId: _routeId(state)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen<AuthState>(authProvider, (_, _) {
    refresh.value++;
  });
  ref.onDispose(refresh.dispose);
  return createAppRouter(
    readAuth: () => ref.read(authProvider),
    refreshListenable: refresh,
  );
});
