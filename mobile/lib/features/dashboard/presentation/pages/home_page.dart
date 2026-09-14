import 'package:alize_mobile/core/format/dates.dart';
import 'package:alize_mobile/core/l10n/i18n_provider.dart';
import 'package:alize_mobile/core/theme/alize_colors.dart';
import 'package:alize_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:alize_mobile/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:alize_mobile/features/documents/domain/entities/document_request.dart';
import 'package:alize_mobile/features/documents/domain/entities/document_status.dart';
import 'package:alize_mobile/features/leave/domain/entities/leave_request.dart';
import 'package:alize_mobile/features/leave/domain/entities/leave_status.dart';
import 'package:alize_mobile/features/leave/presentation/leave_labels.dart';
import 'package:alize_mobile/features/leave/presentation/widgets/leave_status_chip.dart';
import 'package:alize_mobile/features/leave/presentation/widgets/leave_step_tracker.dart';
import 'package:alize_mobile/features/team/domain/entities/presence_status.dart';
import 'package:alize_mobile/features/team/domain/entities/schedule_entry.dart';
import 'package:alize_mobile/features/team/domain/entities/team_member.dart';
import 'package:alize_mobile/features/team/domain/person_format.dart';
import 'package:alize_mobile/features/team/presentation/providers/team_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _avatarColors = [
  Color(0xFF460CAD),
  Color(0xFF6D28D9),
  Color(0xFF7C3AED),
  Color(0xFF9333EA),
  Color(0xFF5B21B6),
  Color(0xFF7E22CE),
  Color(0xFF4338CA),
];

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.watch(i18nProvider);
    return Directionality(
      textDirection:
          i18n.dir == 'rtl' ? TextDirection.rtl : TextDirection.ltr,
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends ConsumerWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.watch(i18nProvider);
    final state = ref.watch(dashboardControllerProvider);
    final auth = ref.watch(authProvider);
    final colors = alizePaletteOf(context);
    final role = auth is AuthSignedIn ? auth.session.user.role : '';
    final showManager = role == 'manager' || role == 'admin';
    final showRh = role == 'rh' || role == 'admin';
    final firstName = auth is AuthSignedIn
        ? _firstName(auth.session.user.firstName, auth.session.user.lastName,
            auth.session.user.email)
        : '';
    final intro = showRh
        ? i18n.t('dashboard.introRh')
        : showManager
            ? i18n.t('dashboard.introManager')
            : i18n.t('dashboard.introEmployee');

    ref.listen(dashboardControllerProvider, (prev, next) {
      if (next.loadFailed && prev?.loadFailed != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(i18n.t('dashboard.loadFail'))),
        );
      }
    });

    return Scaffold(
      backgroundColor: colors.paper,
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(dashboardControllerProvider.notifier).reload(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text(
              i18n.t('dashboard.hello', {'name': firstName}),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(intro, style: TextStyle(fontSize: 14, color: colors.ink2)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: () => _open(context, '/conges'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.brand,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(i18n.t('common.newRequest')),
                ),
                OutlinedButton(
                  onPressed: () => _open(context, '/documents'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: colors.ink,
                  ),
                  child: Text(i18n.t('dashboard.askDocument')),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (state.loading)
              const _DashboardSkeleton()
            else
              ..._loadedWidgets(
                context: context,
                ref: ref,
                state: state,
                colors: colors,
                i18n: i18n,
                showManager: showManager,
                showRh: showRh,
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _loadedWidgets({
    required BuildContext context,
    required WidgetRef ref,
    required DashboardViewState state,
    required AlizePalette colors,
    required I18nController i18n,
    required bool showManager,
    required bool showRh,
  }) {
    final today = isoDate(DateTime.now());
    final recent = state.requests.take(3).toList();
    final next = _nextLeave(state.requests, today, i18n);
    final readyDocs =
        state.documents.where((d) => d.status == DocumentStatus.ready).toList();
    final waitingDocs = state.documents.where((d) => d.status.isOpen).length;
    final openInbox =
        state.inbox.where((d) => d.status.isOpen).toList();
    final teamToday = _presenceList(state.roster, state.todayEntries, today);
    final weekOut = _outThisWeek(state.roster, state.weekEntries);
    final outToday = teamToday
        .where((row) => row.status == PresenceStatus.holiday)
        .toList();

    return [
      _LeaveBalanceWidget(
        colors: colors,
        i18n: i18n,
        days: state.balanceDays,
        nextLeave: next,
        onSeeLeave: () => _open(context, '/conges'),
      ),
      const SizedBox(height: 12),
      _DocumentsWidget(
        colors: colors,
        i18n: i18n,
        ready: readyDocs,
        waiting: waitingDocs,
        onSeeAll: () => _open(context, '/documents'),
      ),
      if (showManager) ...[
        const SizedBox(height: 12),
        _QueueWidget(
          colors: colors,
          i18n: i18n,
          title: i18n.t('dashboard.managerQueue'),
          empty: i18n.t('dashboard.nothingToValidate'),
          queue: state.managerQueue,
          busyId: state.busyId,
          onOpenValidation: () => _open(context, '/validation-conges'),
          onApprove: (req) => _approve(context, ref, req),
          onReject: (req) => _reject(context, ref, req),
        ),
        const SizedBox(height: 12),
        _PresenceWidget(
          colors: colors,
          i18n: i18n,
          title: i18n.t('dashboard.thisWeek'),
          empty: i18n.t('dashboard.nobodyOff'),
          rows: weekOut,
          onOpenTeam: () => _open(context, '/equipe'),
        ),
      ],
      if (showRh) ...[
        const SizedBox(height: 12),
        _QueueWidget(
          colors: colors,
          i18n: i18n,
          title: i18n.t('dashboard.hrConfirm'),
          empty: i18n.t('dashboard.noHrPending'),
          queue: state.hrQueue,
          busyId: state.busyId,
          onOpenValidation: () => _open(context, '/validation-conges'),
          onApprove: (req) => _approve(context, ref, req),
          onReject: (req) => _reject(context, ref, req),
        ),
        const SizedBox(height: 12),
        _InboxWidget(
          colors: colors,
          i18n: i18n,
          open: openInbox,
          onOpenInbox: () => _open(context, '/documents-rh'),
        ),
        const SizedBox(height: 12),
        _PresenceWidget(
          colors: colors,
          i18n: i18n,
          title: i18n.t('dashboard.presenceToday'),
          empty: i18n.t('dashboard.nobodyOff'),
          rows: outToday,
          onOpenTeam: () => _open(context, '/equipe'),
        ),
      ],
      const SizedBox(height: 12),
      _MyRequestsWidget(
        colors: colors,
        i18n: i18n,
        recent: recent,
        onSeeAll: () => _open(context, '/conges'),
        onRequest: () => _open(context, '/conges'),
      ),
      const SizedBox(height: 12),
      _PresenceWidget(
        colors: colors,
        i18n: i18n,
        title: state.teamName == null
            ? i18n.t('dashboard.presenceToday')
            : i18n.t('dashboard.teamToday'),
        empty: i18n.t('dashboard.noTeam'),
        rows: teamToday,
        onOpenTeam: () => _open(context, '/equipe'),
      ),
    ];
  }
}

class _LeaveBalanceWidget extends StatelessWidget {
  const _LeaveBalanceWidget({
    required this.colors,
    required this.i18n,
    required this.days,
    required this.nextLeave,
    required this.onSeeLeave,
  });

  final AlizePalette colors;
  final I18nController i18n;
  final double days;
  final String? nextLeave;
  final VoidCallback onSeeLeave;

  @override
  Widget build(BuildContext context) {
    return _Card(
      colors: colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WidgetHeader(title: i18n.t('dashboard.leaveBalance'), colors: colors),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                formatDays(days),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: colors.ink,
                  height: 1.1,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                i18n.t('common.daysUnit'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colors.ink2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            nextLeave ?? i18n.t('dashboard.noUpcoming'),
            style: TextStyle(fontSize: 13, color: colors.ink2),
          ),
          const SizedBox(height: 10),
          _GhostButton(
            label: i18n.t('dashboard.seeLeave'),
            colors: colors,
            onPressed: onSeeLeave,
          ),
        ],
      ),
    );
  }
}

class _DocumentsWidget extends StatelessWidget {
  const _DocumentsWidget({
    required this.colors,
    required this.i18n,
    required this.ready,
    required this.waiting,
    required this.onSeeAll,
  });

  final AlizePalette colors;
  final I18nController i18n;
  final List<DocumentRequest> ready;
  final int waiting;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return _Card(
      colors: colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WidgetHeader(
            title: i18n.t('dashboard.documents'),
            colors: colors,
            action: i18n.t('common.seeAll'),
            onAction: onSeeAll,
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              text: '${ready.length}',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: colors.ink,
              ),
              children: [
                TextSpan(
                  text: ' ${i18n.t('dashboard.readyCount')}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colors.ink2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            i18n.t('dashboard.waitingRh', {'n': waiting}),
            style: TextStyle(fontSize: 13, color: colors.ink2),
          ),
          const SizedBox(height: 8),
          if (ready.isEmpty)
            Text(
              i18n.t('dashboard.noDownload'),
              style: TextStyle(fontSize: 13, color: colors.ink2),
            )
          else
            for (final doc in ready.take(4))
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  i18n.t('docType.${doc.docType}'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.ink,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _InboxWidget extends StatelessWidget {
  const _InboxWidget({
    required this.colors,
    required this.i18n,
    required this.open,
    required this.onOpenInbox,
  });

  final AlizePalette colors;
  final I18nController i18n;
  final List<DocumentRequest> open;
  final VoidCallback onOpenInbox;

  @override
  Widget build(BuildContext context) {
    return _Card(
      colors: colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WidgetHeader(
            title: i18n.t('dashboard.docsToWrite'),
            colors: colors,
            action: i18n.t('dashboard.inbox'),
            onAction: onOpenInbox,
          ),
          const SizedBox(height: 8),
          Text(
            '${open.length}',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 8),
          if (open.isEmpty)
            Text(
              i18n.t('dashboard.inboxEmpty'),
              style: TextStyle(fontSize: 13, color: colors.ink2),
            )
          else
            for (final doc in open.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        i18n.t('docType.${doc.docType}'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.ink,
                        ),
                      ),
                    ),
                    _StatusPill(
                      label: i18n.t('status.doc.${doc.status.wire}'),
                      fg: _docColors(colors, doc.status).$1,
                      bg: _docColors(colors, doc.status).$2,
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _MyRequestsWidget extends StatelessWidget {
  const _MyRequestsWidget({
    required this.colors,
    required this.i18n,
    required this.recent,
    required this.onSeeAll,
    required this.onRequest,
  });

  final AlizePalette colors;
  final I18nController i18n;
  final List<LeaveRequest> recent;
  final VoidCallback onSeeAll;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    return _Card(
      colors: colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WidgetHeader(
            title: i18n.t('dashboard.myRequests'),
            colors: colors,
            action: i18n.t('common.seeAll'),
            onAction: onSeeAll,
          ),
          if (recent.isEmpty) ...[
            const SizedBox(height: 16),
            Text(
              i18n.t('dashboard.noRequests'),
              style: TextStyle(fontSize: 13, color: colors.ink2),
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: onRequest,
              style: FilledButton.styleFrom(
                backgroundColor: colors.brand,
                foregroundColor: Colors.white,
                visualDensity: VisualDensity.compact,
              ),
              child: Text(i18n.t('dashboard.requestLeave')),
            ),
          ] else
            for (final request in recent)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            formatRange(request.startDate, request.endDate),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: colors.ink,
                            ),
                          ),
                        ),
                        LeaveStatusChip(
                          status: request.status,
                          label: i18n.t('status.leave.${request.status.wire}'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LeaveStepTracker(status: request.status),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _QueueWidget extends ConsumerWidget {
  const _QueueWidget({
    required this.colors,
    required this.i18n,
    required this.title,
    required this.empty,
    required this.queue,
    required this.busyId,
    required this.onOpenValidation,
    required this.onApprove,
    required this.onReject,
  });

  final AlizePalette colors;
  final I18nController i18n;
  final String title;
  final String empty;
  final List<LeaveRequest> queue;
  final int? busyId;
  final VoidCallback onOpenValidation;
  final ValueChanged<LeaveRequest> onApprove;
  final ValueChanged<LeaveRequest> onReject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = ref.watch(peopleDirectoryProvider);
    return _Card(
      colors: colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WidgetHeader(
            title: title,
            colors: colors,
            action: i18n.t('dashboard.validation'),
            onAction: onOpenValidation,
          ),
          if (queue.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                empty,
                style: TextStyle(fontSize: 13, color: colors.ink2),
              ),
            )
          else
            for (final req in queue)
              _QueueItem(
                request: req,
                name: people.nameOf(req.userId),
                jobTitle: people.jobTitleOf(req.userId),
                initials: people.initialsOf(req.userId),
                colors: colors,
                i18n: i18n,
                busy: busyId == req.id,
                onApprove: () => onApprove(req),
                onReject: () => onReject(req),
              ),
        ],
      ),
    );
  }
}

class _QueueItem extends StatelessWidget {
  const _QueueItem({
    required this.request,
    required this.name,
    required this.jobTitle,
    required this.initials,
    required this.colors,
    required this.i18n,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  final LeaveRequest request;
  final String name;
  final String? jobTitle;
  final String initials;
  final AlizePalette colors;
  final I18nController i18n;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final days = request.days ?? workingDays(request.startDate, request.endDate);
    final approveLabel = request.status == LeaveStatus.pendingHr
        ? i18n.t('leaveReview.confirmLeave')
        : i18n.t('common.approve');
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: _avatarColors[avatarIndex(request.userId)],
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        text: name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: colors.ink,
                        ),
                        children: [
                          if (jobTitle != null)
                            TextSpan(
                              text: '  $jobTitle',
                              style: TextStyle(
                                fontWeight: FontWeight.w400,
                                fontSize: 12,
                                color: colors.ink2,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '${formatRange(request.startDate, request.endDate)} · $days ${i18n.t('common.daysShort')}',
                      style: TextStyle(fontSize: 12, color: colors.ink2),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LeaveStepTracker(status: request.status),
          const SizedBox(height: 8),
          Row(
            children: [
              FilledButton(
                onPressed: busy ? null : onApprove,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.brand,
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(approveLabel),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: busy ? null : onReject,
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.bad,
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(i18n.t('common.reject')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PresenceRowData {
  const _PresenceRowData({
    required this.member,
    required this.status,
  });

  final TeamMember member;
  final PresenceStatus status;
}

class _PresenceWidget extends StatelessWidget {
  const _PresenceWidget({
    required this.colors,
    required this.i18n,
    required this.title,
    required this.empty,
    required this.rows,
    required this.onOpenTeam,
  });

  final AlizePalette colors;
  final I18nController i18n;
  final String title;
  final String empty;
  final List<_PresenceRowData> rows;
  final VoidCallback onOpenTeam;

  @override
  Widget build(BuildContext context) {
    return _Card(
      colors: colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WidgetHeader(
            title: title,
            colors: colors,
            action: i18n.t('dashboard.team'),
            onAction: onOpenTeam,
          ),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                empty,
                style: TextStyle(fontSize: 13, color: colors.ink2),
              ),
            )
          else
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: _avatarColors[avatarIndex(row.member.id)],
                      child: Text(
                        initialsOf(row.member),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName(row.member),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: colors.ink,
                            ),
                          ),
                          Text(
                            i18n.t('status.role.${row.member.role}'),
                            style: TextStyle(fontSize: 12, color: colors.ink2),
                          ),
                        ],
                      ),
                    ),
                    _StatusPill(
                      label: i18n.t('status.presence.${row.status.wire}'),
                      fg: _presenceColors(colors, row.status).$1,
                      bg: _presenceColors(colors, row.status).$2,
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = alizePaletteOf(context);
    return Column(
      key: const Key('dashboard-skeleton'),
      children: [
        _skel(colors, 96),
        const SizedBox(height: 12),
        _skel(colors, 72),
        const SizedBox(height: 12),
        _skel(colors, 120),
        const SizedBox(height: 12),
        _skel(colors, 72),
      ],
    );
  }

  Widget _skel(AlizePalette colors, double height) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.brandTint,
        borderRadius: BorderRadius.circular(AlizeColors.radius),
      ),
      child: SizedBox(width: double.infinity, height: height),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.colors, required this.child});

  final AlizePalette colors;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AlizeColors.radius),
        border: Border.all(color: colors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: child,
      ),
    );
  }
}

class _WidgetHeader extends StatelessWidget {
  const _WidgetHeader({
    required this.title,
    required this.colors,
    this.action,
    this.onAction,
  });

  final String title;
  final AlizePalette colors;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colors.ink,
            ),
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              foregroundColor: colors.brandInk,
            ),
            child: Text(action!),
          ),
      ],
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({
    required this.label,
    required this.colors,
    required this.onPressed,
  });

  final String label;
  final AlizePalette colors;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        foregroundColor: colors.ink,
      ),
      child: Text(label),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.fg,
    required this.bg,
  });

  final String label;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(7, 3, 9, 3),
        child: Text(
          label,
          style: TextStyle(
            color: fg,
            fontSize: 12.2,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

void _open(BuildContext context, String path) {
  GoRouter.maybeOf(context)?.go(path);
}

String _firstName(String? first, String? last, String email) {
  final name = [first, last]
      .whereType<String>()
      .where((part) => part.trim().isNotEmpty)
      .join(' ')
      .trim();
  final source = name.isEmpty ? email.split('@').first : name;
  return source.split(' ').first;
}

String? _nextLeave(
  List<LeaveRequest> requests,
  String today,
  I18nController i18n,
) {
  final upcoming = requests
      .where(
        (r) => r.status == LeaveStatus.approved && r.startDate.compareTo(today) >= 0,
      )
      .toList()
    ..sort((a, b) => a.startDate.compareTo(b.startDate));
  if (upcoming.isEmpty) return null;
  return i18n.t('dashboard.nextLeave', {
    'range': formatRange(upcoming.first.startDate, upcoming.first.endDate),
  });
}

PresenceStatus _statusOn(
  List<ScheduleEntry> entries,
  int userId,
  String day,
) {
  return entries
          .where((e) => e.userId == userId && e.date == day)
          .map((e) => e.status)
          .firstOrNull ??
      PresenceStatus.onSite;
}

List<_PresenceRowData> _presenceList(
  List<TeamMember> roster,
  List<ScheduleEntry> entries,
  String day,
) {
  return [
    for (final member in roster)
      _PresenceRowData(
        member: member,
        status: _statusOn(entries, member.id, day),
      ),
  ];
}

List<_PresenceRowData> _outThisWeek(
  List<TeamMember> roster,
  List<ScheduleEntry> entries,
) {
  return [
    for (final member in roster)
      if (entries.any(
        (e) => e.userId == member.id && e.status == PresenceStatus.holiday,
      ))
        _PresenceRowData(member: member, status: PresenceStatus.holiday),
  ];
}

(Color, Color) _presenceColors(AlizePalette colors, PresenceStatus status) {
  return switch (status) {
    PresenceStatus.onSite => (colors.ok, colors.okTint),
    PresenceStatus.remote => (colors.info, colors.infoTint),
    PresenceStatus.holiday => (colors.warn, colors.warnTint),
  };
}

(Color, Color) _docColors(AlizePalette colors, DocumentStatus status) {
  return switch (status) {
    DocumentStatus.pending => (colors.warn, colors.warnTint),
    DocumentStatus.processing => (colors.info, colors.infoTint),
    DocumentStatus.ready => (colors.ok, colors.okTint),
    DocumentStatus.rejected => (colors.bad, colors.badTint),
    DocumentStatus.cancelled => (colors.ink3, colors.surface2),
  };
}

Future<void> _approve(
  BuildContext context,
  WidgetRef ref,
  LeaveRequest request,
) async {
  final i18n = ref.read(i18nProvider);
  final people = ref.read(peopleDirectoryProvider);
  final result =
      await ref.read(dashboardControllerProvider.notifier).approve(request.id);
  if (!context.mounted) return;
  final name = people.nameOf(request.userId);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        result.isOk
            ? (request.status == LeaveStatus.pendingHr
                ? i18n.t('leaveReview.confirmed', {'name': name})
                : i18n.t('leaveReview.forwarded', {'name': name}))
            : i18n.t('leaveReview.approveFail'),
      ),
    ),
  );
}

Future<void> _reject(
  BuildContext context,
  WidgetRef ref,
  LeaveRequest request,
) async {
  final i18n = ref.read(i18nProvider);
  final people = ref.read(peopleDirectoryProvider);
  final result =
      await ref.read(dashboardControllerProvider.notifier).reject(request.id);
  if (!context.mounted) return;
  final name = people.nameOf(request.userId);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        result.isOk
            ? i18n.t('leaveReview.rejectedFor', {'name': name})
            : i18n.t('leaveReview.rejectFail'),
      ),
    ),
  );
}
