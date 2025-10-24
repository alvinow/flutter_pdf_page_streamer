import 'package:meta/meta.dart';
import '../cdn/cdn_config.dart';

/// Configuration for page-based PDF streaming
///
/// This class contains all the configuration needed to stream PDFs
/// using the page-based loading approach via the backend's :id/page endpoints.
@immutable
class PdfConfig {
  /// Creates a PDF streaming configuration
  const PdfConfig({
    required this.pdfId,
    required this.backendUrl,
    required this.cdnConfig,
    this.initialPage = 1,
    this.initialZoom = 1.0,
    this.enablePagePreloading = true,
    this.preloadBuffer = 2,
    this.maxConcurrentPageLoads = 3,
    this.cacheSize = 50,
    this.enableZoom = true,
    this.enableNavigation = true,
    this.enableSearch = false,
    this.debugMode = false,
  });

  /// Unique identifier for the PDF document
  final String pdfId;

  /// Base URL of the PDF Page Streamer backend
  /// Should point to the backend that serves :id/page endpoints
  final String backendUrl;

  /// CDN configuration for loading PDF viewer assets
  final CdnConfig cdnConfig;

  /// Initial page to display (1-indexed)
  final int initialPage;

  /// Initial zoom level (1.0 = 100%)
  final double initialZoom;

  /// Whether to enable page preloading for smoother navigation
  final bool enablePagePreloading;

  /// Number of pages to preload around current page
  final int preloadBuffer;

  /// Maximum concurrent page load requests
  final int maxConcurrentPageLoads;

  /// Maximum number of pages to keep in cache
  final int cacheSize;

  /// Whether zoom controls are enabled
  final bool enableZoom;

  /// Whether page navigation is enabled
  final bool enableNavigation;

  /// Whether search functionality is enabled (future feature)
  final bool enableSearch;

  /// Whether to enable debug mode with additional logging
  final bool debugMode;

  /// Get the backend URL for loading a specific page
  String getPageUrl(int pageNumber) {
    return '$backendUrl/$pdfId/page/$pageNumber';
  }

  /// Get the backend URL for PDF metadata
  String getMetadataUrl() {
    return '$backendUrl/$pdfId/info';
  }

  /// Create a development configuration with local backend
  factory PdfConfig.development({
    required String pdfId,
    String backendUrl = 'http://localhost:3000/api/pdf',
    String cdnUrl = 'http://localhost:3002',
    int initialPage = 1,
    double initialZoom = 1.0,
  }) {
    return PdfConfig(
      pdfId: pdfId,
      backendUrl: backendUrl,
      cdnConfig: CdnConfig.development(baseUrl: cdnUrl),
      initialPage: initialPage,
      initialZoom: initialZoom,
      debugMode: true,
    );
  }

  /// Create a production configuration with CDN and optimized settings
  factory PdfConfig.production({
    required String pdfId,
    required String backendUrl,
    required String cdnUrl,
    List<String> fallbackCdnUrls = const [],
    int initialPage = 1,
    double initialZoom = 1.0,
    bool enablePagePreloading = true,
    int preloadBuffer = 3,
  }) {
    return PdfConfig(
      pdfId: pdfId,
      backendUrl: backendUrl,
      cdnConfig: CdnConfig.production(
        cdnUrl: cdnUrl,
        fallbackUrls: fallbackCdnUrls,
      ),
      initialPage: initialPage,
      initialZoom: initialZoom,
      enablePagePreloading: enablePagePreloading,
      preloadBuffer: preloadBuffer,
      maxConcurrentPageLoads: 5,
      cacheSize: 100,
      debugMode: false,
    );
  }

