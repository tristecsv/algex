import 'package:algex/core/model/settings.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScope extends InheritedNotifier<SettingsNotifier> {
  const SettingsScope({
    super.key,
    required super.notifier,
    required super.child,
  });

  static SettingsNotifier of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SettingsScope>()!.notifier!;
}

class SettingsNotifier extends ChangeNotifier {
  Settings _settings = const Settings();
  SharedPreferences? _prefs;

  SettingsNotifier() {
    _load();
  }

  Settings get settings => _settings;
  set settings(Settings s) {
    _settings = s;
    notifyListeners();
    _save(s);
  }

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    final index = _prefs!.getInt('toleranceType');

    _settings = _settings.copyWith(
      maxIterations: _prefs!.getInt('maxIterations'),
      tolerance: _prefs!.getDouble('tolerance'),
      toleranceType: index != null ? ToleranceType.values[index] : null,
      showRealValue: _prefs!.getBool('showRealValue'),
      decimalPrecision: _prefs!.getInt('decimalPrecision'),
    );
    notifyListeners();
  }

  Future<void> _save(Settings s) async {
    _prefs ??= await SharedPreferences.getInstance();
    await Future.wait([
      _prefs!.setInt('maxIterations', s.maxIterations),
      _prefs!.setDouble('tolerance', s.tolerance),
      _prefs!.setInt('toleranceType', s.toleranceType.index),
      _prefs!.setBool('showRealValue', s.showRealValue),
      _prefs!.setInt('decimalPrecision', s.decimalPrecision),
    ]);
  }
}
