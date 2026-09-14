import 'package:alize_mobile/features/notifications/domain/notification_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts known in-app paths including nested ids', () {
    expect(isKnownNotificationLink('/dashboard'), isTrue);
    expect(isKnownNotificationLink('/conges'), isTrue);
    expect(isKnownNotificationLink('/equipe'), isTrue);
    expect(isKnownNotificationLink('/messages'), isTrue);
    expect(isKnownNotificationLink('/documents'), isTrue);
    expect(isKnownNotificationLink('/documents/21'), isTrue);
    expect(isKnownNotificationLink('/documents-rh'), isTrue);
    expect(isKnownNotificationLink('/dossiers'), isTrue);
    expect(isKnownNotificationLink('/validation-conges'), isTrue);
    expect(isKnownNotificationLink('/parametres'), isTrue);
    expect(isKnownNotificationLink('/business-units'), isTrue);
    expect(isKnownNotificationLink('/projets'), isTrue);
    expect(isKnownNotificationLink('/equipes'), isTrue);
    expect(isKnownNotificationLink('/utilisateurs'), isTrue);
  });

  test('ignores null, external, and unknown links', () {
    expect(isKnownNotificationLink(null), isFalse);
    expect(isKnownNotificationLink(''), isFalse);
    expect(isKnownNotificationLink('https://example.com/conges'), isFalse);
    expect(isKnownNotificationLink('//evil.example/conges'), isFalse);
    expect(isKnownNotificationLink('/unknown'), isFalse);
    expect(isKnownNotificationLink('conges'), isFalse);
  });
}
