import 'presence_status.dart';

class NewPresence {
  const NewPresence({
    required this.startDate,
    required this.status,
    this.endDate,
  });

  final String startDate;
  final String? endDate;
  final DeclarableStatus status;
}
