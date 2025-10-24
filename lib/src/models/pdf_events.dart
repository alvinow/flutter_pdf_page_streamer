import 'package:meta/meta.dart';

/// Page-specific events from the PDF viewer
///
/// These events are generated during page-based PDF streaming
/// and provide real-time updates about the viewer state.

/// Base class for all PDF viewer events
@immutable
abstract class PdfEvent {
  /// Creates a PDF event with timestamp
  const PdfEvent(this.timestamp);

  /// When the event occurred
  final DateTime timestamp;
}

/// Event fired when a PDF document is successfully loaded
@immutable
class PdfLoadedEvent extends PdfEvent {
  /// Creates a PDF loaded event
  PdfLoadedEvent({
    required this.pdfId,
    required this.pageCount,
    required this.title,
    DateTime? timestamp,
  }) : super(timestamp ?? _getCurrentTimestamp());

  /// The unique identifier of the loaded PDF
  final String pdfId;

  /// The total number of pages in the PDF
  final int pageCount;

  /// The title of the PDF document
  final String? title;

  @override
  String toString() => 'PdfLoadedEvent(pdfId: $pdfId, pageCount: $pageCount)';
}

/// Event fired when the current page changes during navigation
@immutable
class PageChangedEvent extends PdfEvent {
  /// Creates a page changed event
  PageChangedEvent({
    required this.currentPage,
    required this.totalPages,
    this.previousPage,
    DateTime? timestamp,
  }) : super(timestamp ?? _getCurrentTimestamp());

  /// The current page number (1-indexed)
  final int currentPage;

  /// The total number of pages
  final int totalPages;

  /// The previous page number (may be null for initial load)
  final int? previousPage;

  /// Progress as percentage (0.0 to 1.0)
  double get progress => totalPages > 0 ? currentPage / totalPages : 0.0;

  /// Whether this is the first page
  bool get isFirstPage => currentPage == 1;

  /// Whether this is the last page
  bool get isLastPage => currentPage == totalPages;

  @override
  String toString() => 'PageChangedEvent(page: $currentPage/$totalPages)';
}

/// Event fired when the zoom level changes
@immutable
class ZoomChangedEvent extends PdfEvent {
  /// Creates a zoom changed event
  ZoomChangedEvent({
    required this.zoomLevel,
    this.previousZoom,
    DateTime? timestamp,
  }) : super(timestamp ?? _getCurrentTimestamp());

  /// The new zoom level (1.0 = 100%)
  final double zoomLevel;

  /// The previous zoom level
  final double? previousZoom;

  /// Zoom percentage as integer (e.g., 150 for 150%)
  int get zoomPercentage => (zoomLevel * 100).round();

  @override
  String toString() => 'ZoomChangedEvent(zoom: $zoomPercentage%)';
}

/// Event fired when the loading state changes (for individual pages)
@immutable
class LoadingStateChangedEvent extends PdfEvent {
  /// Creates a loading state changed event
  LoadingStateChangedEvent({
    required this.isLoading,
    required this.progress,
    this.pageNumber,
    this.operation,
    DateTime? timestamp,
  }) : super(timestamp ?? _getCurrentTimestamp());

  /// Whether the PDF viewer is currently loading
  final bool isLoading;

  /// The loading progress (0.0 to 1.0)
  final double progress;

  /// The page number being loaded (if applicable)
  final int? pageNumber;

  /// Description of the current operation
  final String? operation;

  /// Progress as percentage
  int get progressPercentage => (progress * 100).round();

  @override
  String toString() => 'LoadingStateChangedEvent(loading: $isLoading, progress: $progressPercentage%)';
}

/// Event fired when an error occurs in the PDF viewer
@immutable
class PdfErrorEvent extends PdfEvent {
  /// Creates a PDF error event
  PdfErrorEvent({
    required this.message,
    required this.code,
    this.pageNumber,
    this.recoverable = false,
    DateTime? timestamp,
  }) : super(timestamp ?? _getCurrentTimestamp());

