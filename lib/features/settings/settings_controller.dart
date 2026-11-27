import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settle_app/core/enums.dart';
import 'package:settle_app/data/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 语言设置：持久化到 SharedPreferences；默认跟随系统（locale=null）。
class SettingsController extends StateNotifier<LocaleSelection> {
  SettingsController(this._prefs) : super(LocaleSelection.system) {
    final saved = _prefs.getString('locale');
    if (saved != null) {
      state = LocaleSelection.values.firstWhere(
        (s) => s.name == saved,
        orElse: () => LocaleSelection.system,
      );
    }
  }

  final SharedPreferences _prefs;

  Future<void> setLocale(LocaleSelection selection) async {
    state = selection;
    await _prefs.setString('locale', selection.name);
  }
}

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, LocaleSelection>(
      (ref) => SettingsController(ref.watch(sharedPreferencesProvider)),
    );

class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController(this._prefs)
    : super(switch (_prefs.getString('theme_mode')) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      });

  final SharedPreferences _prefs;

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _prefs.setString('theme_mode', mode.name);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeController, ThemeMode>(
  (ref) => ThemeModeController(ref.watch(sharedPreferencesProvider)),
);
