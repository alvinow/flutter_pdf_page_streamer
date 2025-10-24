import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import '../bridge/pdf_bridge.dart';
import '../cdn/cdn_manager.dart';
import '../models/pdf_config.dart';
import '../models/pdf_events.dart';

/// Page-based PDF streaming widget for Flutter Web
///
/// This widget provides high-performance PDF viewing for large documents
/// by streaming individual pages instead of loading entire files. It wraps
/// the html_core/ PDF viewer with Flutter platform channels for seamless
/// integration following the Syncfusion architectural pattern.
class PdfStreamerWidget extends StatefulWidget {
  /// Creates a PDF streamer widget
  const PdfStreamerWidget({
    super.key,
    required this.config,
    this.eventListeners = const PdfEventListeners(),
    this.errorBuilder,
    this.loadingBuilder,
    this.width,
    this.height,
  });

  /// Configuration for PDF streaming
  final PdfConfig config;

  /// Event listeners for PDF viewer events
  final PdfEventListeners eventListeners;

  /// Builder for custom error display
  final Widget Function(BuildContext context, PdfErrorEvent error)? errorBuilder;

  /// Builder for custom loading display
  final Widget Function(BuildContext context, LoadingStateChangedEvent state)? loadingBuilder;

  /// Fixed width for the widget (optional)
  final double? width;

  /// Fixed height for the widget (optional)
  final double? height;

  @override
  State<PdfStreamerWidget> createState() => _PdfStreamerWidgetState();
}

