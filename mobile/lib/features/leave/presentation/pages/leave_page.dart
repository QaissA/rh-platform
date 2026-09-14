import 'package:alize_mobile/core/format/dates.dart';
import 'package:alize_mobile/core/l10n/i18n_provider.dart';
import 'package:alize_mobile/core/theme/alize_colors.dart';
import 'package:alize_mobile/features/leave/domain/entities/leave_request.dart';
import 'package:alize_mobile/features/leave/domain/entities/leave_status.dart';
import 'package:alize_mobile/features/leave/domain/entities/new_leave_request.dart';
import 'package:alize_mobile/features/leave/presentation/leave_labels.dart';
import 'package:alize_mobile/features/leave/presentation/providers/leave_providers.dart';
import 'package:alize_mobile/features/leave/presentation/widgets/leave_status_chip.dart';
import 'package:alize_mobile/features/leave/presentation/widgets/leave_step_tracker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LeavePage extends ConsumerWidget {
  const LeavePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.watch(i18nProvider);
    return Directionality(
      textDirection:
          i18n.dir == 'rtl' ? TextDirection.rtl : TextDirection.ltr,
      child: const _LeaveView(),
    );
  }
}

class _LeaveView extends ConsumerStatefulWidget {
  const _LeaveView();

  @override
  ConsumerState<_LeaveView> createState() => _LeaveViewState();
}

class _LeaveViewState extends ConsumerState<_LeaveView> {
  String _type = 'paid';
  String? _startDate;
  String? _endDate;
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  int? get _plannedDays {
    final start = _startDate;
    final end = _endDate;
    if (start == null || end == null) return null;
    return workingDays(start, end);
  }

  Future<void> _pickDate({required bool start}) async {
    final now = DateTime.now();
    final initial = _parseOr(_startDate) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: start ? initial : (_parseOr(_endDate) ?? initial),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (picked == null) return;
    setState(() {
      final iso = isoDate(picked);
      if (start) {
        _startDate = iso;
      } else {
        _endDate = iso;
      }
    });
  }

  DateTime? _parseOr(String? iso) {
    if (iso == null) return null;
    return DateTime.tryParse(iso.split('T').first);
  }

