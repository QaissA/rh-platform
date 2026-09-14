const knownNotificationRoots = {
  'dashboard',
  'conges',
  'equipe',
  'messages',
  'documents',
  'documents-rh',
  'dossiers',
  'validation-conges',
  'parametres',
  'business-units',
  'projets',
  'equipes',
  'utilisateurs',
};

bool isKnownNotificationLink(String? link) {
  if (link == null || !link.startsWith('/') || link.startsWith('//')) {
    return false;
  }
  final uri = Uri.tryParse(link);
  if (uri == null || uri.hasScheme) return false;
  final first = uri.path.split('/').where((part) => part.isNotEmpty).firstOrNull;
  return first != null && knownNotificationRoots.contains(first);
}
