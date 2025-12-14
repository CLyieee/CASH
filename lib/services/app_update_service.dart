import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:open_filex/open_filex.dart';

class AppUpdateService {
  // MediaFire link - Update this with your MediaFire file link
  // To get direct download: Right-click MediaFire download button → Copy link address
  // Or use: https://www.mediafire.com/file/54tpdypuidawbwk/app-arm64-v8a-release.apk/file
  static const String _mediaFireLink =
      'https://www.mediafire.com/file/54tpdypuidawbwk/app-arm64-v8a-release.apk/file';

  // Alternative: Use direct download URL if you have it
  // MediaFire direct downloads usually look like: https://download[number].mediafire.com/...
  // You can get this by right-clicking the download button and copying the link

  /// Get current app version
  static Future<String> getCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Get current build number
  static Future<int> getCurrentBuildNumber() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return int.tryParse(packageInfo.buildNumber) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Check if update is available
  /// In a real scenario, you'd check against a server API
  /// For now, we'll always show update option
  static Future<bool> checkForUpdate() async {
    // TODO: Implement version checking against your server/API
    // For now, always return true to allow manual updates
    return true;
  }

  /// Request install permission (Android 8.0+)
  static Future<bool> requestInstallPermission() async {
    if (Platform.isAndroid) {
      if (await Permission.requestInstallPackages.isGranted) {
        return true;
      }

      final status = await Permission.requestInstallPackages.request();
      return status.isGranted;
    }
    return true;
  }

  /// Download APK from MediaFire
  static Future<String?> downloadAPK({
    required Function(int received, int total) onProgress,
  }) async {
    try {
      // Try to get direct download URL first
      String? downloadUrl = await getDirectDownloadUrl();

      // If direct URL not found, try the MediaFire link with redirect following
      downloadUrl ??= _mediaFireLink;

      // Create a client that follows redirects
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(downloadUrl));
      final response = await client.send(request);

      // Follow redirects
      var finalResponse = response;
      int redirectCount = 0;
      while (finalResponse.statusCode == 301 ||
          finalResponse.statusCode == 302 ||
          finalResponse.statusCode == 307 ||
          finalResponse.statusCode == 308) {
        if (redirectCount++ > 5) break; // Prevent infinite redirects
        final location = finalResponse.headers['location'];
        if (location == null) break;
        final redirectRequest = http.Request('GET', Uri.parse(location));
        finalResponse = await client.send(redirectRequest);
      }

      if (finalResponse.statusCode != 200) {
        throw Exception('Failed to download: ${finalResponse.statusCode}');
      }

      downloadUrl = finalResponse.request?.url.toString() ?? downloadUrl;

      // Get download directory
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        throw Exception('Cannot access storage directory');
      }

      final filePath = '${directory.path}/app_update.apk';
      final file = File(filePath);

      // Download with progress
      final totalBytes = finalResponse.contentLength ?? 0;
      final bytes = <int>[];
      int receivedBytes = 0;

      await for (final chunk in finalResponse.stream) {
        bytes.addAll(chunk);
        receivedBytes += chunk.length;
        onProgress(receivedBytes, totalBytes);
      }

      client.close();

      await file.writeAsBytes(bytes);
      return filePath;
    } catch (e) {
      debugPrint('Download error: $e');
      return null;
    }
  }

  /// Install APK file
  static Future<bool> installAPK(String filePath) async {
    try {
      // Request permission first
      final hasPermission = await requestInstallPermission();
      if (!hasPermission) {
        throw Exception('Install permission denied');
      }

      // Open the APK file for installation
      final result = await OpenFilex.open(filePath);
      return result.type == ResultType.done;
    } catch (e) {
      debugPrint('Install error: $e');
      return false;
    }
  }

  /// Get MediaFire direct download URL
  /// This is a helper to extract the actual download URL from MediaFire
  static Future<String?> getDirectDownloadUrl() async {
    try {
      final response = await http.get(Uri.parse(_mediaFireLink));

      // MediaFire redirects, so follow redirects
      if (response.statusCode == 302 || response.statusCode == 301) {
        return response.headers['location'];
      }

      // Try to extract from page content
      final body = response.body;
      // MediaFire uses various patterns, try common ones
      final patterns = [
        RegExp(r'https://download[0-9]+\.mediafire\.com/[^"\s]+'),
        RegExp(r'href="(https://[^"]*mediafire[^"]*download[^"]*)"'),
        RegExp(r'data-downloadurl="([^"]+)"'),
      ];

      for (var pattern in patterns) {
        final match = pattern.firstMatch(body);
        if (match != null) {
          return match.group(0) ?? match.group(1);
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error getting direct URL: $e');
      return null;
    }
  }
}
