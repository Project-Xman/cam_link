import "package:flutter/material.dart";

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff096e00),
      surfaceTint: Color(0xff096e00),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff62ca4d),
      onPrimaryContainer: Color(0xff023000),
      secondary: Color(0xff3e6932),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xffc0f2ad),
      onSecondaryContainer: Color(0xff28521f),
      tertiary: Color(0xff00687b),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff29c4e4),
      onTertiaryContainer: Color(0xff002d36),
      error: Color(0xffba1a1a),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffffdad6),
      onErrorContainer: Color(0xff410002),
      surface: Color(0xfff5fced),
      onSurface: Color(0xff171d14),
      onSurfaceVariant: Color(0xff3f4a3a),
      outline: Color(0xff6f7a69),
      outlineVariant: Color(0xffbecab6),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2c3229),
      inversePrimary: Color(0xff75de5e),
      primaryFixed: Color(0xff91fb77),
      onPrimaryFixed: Color(0xff012200),
      primaryFixedDim: Color(0xff75de5e),
      onPrimaryFixedVariant: Color(0xff055300),
      secondaryFixed: Color(0xffbef0ac),
      onSecondaryFixed: Color(0xff012200),
      secondaryFixedDim: Color(0xffa3d492),
      onSecondaryFixedVariant: Color(0xff26501d),
      tertiaryFixed: Color(0xffaeecff),
      onTertiaryFixed: Color(0xff001f26),
      tertiaryFixedDim: Color(0xff48d7f8),
      onTertiaryFixedVariant: Color(0xff004e5d),
      surfaceDim: Color(0xffd6dcce),
      surfaceBright: Color(0xfff5fced),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xffeff6e7),
      surfaceContainer: Color(0xffeaf0e1),
      surfaceContainerHigh: Color(0xffe4eadc),
      surfaceContainerHighest: Color(0xffdee5d6),
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  static ColorScheme lightMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff054f00),
      surfaceTint: Color(0xff096e00),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff1a870c),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff224c19),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff537f46),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff004a58),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff008097),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff8c0009),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffda342e),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfff5fced),
      onSurface: Color(0xff171d14),
      onSurfaceVariant: Color(0xff3b4636),
      outline: Color(0xff576251),
      outlineVariant: Color(0xff737e6c),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2c3229),
      inversePrimary: Color(0xff75de5e),
      primaryFixed: Color(0xff1a870c),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff096b00),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff537f46),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff3b6630),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff008097),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff006578),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffd6dcce),
      surfaceBright: Color(0xfff5fced),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xffeff6e7),
      surfaceContainer: Color(0xffeaf0e1),
      surfaceContainerHigh: Color(0xffe4eadc),
      surfaceContainerHighest: Color(0xffdee5d6),
    );
  }

  ThemeData lightMediumContrast() {
    return theme(lightMediumContrastScheme());
  }

  static ColorScheme lightHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff012900),
      surfaceTint: Color(0xff096e00),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff054f00),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff012900),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff224c19),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff00262f),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff004a58),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff4e0002),
      onError: Color(0xffffffff),
      errorContainer: Color(0xff8c0009),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfff5fced),
      onSurface: Color(0xff000000),
      onSurfaceVariant: Color(0xff1d2719),
      outline: Color(0xff3b4636),
      outlineVariant: Color(0xff3b4636),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2c3229),
      inversePrimary: Color(0xffb5ff9e),
      primaryFixed: Color(0xff054f00),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff023500),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff224c19),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff0a3504),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff004a58),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff00323c),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffd6dcce),
      surfaceBright: Color(0xfff5fced),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xffeff6e7),
      surfaceContainer: Color(0xffeaf0e1),
      surfaceContainerHigh: Color(0xffe4eadc),
      surfaceContainerHighest: Color(0xffdee5d6),
    );
  }

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme());
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xff78e161),
      surfaceTint: Color(0xff75de5e),
      onPrimary: Color(0xff033900),
      primaryContainer: Color(0xff4fb63c),
      onPrimaryContainer: Color(0xff011900),
      secondary: Color(0xffa3d492),
      onSecondary: Color(0xff0e3907),
      secondaryContainer: Color(0xff1e4816),
      onSecondaryContainer: Color(0xffb0e19e),
      tertiary: Color(0xff4cd9fa),
      onTertiary: Color(0xff003641),
      tertiaryContainer: Color(0xff00afce),
      onTertiaryContainer: Color(0xff00171d),
      error: Color(0xffffb4ab),
      onError: Color(0xff690005),
      errorContainer: Color(0xff93000a),
      onErrorContainer: Color(0xffffdad6),
      surface: Color(0xff0f150d),
      onSurface: Color(0xffdee5d6),
      onSurfaceVariant: Color(0xffbecab6),
      outline: Color(0xff899481),
      outlineVariant: Color(0xff3f4a3a),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffdee5d6),
      inversePrimary: Color(0xff096e00),
      primaryFixed: Color(0xff91fb77),
      onPrimaryFixed: Color(0xff012200),
      primaryFixedDim: Color(0xff75de5e),
      onPrimaryFixedVariant: Color(0xff055300),
      secondaryFixed: Color(0xffbef0ac),
      onSecondaryFixed: Color(0xff012200),
      secondaryFixedDim: Color(0xffa3d492),
      onSecondaryFixedVariant: Color(0xff26501d),
      tertiaryFixed: Color(0xffaeecff),
      onTertiaryFixed: Color(0xff001f26),
      tertiaryFixedDim: Color(0xff48d7f8),
      onTertiaryFixedVariant: Color(0xff004e5d),
      surfaceDim: Color(0xff0f150d),
      surfaceBright: Color(0xff353b31),
      surfaceContainerLowest: Color(0xff0a1008),
      surfaceContainerLow: Color(0xff171d14),
      surfaceContainer: Color(0xff1b2118),
      surfaceContainerHigh: Color(0xff252c22),
      surfaceContainerHighest: Color(0xff30372d),
    );
  }

  ThemeData dark() {
    return theme(darkScheme());
  }

  static ColorScheme darkMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xff79e262),
      surfaceTint: Color(0xff75de5e),
      onPrimary: Color(0xff011c00),
      primaryContainer: Color(0xff4fb63c),
      onPrimaryContainer: Color(0xff000000),
      secondary: Color(0xffa7d896),
      onSecondary: Color(0xff011c00),
      secondaryContainer: Color(0xff6f9c60),
      onSecondaryContainer: Color(0xff000000),
      tertiary: Color(0xff4edbfc),
      onTertiary: Color(0xff001920),
      tertiaryContainer: Color(0xff00afce),
      onTertiaryContainer: Color(0xff000000),
      error: Color(0xffffbab1),
      onError: Color(0xff370001),
      errorContainer: Color(0xffff5449),
      onErrorContainer: Color(0xff000000),
      surface: Color(0xff0f150d),
      onSurface: Color(0xfff7fdee),
      onSurfaceVariant: Color(0xffc3ceba),
      outline: Color(0xff9ba693),
      outlineVariant: Color(0xff7b8774),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffdee5d6),
      inversePrimary: Color(0xff065400),
      primaryFixed: Color(0xff91fb77),
      onPrimaryFixed: Color(0xff011600),
      primaryFixedDim: Color(0xff75de5e),
      onPrimaryFixedVariant: Color(0xff034000),
      secondaryFixed: Color(0xffbef0ac),
      onSecondaryFixed: Color(0xff011600),
      secondaryFixedDim: Color(0xffa3d492),
      onSecondaryFixedVariant: Color(0xff153f0d),
      tertiaryFixed: Color(0xffaeecff),
      onTertiaryFixed: Color(0xff001419),
      tertiaryFixedDim: Color(0xff48d7f8),
      onTertiaryFixedVariant: Color(0xff003c48),
      surfaceDim: Color(0xff0f150d),
      surfaceBright: Color(0xff353b31),
      surfaceContainerLowest: Color(0xff0a1008),
      surfaceContainerLow: Color(0xff171d14),
      surfaceContainer: Color(0xff1b2118),
      surfaceContainerHigh: Color(0xff252c22),
      surfaceContainerHighest: Color(0xff30372d),
    );
  }

  ThemeData darkMediumContrast() {
    return theme(darkMediumContrastScheme());
  }

  static ColorScheme darkHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xfff2ffe7),
      surfaceTint: Color(0xff75de5e),
      onPrimary: Color(0xff000000),
      primaryContainer: Color(0xff79e262),
      onPrimaryContainer: Color(0xff000000),
      secondary: Color(0xfff2ffe7),
      onSecondary: Color(0xff000000),
      secondaryContainer: Color(0xffa7d896),
      onSecondaryContainer: Color(0xff000000),
      tertiary: Color(0xfff4fcff),
      onTertiary: Color(0xff000000),
      tertiaryContainer: Color(0xff4edbfc),
      onTertiaryContainer: Color(0xff000000),
      error: Color(0xfffff9f9),
      onError: Color(0xff000000),
      errorContainer: Color(0xffffbab1),
      onErrorContainer: Color(0xff000000),
      surface: Color(0xff0f150d),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xfff3ffe9),
      outline: Color(0xffc3ceba),
      outlineVariant: Color(0xffc3ceba),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffdee5d6),
      inversePrimary: Color(0xff023200),
      primaryFixed: Color(0xff97ff7e),
      onPrimaryFixed: Color(0xff000000),
      primaryFixedDim: Color(0xff79e262),
      onPrimaryFixedVariant: Color(0xff011c00),
      secondaryFixed: Color(0xffc2f5b0),
      onSecondaryFixed: Color(0xff000000),
      secondaryFixedDim: Color(0xffa7d896),
      onSecondaryFixedVariant: Color(0xff011c00),
      tertiaryFixed: Color(0xffbbefff),
      onTertiaryFixed: Color(0xff000000),
      tertiaryFixedDim: Color(0xff4edbfc),
      onTertiaryFixedVariant: Color(0xff001920),
      surfaceDim: Color(0xff0f150d),
      surfaceBright: Color(0xff353b31),
      surfaceContainerLowest: Color(0xff0a1008),
      surfaceContainerLow: Color(0xff171d14),
      surfaceContainer: Color(0xff1b2118),
      surfaceContainerHigh: Color(0xff252c22),
      surfaceContainerHighest: Color(0xff30372d),
    );
  }

  ThemeData darkHighContrast() {
    return theme(darkHighContrastScheme());
  }

  ThemeData theme(ColorScheme colorScheme) => ThemeData(
        useMaterial3: true,
        brightness: colorScheme.brightness,
        colorScheme: colorScheme,
        textTheme: textTheme.apply(
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
        ),
        scaffoldBackgroundColor: colorScheme.surface,
        canvasColor: colorScheme.surface,
      );

  List<ExtendedColor> get extendedColors => [];
}

class ExtendedColor {
  final Color seed, value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;
  final ColorFamily dark;
  final ColorFamily darkHighContrast;
  final ColorFamily darkMediumContrast;

  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
    required this.dark,
    required this.darkHighContrast,
    required this.darkMediumContrast,
  });
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
}
