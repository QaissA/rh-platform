import 'package:alize_mobile/features/leave/domain/entities/leave_status.dart';
import 'package:alize_mobile/features/leave/presentation/leave_labels.dart';
import 'package:flutter/material.dart';

class LeaveStatusChip extends StatelessWidget {
  const LeaveStatusChip({
    super.key,
    required this.status,
    required this.label,
  });

  final LeaveStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = alizePaletteOf(context);
    final (fg, bg) = leaveStatusColors(palette, status);
    return DecoratedBox(
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
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
              child: const SizedBox(width: 6, height: 6),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 12.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
