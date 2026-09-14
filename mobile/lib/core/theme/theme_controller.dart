import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { light, dark, system }

abstract class ThemePrefs {
  static const key = 'alize.theme';

  String? read();
  Future<void> write(String value);
}

class SharedThemePrefs implements ThemePrefs {
  SharedThemePrefs(this._prefs);

  final SharedPreferences _prefs;

  @override
  String? read() => _prefs.getString(ThemePrefs.key);

  @override
  Future<void> write(String value) => _prefs.setString(ThemePrefs.key, value);
}

/// In-memory default so the app and tests start without SharedPreferences.
/// Task 31 / app bootstrap can override [themePrefsProvider] with [SharedThemePrefs].
class MemoryThemePrefs implements ThemePrefs {
  MemoryThemePrefs([Map<String, String>? store]) : store = {...?store};

  final Map<String, String> store;

  @override
  String? read() => store[ThemePrefs.key];

  @override
  Future<void> write(String value) async {
    store[ThemePrefs.key] = value;
  }
}

class ThemeController extends ChangeNotifier {
  ThemeController(this._prefs) : _mode = parse(_prefs.read());

  final ThemePrefs _prefs;
  AppThemeMode _mode;

  AppThemeMode get mode => _mode;

  ThemeMode get themeMode => switch (_mode) {
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
        AppThemeMode.system => ThemeMode.system,
      };

  Future<void> setMode(AppThemeMode mode) async {
    _mode = mode;
    await _prefs.write(mode.name);
    notifyListeners();
  }

  Future<void> toggle() {
    return setMode(
      _mode == AppThemeMode.dark ? AppThemeMode.light : AppThemeMode.dark,
    );
  }

  static AppThemeMode parse(String? raw) {
    return switch (raw) {
      'light' => AppThemeMode.light,
      'dark' => AppThemeMode.dark,
      'system' => AppThemeMode.system,
      _ => AppThemeMode.system,
    };
  }
}

final themePrefsProvider = Provider<ThemePrefs>(
  (ref) => MemoryThemePrefs(),
);

final themeControllerProvider = ChangeNotifierProvider<ThemeController>(
  (ref) => ThemeController(ref.watch(themePrefsProvider)),
);
