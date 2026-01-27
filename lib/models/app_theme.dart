import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Simple 4-color theme definition that users can easily customize.
/// All Material 3 color variations are auto-generated from these 4 base colors.
class SimpleThemeColors {
  final Color primary;
  final Color secondary;
  final Color background;
  final Color text;

  const SimpleThemeColors({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.text,
  });

  Map<String, dynamic> toJson() => {
        'primary': _colorToHex(primary),
        'secondary': _colorToHex(secondary),
        'background': _colorToHex(background),
        'text': _colorToHex(text),
      };

  factory SimpleThemeColors.fromJson(Map<String, dynamic> json) =>
      SimpleThemeColors(
        primary: _hexToColor(json['primary']),
        secondary: _hexToColor(json['secondary']),
        background: _hexToColor(json['background']),
        text: _hexToColor(json['text']),
      );

  static String _colorToHex(Color color) =>
      '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';

  static Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  SimpleThemeColors copyWith({
    Color? primary,
    Color? secondary,
    Color? background,
    Color? text,
  }) {
    return SimpleThemeColors(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      background: background ?? this.background,
      text: text ?? this.text,
    );
  }
}

/// Extension methods for HSL color manipulation
extension ColorHSL on Color {
  /// Convert to HSL components (h: 0-360, s: 0-1, l: 0-1)
  ({double h, double s, double l}) toHSL() {
    // Use the new Flutter color API (r, g, b are 0-1 range)
    final rVal = r;
    final gVal = g;
    final bVal = b;

    final max = math.max(rVal, math.max(gVal, bVal));
    final min = math.min(rVal, math.min(gVal, bVal));
    final l = (max + min) / 2;

    if (max == min) {
      return (h: 0.0, s: 0.0, l: l);
    }

    final d = max - min;
    final s = l > 0.5 ? d / (2 - max - min) : d / (max + min);

    double h;
    if (max == rVal) {
      h = (gVal - bVal) / d + (gVal < bVal ? 6 : 0);
    } else if (max == gVal) {
      h = (bVal - rVal) / d + 2;
    } else {
      h = (rVal - gVal) / d + 4;
    }
    h *= 60;

    return (h: h, s: s, l: l);
  }

  /// Create a color from HSL values
  static Color fromHSL(double h, double s, double l, [double alpha = 1.0]) {
    h = h % 360;
    if (h < 0) h += 360;
    s = s.clamp(0.0, 1.0);
    l = l.clamp(0.0, 1.0);

    if (s == 0) {
      return Color.from(alpha: alpha, red: l, green: l, blue: l);
    }

    double hueToRgb(double p, double q, double t) {
      if (t < 0) t += 1;
      if (t > 1) t -= 1;
      if (t < 1 / 6) return p + (q - p) * 6 * t;
      if (t < 1 / 2) return q;
      if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
      return p;
    }

    final q = l < 0.5 ? l * (1 + s) : l + s - l * s;
    final p = 2 * l - q;
    final hNorm = h / 360;

    final rVal = hueToRgb(p, q, hNorm + 1 / 3);
    final gVal = hueToRgb(p, q, hNorm);
    final bVal = hueToRgb(p, q, hNorm - 1 / 3);

    return Color.from(alpha: alpha, red: rVal, green: gVal, blue: bVal);
  }

  /// Adjust lightness by a delta (-1 to 1)
  Color adjustLightness(double delta) {
    final hsl = toHSL();
    return ColorHSL.fromHSL(hsl.h, hsl.s, hsl.l + delta, a);
  }

  /// Adjust saturation by a delta (-1 to 1)
  Color adjustSaturation(double delta) {
    final hsl = toHSL();
    return ColorHSL.fromHSL(hsl.h, hsl.s + delta, hsl.l, a);
  }

  /// Shift hue by degrees
  Color shiftHue(double degrees) {
    final hsl = toHSL();
    return ColorHSL.fromHSL(hsl.h + degrees, hsl.s, hsl.l, a);
  }

  /// Get contrast color (black or white based on luminance)
  Color contrastColor() {
    return computeLuminance() > 0.5 ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
  }
}

/// Generates all 31 Material 3 colors from 4 simple base colors
class ThemeColorGenerator {
  final SimpleThemeColors simpleColors;
  final bool isDark;

  const ThemeColorGenerator({
    required this.simpleColors,
    required this.isDark,
  });