  /// Copy with method for configuration updates
  PdfConfig copyWith({
    String? pdfId,
    String? backendUrl,
    CdnConfig? cdnConfig,
    int? initialPage,
    double? initialZoom,
    bool? enablePagePreloading,
    int? preloadBuffer,
    int? maxConcurrentPageLoads,
    int? cacheSize,
    bool? enableZoom,
    bool? enableNavigation,
    bool? enableSearch,
    bool? debugMode,
  }) {
    return PdfConfig(
      pdfId: pdfId ?? this.pdfId,
      backendUrl: backendUrl ?? this.backendUrl,
      cdnConfig: cdnConfig ?? this.cdnConfig,
      initialPage: initialPage ?? this.initialPage,
      initialZoom: initialZoom ?? this.initialZoom,
      enablePagePreloading: enablePagePreloading ?? this.enablePagePreloading,
      preloadBuffer: preloadBuffer ?? this.preloadBuffer,
      maxConcurrentPageLoads: maxConcurrentPageLoads ?? this.maxConcurrentPageLoads,
      cacheSize: cacheSize ?? this.cacheSize,
      enableZoom: enableZoom ?? this.enableZoom,
      enableNavigation: enableNavigation ?? this.enableNavigation,
      enableSearch: enableSearch ?? this.enableSearch,
      debugMode: debugMode ?? this.debugMode,
    );
  }

  @override
  String toString() => 'PdfConfig(pdfId: $pdfId, backendUrl: $backendUrl)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfConfig &&
          runtimeType == other.runtimeType &&
          pdfId == other.pdfId &&
          backendUrl == other.backendUrl &&
          initialPage == other.initialPage &&
          initialZoom == other.initialZoom;

  @override
  int get hashCode =>
      pdfId.hashCode ^
      backendUrl.hashCode ^
      initialPage.hashCode ^
      initialZoom.hashCode;
}

/// Validation result for PDF configuration
@immutable
class PdfConfigValidation {
  /// Creates a configuration validation result
  const PdfConfigValidation({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });

  /// Whether the configuration is valid
  final bool isValid;

  /// List of validation errors
  final List<String> errors;

  /// List of validation warnings
  final List<String> warnings;

  /// Create a valid result
  const PdfConfigValidation.valid() : this(isValid: true);

  /// Create an invalid result with errors
  const PdfConfigValidation.invalid(List<String> errors)
      : this(isValid: false, errors: errors);

  @override
  String toString() => isValid
      ? 'PdfConfigValidation(valid)'
      : 'PdfConfigValidation(invalid: ${errors.join(', ')})';
}

/// PDF configuration validator
class PdfConfigValidator {
  /// Validate a PDF configuration
  static PdfConfigValidation validate(PdfConfig config) {
    final errors = <String>[];
    final warnings = <String>[];

    // Validate PDF ID
    if (config.pdfId.isEmpty) {
      errors.add('PDF ID cannot be empty');
    }

    // Validate backend URL
    if (config.backendUrl.isEmpty) {
      errors.add('Backend URL cannot be empty');
    } else {
      final uri = Uri.tryParse(config.backendUrl);
      if (uri == null || !uri.hasAbsolutePath) {
        errors.add('Backend URL must be a valid absolute URL');
      }
    }

    // Validate page settings
    if (config.initialPage < 1) {
      errors.add('Initial page must be 1 or greater');
    }

    if (config.initialZoom <= 0) {
      errors.add('Initial zoom must be greater than 0');
    } else if (config.initialZoom < 0.1 || config.initialZoom > 10.0) {
      warnings.add('Initial zoom outside recommended range (0.1 - 10.0)');
    }

    // Validate performance settings
    if (config.preloadBuffer < 0) {
      errors.add('Preload buffer cannot be negative');
    } else if (config.preloadBuffer > 10) {
      warnings.add('Large preload buffer may impact performance');
    }

    if (config.maxConcurrentPageLoads < 1) {
      errors.add('Max concurrent page loads must be at least 1');
    } else if (config.maxConcurrentPageLoads > 10) {
      warnings.add('High concurrent page loads may overwhelm backend');
    }

    if (config.cacheSize < 1) {
      errors.add('Cache size must be at least 1');
    }

    return PdfConfigValidation(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }
}