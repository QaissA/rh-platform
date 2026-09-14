import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class SessionStore {
  Future<void> save({required String token, required String userJson});
  Future<String?> readToken();
  Future<String?> readUserJson();
  Future<void> clear();
}

class MemorySessionStore implements SessionStore {
  String? _token;
  String? _userJson;

  @override
  Future<void> save({required String token, required String userJson}) async {
    _token = token;
    _userJson = userJson;
  }

  @override
  Future<String?> readToken() async => _token;

  @override
  Future<String?> readUserJson() async => _userJson;

  @override
  Future<void> clear() async {
    _token = null;
    _userJson = null;
  }
}

class SecureSessionStore implements SessionStore {
  SecureSessionStore(this._storage);

  final FlutterSecureStorage _storage;

  static const _tokenKey = 'alize.token';
  static const _userKey = 'alize.user';

  @override
  Future<void> save({required String token, required String userJson}) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userKey, value: userJson);
  }

  @override
  Future<String?> readToken() => _storage.read(key: _tokenKey);

  @override
  Future<String?> readUserJson() => _storage.read(key: _userKey);

  @override
  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }
}