  /// Generate the full AppThemeColors from 4 base colors
  AppThemeColors generate() {
    final primary = simpleColors.primary;
    final secondary = simpleColors.secondary;
    final background = simpleColors.background;
    final text = simpleColors.text;

    // Generate tertiary by shifting primary hue
    final tertiary = primary.shiftHue(30);

    // Container adjustments depend on light/dark mode
    final containerDelta = isDark ? -0.15 : 0.25;
    final onContainerDelta = isDark ? 0.35 : -0.35;

    return AppThemeColors(
      // Primary colors
      primary: primary,
      onPrimary: primary.contrastColor(),
      primaryContainer: primary.adjustLightness(containerDelta),
      onPrimaryContainer: primary.adjustLightness(onContainerDelta),

      // Secondary colors
      secondary: secondary,
      onSecondary: secondary.contrastColor(),
      secondaryContainer: secondary.adjustLightness(containerDelta),
      onSecondaryContainer: secondary.adjustLightness(onContainerDelta),

      // Tertiary colors (hue-shifted from primary)
      tertiary: tertiary,
      onTertiary: tertiary.contrastColor(),
      tertiaryContainer: tertiary.adjustLightness(containerDelta),
      onTertiaryContainer: tertiary.adjustLightness(onContainerDelta),

      // Error colors (standard Material red)
      error: isDark ? const Color(0xFFFFB4AB) : const Color(0xFFBA1A1A),
      onError: isDark ? const Color(0xFF690005) : const Color(0xFFFFFFFF),
      errorContainer: isDark ? const Color(0xFF93000A) : const Color(0xFFFFDAD6),
      onErrorContainer: isDark ? const Color(0xFFFFDAD6) : const Color(0xFF410002),

      // Surface colors
      surface: background,
      onSurface: text,
      surfaceContainerHighest: background.adjustLightness(isDark ? 0.12 : -0.08),
      surfaceContainerHigh: background.adjustLightness(isDark ? 0.09 : -0.05),
      surfaceContainer: background.adjustLightness(isDark ? 0.06 : -0.03),
      surfaceContainerLow: background.adjustLightness(isDark ? 0.03 : -0.01),
      surfaceContainerLowest: background.adjustLightness(isDark ? -0.02 : 0.02),

      // Outline colors
      outline: text.adjustSaturation(-0.3).adjustLightness(isDark ? -0.2 : 0.2),
      outlineVariant: text.adjustSaturation(-0.5).adjustLightness(isDark ? -0.35 : 0.35),

      // System colors
      shadow: const Color(0xFF000000),
      scrim: const Color(0xFF000000),

      // Inverse colors
      inverseSurface: isDark ? text.adjustLightness(0.1) : text.adjustLightness(-0.1),
      onInverseSurface: isDark ? background.adjustLightness(-0.05) : background.adjustLightness(0.05),
      inversePrimary: primary.adjustLightness(isDark ? -0.2 : 0.2),
    );
  }
}

/// All customizable colors in a theme
class AppThemeColors {
  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color secondary;
  final Color onSecondary;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color tertiary;
  final Color onTertiary;
  final Color tertiaryContainer;
  final Color onTertiaryContainer;
  final Color error;
  final Color onError;
  final Color errorContainer;
  final Color onErrorContainer;
  final Color surface;
  final Color onSurface;
  final Color surfaceContainerHighest;
  final Color surfaceContainerHigh;
  final Color surfaceContainer;
  final Color surfaceContainerLow;
  final Color surfaceContainerLowest;
  final Color outline;
  final Color outlineVariant;
  final Color shadow;
  final Color scrim;
  final Color inverseSurface;
  final Color onInverseSurface;
  final Color inversePrimary;

  const AppThemeColors({
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.tertiary,
    required this.onTertiary,
    required this.tertiaryContainer,
    required this.onTertiaryContainer,
    required this.error,
    required this.onError,
    required this.errorContainer,
    required this.onErrorContainer,
    required this.surface,
    required this.onSurface,
    required this.surfaceContainerHighest,
    required this.surfaceContainerHigh,
    required this.surfaceContainer,
    required this.surfaceContainerLow,
    required this.surfaceContainerLowest,
    required this.outline,
    required this.outlineVariant,
    required this.shadow,
    required this.scrim,
    required this.inverseSurface,
    required this.onInverseSurface,
    required this.inversePrimary,
  });

