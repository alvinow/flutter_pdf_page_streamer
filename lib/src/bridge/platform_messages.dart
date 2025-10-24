import 'package:meta/meta.dart';

/// Platform channel message types for PDF page streaming operations
///
/// These classes define the message structure for communication between
/// Flutter and the underlying PDF viewer JavaScript implementation.

/// Base class for all platform messages
@immutable
abstract class PlatformMessage {
  /// Creates a platform message
  const PlatformMessage(this.type);

  /// The message type identifier
  final String type;

  /// Convert the message to a map for platform channel transmission
  Map<String, dynamic> toMap();
}

/// Message for loading a PDF document
@immutable
class LoadPdfMessage extends PlatformMessage {
  /// Creates a load PDF message
  const LoadPdfMessage({
    required this.pdfId,
    required this.backendUrl,
    required this.cdnUrl,
  }) : super('LOAD_PDF');

  /// The unique identifier for the PDF document
  final String pdfId;

  /// The base URL of the PDF Page Streamer backend
  final String backendUrl;

  /// The CDN URL where PDF viewer assets are hosted
  final String cdnUrl;

  @override
  Map<String, dynamic> toMap() => {
        'type': type,
        'pdfId': pdfId,
        'backendUrl': backendUrl,
        'cdnUrl': cdnUrl,
      };
}

/// Message for setting the current page
@immutable
class SetPageMessage extends PlatformMessage {
  /// Creates a set page message
  const SetPageMessage(this.pageNumber) : super('SET_PAGE');

  /// The page number to navigate to (1-indexed)
  final int pageNumber;

  @override
  Map<String, dynamic> toMap() => {
        'type': type,
        'pageNumber': pageNumber,
      };
}

/// Message for setting the zoom level
@immutable
class SetZoomMessage extends PlatformMessage {
  /// Creates a set zoom message
  const SetZoomMessage(this.zoomLevel) : super('SET_ZOOM');

  /// The zoom level (0.5 to 4.0)
  final double zoomLevel;

  @override
  Map<String, dynamic> toMap() => {
        'type': type,
        'zoomLevel': zoomLevel,
      };
}

/// Base class for all event messages from the PDF viewer
@immutable
abstract class EventMessage {
  /// Creates an event message
  const EventMessage(this.type);

  /// The event type identifier
  final String type;

  /// Creates an event message from a map received via platform channel
  factory EventMessage.fromMap(Map<String, dynamic> map) {
    final type = map['type'] as String?;

    switch (type) {
      case 'PDF_LOADED':
        return PdfLoadedEvent.fromMap(map);
      case 'PAGE_CHANGED':
        return PageChangedEvent.fromMap(map);
      case 'ZOOM_CHANGED':
        return ZoomChangedEvent.fromMap(map);
      case 'LOADING_STATE_CHANGED':
        return LoadingStateChangedEvent.fromMap(map);
      case 'ERROR':
        return ErrorEvent.fromMap(map);
      default:
        return UnknownEvent(type ?? 'UNKNOWN', map);
    }
  }
}

/// Event fired when a PDF has been successfully loaded
@immutable
class PdfLoadedEvent extends EventMessage {
  /// Creates a PDF loaded event
  const PdfLoadedEvent({
    required this.pdfId,
    required this.pageCount,
    required this.title,
  }) : super('PDF_LOADED');

  /// The unique identifier of the loaded PDF
  final String pdfId;

  /// The total number of pages in the PDF
  final int pageCount;

  /// The title of the PDF document
  final String? title;

  /// Creates a PDF loaded event from a map
  factory PdfLoadedEvent.fromMap(Map<String, dynamic> map) => PdfLoadedEvent(
        pdfId: map['pdfId'] as String,
        pageCount: map['pageCount'] as int,
        title: map['title'] as String?,
      );
}

/// Event fired when the current page changes
@immutable
class PageChangedEvent extends EventMessage {
  /// Creates a page changed event
  const PageChangedEvent({
    required this.currentPage,
    required this.totalPages,
  }) : super('PAGE_CHANGED');

  /// The current page number (1-indexed)
  final int currentPage;

  /// The total number of pages
  final int totalPages;

  /// Creates a page changed event from a map
  factory PageChangedEvent.fromMap(Map<String, dynamic> map) => PageChangedEvent(
        currentPage: map['currentPage'] as int,
        totalPages: map['totalPages'] as int,
      );
}

/// Event fired when the zoom level changes
@immutable
class ZoomChangedEvent extends EventMessage {
  /// Creates a zoom changed event
  const ZoomChangedEvent(this.zoomLevel) : super('ZOOM_CHANGED');

  /// The new zoom level
  final double zoomLevel;

  /// Creates a zoom changed event from a map
  factory ZoomChangedEvent.fromMap(Map<String, dynamic> map) => ZoomChangedEvent(
        map['zoomLevel'] as double,
      );
}

/// Event fired when the loading state changes
@immutable
class LoadingStateChangedEvent extends EventMessage {
  /// Creates a loading state changed event
  const LoadingStateChangedEvent({
    required this.isLoading,
    required this.progress,
  }) : super('LOADING_STATE_CHANGED');

  /// Whether the PDF viewer is currently loading
  final bool isLoading;

  /// The loading progress (0.0 to 1.0)
  final double progress;

  /// Creates a loading state changed event from a map
  factory LoadingStateChangedEvent.fromMap(Map<String, dynamic> map) =>
      LoadingStateChangedEvent(
        isLoading: map['isLoading'] as bool,
        progress: map['progress'] as double,
      );
}

/// Event fired when an error occurs
@immutable
class ErrorEvent extends EventMessage {
  /// Creates an error event
  const ErrorEvent({
    required this.message,
    required this.code,
  }) : super('ERROR');

  /// The error message
  final String message;

  /// The error code
  final String? code;

  /// Creates an error event from a map
  factory ErrorEvent.fromMap(Map<String, dynamic> map) => ErrorEvent(
        message: map['message'] as String,
        code: map['code'] as String?,
      );
}

/// Event for unknown/unhandled event types
@immutable
class UnknownEvent extends EventMessage {
  /// Creates an unknown event
  const UnknownEvent(super.type, this.data);

  /// The raw event data
  final Map<String, dynamic> data;
}