import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class NavigationService {
  /// Opens Google Maps for turn-by-turn navigation from the current location
  /// to the specified destination coordinates.
  static Future<bool> navigateTo(double latitude, double longitude) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving',
    );
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to launching in standard web browser/webview
        return await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NavigationService] Failed to launch navigation URL: $e');
      }
      return false;
    }
  }
}
