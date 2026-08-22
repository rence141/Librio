/// Google OAuth 2.0 Configuration for Librio
///
/// Get your Client IDs from Google Cloud Console:
/// https://console.cloud.google.com/apis/credentials
class GoogleConfig {
  /// Debug Client ID (for development/testing)
  /// Replace with your actual debug Client ID from Google Cloud Console
  static const String debugClientId =
      'YOUR_DEBUG_CLIENT_ID.apps.googleusercontent.com';

  /// Release Client ID (for production/Google Play)
  /// Replace with your actual release Client ID from Google Cloud Console
  static const String releaseClientId =
      'YOUR_RELEASE_CLIENT_ID.apps.googleusercontent.com';

  /// Web Client ID (for backend verification)
  /// Used to verify ID tokens on your backend server
  static const String webClientId =
      'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com';

  /// Get the appropriate Client ID based on build type
  static String getClientId(bool isProduction) {
    return isProduction ? releaseClientId : debugClientId;
  }

  /// OAuth scopes requested from Google
  static const List<String> scopes = [
    'email',
    'profile',
  ];

  /// Your debug keystore SHA-1 fingerprint
  /// Used when creating Android OAuth credentials
  static const String debugSha1 =
      '42:13:1B:8F:CB:45:94:3F:B2:3E:D4:B1:39:23:2C:C3:0F:CD:65:C0';

  /// Your release keystore SHA-1 fingerprint
  /// Generate with: keytool -list -v -keystore librio-release-key.jks
  static const String releaseSha1 = 'YOUR_RELEASE_SHA1_HERE';
}
