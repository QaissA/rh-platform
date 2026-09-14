import 'dart:async';

import 'package:alize_mobile/core/error/failures.dart';
import 'package:alize_mobile/core/l10n/i18n_provider.dart';
import 'package:alize_mobile/core/theme/alize_colors.dart';
import 'package:alize_mobile/features/admin_projects/domain/entities/project.dart';
import 'package:alize_mobile/features/admin_projects/presentation/providers/project_admin_providers.dart';
import 'package:alize_mobile/features/admin_teams/domain/entities/new_team.dart';
import 'package:alize_mobile/features/admin_teams/domain/entities/team_detail.dart';
import 'package:alize_mobile/features/admin_teams/domain/entities/team_summary.dart';
import 'package:alize_mobile/features/admin_teams/domain/entities/update_team.dart';
import 'package:alize_mobile/features/admin_teams/presentation/providers/team_admin_providers.dart';
import 'package:alize_mobile/features/team/domain/entities/team_member.dart';
import 'package:alize_mobile/features/team/domain/person_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminTeamFormPage extends ConsumerStatefulWidget {
  const AdminTeamFormPage({super.key, this.id});

  final int? id;

  @override
  ConsumerState<AdminTeamFormPage> createState() => _AdminTeamFormPageState();
}

class _AdminTeamFormPageState extends ConsumerState<AdminTeamFormPage> {
  final _name = TextEditingController();
  int? _projectId;
  var _loading = true;
  var _saving = false;
  TeamSummary? _team;
  List<Project> _projects = const [];
  List<TeamMember> _members = const [];

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
    final projects = await ref.read(projectAdminRepositoryProvider).list();
    final teams = await ref.read(teamAdminRepositoryProvider).list();
    if (!mounted) return;
    final taken = {
      for (final team in teams.data ?? const <TeamSummary>[])
        if (team.projectId != null) team.projectId!,
    };
    var free = (projects.data ?? const [])
        .where((p) => !taken.contains(p.id))
        .toList();
    if (!_isNew) {
      final detail =
          await ref.read(teamAdminRepositoryProvider).get(widget.id!);
      if (!mounted) return;
      final team = detail.data;
      _team = team ?? teams.data?.where((t) => t.id == widget.id).firstOrNull;
      if (_team != null) {
        _name.text = _team!.name;
        _projectId = _team!.projectId;
        if (team is TeamDetail) {
          _members = team.members;
        }
        final current = (projects.data ?? const [])
            .where((p) => p.id == _team!.projectId)
            .toList();
        if (current.isNotEmpty &&
            !free.any((p) => p.id == current.first.id)) {
          free = [...current, ...free];
        }
      }
    }
    _projects = free;
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
      final result = await ref.read(teamAdminRepositoryProvider).create(
            NewTeam(name: _name.text.trim(), projectId: _projectId),
          );
      if (!mounted) return;
      setState(() => _saving = false);
      await _toast(
        result.isOk
            ? i18n.t('teamsAdmin.created')
            : _err(result.failure, i18n.t('teamsAdmin.createFail')),
      );
      if (result.isOk) router?.go('/equipes');
      return;
    }
    final team = _team;
    if (team == null) {
      setState(() => _saving = false);
      return;
    }
    final result = await ref.read(teamAdminRepositoryProvider).update(
          team.id,
          UpdateTeam(name: _name.text.trim(), projectId: _projectId),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    await _toast(
      result.isOk
          ? i18n.t('teamsAdmin.renamed')
          : _err(result.failure, i18n.t('teamsAdmin.renameFail')),
    );
    if (result.isOk) router?.go('/equipes');
  }

  Future<void> _delete() async {
    final team = _team;
    if (team == null || _saving) return;
    final i18n = ref.read(i18nProvider);
    final router = GoRouter.maybeOf(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(i18n.t('teamsAdmin.deleteQ')),
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
    final result = await ref.read(teamAdminRepositoryProvider).remove(team.id);
    if (!mounted) return;
    setState(() => _saving = false);
    await _toast(
      result.isOk
          ? i18n.t('teamsAdmin.deleted', {'name': team.name})
          : _err(result.failure, i18n.t('teamsAdmin.deleteFail')),
    );
    if (result.isOk) router?.go('/equipes');
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
                  onPressed: () => context.go('/equipes'),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(i18n.t('dossiers.back')),
                  ),
                ),
                Text(
                  i18n.t(_isNew ? 'teamsAdmin.createTitle' : 'teamsAdmin.title'),
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
                  key: ValueKey(_projectId),
                  initialValue: _projectId,
                  decoration: InputDecoration(
                    labelText: i18n.t('teamsAdmin.projectOptional'),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(i18n.t('common.noneOption')),
                    ),
                    for (final project in _projects)
                      DropdownMenuItem(
                        value: project.id,
                        child: Text(project.name),
                      ),
                  ],
                  onChanged: (value) => setState(() => _projectId = value),
                ),
                if (_members.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    i18n.t('common.members'),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: colors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final member in _members)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '${fullName(member)} · ${member.email}',
                        style: TextStyle(color: colors.ink2),
                      ),
                    ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _saving || !_nameValid ? null : _submit,
                  child:
                      Text(i18n.t(_isNew ? 'teamsAdmin.create' : 'common.save')),
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
