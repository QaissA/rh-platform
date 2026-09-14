import 'dart:async';

import 'package:alize_mobile/core/error/failures.dart';
import 'package:alize_mobile/core/l10n/i18n_provider.dart';
import 'package:alize_mobile/core/theme/alize_colors.dart';
import 'package:alize_mobile/features/admin_business_units/domain/entities/business_unit.dart';
import 'package:alize_mobile/features/admin_business_units/presentation/providers/business_unit_admin_providers.dart';
import 'package:alize_mobile/features/admin_projects/domain/entities/new_project.dart';
import 'package:alize_mobile/features/admin_projects/domain/entities/project.dart';
import 'package:alize_mobile/features/admin_projects/domain/entities/update_project.dart';
import 'package:alize_mobile/features/admin_projects/presentation/providers/project_admin_providers.dart';
import 'package:alize_mobile/features/admin_users/presentation/providers/user_admin_providers.dart';
import 'package:alize_mobile/features/admin_users/presentation/user_labels.dart';
import 'package:alize_mobile/features/auth/domain/entities/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminProjectFormPage extends ConsumerStatefulWidget {
  const AdminProjectFormPage({super.key, this.id});

  final int? id;

  @override
  ConsumerState<AdminProjectFormPage> createState() =>
      _AdminProjectFormPageState();
}

class _AdminProjectFormPageState extends ConsumerState<AdminProjectFormPage> {
  final _name = TextEditingController();
  int? _businessUnitId;
  int? _leadId;
  var _loading = true;
  var _saving = false;
  Project? _project;
  List<BusinessUnit> _units = const [];
  List<User> _leads = const [];

  bool get _isNew => widget.id == null;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final units = await ref.read(businessUnitAdminRepositoryProvider).list();
    final users = await ref.read(userAdminRepositoryProvider).list();
    final projects = await ref.read(projectAdminRepositoryProvider).list();
    if (!mounted) return;
    _units = units.data ?? const [];
    _leads = (users.data ?? const [])
        .where((u) => u.role == 'lead' || u.role == 'admin')
        .toList();
    if (!_isNew) {
      _project = projects.data?.where((p) => p.id == widget.id).firstOrNull;
      if (_project != null) {
        _name.text = _project!.name;
        _businessUnitId = _project!.businessUnitId;
        _leadId = _project!.leadId;
      }
    }
    setState(() => _loading = false);
  }

  bool get _valid =>
      _name.text.trim().isNotEmpty && _businessUnitId != null;

  Future<void> _toast(String message) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _err(Failure? failure, String fallback) {
    if (failure is ValidationFailure && failure.message.isNotEmpty) {
      return failure.message;
    }
    if (failure is ServerFailure) {
      final message = failure.message;
      if (message != null && message.isNotEmpty) return message;
    }
    return fallback;
  }

  Future<void> _submit() async {
    if (_saving || !_valid) return;
    final i18n = ref.read(i18nProvider);
    final router = GoRouter.maybeOf(context);
    setState(() => _saving = true);
    if (_isNew) {
      final result = await ref.read(projectAdminRepositoryProvider).create(
            NewProject(
              name: _name.text.trim(),
              businessUnitId: _businessUnitId!,
              leadId: _leadId,
            ),
          );
      if (!mounted) return;
      setState(() => _saving = false);
      await _toast(
        result.isOk
            ? i18n.t('projects.created')
            : _err(result.failure, i18n.t('projects.createFail')),
      );
      if (result.isOk) router?.go('/projets');
      return;
    }
    final project = _project;
    if (project == null) {
      setState(() => _saving = false);
      return;
    }
    final result = await ref.read(projectAdminRepositoryProvider).update(
          project.id,
          UpdateProject(
            name: _name.text.trim(),
            businessUnitId: _businessUnitId,
            leadId: _leadId,
          ),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    await _toast(
      result.isOk
          ? i18n.t('projects.renamed')
          : _err(result.failure, i18n.t('projects.renameFail')),
    );
    if (result.isOk) router?.go('/projets');
  }

  Future<void> _delete() async {
    final project = _project;
    if (project == null || _saving) return;
    final i18n = ref.read(i18nProvider);
    final router = GoRouter.maybeOf(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(i18n.t('projects.deleteQ')),
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
    final result =
        await ref.read(projectAdminRepositoryProvider).remove(project.id);
    if (!mounted) return;
    setState(() => _saving = false);
    await _toast(
      result.isOk
          ? i18n.t('projects.deleted', {'name': project.name})
          : _err(result.failure, i18n.t('projects.deleteFail')),
    );
    if (result.isOk) router?.go('/projets');
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.watch(i18nProvider);
    final colors = Theme.of(context).brightness == Brightness.dark
        ? AlizeColors.dark
        : AlizeColors.light;

    return Scaffold(
      backgroundColor: colors.paper,
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                TextButton(
                  onPressed: () => context.go('/projets'),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(i18n.t('dossiers.back')),
                  ),
                ),
                Text(
                  i18n.t(_isNew ? 'projects.createTitle' : 'projects.title'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.ink,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _name,
                  decoration: InputDecoration(labelText: i18n.t('common.name')),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  key: ValueKey(_businessUnitId),
                  initialValue: _businessUnitId,
                  decoration:
                      InputDecoration(labelText: i18n.t('projects.filterBu')),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(i18n.t('common.choose')),
                    ),
                    for (final unit in _units)
                      DropdownMenuItem(value: unit.id, child: Text(unit.name)),
                  ],
                  onChanged: (value) => setState(() => _businessUnitId = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  key: ValueKey(_leadId),
                  initialValue: _leadId,
                  decoration:
                      InputDecoration(labelText: i18n.t('projects.leadOptional')),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(i18n.t('common.nonePerson')),
                    ),
                    for (final user in _leads)
                      DropdownMenuItem(
                        value: user.id,
                        child: Text(userDisplayName(user)),
                      ),
                  ],
                  onChanged: (value) => setState(() => _leadId = value),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _saving || !_valid ? null : _submit,
                  child:
                      Text(i18n.t(_isNew ? 'projects.create' : 'common.save')),
                ),
                if (!_isNew) ...[
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
            ),
    );
  }
}
