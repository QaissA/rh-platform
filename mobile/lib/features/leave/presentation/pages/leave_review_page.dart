import 'package:alize_mobile/core/format/dates.dart';
import 'package:alize_mobile/core/l10n/i18n_provider.dart';
import 'package:alize_mobile/core/theme/alize_colors.dart';
import 'package:alize_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:alize_mobile/features/leave/domain/entities/leave_request.dart';
import 'package:alize_mobile/features/leave/domain/entities/leave_status.dart';
import 'package:alize_mobile/features/leave/domain/leave_review_queue.dart';
import 'package:alize_mobile/features/leave/presentation/leave_labels.dart';
import 'package:alize_mobile/features/leave/presentation/providers/leave_review_providers.dart';
import 'package:alize_mobile/features/leave/presentation/widgets/leave_status_chip.dart';
import 'package:alize_mobile/features/leave/presentation/widgets/leave_step_tracker.dart';
import 'package:alize_mobile/features/team/domain/person_format.dart';
import 'package:alize_mobile/features/team/presentation/providers/team_providers.dart';
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

class LeaveReviewPage extends ConsumerWidget {
  const LeaveReviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.watch(i18nProvider);
    return Directionality(
      textDirection:
          i18n.dir == 'rtl' ? TextDirection.rtl : TextDirection.ltr,
      child: const _LeaveReviewView(),
    );
  }
}

class _LeaveReviewView extends ConsumerStatefulWidget {
  const _LeaveReviewView();

  @override
  ConsumerState<_LeaveReviewView> createState() => _LeaveReviewViewState();
}

class _LeaveReviewViewState extends ConsumerState<_LeaveReviewView> {
  final _rejectComment = TextEditingController();

  @override
  void dispose() {
    _rejectComment.dispose();
    super.dispose();
  }

