import 'package:alize_mobile/core/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('persist key is alize.theme', () {
    expect(ThemePrefs.key, 'alize.theme');
  });

  test('defaults to system when prefs are empty', () {
    final controller = ThemeController(MemoryThemePrefs());

    expect(controller.mode, AppThemeMode.system);
    expect(controller.themeMode, ThemeMode.system);
  });

  test('hydrates light, dark, and system from alize.theme', () {
    expect(
      ThemeController(MemoryThemePrefs({'alize.theme': 'light'})).mode,
      AppThemeMode.light,
    );
    expect(
      ThemeController(MemoryThemePrefs({'alize.theme': 'dark'})).mode,
      AppThemeMode.dark,
    );
    expect(
      ThemeController(MemoryThemePrefs({'alize.theme': 'system'})).mode,
      AppThemeMode.system,
    );
  });

  test('invalid stored value falls back to system', () {
    final controller = ThemeController(
      MemoryThemePrefs({'alize.theme': 'neon'}),
    );

    expect(controller.mode, AppThemeMode.system);
  });

  test('setMode persists to alize.theme', () async {
    final prefs = MemoryThemePrefs();
    final controller = ThemeController(prefs);

    await controller.setMode(AppThemeMode.light);
    expect(prefs.store['alize.theme'], 'light');
    expect(controller.themeMode, ThemeMode.light);

    await controller.setMode(AppThemeMode.dark);
    expect(prefs.store['alize.theme'], 'dark');
    expect(controller.themeMode, ThemeMode.dark);

    await controller.setMode(AppThemeMode.system);
    expect(prefs.store['alize.theme'], 'system');
    expect(controller.themeMode, ThemeMode.system);
  });

  test('toggle switches light and dark and persists', () async {
    final prefs = MemoryThemePrefs();
    final controller = ThemeController(prefs);

    await controller.toggle();
    expect(controller.mode, AppThemeMode.dark);
    expect(prefs.store['alize.theme'], 'dark');

    await controller.toggle();
    expect(controller.mode, AppThemeMode.light);
    expect(prefs.store['alize.theme'], 'light');

    await controller.toggle();
    expect(controller.mode, AppThemeMode.dark);
    expect(prefs.store['alize.theme'], 'dark');
  });

  test('themeControllerProvider uses injected ThemePrefs', () async {
    final prefs = MemoryThemePrefs({'alize.theme': 'light'});
    final container = ProviderContainer(
      overrides: [
        themePrefsProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(themeControllerProvider).mode, AppThemeMode.light);

    await container.read(themeControllerProvider).toggle();

    expect(container.read(themeControllerProvider).mode, AppThemeMode.dark);
    expect(prefs.store['alize.theme'], 'dark');
  });
}
