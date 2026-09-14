import 'dart:async';

import 'package:alize_mobile/core/l10n/i18n_provider.dart';
import 'package:alize_mobile/core/theme/alize_colors.dart';
import 'package:alize_mobile/features/admin_business_units/domain/entities/business_unit.dart';
import 'package:alize_mobile/features/admin_business_units/presentation/providers/business_unit_admin_providers.dart';
import 'package:alize_mobile/features/admin_teams/domain/entities/team_summary.dart';
import 'package:alize_mobile/features/admin_teams/presentation/providers/team_admin_providers.dart';
import 'package:alize_mobile/features/admin_users/domain/entities/created_user.dart';
import 'package:alize_mobile/features/admin_users/domain/entities/new_user.dart';
import 'package:alize_mobile/features/admin_users/domain/entities/update_user.dart';
import 'package:alize_mobile/features/admin_users/presentation/providers/user_admin_providers.dart';
import 'package:alize_mobile/features/admin_users/presentation/user_labels.dart';
import 'package:alize_mobile/features/admin_users/presentation/widgets/temporary_password_dialog.dart';
import 'package:alize_mobile/features/auth/domain/entities/user.dart';
import 'package:alize_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminUserFormPage extends ConsumerStatefulWidget {
  const AdminUserFormPage({super.key, this.userId});

  final int? userId;

  @override
  ConsumerState<AdminUserFormPage> createState() => _AdminUserFormPageState();
}

class _AdminUserFormPageState extends ConsumerState<AdminUserFormPage> {
  final _email = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();

  var _role = 'employee';
  String _assignment = '';
  var _loading = true;
  var _saving = false;
  List<BusinessUnit> _units = const [];
  List<TeamSummary> _teams = const [];
  User? _user;

  bool get _isNew => widget.userId == null;

