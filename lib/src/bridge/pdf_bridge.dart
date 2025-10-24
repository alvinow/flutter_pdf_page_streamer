import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

/// Platform channel bridge for PDF page streaming operations
///
/// This class handles communication between Flutter and the underlying
/// JavaScript PDF viewer using MethodChannel and EventChannel patterns,
/// following the same architecture as Syncfusion's PDF viewer.
class PdfBridge {
  /// Method channel for sending commands to the PDF viewer
  static const MethodChannel _methodChannel = MethodChannel(
    'flutter_pdf_page_streamer/methods',
  );

  /// Event channel for receiving real-time events from the PDF viewer (lazy initialization)
  static EventChannel? _eventChannel;

  /// Stream controller for PDF viewer events
  static StreamController<Map<String, dynamic>>? _eventController;

  /// Stream of PDF viewer events (page changes, loading states, errors)
  static Stream<Map<String, dynamic>> get eventStream {
    _eventController ??= StreamController<Map<String, dynamic>>.broadcast();
    return _eventController!.stream;
  }

  /// Initialize the platform channel bridge
  ///
  /// This sets up the communication channels between Flutter and the
  /// underlying PDF viewer JavaScript implementation.
  static Future<void> initialize() async {
    try {
      // Initialize method channel communication
      await _methodChannel.invokeMethod('initialize');

      // Set up event channel listener (skip for web due to registration issues)
      if (!kIsWeb) {
        // Create EventChannel only for non-web platforms
        _eventChannel = const EventChannel('flutter_pdf_page_streamer/events');
        _eventChannel!.receiveBroadcastStream().listen(
          (dynamic event) {
            if (event is Map<String, dynamic>) {
              _eventController?.add(event);
            }
          },
          onError: (dynamic error) {
            _eventController?.addError(error);
          },
        );
      } else {
        // For web, we'll handle events differently through postMessage
        // The web implementation will directly add events to _eventController
        if (kDebugMode) {
          print('PDF Bridge: Initialized for web platform (EventChannel skipped)');
        }
      }
    } on PlatformException catch (e) {
      throw PdfBridgeException(
        'Failed to initialize PDF bridge: ${e.message}',
        e.code,
      );
    }
  }

  /// Add event to the stream (used by web implementation)
  static void addEvent(Map<String, dynamic> event) {
    _eventController?.add(event);
  }

  /// Load a PDF for page-based streaming
  ///
  /// [pdfId] The unique identifier for the PDF document
  /// [backendUrl] The base URL of the PDF Page Streamer backend
  /// [cdnUrl] The CDN URL where PDF viewer assets are hosted
  ///
  /// Returns the total number of pages in the PDF
  static Future<int> loadPdf({
    required String pdfId,
    required String backendUrl,
    required String cdnUrl,
  }) async {
    try {
      final result = await _methodChannel.invokeMethod<int>('loadPdf', {
        'pdfId': pdfId,
        'backendUrl': backendUrl,
        'cdnUrl': cdnUrl,
      });
      return result ?? 0;
    } on PlatformException catch (e) {
      throw PdfBridgeException(
        'Failed to load PDF: ${e.message}',
        e.code,
      );
    }
  }

  /// Navigate to a specific page
  ///
  /// [pageNumber] The page number to navigate to (1-indexed)
  static Future<void> setPage(int pageNumber) async {
    try {
      await _methodChannel.invokeMethod('setPage', {
        'pageNumber': pageNumber,
      });
    } on PlatformException catch (e) {
      throw PdfBridgeException(
        'Failed to set page: ${e.message}',
        e.code,
      );
    }
  }

  /// Set the zoom level for the PDF viewer
  ///
  /// [zoomLevel] The zoom level (0.5 to 4.0)
  static Future<void> setZoom(double zoomLevel) async {
    try {
      await _methodChannel.invokeMethod('setZoom', {
        'zoomLevel': zoomLevel,
      });
    } on PlatformException catch (e) {
      throw PdfBridgeException(
        'Failed to set zoom: ${e.message}',
        e.code,
      );
    }
  }

  /// Get the current page number
  static Future<int> getCurrentPage() async {
    try {
      final result = await _methodChannel.invokeMethod<int>('getCurrentPage');
      return result ?? 1;
    } on PlatformException catch (e) {
      throw PdfBridgeException(
        'Failed to get current page: ${e.message}',
        e.code,
      );
    }
  }

  /// Get the total number of pages
  static Future<int> getPageCount() async {
    try {
      final result = await _methodChannel.invokeMethod<int>('getPageCount');
      return result ?? 0;
    } on PlatformException catch (e) {
      throw PdfBridgeException(
        'Failed to get page count: ${e.message}',
        e.code,
      );
    }
  }

  /// Dispose of the platform channel bridge
  static void dispose() {
    _eventController?.close();
    _eventController = null;
  }
}

/// Exception thrown by the PDF bridge
@immutable
class PdfBridgeException implements Exception {
  /// Creates a PDF bridge exception
  const PdfBridgeException(this.message, [this.code]);

  /// The error message
  final String message;

  /// The error code (optional)
  final String? code;

  @override
  String toString() => 'PdfBridgeException: $message${code != null ? ' ($code)' : ''}';
}