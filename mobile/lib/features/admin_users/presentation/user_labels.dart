import 'package:alize_mobile/features/auth/domain/entities/user.dart';

String userDisplayName(User user) {
  final name = [
    user.firstName,
    user.lastName,
  ].whereType<String>().where((part) => part.trim().isNotEmpty).join(' ').trim();
  if (name.isNotEmpty) return name;
  return user.email.split('@').first;
}

final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

const adminRoles = ['employee', 'lead', 'manager', 'rh', 'admin'];
