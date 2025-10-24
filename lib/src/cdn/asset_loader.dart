import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'cdn_config.dart';

/// Individual asset loader with retry logic and error handling
///
/// This class handles loading individual CSS/JS assets from CDN
/// with automatic retry logic, exponential backoff, and fallback URLs.
class AssetLoader {
  /// Creates an asset loader with configuration
  const AssetLoader(this.config);

  /// CDN configuration
  final CdnConfig config;

  /// Load a CSS asset from CDN
  Future<String> loadCssAsset(String assetPath) async {
    return _loadAssetWithRetry(assetPath, 'text/css');
  }

  /// Load a JavaScript asset from CDN
  Future<String> loadJsAsset(String assetPath) async {
    return _loadAssetWithRetry(assetPath, 'application/javascript');
  }

  /// Load any asset with retry logic and fallbacks
  Future<String> _loadAssetWithRetry(String assetPath, String expectedContentType) async {
    var attemptCount = 0;
    var lastError = Exception('Unknown error');

    // Primary URL attempts
    while (attemptCount < config.retryAttempts) {
      try {
        final url = config.getAssetUrl(assetPath);
        final response = await _fetchAsset(url, expectedContentType);
        if (response != null) {
          return response;
        }
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
      }

      attemptCount++;
      if (attemptCount < config.retryAttempts) {
        await Future.delayed(config.retryDelay * attemptCount);
      }
    }

    // Fallback URL attempts
    final fallbackUrls = config.getFallbackUrls(assetPath);
    for (final fallbackUrl in fallbackUrls) {
      try {
        final response = await _fetchAsset(fallbackUrl, expectedContentType);
        if (response != null) {
          return response;
        }
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        // Continue to next fallback
      }
    }

    throw CdnLoadingException(
      'Failed to load asset $assetPath after ${config.retryAttempts} attempts and ${fallbackUrls.length} fallbacks',
      lastError,
    );
  }

  /// Fetch asset from specific URL with validation
  Future<String?> _fetchAsset(String url, String expectedContentType) async {
    final client = http.Client();
    try {
      final response = await client.get(
        Uri.parse(url),
        headers: {
          'Accept': expectedContentType,
          'Cache-Control': 'no-cache',
        },
      ).timeout(config.timeout);

      if (response.statusCode == 200) {
        // Validate content type if provided by server
        final contentType = response.headers['content-type'];
        if (contentType != null && !contentType.contains(_getBaseContentType(expectedContentType))) {
          throw CdnLoadingException(
            'Invalid content type: expected $expectedContentType, got $contentType',
          );
        }

        return response.body;
      } else {
        throw CdnLoadingException(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } on TimeoutException {
      throw const CdnLoadingException('Request timeout');
    } catch (e) {
      if (e is CdnLoadingException) {
        rethrow;
      }
      throw CdnLoadingException('Network error', e);
    } finally {
      client.close();
    }
  }

  /// Get base content type for validation
  String _getBaseContentType(String contentType) {
    if (contentType.contains('css')) return 'css';
    if (contentType.contains('javascript')) return 'javascript';
    return contentType;
  }
}

/// Asset loading result with metadata
@immutable
class AssetLoadResult {
  /// Creates an asset load result
  const AssetLoadResult({
    required this.content,
    required this.assetPath,
    required this.loadTime,
    this.url,
    this.contentType,
  });

  /// The loaded asset content
  final String content;

  /// The path of the loaded asset
  final String assetPath;

  /// Time taken to load the asset
  final Duration loadTime;

  /// The URL used to load the asset (may be fallback)
  final String? url;

  /// Content type returned by server
  final String? contentType;

  @override
  String toString() => 'AssetLoadResult(assetPath: $assetPath, loadTime: ${loadTime.inMilliseconds}ms)';
}

/// Progress information for asset loading
@immutable
class LoadingProgress {
  /// Creates loading progress information
  const LoadingProgress({
    required this.loadedAssets,
    required this.totalAssets,
    required this.currentAsset,
    this.error,
  });

  /// Number of assets loaded successfully
  final int loadedAssets;

  /// Total number of assets to load
  final int totalAssets;

  /// Currently loading asset path
  final String? currentAsset;

  /// Error if loading failed
  final CdnLoadingException? error;

  /// Progress as percentage (0.0 to 1.0)
  double get progress => totalAssets > 0 ? loadedAssets / totalAssets : 0.0;

  /// Whether loading is complete
  bool get isComplete => loadedAssets >= totalAssets;

  /// Whether loading has error
  bool get hasError => error != null;

  @override
  String toString() => 'LoadingProgress(${(progress * 100).toStringAsFixed(1)}%, $loadedAssets/$totalAssets)';
}