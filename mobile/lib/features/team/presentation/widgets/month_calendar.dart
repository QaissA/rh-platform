import 'package:alize_mobile/core/format/dates.dart';
import 'package:alize_mobile/core/l10n/i18n_provider.dart';
import 'package:alize_mobile/core/theme/alize_colors.dart';
import 'package:alize_mobile/features/team/domain/entities/presence_status.dart';
import 'package:alize_mobile/features/team/domain/entities/schedule_entry.dart';
import 'package:flutter/material.dart';

class MonthCalendar extends StatelessWidget {
  const MonthCalendar({
    super.key,
    required this.month,
    required this.entries,
    required this.shortNames,
    required this.colors,
    required this.i18n,
    required this.onDayTap,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
  });

  final DateTime month;
  final List<ScheduleEntry> entries;
  final Map<int, String> shortNames;
  final AlizePalette colors;
  final I18nController i18n;
  final ValueChanged<String> onDayTap;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final weeks = _weeksOf(month);
    final byDate = <String, List<ScheduleEntry>>{};
    for (final entry in entries) {
      if (entry.status == PresenceStatus.onSite) continue;
      byDate.putIfAbsent(entry.date, () => []).add(entry);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onPrev,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                _monthTitle(month, i18n.lang),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colors.ink,
                ),
              ),
            ),
            IconButton(
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right),
            ),
            IconButton(
              onPressed: onToday,
              icon: const Icon(Icons.today_outlined),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final label in _weekdayLabels(i18n.lang))
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.ink3,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        for (final week in weeks)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final day in week)
                  Expanded(
                    child: _DayCell(
                      day: day,
                      inMonth: day.month == month.month,
                      isToday: isoDate(day) == isoDate(DateTime.now()),
                      events: byDate[isoDate(day)] ?? const [],
                      shortNames: shortNames,
                      fallbackName: i18n.t('team.member'),
                      colors: colors,
                      onTap: () => onDayTap(isoDate(day)),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.inMonth,
    required this.isToday,
    required this.events,
    required this.shortNames,
    required this.fallbackName,
    required this.colors,
    required this.onTap,
  });

  final DateTime day;
  final bool inMonth;
  final bool isToday;
  final List<ScheduleEntry> events;
  final Map<int, String> shortNames;
  final String fallbackName;
  final AlizePalette colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Material(
        color: inMonth ? colors.surface2 : colors.paper,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: isToday ? colors.brand : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isToday
                                ? Colors.white
                                : (inMonth ? colors.ink : colors.ink3),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  for (final event in events.take(3))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: _EventChip(
                        label: shortNames[event.userId] ?? fallbackName,
                        status: event.status,
                        colors: colors,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EventChip extends StatelessWidget {
  const _EventChip({
    required this.label,
    required this.status,
    required this.colors,
  });

  final String label;
  final PresenceStatus status;
  final AlizePalette colors;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = switch (status) {
      PresenceStatus.remote => (colors.info, colors.infoTint),
      PresenceStatus.holiday => (colors.warn, colors.warnTint),
      PresenceStatus.onSite => (colors.ok, colors.okTint),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: fg,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

List<List<DateTime>> _weeksOf(DateTime month) {
  final first = DateTime(month.year, month.month, 1);
  final last = DateTime(month.year, month.month + 1, 0);
  var cursor = first.subtract(Duration(days: first.weekday - DateTime.monday));
  final weeks = <List<DateTime>>[];
  while (!cursor.isAfter(last)) {
    final week = <DateTime>[];
    for (var i = 0; i < 7; i++) {
      week.add(cursor);
      cursor = DateTime(cursor.year, cursor.month, cursor.day + 1);
    }
    weeks.add(week);
  }
  return weeks;
}

String _monthTitle(DateTime month, String lang) {
  final names = _monthNames[lang] ?? _monthNames['fr']!;
  return '${names[month.month - 1]} ${month.year}';
}

List<String> _weekdayLabels(String lang) =>
    _weekdays[lang] ?? _weekdays['fr']!;

const _monthNames = {
  'fr': [
    'Janvier',
    'Février',
    'Mars',
    'Avril',
    'Mai',
    'Juin',
    'Juillet',
    'Août',
    'Septembre',
    'Octobre',
    'Novembre',
    'Décembre',
  ],
  'en': [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ],
  'ar': [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ],
};

const _weekdays = {
  'fr': ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'],
  'en': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
  'ar': ['اثن', 'ثلث', 'أرب', 'خمس', 'جمع', 'سبت', 'أحد'],
};