  Future<void> _approve(LeaveRequest request) async {
    final result = await ref
        .read(leaveReviewControllerProvider.notifier)
        .approve(request.id);
    if (!mounted) return;
    final i18n = ref.read(i18nProvider);
    final name = ref.read(peopleDirectoryProvider).nameOf(request.userId);
    final updated = result.data;
    final success = result.isOk && updated != null
        ? (updated.status == LeaveStatus.pendingHr
            ? i18n.t('leaveReview.forwarded', {'name': name})
            : i18n.t('leaveReview.confirmed', {'name': name}))
        : i18n.t('leaveReview.approveFail');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success)));
  }

  Future<void> _confirmReject(LeaveRequest request) async {
    final comment = _rejectComment.text.trim();
    final result = await ref
        .read(leaveReviewControllerProvider.notifier)
        .reject(request.id, comment: comment.isEmpty ? null : comment);
    if (!mounted) return;
    _rejectComment.clear();
    final i18n = ref.read(i18nProvider);
    final name = ref.read(peopleDirectoryProvider).nameOf(request.userId);
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

  @override
  Widget build(BuildContext context) {
    final i18n = ref.watch(i18nProvider);
    final state = ref.watch(leaveReviewControllerProvider);
    final colors = alizePaletteOf(context);
    final auth = ref.watch(authProvider);
    final role = auth is AuthSignedIn ? auth.session.user.role : '';
    final pendingOnly = state.filter == LeaveReviewFilter.pending;

    return Scaffold(
      backgroundColor: colors.paper,
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(leaveReviewControllerProvider.notifier).reload(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        i18n.t('leaveReview.title'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        i18n.t(
                          role == 'rh'
                              ? 'leaveReview.introRh'
                              : 'leaveReview.introManager',
                        ),
                        style: TextStyle(fontSize: 13, color: colors.ink2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    _FilterButton(
                      colors: colors,
                      label: i18n.t('leaveReview.pending'),
                      selected: pendingOnly,
                      onTap: () => ref
                          .read(leaveReviewControllerProvider.notifier)
                          .setFilter(LeaveReviewFilter.pending),
                    ),
                    const SizedBox(height: 6),
                    _FilterButton(
                      colors: colors,
                      label: i18n.t('common.all'),
                      selected: !pendingOnly,
                      onTap: () => ref
                          .read(leaveReviewControllerProvider.notifier)
                          .setFilter(LeaveReviewFilter.all),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _KpiTile(
                    colors: colors,
                    figure: '${state.pendingCount(role)}',
                    unit: i18n.t('leaveReview.toProcess'),
                    sub: i18n.t('leaveReview.inQueue'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _KpiTile(
                    colors: colors,
                    figure: '${state.requests.length}',
                    sub: i18n.t(
                      pendingOnly ? 'leaveReview.pending' : 'common.all',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _KpiTile(
                    colors: colors,
                    figure: i18n.t(
                      role == 'manager'
                          ? 'leaveReview.scopeTeam'
                          : 'leaveReview.scopeCompany',
                    ),
                    sub: i18n.t(
                      role == 'manager'
                          ? 'leaveReview.scopeTeamSub'
                          : 'leaveReview.scopeCompanySub',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              i18n.t(
                role == 'rh'
                    ? 'leaveReview.queueRh'
                    : role == 'admin'
                        ? 'leaveReview.queueAdmin'
                        : 'leaveReview.queueManager',
              ),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 10),
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
                    Flexible(
                      child: Text(
                        i18n.t('leaveReview.loading'),
                        style: TextStyle(color: colors.ink2),
                      ),
                    ),
                  ],
                ),
              )
            else if (state.requests.isEmpty)
              _EmptyQueue(
                colors: colors,
                message: i18n.t(
                  pendingOnly
                      ? 'leaveReview.emptyPending'
                      : 'leaveReview.emptyAll',
                ),
              )
            else
              ...state.requests.map(
                (request) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ReviewCard(
                    request: request,
                    colors: colors,
                    i18n: i18n,
                    role: role,
                    busy: state.busyId == request.id,
                    rejecting: state.rejectingId == request.id,
                    rejectComment: _rejectComment,
                    onApprove: () => _approve(request),
                    onAskReject: () {
                      _rejectComment.clear();
                      ref
                          .read(leaveReviewControllerProvider.notifier)
                          .askReject(request.id);
                    },
                    onCancelReject: () {
                      _rejectComment.clear();
                      ref
                          .read(leaveReviewControllerProvider.notifier)
                          .cancelReject();
                    },
                    onConfirmReject: () => _confirmReject(request),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.colors,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final AlizePalette colors;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 108,
      child: selected
          ? FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: colors.brand,
                foregroundColor: Colors.white,
                visualDensity: VisualDensity.compact,
              ),
              child: Text(label),
            )
          : OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
              child: Text(label),
            ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.colors,
    required this.figure,
    required this.sub,
    this.unit,
  });

  final AlizePalette colors;
  final String figure;
  final String sub;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AlizeColors.radius),
        border: Border.all(color: colors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                text: figure,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colors.ink,
                ),
                children: [
                  if (unit != null)
                    TextSpan(
                      text: ' $unit',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: colors.ink2,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sub,
              style: TextStyle(fontSize: 11, color: colors.ink2),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyQueue extends StatelessWidget {
  const _EmptyQueue({required this.colors, required this.message});

  final AlizePalette colors;
  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AlizeColors.radius),
        border: Border.all(color: colors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.ink2, height: 1.4),
        ),
      ),
    );
  }
}

class _ReviewCard extends ConsumerWidget {
  const _ReviewCard({
    required this.request,
    required this.colors,
    required this.i18n,
    required this.role,
    required this.busy,
    required this.rejecting,
    required this.rejectComment,
    required this.onApprove,
    required this.onAskReject,
    required this.onCancelReject,
    required this.onConfirmReject,
  });

  final LeaveRequest request;
  final AlizePalette colors;
  final I18nController i18n;
  final String role;
  final bool busy;
  final bool rejecting;
  final TextEditingController rejectComment;
  final VoidCallback onApprove;
  final VoidCallback onAskReject;
  final VoidCallback onCancelReject;
  final VoidCallback onConfirmReject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = ref.watch(peopleDirectoryProvider);
    final name = people.nameOf(request.userId);
    final jobTitle = people.jobTitleOf(request.userId);
    final initials = people.initialsOf(request.userId);
    final days = request.days ?? workingDays(request.startDate, request.endDate);
    final actionable = isLeaveActionable(role, request.status);
    final approveLabel = request.status == LeaveStatus.pendingHr
        ? i18n.t('leaveReview.confirmLeave')
        : i18n.t('common.approve');

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AlizeColors.radius),
        border: Border.all(color: colors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
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
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: colors.ink,
                        ),
                      ),
                      if (jobTitle != null)
                        Text(
                          jobTitle,
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                            color: colors.ink2,
                          ),
                        ),
                      Text(
                        '${formatRange(request.startDate, request.endDate)} · $days ${i18n.t('common.daysShort')}',
                        style: TextStyle(fontSize: 12, color: colors.ink2),
                      ),
                    ],
                  ),
                ),
                LeaveStatusChip(
                  status: request.status,
                  label: i18n.t('status.leave.${request.status.wire}'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LeaveStepTracker(status: request.status),
            const SizedBox(height: 10),
            if (!actionable)
              Text(
                [
                  request.status == LeaveStatus.pendingHr
                      ? i18n.t('leaveReview.waitingHr')
                      : i18n.t('common.treated'),
                  if (request.decisionComment != null &&
                      request.decisionComment!.isNotEmpty)
                    request.decisionComment!,
                ].join(' — '),
                style: TextStyle(fontSize: 12.5, color: colors.ink3),
              )
            else if (rejecting)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: rejectComment,
                    decoration: InputDecoration(
                      hintText: i18n.t('common.rejectReason'),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AlizeColors.radiusSm),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      FilledButton(
                        onPressed: busy ? null : onConfirmReject,
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.bad,
                          foregroundColor: Colors.white,
                          visualDensity: VisualDensity.compact,
                        ),
                        child: Text(i18n.t('common.confirm')),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: busy ? null : onCancelReject,
                        child: Text(i18n.t('common.cancel')),
                      ),
                    ],
                  ),
                ],
              )
            else
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
                    onPressed: busy ? null : onAskReject,
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
      ),
    );
  }
}