  @override
  void initState() {
    super.initState();
    if (_isNew) {
      _loading = false;
    } else {
      unawaited(_load());
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _firstName.dispose();
    _lastName.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final id = widget.userId!;
    final users = await ref.read(userAdminRepositoryProvider).list();
    final units = await ref.read(businessUnitAdminRepositoryProvider).list();
    final teams = await ref.read(teamAdminRepositoryProvider).list();
    if (!mounted) return;
    final user = users.data?.where((u) => u.id == id).firstOrNull;
    _units = units.data ?? const [];
    _teams = (teams.data ?? const [])
        .where((t) => t.businessUnit != null)
        .toList();
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    _email.text = user.email;
    _firstName.text = user.firstName ?? '';
    _lastName.text = user.lastName ?? '';
    _role = user.role;
    if (user.teamId != null) {
      _assignment = 'team:${user.teamId}';
    } else if (user.businessUnitId != null) {
      _assignment = 'bu:${user.businessUnitId}';
    } else {
      _assignment = '';
    }
    setState(() {
      _user = user;
      _loading = false;
    });
  }

  bool get _emailValid => emailPattern.hasMatch(_email.text.trim());

  Future<void> _toast(String message) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    if (_saving) return;
    final i18n = ref.read(i18nProvider);
    final router = GoRouter.maybeOf(context);
    if (_isNew && !_emailValid) return;
    setState(() => _saving = true);
    if (_isNew) {
      final result = await ref.read(userAdminRepositoryProvider).create(
            NewUser(
              email: _email.text.trim(),
              firstName: _firstName.text.trim().isEmpty
                  ? null
                  : _firstName.text.trim(),
              lastName:
                  _lastName.text.trim().isEmpty ? null : _lastName.text.trim(),
              role: _role,
            ),
          );
      if (!mounted) return;
      setState(() => _saving = false);
      if (!result.isOk || result.data == null) {
        await _toast(adminFailureMessage(result.failure, i18n.t('users.createFail')));
        return;
      }
      await _showPassword(result.data!, reset: false);
      if (!mounted) return;
      router?.go('/utilisateurs');
      return;
    }

    final user = _user;
    if (user == null) {
      setState(() => _saving = false);
      return;
    }
    final result = await ref.read(userAdminRepositoryProvider).update(
          user.id,
          _updatePayload(),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    await _toast(
      result.isOk
          ? i18n.t('users.assigned', {'name': userDisplayName(user)})
          : adminFailureMessage(result.failure, i18n.t('users.assignFail')),
    );
    if (result.isOk) router?.go('/utilisateurs');
  }

  UpdateUser _updatePayload() {
    if (_assignment.startsWith('team:')) {
      return UpdateUser(
        role: _role,
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        teamId: int.tryParse(_assignment.substring(5)),
      );
    }
    if (_assignment.startsWith('bu:')) {
      return UpdateUser(
        role: _role,
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        teamId: null,
        businessUnitId: int.tryParse(_assignment.substring(3)),
      );
    }
    return UpdateUser(
      role: _role,
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      teamId: null,
      businessUnitId: null,
    );
  }

  Future<void> _showPassword(CreatedUser created, {required bool reset}) {
    return showTemporaryPasswordDialog(
      context: context,
      i18n: ref.read(i18nProvider),
      created: created,
      reset: reset,
    );
  }

  Future<void> _resetPassword() async {
    final user = _user;
    if (user == null || _saving) return;
    final i18n = ref.read(i18nProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(i18n.t('users.resetQ')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(i18n.t('common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(i18n.t('users.reset')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _saving = true);
    final result =
        await ref.read(userAdminRepositoryProvider).resetPassword(user.id);
    if (!mounted) return;
    setState(() => _saving = false);
    if (!result.isOk || result.data == null) {
      await _toast(adminFailureMessage(result.failure, i18n.t('users.resetFail')));
      return;
    }
    await _showPassword(result.data!, reset: true);
  }

  Future<void> _delete() async {
    final user = _user;
    if (user == null || _saving) return;
    final i18n = ref.read(i18nProvider);
    final router = GoRouter.maybeOf(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(i18n.t('common.confirmQ')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(i18n.t('common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(i18n.t('common.delete')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _saving = true);
    final result = await ref.read(userAdminRepositoryProvider).remove(user.id);
    if (!mounted) return;
    setState(() => _saving = false);
    if (!result.isOk) {
      await _toast(adminFailureMessage(result.failure, i18n.t('users.deleteFail')));
      return;
    }
    await _toast(i18n.t('users.deleted', {'name': userDisplayName(user)}));
    if (!mounted) return;
    router?.go('/utilisateurs');
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.watch(i18nProvider);
    final colors = Theme.of(context).brightness == Brightness.dark
        ? AlizeColors.dark
        : AlizeColors.light;
    final auth = ref.watch(authProvider);
    final meId = auth is AuthSignedIn ? auth.session.user.id : -1;

    return Scaffold(
      backgroundColor: colors.paper,
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                TextButton(
                  onPressed: () => context.go('/utilisateurs'),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(i18n.t('dossiers.back')),
                  ),
                ),
                Text(
                  i18n.t(_isNew ? 'users.createTitle' : 'users.title'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.ink,
                  ),
                ),
                const SizedBox(height: 16),
                if (_isNew) ...[
                  TextField(
                    key: const Key('admin-user-email'),
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: i18n.t('common.email'),
                      errorText: _email.text.trim().isNotEmpty && !_emailValid
                          ? i18n.t('users.invalidEmail')
                          : null,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _firstName,
                  decoration: InputDecoration(labelText: i18n.t('common.firstName')),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _lastName,
                  decoration: InputDecoration(labelText: i18n.t('common.lastName')),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey(_role),
                  initialValue: _role,
                  decoration: InputDecoration(labelText: i18n.t('common.role')),
                  items: [
                    for (final role in adminRoles)
                      DropdownMenuItem(
                        value: role,
                        child: Text(i18n.t('status.role.$role')),
                      ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _role = value);
                  },
                ),
                if (!_isNew) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey(_assignment),
                    initialValue: _assignment,
                    decoration:
                        InputDecoration(labelText: i18n.t('users.assignment')),
                    items: [
                      DropdownMenuItem(
                        value: '',
                        child: Text(i18n.t('common.noneOption')),
                      ),
                      for (final team in _teams)
                        DropdownMenuItem(
                          value: 'team:${team.id}',
                          child: Text(
                            '${team.businessUnit?.name ?? ''} · ${team.name}',
                          ),
                        ),
                      for (final unit in _units)
                        DropdownMenuItem(
                          value: 'bu:${unit.id}',
                          child: Text(unit.name),
                        ),
                    ],
                    onChanged: (value) {
                      setState(() => _assignment = value ?? '');
                    },
                  ),
                ],
                if (_isNew) ...[
                  const SizedBox(height: 8),
                  Text(
                    i18n.t('users.tempHelp'),
                    style: TextStyle(fontSize: 13, color: colors.ink3),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _saving || (_isNew && !_emailValid)
                      ? null
                      : _submit,
                  child: Text(
                    i18n.t(_isNew ? 'users.create' : 'common.save'),
                  ),
                ),
                if (!_isNew) ...[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _saving ? null : _resetPassword,
                    child: Text(i18n.t('users.resetPwd')),
                  ),
                  if (_user?.id != meId) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _saving ? null : _delete,
                      child: Text(
                        i18n.t('common.delete'),
                        style: TextStyle(color: colors.bad),
                      ),
                    ),
                  ],
                ],
              ],
            ),
    );
  }
}
