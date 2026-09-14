import 'package:alize_mobile/core/l10n/i18n_provider.dart';
import 'package:alize_mobile/core/theme/alize_colors.dart';
import 'package:alize_mobile/features/leave/domain/entities/leave_status.dart';
import 'package:alize_mobile/features/leave/presentation/leave_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LeaveStepTracker extends ConsumerWidget {
  const LeaveStepTracker({super.key, required this.status});

  final LeaveStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.watch(i18nProvider);
    final palette = alizePaletteOf(context);
    final managerDone =
        status == LeaveStatus.pendingHr || status == LeaveStatus.approved;
    final managerNow = status == LeaveStatus.pending;
    final hrDone = status == LeaveStatus.approved;
    final hrNow = status == LeaveStatus.pendingHr;

    return Semantics(
      label: i18n.t('stepper.label'),
      child: Row(
        children: [
          _Step(
            label: i18n.t('stepper.manager'),
            done: managerDone,
            current: managerNow,
            palette: palette,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7),
            child: Text(
              '→',
              style: TextStyle(color: palette.line, fontWeight: FontWeight.w400),
            ),
          ),
          _Step(
            label: i18n.t('stepper.hr'),
            done: hrDone,
            current: hrNow,
            palette: palette,
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.label,
    required this.done,
    required this.current,
    required this.palette,
  });

  final String label;
  final bool done;
  final bool current;
  final AlizePalette palette;

  @override
  Widget build(BuildContext context) {
    final color = current
        ? palette.warn
        : done
            ? palette.ok
            : palette.ink3;
    return Text(
      label,
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }
}