  /// The error message
  final String message;

  /// The error code for categorization
  final String code;

  /// The page number where error occurred (if applicable)
  final int? pageNumber;

  /// Whether the error is recoverable
  final bool recoverable;

  @override
  String toString() => 'PdfErrorEvent(code: $code, message: $message)';
}

/// Event fired when a page is successfully loaded (page-streaming specific)
@immutable
class PageLoadedEvent extends PdfEvent {
  /// Creates a page loaded event
  PageLoadedEvent({
    required this.pageNumber,
    required this.loadTime,
    this.fromCache = false,
    DateTime? timestamp,
  }) : super(timestamp ?? _getCurrentTimestamp());

  /// The page number that was loaded
  final int pageNumber;

  /// Time taken to load the page
  final Duration loadTime;

  /// Whether the page was loaded from cache
  final bool fromCache;

  @override
  String toString() => 'PageLoadedEvent(page: $pageNumber, loadTime: ${loadTime.inMilliseconds}ms, cached: $fromCache)';
}

/// Event fired when page preloading occurs
@immutable
class PagePreloadEvent extends PdfEvent {
  /// Creates a page preload event
  PagePreloadEvent({
    required this.pageNumber,
    required this.status,
    DateTime? timestamp,
  }) : super(timestamp ?? _getCurrentTimestamp());

  /// The page number being preloaded
  final int pageNumber;

  /// The preload status
  final PagePreloadStatus status;

  @override
  String toString() => 'PagePreloadEvent(page: $pageNumber, status: $status)';
}

/// Status of page preloading
enum PagePreloadStatus {
  /// Preload started
  started,

  /// Preload completed successfully
  completed,

  /// Preload failed
  failed,

  /// Preload cancelled
  cancelled,
}

/// Get current timestamp for events
DateTime _getCurrentTimestamp() => DateTime.now();

/// Callback function signatures for PDF events

/// Callback for when PDF is loaded
typedef PdfLoadedCallback = void Function(PdfLoadedEvent event);

/// Callback for when page changes
typedef PageChangedCallback = void Function(PageChangedEvent event);

/// Callback for when zoom changes
typedef ZoomChangedCallback = void Function(ZoomChangedEvent event);

/// Callback for when loading state changes
typedef LoadingStateChangedCallback = void Function(LoadingStateChangedEvent event);

/// Callback for when errors occur
typedef PdfErrorCallback = void Function(PdfErrorEvent event);

/// Callback for when individual pages load
typedef PageLoadedCallback = void Function(PageLoadedEvent event);

/// Callback for page preloading events
typedef PagePreloadCallback = void Function(PagePreloadEvent event);

/// Comprehensive event listener configuration
@immutable
class PdfEventListeners {
  /// Creates PDF event listeners configuration
  const PdfEventListeners({
    this.onPdfLoaded,
    this.onPageChanged,
    this.onZoomChanged,
    this.onLoadingStateChanged,
    this.onError,
    this.onPageLoaded,
    this.onPagePreload,
  });

  /// Called when PDF document is loaded
  final PdfLoadedCallback? onPdfLoaded;

  /// Called when current page changes
  final PageChangedCallback? onPageChanged;

  /// Called when zoom level changes
  final ZoomChangedCallback? onZoomChanged;

  /// Called when loading state changes
  final LoadingStateChangedCallback? onLoadingStateChanged;

  /// Called when errors occur
  final PdfErrorCallback? onError;

  /// Called when individual pages are loaded
  final PageLoadedCallback? onPageLoaded;

  /// Called when page preloading occurs
  final PagePreloadCallback? onPagePreload;

  /// Whether any listeners are configured
  bool get hasListeners =>
      onPdfLoaded != null ||
      onPageChanged != null ||
      onZoomChanged != null ||
      onLoadingStateChanged != null ||
      onError != null ||
      onPageLoaded != null ||
      onPagePreload != null;
}