  AppThemeColors copyWith({
    Color? primary,
    Color? onPrimary,
    Color? primaryContainer,
    Color? onPrimaryContainer,
    Color? secondary,
    Color? onSecondary,
    Color? secondaryContainer,
    Color? onSecondaryContainer,
    Color? tertiary,
    Color? onTertiary,
    Color? tertiaryContainer,
    Color? onTertiaryContainer,
    Color? error,
    Color? onError,
    Color? errorContainer,
    Color? onErrorContainer,
    Color? surface,
    Color? onSurface,
    Color? surfaceContainerHighest,
    Color? surfaceContainerHigh,
    Color? surfaceContainer,
    Color? surfaceContainerLow,
    Color? surfaceContainerLowest,
    Color? outline,
    Color? outlineVariant,
    Color? shadow,
    Color? scrim,
    Color? inverseSurface,
    Color? onInverseSurface,
    Color? inversePrimary,
  }) {
    return AppThemeColors(
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      onPrimaryContainer: onPrimaryContainer ?? this.onPrimaryContainer,
      secondary: secondary ?? this.secondary,
      onSecondary: onSecondary ?? this.onSecondary,
      secondaryContainer: secondaryContainer ?? this.secondaryContainer,
      onSecondaryContainer: onSecondaryContainer ?? this.onSecondaryContainer,
      tertiary: tertiary ?? this.tertiary,
      onTertiary: onTertiary ?? this.onTertiary,
      tertiaryContainer: tertiaryContainer ?? this.tertiaryContainer,
      onTertiaryContainer: onTertiaryContainer ?? this.onTertiaryContainer,
      error: error ?? this.error,
      onError: onError ?? this.onError,
      errorContainer: errorContainer ?? this.errorContainer,
      onErrorContainer: onErrorContainer ?? this.onErrorContainer,
      surface: surface ?? this.surface,
      onSurface: onSurface ?? this.onSurface,
      surfaceContainerHighest:
          surfaceContainerHighest ?? this.surfaceContainerHighest,
      surfaceContainerHigh: surfaceContainerHigh ?? this.surfaceContainerHigh,
      surfaceContainer: surfaceContainer ?? this.surfaceContainer,
      surfaceContainerLow: surfaceContainerLow ?? this.surfaceContainerLow,
      surfaceContainerLowest:
          surfaceContainerLowest ?? this.surfaceContainerLowest,
      outline: outline ?? this.outline,
      outlineVariant: outlineVariant ?? this.outlineVariant,
      shadow: shadow ?? this.shadow,
      scrim: scrim ?? this.scrim,
      inverseSurface: inverseSurface ?? this.inverseSurface,
      onInverseSurface: onInverseSurface ?? this.onInverseSurface,
      inversePrimary: inversePrimary ?? this.inversePrimary,
    );
  }

  /// Update a single color by property name
  AppThemeColors copyWithProperty(String property, Color color) {
    switch (property) {
      case 'primary':
        return copyWith(primary: color);
      case 'onPrimary':
        return copyWith(onPrimary: color);
      case 'primaryContainer':
        return copyWith(primaryContainer: color);
      case 'onPrimaryContainer':
        return copyWith(onPrimaryContainer: color);
      case 'secondary':
        return copyWith(secondary: color);
      case 'onSecondary':
        return copyWith(onSecondary: color);
      case 'secondaryContainer':
        return copyWith(secondaryContainer: color);
      case 'onSecondaryContainer':
        return copyWith(onSecondaryContainer: color);
      case 'tertiary':
        return copyWith(tertiary: color);
      case 'onTertiary':
        return copyWith(onTertiary: color);
      case 'tertiaryContainer':
        return copyWith(tertiaryContainer: color);
      case 'onTertiaryContainer':
        return copyWith(onTertiaryContainer: color);
      case 'error':
        return copyWith(error: color);
      case 'onError':
        return copyWith(onError: color);
      case 'errorContainer':
        return copyWith(errorContainer: color);
      case 'onErrorContainer':
        return copyWith(onErrorContainer: color);
      case 'surface':
        return copyWith(surface: color);
      case 'onSurface':
        return copyWith(onSurface: color);
      case 'surfaceContainerHighest':
        return copyWith(surfaceContainerHighest: color);
      case 'surfaceContainerHigh':
        return copyWith(surfaceContainerHigh: color);
      case 'surfaceContainer':
        return copyWith(surfaceContainer: color);
      case 'surfaceContainerLow':
        return copyWith(surfaceContainerLow: color);
      case 'surfaceContainerLowest':
        return copyWith(surfaceContainerLowest: color);
      case 'outline':
        return copyWith(outline: color);
      case 'outlineVariant':
        return copyWith(outlineVariant: color);
      case 'shadow':
        return copyWith(shadow: color);
      case 'scrim':
        return copyWith(scrim: color);
      case 'inverseSurface':
        return copyWith(inverseSurface: color);
      case 'onInverseSurface':
        return copyWith(onInverseSurface: color);
      case 'inversePrimary':
        return copyWith(inversePrimary: color);
      default:
        return this;
    }
  }

