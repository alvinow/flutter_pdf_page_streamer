import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'pdf_bridge.dart';

/// Web platform implementation for PDF page streaming
///
/// This class implements the platform channel interface for Flutter Web,
/// using postMessage to communicate with the embedded JavaScript PDF viewer.
/// It acts as the bridge between Flutter's platform channels and the
/// underlying html_core/ PDF viewer.
class PdfPageStreamerWebPlugin {
  /// Registers the web implementation of the platform channels
  static void registerWith(Registrar registrar) {
    // Register method channel handler
    final MethodChannel methodChannel = MethodChannel(
      'flutter_pdf_page_streamer/methods',
      const StandardMethodCodec(),
      registrar,
    );

    final PdfPageStreamerWebPlugin instance = PdfPageStreamerWebPlugin._();
    methodChannel.setMethodCallHandler(instance._handleMethodCall);

    // Note: EventChannel not registered for web - we use postMessage instead

    // Initialize the plugin instance
    instance._initialize();
  }

  PdfPageStreamerWebPlugin._();

  // Note: _eventController removed - events go directly to PdfBridge.addEvent()

  /// Reference to the embedded iframe containing the PDF viewer
  html.IFrameElement? _pdfViewerFrame;

  // Note: StreamHandler methods removed - we use postMessage instead of EventChannel

  /// Message handler for method channel calls
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'initialize':
        return _initialize();

      case 'loadPdf':
        return _loadPdf(Map<String, dynamic>.from(call.arguments as Map));

      case 'setPage':
        return _setPage(Map<String, dynamic>.from(call.arguments as Map));

      case 'setZoom':
        return _setZoom(Map<String, dynamic>.from(call.arguments as Map));

      case 'getCurrentPage':
        return _getCurrentPage();

      case 'getPageCount':
        return _getPageCount();

      default:
        throw PlatformException(
          code: 'UNIMPLEMENTED',
          message: 'Method ${call.method} not implemented on web platform',
        );
    }
  }

  /// Initialize the web platform implementation
  Future<void> _initialize() async {
    // Set up postMessage listener for events from PDF viewer
    html.window.addEventListener('message', _handlePostMessage);
  }

  /// Load a PDF document using page-based streaming
  Future<int> _loadPdf(Map<String, dynamic> arguments) async {
    final String pdfId = arguments['pdfId'] as String;
    final String backendUrl = arguments['backendUrl'] as String;
    final String cdnUrl = arguments['cdnUrl'] as String;

    // Send load command to PDF viewer via postMessage
    _sendMessageToPdfViewer({
      'type': 'LOAD_PDF',
      'payload': {
        'pdfId': pdfId,
        'backendUrl': backendUrl,
        'cdnUrl': cdnUrl,
      },
    });

    // Return placeholder - actual page count will come via event
    return 0;
  }

  /// Set the current page in the PDF viewer
  Future<void> _setPage(Map<String, dynamic> arguments) async {
    final int pageNumber = arguments['pageNumber'] as int;

    _sendMessageToPdfViewer({
      'type': 'SET_PAGE',
      'payload': {
        'pageNumber': pageNumber,
      },
    });
  }

  /// Set the zoom level in the PDF viewer
  Future<void> _setZoom(Map<String, dynamic> arguments) async {
    final double zoomLevel = arguments['zoomLevel'] as double;

    _sendMessageToPdfViewer({
      'type': 'SET_ZOOM',
      'payload': {
        'zoomLevel': zoomLevel,
      },
    });
  }

  /// Get the current page number from the PDF viewer
  Future<int> _getCurrentPage() async {
    // Request current page via postMessage
    _sendMessageToPdfViewer({
      'type': 'GET_CURRENT_PAGE',
    });

    // Return placeholder - actual value will come via event
    return 1;
  }

  /// Get the total page count from the PDF viewer
  Future<int> _getPageCount() async {
    // Request page count via postMessage
    _sendMessageToPdfViewer({
      'type': 'GET_PAGE_COUNT',
    });

    // Return placeholder - actual value will come via event
    return 0;
  }

  /// Send a message to the PDF viewer iframe via postMessage
  void _sendMessageToPdfViewer(Map<String, dynamic> message) {
    if (_pdfViewerFrame?.contentWindow != null) {
      js_util.callMethod(
        _pdfViewerFrame!.contentWindow!,
        'postMessage',
        [message, '*'],
      );
    } else {
      // If no specific frame is registered, try to find and use any iframe on the page
      final iframes = html.document.querySelectorAll('iframe');
      for (final iframe in iframes) {
        if (iframe is html.IFrameElement && iframe.contentWindow != null) {
          js_util.callMethod(
            iframe.contentWindow!,
            'postMessage',
            [message, '*'],
          );
        }
      }
    }
  }

  /// Handle postMessage events from the PDF viewer
  void _handlePostMessage(html.Event event) {
    if (event is html.MessageEvent) {
      final data = event.data;
      if (data is Map<String, dynamic>) {
        // Forward PDF viewer events to Flutter via PdfBridge
        PdfBridge.addEvent(data);
      }
    }
  }

  /// Register the PDF viewer iframe for communication
  void registerPdfViewerFrame(html.IFrameElement frame) {
    _pdfViewerFrame = frame;
  }
}