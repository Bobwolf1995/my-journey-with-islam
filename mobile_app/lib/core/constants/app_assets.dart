class AppAssets {
  const AppAssets._();

  static const String assetsPath = 'assets';
  static const String imagesPath = '$assetsPath/images';
  static const String iconsPath = '$assetsPath/icons';
  static const String animationsPath = '$assetsPath/animations';

  static String image(String fileName) {
    return '$imagesPath/$fileName';
  }

  static String icon(String fileName) {
    return '$iconsPath/$fileName';
  }

  static String animation(String fileName) {
    return '$animationsPath/$fileName';
  }
}
