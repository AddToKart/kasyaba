import 'package:flex_color_scheme/flex_color_scheme.dart';

class AppTheme {
  final light = FlexThemeData.light(
    scheme: FlexScheme.green,
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 7,
    appBarStyle: FlexAppBarStyle.background,
    useMaterial3: true,
    swapLegacyOnMaterial3: true,
  );

  final dark = FlexThemeData.dark(
    scheme: FlexScheme.green,
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 15,
    appBarStyle: FlexAppBarStyle.background,
    useMaterial3: true,
    swapLegacyOnMaterial3: true,
  );
}
