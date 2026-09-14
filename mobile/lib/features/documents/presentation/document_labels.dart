import 'package:alize_mobile/core/theme/alize_colors.dart';
import 'package:alize_mobile/features/documents/domain/entities/document_status.dart';
import 'package:flutter/material.dart';

const documentTypeCodes = [
  'work_certificate',
  'salary_certificate',
  'leave_attestation',
  'other',
];

AlizePalette documentPaletteOf(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? AlizeColors.dark
      : AlizeColors.light;
}

(Color, Color) documentStatusColors(
  AlizePalette colors,
  DocumentStatus status,
) {
  return switch (status) {
    DocumentStatus.pending => (colors.warn, colors.warnTint),
    DocumentStatus.processing => (colors.info, colors.infoTint),
    DocumentStatus.ready => (colors.ok, colors.okTint),
    DocumentStatus.rejected => (colors.bad, colors.badTint),
    DocumentStatus.cancelled => (colors.ink3, colors.surface2),
  };
}