  /// Get color by property name
  Color? getByProperty(String property) {
    switch (property) {
      case 'primary':
        return primary;
      case 'onPrimary':
        return onPrimary;
      case 'primaryContainer':
        return primaryContainer;
      case 'onPrimaryContainer':
        return onPrimaryContainer;
      case 'secondary':
        return secondary;
      case 'onSecondary':
        return onSecondary;
      case 'secondaryContainer':
        return secondaryContainer;
      case 'onSecondaryContainer':
        return onSecondaryContainer;
      case 'tertiary':
        return tertiary;
      case 'onTertiary':
        return onTertiary;
      case 'tertiaryContainer':
        return tertiaryContainer;
      case 'onTertiaryContainer':
        return onTertiaryContainer;
      case 'error':
        return error;
      case 'onError':
        return onError;
      case 'errorContainer':
        return errorContainer;
      case 'onErrorContainer':
        return onErrorContainer;
      case 'surface':
        return surface;
      case 'onSurface':
        return onSurface;
      case 'surfaceContainerHighest':
        return surfaceContainerHighest;
      case 'surfaceContainerHigh':
        return surfaceContainerHigh;
      case 'surfaceContainer':
        return surfaceContainer;
      case 'surfaceContainerLow':
        return surfaceContainerLow;
      case 'surfaceContainerLowest':
        return surfaceContainerLowest;
      case 'outline':
        return outline;
      case 'outlineVariant':
        return outlineVariant;
      case 'shadow':
        return shadow;
      case 'scrim':
        return scrim;
      case 'inverseSurface':
        return inverseSurface;
      case 'onInverseSurface':
        return onInverseSurface;
      case 'inversePrimary':
        return inversePrimary;
      default:
        return null;
    }
  }

  Map<String, dynamic> toJson() => {
        'primary': _colorToHex(primary),
        'onPrimary': _colorToHex(onPrimary),
        'primaryContainer': _colorToHex(primaryContainer),
        'onPrimaryContainer': _colorToHex(onPrimaryContainer),
        'secondary': _colorToHex(secondary),
        'onSecondary': _colorToHex(onSecondary),
        'secondaryContainer': _colorToHex(secondaryContainer),
        'onSecondaryContainer': _colorToHex(onSecondaryContainer),
        'tertiary': _colorToHex(tertiary),
        'onTertiary': _colorToHex(onTertiary),
        'tertiaryContainer': _colorToHex(tertiaryContainer),
        'onTertiaryContainer': _colorToHex(onTertiaryContainer),
        'error': _colorToHex(error),
        'onError': _colorToHex(onError),
        'errorContainer': _colorToHex(errorContainer),
        'onErrorContainer': _colorToHex(onErrorContainer),
        'surface': _colorToHex(surface),
        'onSurface': _colorToHex(onSurface),
        'surfaceContainerHighest': _colorToHex(surfaceContainerHighest),
        'surfaceContainerHigh': _colorToHex(surfaceContainerHigh),
        'surfaceContainer': _colorToHex(surfaceContainer),
        'surfaceContainerLow': _colorToHex(surfaceContainerLow),
        'surfaceContainerLowest': _colorToHex(surfaceContainerLowest),
        'outline': _colorToHex(outline),
        'outlineVariant': _colorToHex(outlineVariant),
        'shadow': _colorToHex(shadow),
        'scrim': _colorToHex(scrim),
        'inverseSurface': _colorToHex(inverseSurface),
        'onInverseSurface': _colorToHex(onInverseSurface),
        'inversePrimary': _colorToHex(inversePrimary),
      };

