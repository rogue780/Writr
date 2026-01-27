import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_theme.dart';

/// Service for managing app themes including presets and custom themes
class ThemeService extends ChangeNotifier {
  static const String _activeThemeIdKey = 'active_theme_id';
  static const String _customThemesKey = 'custom_themes';
  static const String _legacyThemeModeKey = 'theme_mode';

  // Old theme IDs for migration
  static const String _legacyLightId = 'preset_light';
  static const String _legacyDarkId = 'preset_dark';
  static const String _legacyBlueId = 'preset_blue';

  SharedPreferences? _prefs;

  String _activeThemeId = PresetThemes.defaultThemeId;
  List<AppTheme> _customThemes = [];
  AppTheme? _previewTheme;

  // Getters
  String get activeThemeId => _activeThemeId;
  List<AppTheme> get customThemes => List.unmodifiable(_customThemes);
  bool get isPreviewActive => _previewTheme != null;

  /// All available themes (presets + custom)
  List<AppTheme> get allThemes => [...PresetThemes.all, ..._customThemes];

  /// Currently active theme (or preview if active)
  AppTheme get activeTheme {
    if (_previewTheme != null) return _previewTheme!;
    return getThemeById(_activeThemeId) ?? PresetThemes.defaultTheme;
  }

  /// ThemeData for MaterialApp
  ThemeData get themeData => activeTheme.toThemeData();

