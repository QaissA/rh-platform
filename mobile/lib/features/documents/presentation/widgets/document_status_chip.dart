import 'package:alize_mobile/features/documents/domain/entities/document_status.dart';
import 'package:alize_mobile/features/documents/presentation/document_labels.dart';
import 'package:flutter/material.dart';

class DocumentStatusChip extends StatelessWidget {
  const DocumentStatusChip({
    super.key,
    required this.status,
    required this.label,
  });

  final DocumentStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = documentPaletteOf(context);
    final (fg, bg) = documentStatusColors(palette, status);
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
