import 'package:flutter/material.dart';

@immutable
class AlizePalette {
  const AlizePalette({
    required this.paper,
    required this.surface,
    required this.surface2,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.line,
    required this.line2,
    required this.brand,
    required this.brandInk,
    required this.brand600,
    required this.brandTint,
    required this.brandTint2,
    required this.honey,
    required this.ok,
    required this.okTint,
    required this.warn,
    required this.warnTint,
    required this.bad,
    required this.badTint,
    required this.info,
    required this.infoTint,
  });

  final Color paper;
  final Color surface;
  final Color surface2;
  final Color ink;
  final Color ink2;
  final Color ink3;
  final Color line;
  final Color line2;
  final Color brand;
  final Color brandInk;
  final Color brand600;
  final Color brandTint;
  final Color brandTint2;
  final Color honey;
  final Color ok;
  final Color okTint;
  final Color warn;
  final Color warnTint;
  final Color bad;
  final Color badTint;
  final Color info;
  final Color infoTint;
}

class AlizeColors {
  AlizeColors._();

  static const double radius = 14;
  static const double radiusSm = 9;

  static const light = AlizePalette(
    paper: Color(0xFFF4F2F8),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFFAF8FD),
    ink: Color(0xFF0E0B14),
    ink2: Color(0xFF544F5E),
    ink3: Color(0xFF8A8397),
    line: Color(0xFFE5E0EE),
    line2: Color(0xFFEEEBF5),
    brand: Color(0xFF460CAD),
    brandInk: Color(0xFF460CAD),
    brand600: Color(0xFF5A1AC8),
    brandTint: Color(0xFFECE5F8),
    brandTint2: Color(0xFFDACFF1),
    honey: Color(0xFF7C3AED),
    ok: Color(0xFF2F8F5B),
    okTint: Color(0xFFE4F1E9),
    warn: Color(0xFFB77E12),
    warnTint: Color(0xFFF6ECD6),
    bad: Color(0xFFBB5245),
    badTint: Color(0xFFF6E3DF),
    info: Color(0xFF3E6C8C),
    infoTint: Color(0xFFE3ECF2),
  );

  static const dark = AlizePalette(
    paper: Color(0xFF09080D),
    surface: Color(0xFF141220),
    surface2: Color(0xFF0F0E17),
    ink: Color(0xFFECEAF4),
    ink2: Color(0xFFA29DB2),
    ink3: Color(0xFF6E687E),
    line: Color(0xFF272338),
    line2: Color(0xFF1E1B2B),
    brand: Color(0xFF8B5CF6),
    brandInk: Color(0xFFA78BFA),
    brand600: Color(0xFF9B77F8),
    brandTint: Color(0xFF241A3D),
    brandTint2: Color(0xFF2E2150),
    honey: Color(0xFFA78BFA),
    ok: Color(0xFF46B074),
    okTint: Color(0xFF14301F),
    warn: Color(0xFFD3A03A),
    warnTint: Color(0xFF332711),
    bad: Color(0xFFD66A5B),
    badTint: Color(0xFF351D19),
    info: Color(0xFF6398BD),
    infoTint: Color(0xFF132633),
  );
}
