/// Application version and build information for Librio.
/// 
/// This file is the single source of truth for version information.
/// Update this file when releasing new versions.
library version;

class AppVersion {
  /// Semantic versioning: MAJOR.MINOR.PATCH
  /// 
  /// MAJOR: Breaking changes, significant feature releases
  /// MINOR: New features, backward compatible
  /// PATCH: Bug fixes, minor improvements
  static const String version = '1.0.0';

  /// Build number for internal tracking
  /// Incremented with each build/release
  static const int buildNumber = 1;

  /// Full version string with build number
  static String get fullVersion => '$version+$buildNumber';

  /// Application name
  static const String appName = 'Librio';

  /// Application description
  static const String appDescription = 'Offline-first AI academic tutor for mobile';

  /// Release channel (alpha, beta, stable)
  static const String releaseChannel = 'stable';

  /// Version info for display
  static String get displayVersion {
    if (releaseChannel == 'stable') {
      return 'v$version';
    }
    return 'v$version-$releaseChannel';
  }

  /// Check if this is a development build
  static bool get isDevelopment => releaseChannel != 'stable';

  /// Check if this is a beta build
  static bool get isBeta => releaseChannel == 'beta';

  /// Check if this is an alpha build
  static bool get isAlpha => releaseChannel == 'alpha';
}
