import 'package:meta/meta.dart';

/// Configuration for CDN asset loading and management
///
/// This class manages the configuration for loading PDF viewer assets
/// from CDN, including versioning, fallbacks, and URL management.
@immutable
class CdnConfig {
  /// Creates a CDN configuration
  const CdnConfig({
    required this.baseUrl,
    this.version = 'latest',
    this.fallbackUrls = const [],
    this.timeout = const Duration(seconds: 30),
    this.retryAttempts = 3,
    this.retryDelay = const Duration(seconds: 1),
  });

  /// The base CDN URL where PDF viewer assets are hosted
  final String baseUrl;

  /// The version of the PDF viewer assets to load
  final String version;

  /// Fallback CDN URLs to try if primary fails
  final List<String> fallbackUrls;

  /// Timeout for individual asset loading
  final Duration timeout;

  /// Number of retry attempts for failed asset loads
  final int retryAttempts;

  /// Delay between retry attempts
  final Duration retryDelay;

  /// Get the full URL for a specific asset
  String getAssetUrl(String assetPath) {
    // For local assets and development, load assets directly without version path
    if (version == 'local' || version == 'dev') {
      return '$baseUrl/$assetPath';
    }
    return '$baseUrl/$version/$assetPath';
  }

  /// Get fallback URLs for a specific asset
  List<String> getFallbackUrls(String assetPath) {
    if (version == 'local' || version == 'dev') {
      return fallbackUrls.map((url) => '$url/$assetPath').toList();
    }
    return fallbackUrls.map((url) => '$url/$version/$assetPath').toList();
  }

  /// Create a development configuration using local assets
  factory CdnConfig.development({
    String baseUrl = 'http://localhost:3002',
    Duration timeout = const Duration(seconds: 10),
  }) {
    return CdnConfig(
      baseUrl: baseUrl,
      version: 'dev',
      timeout: timeout,
      retryAttempts: 1,
    );
  }

  /// Create a production configuration with CDN and fallbacks
  factory CdnConfig.production({
    required String cdnUrl,
    List<String> fallbackUrls = const [],
    String version = 'latest',
  }) {
    return CdnConfig(
      baseUrl: cdnUrl,
      version: version,
      fallbackUrls: fallbackUrls,
      timeout: const Duration(seconds: 30),
      retryAttempts: 3,
      retryDelay: const Duration(seconds: 2),
    );
  }

  /// Create a configuration for local assets (same directory as index.html)
  /// This is useful when you want to bundle the PDF viewer assets with your Flutter web app
  factory CdnConfig.local({
    String assetsPath = 'assets',
    String version = 'local',
  }) {
    return CdnConfig(
      baseUrl: assetsPath,
      version: version,
      fallbackUrls: const [],
      timeout: const Duration(seconds: 10),
      retryAttempts: 1,
      retryDelay: const Duration(seconds: 1),
    );
  }

  @override
  String toString() => 'CdnConfig(baseUrl: $baseUrl, version: $version)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CdnConfig &&
          runtimeType == other.runtimeType &&
          baseUrl == other.baseUrl &&
          version == other.version;

  @override
  int get hashCode => baseUrl.hashCode ^ version.hashCode;
}

/// State of CDN asset loading
enum LoadingState {
  /// Initial state, not started loading
  initial,

  /// Currently loading assets
  loading,

  /// Assets loaded successfully
  loaded,

  /// Loading failed with error
  error,

  /// Loading timed out
  timeout,
}

/// Exception thrown during CDN asset loading
@immutable
class CdnLoadingException implements Exception {
  /// Creates a CDN loading exception
  const CdnLoadingException(this.message, [this.cause]);

  /// The error message
  final String message;

  /// The underlying cause (optional)
  final Object? cause;

  @override
  String toString() => 'CdnLoadingException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}