import 'package:alize_mobile/core/l10n/i18n_provider.dart';
import 'package:alize_mobile/core/theme/alize_colors.dart';
import 'package:alize_mobile/features/leave/domain/entities/leave_status.dart';
import 'package:flutter/material.dart';

AlizePalette alizePaletteOf(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? AlizeColors.dark
      : AlizeColors.light;
}

const leaveTypeCodes = ['paid', 'rtt', 'unpaid', 'family'];

const _leaveTypeAliases = <String, String>{
  'paid': 'paid',
  'rtt': 'rtt',
  'unpaid': 'unpaid',
  'family': 'family',
  'Congés payés': 'paid',
  'Paid leave': 'paid',
  'Congés': 'paid',
  'Leave': 'paid',
  'إجازة': 'paid',
  'إجازة مدفوعة': 'paid',
  'RTT': 'rtt',
  'Sans solde': 'unpaid',
  'Unpaid leave': 'unpaid',
  'بدون راتب': 'unpaid',
  'Congé familial': 'family',
  'Family leave': 'family',
  'إجازة عائلية': 'family',
};

String? leaveTypeCode(String? reason) {
  if (reason == null || reason.isEmpty) return null;
  return _leaveTypeAliases[reason];
}

String leaveReasonLabel(I18nController i18n, String? reason) {
  final code = leaveTypeCode(reason);
  if (code != null) return i18n.t('leave.types.$code');
  if (reason != null && reason.isNotEmpty) return reason;
  return i18n.t('leave.defaultReason');
}

(Color, Color) leaveStatusColors(AlizePalette colors, LeaveStatus status) {
  return switch (status) {
    LeaveStatus.pending => (colors.warn, colors.warnTint),
    LeaveStatus.pendingHr => (colors.info, colors.infoTint),
    LeaveStatus.approved => (colors.ok, colors.okTint),
    LeaveStatus.rejected => (colors.bad, colors.badTint),
  };
}

String formatDays(double days) {
  if (days == days.roundToDouble()) return '${days.toInt()}';
  return '$days';
}
