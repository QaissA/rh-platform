import 'package:alize_mobile/core/format/dates.dart';
import 'package:alize_mobile/core/l10n/i18n_provider.dart';
import 'package:alize_mobile/core/theme/alize_colors.dart';
import 'package:alize_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:alize_mobile/features/team/domain/entities/presence_status.dart';
import 'package:alize_mobile/features/team/domain/entities/team_member.dart';
import 'package:alize_mobile/features/team/domain/person_format.dart';
import 'package:alize_mobile/features/team/presentation/providers/team_providers.dart';
import 'package:alize_mobile/features/team/presentation/widgets/month_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _avatarColors = [
  Color(0xFF460CAD),
  Color(0xFF6D28D9),
  Color(0xFF7C3AED),
  Color(0xFF9333EA),
  Color(0xFF5B21B6),
  Color(0xFF7E22CE),
  Color(0xFF4338CA),
];

AlizePalette _paletteOf(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? AlizeColors.dark
      : AlizeColors.light;
}

class TeamPage extends ConsumerWidget {
  const TeamPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.watch(i18nProvider);
    return Directionality(
      textDirection:
          i18n.dir == 'rtl' ? TextDirection.rtl : TextDirection.ltr,
      child: const _TeamView(),
    );
  }
}

class _TeamView extends ConsumerWidget {
  const _TeamView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.watch(i18nProvider);
    final state = ref.watch(teamControllerProvider);
    final auth = ref.watch(authProvider);
    final meId = auth is AuthSignedIn ? auth.session.user.id : null;
    final colors = _paletteOf(context);
    final today = isoDate(DateTime.now());
    final statuses = state.statusByKey;
    final shortNames = {
      for (final member in state.roster) member.id: shortName(member),
    };

    return Scaffold(
      backgroundColor: colors.paper,
      body: RefreshIndicator(
        onRefresh: () => ref.read(teamControllerProvider.notifier).reload(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        i18n.t(
                          'team.scheduleTitle',
                          {
                            'name': state.hasTeam
                                ? state.teamName
                                : i18n.t('team.noTeam'),
                          },
                        ),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        i18n.t('team.help'),
                        style: TextStyle(fontSize: 13, color: colors.ink2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () =>
                      ref.read(teamControllerProvider.notifier).togglePanel(),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(i18n.t('team.declare')),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.brand,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            if (state.panelOpen) ...[
              const SizedBox(height: 14),
              _DeclarePanel(colors: colors, i18n: i18n),
            ],
            const SizedBox(height: 16),
            if (state.loading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      i18n.t('team.loading'),
                      style: TextStyle(color: colors.ink2),
                    ),
                  ],
                ),
              )
            else ...[
              for (final member in state.roster) ...[
                _MemberCard(
                  member: member,
                  status: statuses['${member.id}|$today'] ?? PresenceStatus.onSite,
                  isMe: member.id == meId,
                  colors: colors,
                  i18n: i18n,
                ),
                const SizedBox(height: 12),
              ],
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(AlizeColors.radius),
                  border: Border.all(color: colors.line),
                ),
                  child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        i18n.t('team.calendar'),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: colors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        i18n.t('team.calendarHint'),
                        style: TextStyle(fontSize: 12, color: colors.ink3),
                      ),
                      const SizedBox(height: 12),
                      MonthCalendar(
                        month: state.visibleMonth,
                        entries: state.entries,
                        shortNames: shortNames,
                        colors: colors,
                        i18n: i18n,
                        onDayTap: (iso) => ref
                            .read(teamControllerProvider.notifier)
                            .openDay(iso),
                        onPrev: () => ref
                            .read(teamControllerProvider.notifier)
                            .shiftMonth(-1),
                        onNext: () => ref
                            .read(teamControllerProvider.notifier)
                            .shiftMonth(1),
                        onToday: () =>
                            ref.read(teamControllerProvider.notifier).goToToday(),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 14,
                        runSpacing: 8,
                        children: [
                          _LegendDot(
                            color: colors.ok,
                            label: i18n.t('status.presence.on_site'),
                          ),
                          _LegendDot(
                            color: colors.info,
                            label: i18n.t('status.presence.remote'),
                          ),
                          _LegendDot(
                            color: colors.warn,
                            label: i18n.t('status.presence.holiday'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.status,
    required this.isMe,
    required this.colors,
    required this.i18n,
  });

  final TeamMember member;
  final PresenceStatus status;
  final bool isMe;
  final AlizePalette colors;
  final I18nController i18n;

  @override
  Widget build(BuildContext context) {
    final title = jobTitleOf(member);
    final (fg, bg) = _presenceColors(colors, status);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AlizeColors.radius),
        border: Border.all(color: colors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: _avatarColors[avatarIndex(member.id)],
                  child: Text(
                    initialsOf(member),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            fullName(member),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: colors.ink,
                            ),
                          ),
                          if (title != null)
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: colors.ink2,
                              ),
                            ),
                          if (isMe)
                            _MutedChip(
                              label: i18n.t('common.you'),
                              colors: colors,
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        i18n.t('status.role.${member.role}'),
                        style: TextStyle(fontSize: 13, color: colors.ink2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: colors.line2),
            const SizedBox(height: 10),
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(7, 3, 9, 3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DecoratedBox(
                          decoration:
                              BoxDecoration(color: fg, shape: BoxShape.circle),
                          child: const SizedBox(width: 6, height: 6),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          i18n.t('status.presence.${status.wire}'),
                          style: TextStyle(
                            color: fg,
                            fontSize: 12.2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    member.email,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: colors.ink3,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MutedChip extends StatelessWidget {
  const _MutedChip({required this.label, required this.colors});

  final String label;
  final AlizePalette colors;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface2,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: colors.ink2,
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: const SizedBox(width: 10, height: 10),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12.5)),
      ],
    );
  }
}

