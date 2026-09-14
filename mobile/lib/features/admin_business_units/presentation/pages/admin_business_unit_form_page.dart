import 'dart:async';

import 'package:alize_mobile/core/error/failures.dart';
import 'package:alize_mobile/core/l10n/i18n_provider.dart';
import 'package:alize_mobile/core/theme/alize_colors.dart';
import 'package:alize_mobile/features/admin_business_units/domain/entities/business_unit.dart';
import 'package:alize_mobile/features/admin_business_units/domain/entities/new_business_unit.dart';
import 'package:alize_mobile/features/admin_business_units/domain/entities/update_business_unit.dart';
import 'package:alize_mobile/features/admin_business_units/presentation/providers/business_unit_admin_providers.dart';
import 'package:alize_mobile/features/admin_users/presentation/providers/user_admin_providers.dart';
import 'package:alize_mobile/features/admin_users/presentation/user_labels.dart';
import 'package:alize_mobile/features/auth/domain/entities/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminBusinessUnitFormPage extends ConsumerStatefulWidget {
  const AdminBusinessUnitFormPage({super.key, this.id});

  final int? id;

  @override
  ConsumerState<AdminBusinessUnitFormPage> createState() =>
      _AdminBusinessUnitFormPageState();
}

class _AdminBusinessUnitFormPageState
    extends ConsumerState<AdminBusinessUnitFormPage> {
  final _name = TextEditingController();
  int? _managerId;
  var _loading = true;
  var _saving = false;
  BusinessUnit? _unit;
  List<User> _managers = const [];

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
    final users = await ref.read(userAdminRepositoryProvider).list();
    final units = await ref.read(businessUnitAdminRepositoryProvider).list();
    if (!mounted) return;
    _managers = (users.data ?? const [])
        .where((u) => u.role == 'manager' || u.role == 'admin')
        .toList();
    if (!_isNew) {
      _unit = units.data?.where((u) => u.id == widget.id).firstOrNull;
      if (_unit != null) {
        _name.text = _unit!.name;
        _managerId = _unit!.managerId;
      }
    }
    setState(() => _loading = false);
  }

  bool get _nameValid => _name.text.trim().isNotEmpty;

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
    if (_saving || !_nameValid) return;
    final i18n = ref.read(i18nProvider);
    final router = GoRouter.maybeOf(context);
    setState(() => _saving = true);
    if (_isNew) {
      final result = await ref.read(businessUnitAdminRepositoryProvider).create(
            NewBusinessUnit(name: _name.text.trim(), managerId: _managerId),
          );
      if (!mounted) return;
      setState(() => _saving = false);
      await _toast(
        result.isOk
            ? i18n.t('units.created')
            : _err(result.failure, i18n.t('units.createFail')),
      );
      if (result.isOk) router?.go('/business-units');
      return;
    }
    final unit = _unit;
    if (unit == null) {
      setState(() => _saving = false);
      return;
    }
    final result = await ref.read(businessUnitAdminRepositoryProvider).update(
          unit.id,
          UpdateBusinessUnit(name: _name.text.trim(), managerId: _managerId),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    await _toast(
      result.isOk
          ? i18n.t('units.renamed')
          : _err(result.failure, i18n.t('units.renameFail')),
    );
    if (result.isOk) router?.go('/business-units');
  }

  Future<void> _delete() async {
    final unit = _unit;
    if (unit == null || _saving) return;
    final i18n = ref.read(i18nProvider);
    final router = GoRouter.maybeOf(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(i18n.t('units.deleteQ')),
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
        await ref.read(businessUnitAdminRepositoryProvider).remove(unit.id);
    if (!mounted) return;
    setState(() => _saving = false);
    await _toast(
      result.isOk
          ? i18n.t('units.deleted', {'name': unit.name})
          : _err(result.failure, i18n.t('units.deleteFail')),
    );
    if (result.isOk) router?.go('/business-units');
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
                  onPressed: () => context.go('/business-units'),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(i18n.t('dossiers.back')),
                  ),
                ),
                Text(
                  i18n.t(_isNew ? 'units.createTitle' : 'units.title'),
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
                  key: ValueKey(_managerId),
                  initialValue: _managerId,
                  decoration:
                      InputDecoration(labelText: i18n.t('units.managerOptional')),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(i18n.t('common.nonePerson')),
                    ),
                    for (final user in _managers)
                      DropdownMenuItem(
                        value: user.id,
                        child: Text(userDisplayName(user)),
                      ),
                  ],
                  onChanged: (value) => setState(() => _managerId = value),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _saving || !_nameValid ? null : _submit,
                  child: Text(i18n.t(_isNew ? 'units.create' : 'common.save')),
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