  factory AppThemeColors.fromJson(Map<String, dynamic> json) => AppThemeColors(
        primary: _hexToColor(json['primary']),
        onPrimary: _hexToColor(json['onPrimary']),
        primaryContainer: _hexToColor(json['primaryContainer']),
        onPrimaryContainer: _hexToColor(json['onPrimaryContainer']),
        secondary: _hexToColor(json['secondary']),
        onSecondary: _hexToColor(json['onSecondary']),
        secondaryContainer: _hexToColor(json['secondaryContainer']),
        onSecondaryContainer: _hexToColor(json['onSecondaryContainer']),
        tertiary: _hexToColor(json['tertiary']),
        onTertiary: _hexToColor(json['onTertiary']),
        tertiaryContainer: _hexToColor(json['tertiaryContainer']),
        onTertiaryContainer: _hexToColor(json['onTertiaryContainer']),
        error: _hexToColor(json['error']),
        onError: _hexToColor(json['onError']),
        errorContainer: _hexToColor(json['errorContainer']),
        onErrorContainer: _hexToColor(json['onErrorContainer']),
        surface: _hexToColor(json['surface']),
        onSurface: _hexToColor(json['onSurface']),
        surfaceContainerHighest: _hexToColor(json['surfaceContainerHighest']),
        surfaceContainerHigh: _hexToColor(json['surfaceContainerHigh']),
        surfaceContainer: _hexToColor(json['surfaceContainer']),
        surfaceContainerLow: _hexToColor(json['surfaceContainerLow']),
        surfaceContainerLowest: _hexToColor(json['surfaceContainerLowest']),
        outline: _hexToColor(json['outline']),
        outlineVariant: _hexToColor(json['outlineVariant']),
        shadow: _hexToColor(json['shadow']),
        scrim: _hexToColor(json['scrim']),
        inverseSurface: _hexToColor(json['inverseSurface']),
        onInverseSurface: _hexToColor(json['onInverseSurface']),
        inversePrimary: _hexToColor(json['inversePrimary']),
      );

  static String _colorToHex(Color color) =>
      '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';

  static Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  /// Generate ColorScheme from these colors
  ColorScheme toColorScheme(Brightness brightness) => ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondary,
        onSecondary: onSecondary,
        secondaryContainer: secondaryContainer,
        onSecondaryContainer: onSecondaryContainer,
        tertiary: tertiary,
        onTertiary: onTertiary,
        tertiaryContainer: tertiaryContainer,
        onTertiaryContainer: onTertiaryContainer,
        error: error,
        onError: onError,
        errorContainer: errorContainer,
        onErrorContainer: onErrorContainer,
        surface: surface,
        onSurface: onSurface,
        surfaceContainerHighest: surfaceContainerHighest,
        surfaceContainerHigh: surfaceContainerHigh,
        surfaceContainer: surfaceContainer,
        surfaceContainerLow: surfaceContainerLow,
        surfaceContainerLowest: surfaceContainerLowest,
        outline: outline,
        outlineVariant: outlineVariant,
        shadow: shadow,
        scrim: scrim,
        inverseSurface: inverseSurface,
        onInverseSurface: onInverseSurface,
        inversePrimary: inversePrimary,
      );
}

/// Represents a complete app theme with metadata
class AppTheme {
  final String id;
  final String name;
  final String? description;
  final bool isCustom;
  final String? basedOnPresetId;
  final Brightness brightness;
  final AppThemeColors colors;
  final SimpleThemeColors? simpleColors; // v2: 4 base colors for simplified editing
  final int version; // 1 = legacy (31 colors only), 2 = simplified (4 colors + generated)
  final DateTime? createdAt;
  final DateTime? modifiedAt;

  const AppTheme({
    required this.id,
    required this.name,
    this.description,
    this.isCustom = false,
    this.basedOnPresetId,
    required this.brightness,
    required this.colors,
    this.simpleColors,
    this.version = 2,
    this.createdAt,
    this.modifiedAt,
  });