  Future<void> _submit() async {
    final start = _startDate;
    final end = _endDate;
    if (start == null || end == null) return;
    final controller = ref.read(leaveControllerProvider.notifier);
    if (ref.read(leaveControllerProvider).submitting) return;
    final note = _reason.text.trim();
    final result = await controller.submit(
      NewLeaveRequest(
        startDate: start,
        endDate: end,
        reason: note.isEmpty ? _type : note,
      ),
    );
    if (!mounted) return;
    final i18n = ref.read(i18nProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.isOk ? i18n.t('leave.sent') : i18n.t('leave.sendFail'),
        ),
      ),
    );
    if (result.isOk) {
      _reason.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.watch(i18nProvider);
    final state = ref.watch(leaveControllerProvider);
    final colors = alizePaletteOf(context);
    final taken = state.requests
        .where((r) => r.status == LeaveStatus.approved)
        .fold<int>(0, (sum, r) => sum + workingDays(r.startDate, r.endDate));
    final pending = state.requests.where((r) => r.status.isAwaiting).length;
    final remaining = state.balanceDays;
    final total = remaining + taken;
    final meter = total <= 0 ? 0.0 : (remaining / total).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: colors.paper,
      body: RefreshIndicator(
        onRefresh: () => ref.read(leaveControllerProvider.notifier).reload(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _BalanceMeter(
              colors: colors,
              days: remaining,
              meter: meter,
              i18n: i18n,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _KpiTile(
                    colors: colors,
                    eyebrow: i18n.t('leave.taken'),
                    figure: '$taken',
                    unit: i18n.t('common.daysUnit'),
                    sub: i18n.t('leave.takenSub'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _KpiTile(
                    colors: colors,
                    eyebrow: i18n.t('leave.pending'),
                    figure: '$pending',
                    unit: i18n.t('leave.requests'),
                    sub: i18n.t('leave.pendingSub'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        i18n.t('leave.myRequests'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        i18n.t('leave.myRequestsHelp'),
                        style: TextStyle(fontSize: 13, color: colors.ink2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () =>
                      ref.read(leaveControllerProvider.notifier).toggleForm(),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(i18n.t('common.newRequest')),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.brand,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            if (state.formOpen) ...[
              const SizedBox(height: 14),
              _NewRequestForm(
                colors: colors,
                i18n: i18n,
                type: _type,
                startDate: _startDate,
                endDate: _endDate,
                plannedDays: _plannedDays,
                reason: _reason,
                submitting: state.submitting,
                onType: (value) => setState(() => _type = value),
                onPickStart: () => _pickDate(start: true),
                onPickEnd: () => _pickDate(start: false),
                onCancel: () =>
                    ref.read(leaveControllerProvider.notifier).closeForm(),
                onSubmit: _submit,
              ),
            ],
            const SizedBox(height: 14),
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
                      i18n.t('common.loading'),
                      style: TextStyle(color: colors.ink2),
                    ),
                  ],
                ),
              )
            else if (state.requests.isEmpty)
              _EmptyLeave(colors: colors, i18n: i18n)
            else
              ...state.requests.map(
                (request) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RequestCard(request: request, colors: colors),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BalanceMeter extends StatelessWidget {
  const _BalanceMeter({
    required this.colors,
    required this.days,
    required this.meter,
    required this.i18n,
  });

  final AlizePalette colors;
  final double days;
  final double meter;
  final I18nController i18n;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AlizeColors.radius),
        border: Border.all(color: colors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              i18n.t('leave.balance'),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: colors.ink3,
              ),
            ),
            const SizedBox(height: 6),
            Text.rich(
              TextSpan(
                text: formatDays(days),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: colors.ink,
                  height: 1.1,
                ),
                children: [
                  TextSpan(
                    text: ' ${i18n.t('common.daysUnit')}',
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
              i18n.t('leave.balanceSub'),
              style: TextStyle(fontSize: 13, color: colors.ink2),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: meter,
                minHeight: 8,
                backgroundColor: colors.brandTint,
                color: colors.brand,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.colors,
    required this.eyebrow,
    required this.figure,
    required this.unit,
    required this.sub,
  });

  final AlizePalette colors;
  final String eyebrow;
  final String figure;
  final String unit;
  final String sub;

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: colors.ink3,
              ),
            ),
            const SizedBox(height: 6),
            Text.rich(
              TextSpan(
                text: figure,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: colors.ink,
                ),
                children: [
                  TextSpan(
                    text: ' $unit',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colors.ink2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(sub, style: TextStyle(fontSize: 12, color: colors.ink2)),
          ],
        ),
      ),
    );
  }
}

class _NewRequestForm extends StatelessWidget {
  const _NewRequestForm({
    required this.colors,
    required this.i18n,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.plannedDays,
    required this.reason,
    required this.submitting,
    required this.onType,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onCancel,
    required this.onSubmit,
  });

  final AlizePalette colors;
  final I18nController i18n;
  final String type;
  final String? startDate;
  final String? endDate;
  final int? plannedDays;
  final TextEditingController reason;
  final bool submitting;
  final ValueChanged<String> onType;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final canSubmit = !submitting && startDate != null && endDate != null;
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
              i18n.t('leave.newTitle'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              i18n.t('leave.absenceType'),
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
                child: DropdownButton<String>(
                  value: type,
                  isExpanded: true,
                  items: [
                    for (final code in leaveTypeCodes)
                      DropdownMenuItem(
                        value: code,
                        child: Text(i18n.t('leave.types.$code')),
                      ),
                  ],
                  onChanged: submitting
                      ? null
                      : (value) {
                          if (value != null) onType(value);
                        },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              i18n.t('leave.workingDays'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.ink2,
              ),
            ),
            const SizedBox(height: 6),
            InputDecorator(
              decoration: _inputDecoration(colors),
              child: Text(
                plannedDays?.toString() ?? i18n.t('common.dash'),
                style: TextStyle(color: colors.ink, fontSize: 15),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    colors: colors,
                    label: i18n.t('common.from'),
                    value: startDate,
                    onTap: onPickStart,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DateField(
                    colors: colors,
                    label: i18n.t('common.to'),
                    value: endDate,
                    onTap: onPickEnd,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              i18n.t('common.optionalNote'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.ink2,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: reason,
              maxLines: 2,
              decoration: _inputDecoration(colors).copyWith(
                hintText: i18n.t('leave.notePlaceholder'),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onCancel,
                  child: Text(i18n.t('common.cancel')),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: canSubmit ? onSubmit : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.brand,
                    foregroundColor: Colors.white,
                  ),
                  child: submitting
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
                            Text(i18n.t('common.sending')),
                          ],
                        )
                      : Text(i18n.t('common.submitRequest')),
                ),
              ],
            ),
          ],
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

class _RequestCard extends ConsumerWidget {
  const _RequestCard({required this.request, required this.colors});

  final LeaveRequest request;
  final AlizePalette colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.watch(i18nProvider);
    final days = request.days ?? workingDays(request.startDate, request.endDate);
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
                Expanded(
                  child: Text(
                    formatRange(request.startDate, request.endDate),
                    style: TextStyle(
                      fontSize: 15,
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
            Text(
              leaveReasonLabel(i18n, request.reason),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$days ${i18n.t('common.daysUnit')}',
              style: TextStyle(fontSize: 13, color: colors.ink2),
            ),
            const SizedBox(height: 10),
            LeaveStepTracker(status: request.status),
          ],
        ),
      ),
    );
  }
}

class _EmptyLeave extends StatelessWidget {
  const _EmptyLeave({required this.colors, required this.i18n});

  final AlizePalette colors;
  final I18nController i18n;

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
        child: Column(
          children: [
            Icon(Icons.event_outlined, size: 36, color: colors.ink3),
            const SizedBox(height: 12),
            Text(
              i18n.t('leave.empty'),
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.ink2, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
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
