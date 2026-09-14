String formatRange(String startIso, String endIso) {
  final start = _dmy(startIso);
  final end = _dmy(endIso);
  if (start == end) return start;
  return '$start – $end';
}

String formatDay(String iso) => _dmy(iso);

String isoDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Monday of the ISO week containing [date] (defaults to today).
String startOfWeekIso([DateTime? date]) {
  final source = date ?? DateTime.now();
  final day = DateTime(source.year, source.month, source.day);
  return isoDate(day.subtract(Duration(days: day.weekday - DateTime.monday)));
}

String addDaysIso(String iso, int days) {
  final parsed = DateTime.tryParse(iso.split('T').first);
  if (parsed == null) return iso;
  return isoDate(DateTime(parsed.year, parsed.month, parsed.day + days));
}

int workingDays(String startIso, String endIso) {
  final start = _parseDay(startIso);
  final end = _parseDay(endIso);
  if (start == null || end == null || end.isBefore(start)) return 0;
  var count = 0;
  var cursor = start;
  while (!cursor.isAfter(end)) {
    if (cursor.weekday >= DateTime.monday &&
        cursor.weekday <= DateTime.friday) {
      count++;
    }
    cursor = DateTime(cursor.year, cursor.month, cursor.day + 1);
  }
  return count;
}

String _dmy(String iso) {
  final parts = iso.split('T').first.split('-');
  if (parts.length != 3) return iso;
  return '${parts[2]}/${parts[1]}/${parts[0]}';
}

DateTime? _parseDay(String iso) {
  final day = iso.split('T').first;
  return DateTime.tryParse(day);
}
