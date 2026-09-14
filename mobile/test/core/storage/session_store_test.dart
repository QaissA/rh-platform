import 'package:alize_mobile/core/storage/session_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MemorySessionStore store;

  setUp(() {
    store = MemorySessionStore();
  });

  test('reads return null when empty', () async {
    expect(await store.readToken(), isNull);
    expect(await store.readUserJson(), isNull);
  });

  test('save then read returns token and user json', () async {
    await store.save(token: 'jwt-token', userJson: '{"id":1}');

    expect(await store.readToken(), 'jwt-token');
    expect(await store.readUserJson(), '{"id":1}');
  });

  test('clear removes token and user json', () async {
    await store.save(token: 'jwt-token', userJson: '{"id":1}');

    await store.clear();

    expect(await store.readToken(), isNull);
    expect(await store.readUserJson(), isNull);
  });
}