  /// Initialize the service and load saved data
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _migrateFromOldThemeMode();
    _loadActiveThemeId();
    _loadCustomThemes();
  }

  /// Migrate from old 'theme_mode' string to new theme system
  void _migrateFromOldThemeMode() {
    final hasNewTheme = _prefs?.containsKey(_activeThemeIdKey) ?? false;
    if (hasNewTheme) return;

    final oldThemeMode = _prefs?.getString(_legacyThemeModeKey);
    if (oldThemeMode != null) {
      switch (oldThemeMode) {
        case 'dark':
          _activeThemeId = PresetThemes.writerDarkId;
          break;
        case 'light':
        case 'system':
        default:
          _activeThemeId = PresetThemes.writerLightId;
      }
      _prefs?.setString(_activeThemeIdKey, _activeThemeId);
    }
  }

  /// Migrate old theme IDs to new ones (light->writerLight, dark->writerDark, blue->codeLight)
  String _migrateThemeId(String themeId) {
    switch (themeId) {
      case _legacyLightId:
        return PresetThemes.writerLightId;
      case _legacyDarkId:
        return PresetThemes.writerDarkId;
      case _legacyBlueId:
        return PresetThemes.codeLightId;
      default:
        return themeId;
    }
  }

  void _loadActiveThemeId() {
    var themeId = _prefs?.getString(_activeThemeIdKey) ?? PresetThemes.defaultThemeId;

    // Migrate old theme IDs
    final migratedId = _migrateThemeId(themeId);
    if (migratedId != themeId) {
      themeId = migratedId;
      _prefs?.setString(_activeThemeIdKey, themeId);
    }

    _activeThemeId = themeId;
    notifyListeners();
  }

  void _loadCustomThemes() {
    final json = _prefs?.getString(_customThemesKey);
    if (json != null) {
      try {
        final List<dynamic> list = jsonDecode(json);
        _customThemes = list
            .map((e) => AppTheme.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('Error loading custom themes: $e');
        _customThemes = [];
      }
    }
    notifyListeners();
  }

  Future<void> _saveCustomThemes() async {
    final json = jsonEncode(_customThemes.map((t) => t.toJson()).toList());
    await _prefs?.setString(_customThemesKey, json);
  }

  /// Set the active theme by ID
  Future<void> setActiveTheme(String themeId) async {
    _activeThemeId = themeId;
    _previewTheme = null;
    notifyListeners();
    await _prefs?.setString(_activeThemeIdKey, themeId);
  }

  /// Preview a theme temporarily (does not persist)
  void previewTheme(AppTheme theme) {
    _previewTheme = theme;
    notifyListeners();
  }

  /// Cancel the current preview
  void cancelPreview() {
    _previewTheme = null;
    notifyListeners();
  }

  /// Apply the current preview as the active theme
  Future<void> applyPreview() async {
    if (_previewTheme != null) {
      // If previewing a custom theme that was edited, save it
      if (_previewTheme!.isCustom) {
        await updateCustomTheme(_previewTheme!);
      }
      await setActiveTheme(_previewTheme!.id);
    }
  }

  /// Get a theme by ID (checks presets first, then custom)
  AppTheme? getThemeById(String id) {
    // Check presets first
    final preset = PresetThemes.getById(id);
    if (preset != null) return preset;

    // Check custom themes
    try {
      return _customThemes.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Create a new custom theme
  Future<AppTheme> createCustomTheme({
    required String name,
    AppTheme? basedOn,
  }) async {
    final baseTheme = basedOn ?? PresetThemes.defaultTheme;
    final theme = AppTheme(
      id: _generateId(),
      name: name,
      isCustom: true,
      basedOnPresetId:
          basedOn?.isCustom == false ? basedOn?.id : basedOn?.basedOnPresetId,
      brightness: baseTheme.brightness,
      colors: baseTheme.colors,
      simpleColors: baseTheme.simpleColors,
      version: baseTheme.version,
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
    );

    _customThemes.add(theme);
    await _saveCustomThemes();
    notifyListeners();
    return theme;
  }

  /// Create a new custom theme from simple colors (4 base colors)
  Future<AppTheme> createCustomThemeFromSimple({
    required String name,
    required SimpleThemeColors simpleColors,
    required Brightness brightness,
    String? basedOnPresetId,
  }) async {
    final theme = AppTheme.fromSimpleColors(
      id: _generateId(),
      name: name,
      isCustom: true,
      basedOnPresetId: basedOnPresetId,
      brightness: brightness,
      simpleColors: simpleColors,
    );

    _customThemes.add(theme);
    await _saveCustomThemes();
    notifyListeners();
    return theme;
  }

  /// Duplicate an existing theme as a new custom theme
  Future<AppTheme> duplicateTheme(AppTheme source, String newName) async {
    return createCustomTheme(name: newName, basedOn: source);
  }

  /// Update a custom theme
  Future<void> updateCustomTheme(AppTheme updatedTheme) async {
    final index = _customThemes.indexWhere((t) => t.id == updatedTheme.id);
    if (index != -1) {
      _customThemes[index] = updatedTheme.copyWith(
        modifiedAt: DateTime.now(),
      );
      await _saveCustomThemes();

      // If this is the active theme, notify to update UI
      if (_activeThemeId == updatedTheme.id) {
        notifyListeners();
      }
    }
  }

  /// Delete a custom theme
  Future<void> deleteCustomTheme(String themeId) async {
    _customThemes.removeWhere((t) => t.id == themeId);

    // If deleted theme was active, switch to default
    if (_activeThemeId == themeId) {
      await setActiveTheme(PresetThemes.defaultThemeId);
    } else {
      await _saveCustomThemes();
      notifyListeners();
    }
  }

  /// Revert a custom theme to its base preset
  Future<void> revertToPreset(String customThemeId) async {
    final theme = getThemeById(customThemeId);
    if (theme == null || !theme.isCustom || theme.basedOnPresetId == null) {
      return;
    }

    final preset = PresetThemes.getById(theme.basedOnPresetId!);
    if (preset == null) return;

    final reverted = AppTheme(
      id: theme.id,
      name: theme.name,
      description: theme.description,
      isCustom: true,
      basedOnPresetId: preset.id,
      brightness: preset.brightness,
      colors: preset.colors,
      simpleColors: preset.simpleColors,
      version: preset.version,
      createdAt: theme.createdAt,
      modifiedAt: DateTime.now(),
    );

    await updateCustomTheme(reverted);
  }

  /// Check if a custom theme has been modified from its base
  bool isThemeModified(String customThemeId) {
    final theme = getThemeById(customThemeId);
    if (theme == null || !theme.isCustom || theme.basedOnPresetId == null) {
      return false;
    }

    final preset = PresetThemes.getById(theme.basedOnPresetId!);
    if (preset == null) return false;

    // Compare a few key colors to determine if modified
    return theme.colors.primary != preset.colors.primary ||
        theme.colors.secondary != preset.colors.secondary ||
        theme.colors.surface != preset.colors.surface ||
        theme.colors.onSurface != preset.colors.onSurface;
  }

  /// Rename a custom theme
  Future<void> renameCustomTheme(String themeId, String newName) async {
    final theme = getThemeById(themeId);
    if (theme == null || !theme.isCustom) return;

    await updateCustomTheme(theme.copyWith(name: newName));
  }

  String _generateId() => 'custom_${DateTime.now().millisecondsSinceEpoch}';
}