class _PdfStreamerWidgetState extends State<PdfStreamerWidget>
    with WidgetsBindingObserver {

  // Core components
  late CdnManager _cdnManager;
  late StreamSubscription<Map<String, dynamic>> _eventSubscription;

  // State management
  PdfStreamerState _state = PdfStreamerState.initializing;
  PdfErrorEvent? _currentError;
  LoadingStateChangedEvent? _currentLoadingState;

  // HTML view registration
  String? _viewId;
  bool _isViewRegistered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Validate configuration
    final validation = PdfConfigValidator.validate(widget.config);
    if (!validation.isValid) {
      _setError(PdfErrorEvent(
        message: 'Invalid configuration: ${validation.errors.join(', ')}',
        code: 'CONFIG_ERROR',
        timestamp: DateTime.now(),
      ));
      return;
    }

    // Initialize components
    _cdnManager = CdnManager(widget.config.cdnConfig);
    _initializePdfStreamer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _eventSubscription.cancel();
    _cdnManager.dispose();
    PdfBridge.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PdfStreamerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reload if configuration changed
    if (oldWidget.config != widget.config) {
      _reinitialize();
    }
  }

  /// Initialize the PDF streamer with CDN loading and platform channel setup
  Future<void> _initializePdfStreamer() async {
    try {
      _setState(PdfStreamerState.loadingAssets);

      // Initialize platform bridge
      await PdfBridge.initialize();

      // Subscribe to events
      _eventSubscription = PdfBridge.eventStream.listen(
        _handlePlatformEvent,
        onError: (error) => _setError(PdfErrorEvent(
          message: 'Platform event error: $error',
          code: 'PLATFORM_ERROR',
          timestamp: DateTime.now(),
        )),
      );

      // Load CDN assets
      await _cdnManager.loadAssets();

      // Generate HTML template and register view
      await _registerHtmlView();

      _setState(PdfStreamerState.ready);

      // Load PDF document
      await _loadPdfDocument();

    } catch (error) {
      _setError(PdfErrorEvent(
        message: 'Initialization failed: $error',
        code: 'INIT_ERROR',
        timestamp: DateTime.now(),
      ));
    }
  }

  /// Register HTML view with platform view factory
  Future<void> _registerHtmlView() async {
    _viewId = 'pdf-streamer-${widget.config.pdfId}-${DateTime.now().millisecondsSinceEpoch}';

    final htmlContent = _cdnManager.generateHtmlTemplate(
      pdfId: widget.config.pdfId,
      backendUrl: widget.config.backendUrl,
    );

    // Register platform view factory for web
    ui_web.platformViewRegistry.registerViewFactory(
      _viewId!,
      (int viewId) {
        final iframe = html.IFrameElement();
        iframe.src = 'data:text/html;charset=utf-8,${Uri.encodeComponent(htmlContent)}';
        iframe.style.border = 'none';
        iframe.style.width = '100%';
        iframe.style.height = '100%';
        return iframe;
      },
    );

    _isViewRegistered = true;
  }

  /// Load the PDF document using platform channels
  Future<void> _loadPdfDocument() async {
    try {
      _setState(PdfStreamerState.loadingPdf);

      final pageCount = await PdfBridge.loadPdf(
        pdfId: widget.config.pdfId,
        backendUrl: widget.config.backendUrl,
        cdnUrl: widget.config.cdnConfig.baseUrl,
      );

      if (pageCount > 0) {
        _setState(PdfStreamerState.loaded);

        // Navigate to initial page if specified
        if (widget.config.initialPage > 1) {
          await PdfBridge.setPage(widget.config.initialPage);
        }

        // Set initial zoom if specified
        if (widget.config.initialZoom != 1.0) {
          await PdfBridge.setZoom(widget.config.initialZoom);
        }
      }

    } catch (error) {
      _setError(PdfErrorEvent(
        message: 'Failed to load PDF: $error',
        code: 'LOAD_ERROR',
        timestamp: DateTime.now(),
      ));
    }
  }

  /// Handle events from platform channels
  void _handlePlatformEvent(Map<String, dynamic> eventData) {
    final eventType = eventData['type'] as String?;

    if (eventType == null) return;

    final timestamp = DateTime.now();

    switch (eventType) {
      case 'PDF_LOADED':
        final event = PdfLoadedEvent(
          pdfId: eventData['pdfId'] as String,
          pageCount: eventData['pageCount'] as int,
          title: eventData['title'] as String?,
          timestamp: timestamp,
        );
        widget.eventListeners.onPdfLoaded?.call(event);
        break;

      case 'PAGE_CHANGED':
        final event = PageChangedEvent(
          currentPage: eventData['currentPage'] as int,
          totalPages: eventData['totalPages'] as int,
          timestamp: timestamp,
        );
        widget.eventListeners.onPageChanged?.call(event);
        break;

      case 'ZOOM_CHANGED':
        final event = ZoomChangedEvent(
          zoomLevel: (eventData['zoomLevel'] as num).toDouble(),
          timestamp: timestamp,
        );
        widget.eventListeners.onZoomChanged?.call(event);
        break;

      case 'LOADING_STATE_CHANGED':
        final event = LoadingStateChangedEvent(
          isLoading: eventData['isLoading'] as bool,
          progress: (eventData['progress'] as num).toDouble(),
          timestamp: timestamp,
        );
        _currentLoadingState = event;
        widget.eventListeners.onLoadingStateChanged?.call(event);
        setState(() {}); // Update loading UI
        break;

      case 'ERROR':
        final event = PdfErrorEvent(
          message: eventData['message'] as String,
          code: eventData['code'] as String,
          timestamp: timestamp,
        );
        _setError(event);
        break;
    }
  }

  /// Set widget state
  void _setState(PdfStreamerState newState) {
    if (mounted) {
      setState(() {
        _state = newState;
      });
    }
  }

  /// Set error state
  void _setError(PdfErrorEvent error) {
    if (mounted) {
      setState(() {
        _state = PdfStreamerState.error;
        _currentError = error;
      });
      widget.eventListeners.onError?.call(error);
    }
  }

  /// Reinitialize the widget
  Future<void> _reinitialize() async {
    _cdnManager.reset();
    _currentError = null;
    _currentLoadingState = null;
    _isViewRegistered = false;
    await _initializePdfStreamer();
  }

  /// Public API methods for controlling the PDF viewer

  /// Navigate to a specific page
  Future<void> goToPage(int pageNumber) async {
    if (_state == PdfStreamerState.loaded) {
      await PdfBridge.setPage(pageNumber);
    }
  }

  /// Set zoom level
  Future<void> setZoom(double zoomLevel) async {
    if (_state == PdfStreamerState.loaded) {
      await PdfBridge.setZoom(zoomLevel);
    }
  }

  /// Get current page number
  Future<int> getCurrentPage() async {
    if (_state == PdfStreamerState.loaded) {
      return await PdfBridge.getCurrentPage();
    }
    return 1;
  }

  /// Get total page count
  Future<int> getPageCount() async {
    if (_state == PdfStreamerState.loaded) {
      return await PdfBridge.getPageCount();
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    Widget child;

    switch (_state) {
      case PdfStreamerState.initializing:
      case PdfStreamerState.loadingAssets:
      case PdfStreamerState.loadingPdf:
        child = _buildLoadingWidget();
        break;

      case PdfStreamerState.error:
        child = _buildErrorWidget();
        break;

      case PdfStreamerState.ready:
      case PdfStreamerState.loaded:
        child = _buildPdfViewer();
        break;
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: child,
    );
  }

  /// Build loading widget
  Widget _buildLoadingWidget() {
    if (widget.loadingBuilder != null && _currentLoadingState != null) {
      return widget.loadingBuilder!(context, _currentLoadingState!);
    }

    String message;
    switch (_state) {
      case PdfStreamerState.initializing:
        message = 'Initializing PDF Viewer...';
        break;
      case PdfStreamerState.loadingAssets:
        message = 'Loading PDF Viewer Assets...';
        break;
      case PdfStreamerState.loadingPdf:
        message = 'Loading PDF Document...';
        break;
      default:
        message = 'Loading...';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(message),
          if (_currentLoadingState != null && _currentLoadingState!.progress > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(
                value: _currentLoadingState!.progress,
              ),
            ),
        ],
      ),
    );
  }

  /// Build error widget
  Widget _buildErrorWidget() {
    if (widget.errorBuilder != null && _currentError != null) {
      return widget.errorBuilder!(context, _currentError!);
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'PDF Loading Error',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _currentError?.message ?? 'Unknown error occurred',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _reinitialize,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// Build the main PDF viewer
  Widget _buildPdfViewer() {
    if (!_isViewRegistered || _viewId == null) {
      return _buildLoadingWidget();
    }

    return HtmlElementView(viewType: _viewId!);
  }
}

/// State of the PDF streamer widget
enum PdfStreamerState {
  /// Initial state, starting initialization
  initializing,

  /// Loading PDF viewer assets from CDN
  loadingAssets,

  /// PDF viewer ready, loading document
  loadingPdf,

  /// PDF viewer initialized and ready
  ready,

  /// PDF document loaded successfully
  loaded,

  /// Error state
  error,
}