  AppTheme copyWith({
    String? id,
    String? name,
    String? description,
    bool? isCustom,
    String? basedOnPresetId,
    Brightness? brightness,
    AppThemeColors? colors,
    SimpleThemeColors? simpleColors,
    int? version,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) {
    return AppTheme(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isCustom: isCustom ?? this.isCustom,
      basedOnPresetId: basedOnPresetId ?? this.basedOnPresetId,
      brightness: brightness ?? this.brightness,
      colors: colors ?? this.colors,
      simpleColors: simpleColors ?? this.simpleColors,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  /// Create a custom copy of this theme
  AppTheme copyAsCustom({required String newId, required String newName}) {
    return AppTheme(
      id: newId,
      name: newName,
      isCustom: true,
      basedOnPresetId: isCustom ? basedOnPresetId : id,
      brightness: brightness,
      colors: colors,
      simpleColors: simpleColors,
      version: version,
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
    );
  }

  /// Create a theme from simple colors (auto-generates full color scheme)
  factory AppTheme.fromSimpleColors({
    required String id,
    required String name,
    String? description,
    bool isCustom = true,
    String? basedOnPresetId,
    required Brightness brightness,
    required SimpleThemeColors simpleColors,
  }) {
    final generator = ThemeColorGenerator(
      simpleColors: simpleColors,
      isDark: brightness == Brightness.dark,
    );
    return AppTheme(
      id: id,
      name: name,
      description: description,
      isCustom: isCustom,
      basedOnPresetId: basedOnPresetId,
      brightness: brightness,
      colors: generator.generate(),
      simpleColors: simpleColors,
      version: 2,
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
    );
  }

  /// Regenerate colors from simpleColors (useful after user changes base colors)
  AppTheme regenerateColors() {
    if (simpleColors == null) return this;
    final generator = ThemeColorGenerator(
      simpleColors: simpleColors!,
      isDark: brightness == Brightness.dark,
    );
    return copyWith(
      colors: generator.generate(),
      modifiedAt: DateTime.now(),
    );
  }

  /// Generate ThemeData for MaterialApp
  ThemeData toThemeData() {
    final colorScheme = colors.toColorScheme(brightness);
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'isCustom': isCustom,
        'basedOnPresetId': basedOnPresetId,
        'brightness': brightness.name,
        'colors': colors.toJson(),
        'simpleColors': simpleColors?.toJson(),
        'version': version,
        'createdAt': createdAt?.toIso8601String(),
        'modifiedAt': modifiedAt?.toIso8601String(),
      };

  factory AppTheme.fromJson(Map<String, dynamic> json) => AppTheme(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        isCustom: json['isCustom'] ?? true,
        basedOnPresetId: json['basedOnPresetId'],
        brightness: Brightness.values.firstWhere(
          (b) => b.name == json['brightness'],
          orElse: () => Brightness.light,
        ),
        colors: AppThemeColors.fromJson(json['colors']),
        simpleColors: json['simpleColors'] != null
            ? SimpleThemeColors.fromJson(json['simpleColors'])
            : null,
        version: json['version'] ?? 1, // Default to v1 for legacy themes
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : null,
        modifiedAt: json['modifiedAt'] != null
            ? DateTime.parse(json['modifiedAt'])
            : null,
      );

  String toJsonString() => jsonEncode(toJson());

  factory AppTheme.fromJsonString(String jsonString) =>
      AppTheme.fromJson(jsonDecode(jsonString));
}

/// Built-in preset themes
class PresetThemes {
  static const String writerLightId = 'preset_writer_light';
  static const String writerDarkId = 'preset_writer_dark';
  static const String codeLightId = 'preset_code_light';
  static const String codeDarkId = 'preset_code_dark';
  static const String sepiaId = 'preset_sepia';
  static const String hotdogStandId = 'preset_hotdog_stand';
  static const String nordId = 'preset_nord';
  static const String solarizedId = 'preset_solarized';

  // Default theme ID
  static const String defaultThemeId = writerDarkId;

  // Simple color definitions for new themes
  static const _writerLightSimple = SimpleThemeColors(
    primary: Color(0xFF5D4E37), // warm brown, cork-board inspired
    secondary: Color(0xFF7A6B5A), // muted taupe
    background: Color(0xFFFAF8F5), // warm off-white paper
    text: Color(0xFF2D2A26), // dark brown-gray
  );

  static const _writerDarkSimple = SimpleThemeColors(
    primary: Color(0xFFD4B896), // light warm tan
    secondary: Color(0xFFB8A898), // muted light taupe
    background: Color(0xFF1E1C1A), // dark warm gray
    text: Color(0xFFE8E4DF), // off-white
  );

  static const _codeLightSimple = SimpleThemeColors(
    primary: Color(0xFF0066B8), // VSCode blue
    secondary: Color(0xFF6A737D), // GitHub gray
    background: Color(0xFFFFFFFF), // pure white
    text: Color(0xFF24292E), // GitHub dark
  );

  static const _codeDarkSimple = SimpleThemeColors(
    primary: Color(0xFF569CD6), // VSCode light blue
    secondary: Color(0xFF9CDCFE), // VSCode cyan
    background: Color(0xFF1E1E1E), // VSCode dark
    text: Color(0xFFD4D4D4), // VSCode light gray
  );

  // Writer Light - Scrivener-inspired warm tones
  static final AppTheme writerLight = AppTheme(
    id: writerLightId,
    name: 'Writer Light',
    description: 'Warm, comfortable tones for distraction-free writing',
    brightness: Brightness.light,
    simpleColors: _writerLightSimple,
    version: 2,
    colors: ThemeColorGenerator(
      simpleColors: _writerLightSimple,
      isDark: false,
    ).generate(),
  );

  // Writer Dark - Scrivener-inspired warm dark tones (DEFAULT)
  static final AppTheme writerDark = AppTheme(
    id: writerDarkId,
    name: 'Writer Dark',
    description: 'Warm dark theme for comfortable night writing',
    brightness: Brightness.dark,
    simpleColors: _writerDarkSimple,
    version: 2,
    colors: ThemeColorGenerator(
      simpleColors: _writerDarkSimple,
      isDark: true,
    ).generate(),
  );

  // Code Light - VSCode-inspired clean professional look
  static final AppTheme codeLight = AppTheme(
    id: codeLightId,
    name: 'Code Light',
    description: 'Clean, professional light theme inspired by VSCode',
    brightness: Brightness.light,
    simpleColors: _codeLightSimple,
    version: 2,
    colors: ThemeColorGenerator(
      simpleColors: _codeLightSimple,
      isDark: false,
    ).generate(),
  );

  // Code Dark - VSCode-inspired dark theme
  static final AppTheme codeDark = AppTheme(
    id: codeDarkId,
    name: 'Code Dark',
    description: 'Professional dark theme inspired by VSCode',
    brightness: Brightness.dark,
    simpleColors: _codeDarkSimple,
    version: 2,
    colors: ThemeColorGenerator(
      simpleColors: _codeDarkSimple,
      isDark: true,
    ).generate(),
  );

  // Sepia/Brown Theme (reading-friendly warm tones)
  static const AppTheme sepia = AppTheme(
    id: sepiaId,
    name: 'Sepia',
    description: 'Warm brown tones for comfortable reading',
    brightness: Brightness.light,
    colors: AppThemeColors(
      primary: Color(0xFF8B5A2B),
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFFFDCC2),
      onPrimaryContainer: Color(0xFF2E1500),
      secondary: Color(0xFF765848),
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFFFDCC8),
      onSecondaryContainer: Color(0xFF2B160A),
      tertiary: Color(0xFF636032),
      onTertiary: Color(0xFFFFFFFF),
      tertiaryContainer: Color(0xFFEAE5AB),
      onTertiaryContainer: Color(0xFF1E1C00),
      error: Color(0xFFBA1A1A),
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF410002),
      surface: Color(0xFFFFF8F5),
      onSurface: Color(0xFF211A14),
      surfaceContainerHighest: Color(0xFFEDE0D4),
      surfaceContainerHigh: Color(0xFFF3E5D9),
      surfaceContainer: Color(0xFFF9EBDE),
      surfaceContainerLow: Color(0xFFFDF0E5),
      surfaceContainerLowest: Color(0xFFFFFBFF),
      outline: Color(0xFF857369),
      outlineVariant: Color(0xFFD7C2B4),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFF372F28),
      onInverseSurface: Color(0xFFFDEEE3),
      inversePrimary: Color(0xFFFFB77C),
    ),
  );

  // Hotdog Stand Theme (Windows 3.1 classic)
  static const AppTheme hotdogStand = AppTheme(
    id: hotdogStandId,
    name: 'Hotdog Stand',
    description: 'Windows 3.1 classic: red, yellow, and black',
    brightness: Brightness.light,
    colors: AppThemeColors(
      primary: Color(0xFFCC0000),
      onPrimary: Color(0xFFFFFF00),
      primaryContainer: Color(0xFFFFFF00),
      onPrimaryContainer: Color(0xFF000000),
      secondary: Color(0xFFFFFF00),
      onSecondary: Color(0xFF000000),
      secondaryContainer: Color(0xFFCC0000),
      onSecondaryContainer: Color(0xFFFFFF00),
      tertiary: Color(0xFF000000),
      onTertiary: Color(0xFFFFFF00),
      tertiaryContainer: Color(0xFFFFFF00),
      onTertiaryContainer: Color(0xFF000000),
      error: Color(0xFF000000),
      onError: Color(0xFFFFFF00),
      errorContainer: Color(0xFFFFFF00),
      onErrorContainer: Color(0xFF000000),
      surface: Color(0xFFCC0000),
      onSurface: Color(0xFFFFFF00),
      surfaceContainerHighest: Color(0xFFAA0000),
      surfaceContainerHigh: Color(0xFFBB0000),
      surfaceContainer: Color(0xFFCC0000),
      surfaceContainerLow: Color(0xFFDD0000),
      surfaceContainerLowest: Color(0xFFEE0000),
      outline: Color(0xFF000000),
      outlineVariant: Color(0xFFFFFF00),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFFFFFF00),
      onInverseSurface: Color(0xFF000000),
      inversePrimary: Color(0xFF000000),
    ),
  );

  // Nord Theme (Arctic blue-gray dark theme)
  static const AppTheme nord = AppTheme(
    id: nordId,
    name: 'Nord',
    description: 'Arctic, north-bluish color palette',
    brightness: Brightness.dark,
    colors: AppThemeColors(
      primary: Color(0xFF88C0D0),
      onPrimary: Color(0xFF2E3440),
      primaryContainer: Color(0xFF5E81AC),
      onPrimaryContainer: Color(0xFFECEFF4),
      secondary: Color(0xFF81A1C1),
      onSecondary: Color(0xFF2E3440),
      secondaryContainer: Color(0xFF4C566A),
      onSecondaryContainer: Color(0xFFECEFF4),
      tertiary: Color(0xFFA3BE8C),
      onTertiary: Color(0xFF2E3440),
      tertiaryContainer: Color(0xFF4C566A),
      onTertiaryContainer: Color(0xFFECEFF4),
      error: Color(0xFFBF616A),
      onError: Color(0xFF2E3440),
      errorContainer: Color(0xFF4C566A),
      onErrorContainer: Color(0xFFBF616A),
      surface: Color(0xFF2E3440),
      onSurface: Color(0xFFECEFF4),
      surfaceContainerHighest: Color(0xFF4C566A),
      surfaceContainerHigh: Color(0xFF434C5E),
      surfaceContainer: Color(0xFF3B4252),
      surfaceContainerLow: Color(0xFF2E3440),
      surfaceContainerLowest: Color(0xFF242933),
      outline: Color(0xFF81A1C1),
      outlineVariant: Color(0xFF4C566A),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFFECEFF4),
      onInverseSurface: Color(0xFF2E3440),
      inversePrimary: Color(0xFF5E81AC),
    ),
  );

  // Solarized Light Theme
  static const AppTheme solarized = AppTheme(
    id: solarizedId,
    name: 'Solarized Light',
    description: 'Precision colors for readability',
    brightness: Brightness.light,
    colors: AppThemeColors(
      primary: Color(0xFF268BD2),
      onPrimary: Color(0xFFFDF6E3),
      primaryContainer: Color(0xFFEEE8D5),
      onPrimaryContainer: Color(0xFF073642),
      secondary: Color(0xFF2AA198),
      onSecondary: Color(0xFFFDF6E3),
      secondaryContainer: Color(0xFFEEE8D5),
      onSecondaryContainer: Color(0xFF073642),
      tertiary: Color(0xFF859900),
      onTertiary: Color(0xFFFDF6E3),
      tertiaryContainer: Color(0xFFEEE8D5),
      onTertiaryContainer: Color(0xFF073642),
      error: Color(0xFFDC322F),
      onError: Color(0xFFFDF6E3),
      errorContainer: Color(0xFFEEE8D5),
      onErrorContainer: Color(0xFFDC322F),
      surface: Color(0xFFFDF6E3),
      onSurface: Color(0xFF657B83),
      surfaceContainerHighest: Color(0xFFEEE8D5),
      surfaceContainerHigh: Color(0xFFF0EAD6),
      surfaceContainer: Color(0xFFF5EFDC),
      surfaceContainerLow: Color(0xFFFAF4E7),
      surfaceContainerLowest: Color(0xFFFDF6E3),
      outline: Color(0xFF93A1A1),
      outlineVariant: Color(0xFFEEE8D5),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFF073642),
      onInverseSurface: Color(0xFFFDF6E3),
      inversePrimary: Color(0xFF268BD2),
    ),
  );

  /// All preset themes (Writer Dark is the default)
  static List<AppTheme> get all =>
      [writerDark, writerLight, codeDark, codeLight, sepia, hotdogStand, nord, solarized];

  /// Get a preset theme by ID
  static AppTheme? getById(String id) {
    try {
      return all.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get the default theme
  static AppTheme get defaultTheme => writerDark;
}
