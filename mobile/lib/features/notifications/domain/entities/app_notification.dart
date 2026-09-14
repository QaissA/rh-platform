class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.read,
    required this.createdAt,
    this.body,
    this.link,
  });

  final int id;
  final String kind;
  final String title;
  final String? body;
  final String? link;
  final bool read;
  final String createdAt;
}