class _DeclarePanel extends ConsumerWidget {
  const _DeclarePanel({required this.colors, required this.i18n});

  final AlizePalette colors;
  final I18nController i18n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(teamControllerProvider);
    final canSubmit = !state.submitting && state.declStart != null;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AlizeColors.radius),
        border: Border.all(color: colors.brand600),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              i18n.t('team.declare'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              i18n.t('team.place'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.ink2,
              ),
            ),
            const SizedBox(height: 6),
            InputDecorator(
              decoration: _inputDecoration(colors),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<DeclarableStatus>(
                  value: state.declStatus,
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(
                      value: DeclarableStatus.remote,
                      child: Text(i18n.t('status.presence.remote')),
                    ),
                    DropdownMenuItem(
                      value: DeclarableStatus.onSite,
                      child: Text(i18n.t('status.presence.on_site')),
                    ),
                  ],
                  onChanged: state.submitting
                      ? null
                      : (value) {
                          if (value != null) {
                            ref
                                .read(teamControllerProvider.notifier)
                                .setDeclStatus(value);
                          }
                        },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    colors: colors,
                    label: i18n.t('common.from'),
                    value: state.declStart,
                    onTap: () => _pickDate(context, ref, start: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DateField(
                    colors: colors,
                    label: i18n.t('common.to'),
                    value: state.declEnd,
                    onTap: () => _pickDate(context, ref, start: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () =>
                      ref.read(teamControllerProvider.notifier).closePanel(),
                  child: Text(i18n.t('common.cancel')),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: canSubmit ? () => _submit(context, ref) : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.brand,
                    foregroundColor: Colors.white,
                  ),
                  child: state.submitting
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(i18n.t('common.saving')),
                          ],
                        )
                      : Text(i18n.t('common.save')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    WidgetRef ref, {
    required bool start,
  }) async {
    final state = ref.read(teamControllerProvider);
    final now = DateTime.now();
    final initial = _parseOr(state.declStart) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: start ? initial : (_parseOr(state.declEnd) ?? initial),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (picked == null) return;
    final iso = isoDate(picked);
    final controller = ref.read(teamControllerProvider.notifier);
    if (start) {
      controller.setDeclStart(iso);
    } else {
      controller.setDeclEnd(iso);
    }
  }

  DateTime? _parseOr(String? iso) {
    if (iso == null) return null;
    return DateTime.tryParse(iso.split('T').first);
  }

  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(teamControllerProvider.notifier).submit();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.isOk ? i18n.t('team.saved') : i18n.t('team.saveFail'),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.colors,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final AlizePalette colors;
  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.ink2,
          ),
        ),
        const SizedBox(height: 6),
        Material(
          color: colors.surface,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AlizeColors.radiusSm),
            child: InputDecorator(
              decoration: _inputDecoration(colors),
              child: Text(
                value == null ? '—' : formatRange(value!, value!),
                style: TextStyle(
                  color: value == null ? colors.ink3 : colors.ink,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

(Color, Color) _presenceColors(AlizePalette colors, PresenceStatus status) {
  return switch (status) {
    PresenceStatus.onSite => (colors.ok, colors.okTint),
    PresenceStatus.remote => (colors.info, colors.infoTint),
    PresenceStatus.holiday => (colors.warn, colors.warnTint),
  };
}

InputDecoration _inputDecoration(AlizePalette colors) {
  return InputDecoration(
    filled: true,
    fillColor: colors.surface,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AlizeColors.radiusSm),
      borderSide: BorderSide(color: colors.line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AlizeColors.radiusSm),
      borderSide: BorderSide(color: colors.line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AlizeColors.radiusSm),
      borderSide: BorderSide(color: colors.brand),
    ),
  );
}
