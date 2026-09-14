import 'entities/team_member.dart';

String fullName(TeamMember member) {
  final name = [
    member.firstName,
    member.lastName,
  ].whereType<String>().where((part) => part.trim().isNotEmpty).join(' ').trim();
  if (name.isNotEmpty) return name;
  return member.email.split('@').first;
}

String initialsOf(TeamMember member) {
  if (_hasText(member.firstName) || _hasText(member.lastName)) {
    final first = _hasText(member.firstName) ? member.firstName![0] : '';
    final last = _hasText(member.lastName) ? member.lastName![0] : '';
    final value = '$first$last'.toUpperCase();
    return value.isEmpty ? '?' : value;
  }
  final local = member.email.split('@').first;
  if (local.isEmpty) return '?';
  return local.substring(0, local.length.clamp(0, 2)).toUpperCase();
}

String? jobTitleOf(TeamMember? member) {
  final title = member?.jobTitle?.trim();
  if (title == null || title.isEmpty) return null;
  return title;
}

String shortName(TeamMember member) {
  final parts = fullName(member).split(' ').where((p) => p.isNotEmpty).toList();
  if (parts.length > 1) return '${parts[0]} ${parts[1][0]}.';
  return parts.isEmpty ? member.email : parts[0];
}

int avatarIndex(int id) => id % 7;

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;
