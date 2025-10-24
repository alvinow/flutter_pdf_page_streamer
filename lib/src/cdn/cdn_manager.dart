import 'dart:async';
import 'package:meta/meta.dart';
import 'asset_loader.dart';
import 'cdn_config.dart';

/// CDN asset loading and management coordinator
///
/// This class orchestrates the loading of PDF viewer assets from CDN,
/// generates HTML templates, and manages the initialization sequence
/// for the embedded PDF viewer with platform channel communication.
class CdnManager {
  /// Creates a CDN manager with configuration
  CdnManager(this.config) : _assetLoader = AssetLoader(config);

  /// CDN configuration
  final CdnConfig config;

  /// Asset loader instance
  final AssetLoader _assetLoader;

  /// Current loading state
  LoadingState _state = LoadingState.initial;

  /// Stream controller for loading progress
  final StreamController<LoadingProgress> _progressController =
      StreamController<LoadingProgress>.broadcast();

  /// Loaded CSS content
  String? _cssContent;

  /// Loaded JavaScript content
  String? _jsContent;

  /// Current loading state
  LoadingState get state => _state;

  /// Stream of loading progress updates
  Stream<LoadingProgress> get progressStream => _progressController.stream;

  /// Whether assets are loaded and ready
  bool get isReady => _state == LoadingState.loaded &&
                     _cssContent != null &&
                     _jsContent != null;

  /// Load all PDF viewer assets from CDN
  Future<void> loadAssets() async {
    if (_state == LoadingState.loading) {
      throw const CdnLoadingException('Asset loading already in progress');
    }

    if (_state == LoadingState.loaded) {
      return; // Already loaded
    }

    _setState(LoadingState.loading);
    _notifyProgress(0, 2, 'Starting asset loading');

    try {
      // Define required assets
      final assets = [
        _AssetInfo('pdf-viewer.css', AssetType.css),
        _AssetInfo('pdf-viewer.js', AssetType.js),
      ];

      var loadedCount = 0;

      // Load CSS first for better progressive loading
      final cssAsset = assets.firstWhere((a) => a.type == AssetType.css);
      _notifyProgress(loadedCount, assets.length, 'Loading ${cssAsset.path}');

      final stopwatch = Stopwatch()..start();
      _cssContent = await _assetLoader.loadCssAsset(cssAsset.path);
      stopwatch.stop();

      loadedCount++;
      _notifyProgress(loadedCount, assets.length, 'CSS loaded in ${stopwatch.elapsedMilliseconds}ms');

      // Load JavaScript
      final jsAsset = assets.firstWhere((a) => a.type == AssetType.js);
      _notifyProgress(loadedCount, assets.length, 'Loading ${jsAsset.path}');

      stopwatch.reset();
      stopwatch.start();
      _jsContent = await _assetLoader.loadJsAsset(jsAsset.path);
      stopwatch.stop();

      loadedCount++;
      _notifyProgress(loadedCount, assets.length, 'JavaScript loaded in ${stopwatch.elapsedMilliseconds}ms');

      _setState(LoadingState.loaded);
      _notifyProgress(loadedCount, assets.length, 'All assets loaded successfully');

    } catch (e) {
      _setState(LoadingState.error);
      final error = e is CdnLoadingException ? e : CdnLoadingException('Asset loading failed', e);
      _notifyError(error);
      rethrow;
    }
  }

  /// Generate HTML template with loaded assets for HtmlElementView
  String generateHtmlTemplate({
    required String pdfId,
    required String backendUrl,
  }) {
    if (!isReady) {
      throw const CdnLoadingException('Assets not loaded yet. Call loadAssets() first.');
    }

    return '''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PDF Page Streamer</title>
    <style>
        /* PDF Viewer Styles */
        $_cssContent

        /* Container styles for Flutter integration */
        body {
            margin: 0;
            padding: 0;
            overflow: hidden;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        }

        #pdf-container {
            width: 100%;
            height: 100vh;
            position: relative;
        }

        .loading-overlay {
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(255, 255, 255, 0.9);
            display: flex;
            align-items: center;
            justify-content: center;
            flex-direction: column;
            z-index: 1000;
        }

        .loading-spinner {
            width: 40px;
            height: 40px;
            border: 4px solid #f3f3f3;
            border-top: 4px solid #3498db;
            border-radius: 50%;
            animation: spin 1s linear infinite;
        }

        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
    </style>
</head>
<body>
    <div id="pdf-container">
        <div id="loading-overlay" class="loading-overlay">
            <div class="loading-spinner"></div>
            <p>Loading PDF Viewer...</p>
        </div>
        <div id="pdf-viewer-app"></div>
    </div>

    <script>
        // PDF Viewer JavaScript
        $_jsContent

        // Platform channel communication bridge
        class FlutterPdfBridge {
            constructor() {
                this.pdfId = '$pdfId';
                this.backendUrl = '$backendUrl';
                this.viewerEngine = null;
                this.isInitialized = false;

                this.setupMessageListener();
                this.initializePdfViewer();
            }

            setupMessageListener() {
                window.addEventListener('message', (event) => {
                    if (event.source !== window.parent) return;

                    const { type, payload } = event.data;
                    this.handleFlutterMessage(type, payload);
                });
            }

            async initializePdfViewer() {
                try {
                    console.log('🔧 FlutterPdfBridge: Starting initialization...');

                    // Wait for DOM to be ready and global functions to be available
                    if (typeof window.initPdfViewer !== 'function') {
                        throw new Error('window.initPdfViewer is not available');
                    }

                    console.log('✅ window.initPdfViewer found, calling with pdfId:', this.pdfId);

                    // Use the global function that's exported by html_core
                    await window.initPdfViewer(this.pdfId);

                    // Get the viewer instance for our bridge
                    this.viewerInstance = window.pdfViewerInstance;
                    if (!this.viewerInstance) {
                        throw new Error('PDF viewer instance not created');
                    }

                    console.log('✅ PDF viewer instance created:', this.viewerInstance);

                    // Hide loading overlay
                    const loadingOverlay = document.getElementById('loading-overlay');
                    if (loadingOverlay) {
                        loadingOverlay.style.display = 'none';
                    }

                    this.isInitialized = true;
                    console.log('✅ FlutterPdfBridge initialized successfully');

                    // Notify Flutter that PDF is loaded
                    setTimeout(() => {
                        this.onPdfLoaded({
                            pdfId: this.pdfId,
                            totalPages: this.getPageCount(),
                            metadata: { title: 'PDF Document' }
                        });
                    }, 500);

                } catch (error) {
                    console.error('❌ FlutterPdfBridge initialization failed:', error);
                    this.onError({ message: error.message, code: 'INIT_ERROR' });
                }
            }

            getPageCount() {
                try {
                    // Get page count from PDF store or viewer instance
                    if (window.getCurrentPdfState) {
                        const state = window.getCurrentPdfState();
                        return state.totalPages || 0;
                    }
                    return 0;
                } catch (error) {
                    console.warn('Could not get page count:', error);
                    return 0;
                }
            }

            handleFlutterMessage(type, payload) {
                if (!this.isInitialized) return;

                try {
                    console.log('📨 Handling Flutter message:', type, payload);

                    switch (type) {
                        case 'LOAD_PDF':
                            // Reload with new PDF
                            window.initPdfViewer(payload.pdfId);
                            break;
                        case 'SET_PAGE':
                            // Use store to set page if available
                            if (window.getCurrentPdfState) {
                                const store = window.getPdfStore();
                                if (store) {
                                    store.getState().setCurrentPage(payload.pageNumber);
                                }
                            }
                            break;
                        case 'SET_ZOOM':
                            // Use store to set zoom if available
                            if (window.getCurrentPdfState) {
                                const store = window.getPdfStore();
                                if (store) {
                                    store.getState().setZoomLevel(payload.zoomLevel);
                                }
                            }
                            break;
                        case 'GET_CURRENT_PAGE':
                            const currentPage = this.getCurrentPage();
                            this.sendToFlutter('CURRENT_PAGE_RESPONSE', {
                                currentPage: currentPage
                            });
                            break;
                        case 'GET_PAGE_COUNT':
                            const pageCount = this.getPageCount();
                            this.sendToFlutter('PAGE_COUNT_RESPONSE', {
                                pageCount: pageCount
                            });
                            break;
                    }
                } catch (error) {
                    console.error('❌ Error handling Flutter message:', error);
                    this.onError({ message: error.message, code: 'MESSAGE_HANDLER_ERROR' });
                }
            }

            getCurrentPage() {
                try {
                    if (window.getCurrentPdfState) {
                        const state = window.getCurrentPdfState();
                        return state.currentPage || 1;
                    }
                    return 1;
                } catch (error) {
                    console.warn('Could not get current page:', error);
                    return 1;
                }
            }

            sendToFlutter(type, payload = {}) {
                window.parent.postMessage({ type, payload }, '*');
            }

            onPdfLoaded(data) {
                this.sendToFlutter('PDF_LOADED', {
                    pdfId: data.pdfId,
                    pageCount: data.totalPages,
                    title: data.metadata?.title || 'PDF Document'
                });
            }

            onPageChanged(currentPage, totalPages) {
                this.sendToFlutter('PAGE_CHANGED', {
                    currentPage,
                    totalPages
                });
            }

            onZoomChanged(zoomLevel) {
                this.sendToFlutter('ZOOM_CHANGED', { zoomLevel });
            }

            onLoadingStateChanged(isLoading, progress) {
                this.sendToFlutter('LOADING_STATE_CHANGED', {
                    isLoading,
                    progress: progress || 0
                });
            }

            onError(error) {
                this.sendToFlutter('ERROR', {
                    message: error.message,
                    code: error.code || 'UNKNOWN'
                });
            }
        }

        // Initialize the bridge when page loads
        document.addEventListener('DOMContentLoaded', () => {
            window.flutterPdfBridge = new FlutterPdfBridge();
        });
    </script>
</body>
</html>''';
  }

  /// Reset manager state for cleanup
  void reset() {
    _setState(LoadingState.initial);
    _cssContent = null;
    _jsContent = null;
  }

  /// Dispose of resources
  void dispose() {
    _progressController.close();
  }

  /// Set loading state and notify listeners
  void _setState(LoadingState newState) {
    _state = newState;
  }

  /// Notify progress update
  void _notifyProgress(int loaded, int total, String? currentAsset) {
    if (!_progressController.isClosed) {
      _progressController.add(LoadingProgress(
        loadedAssets: loaded,
        totalAssets: total,
        currentAsset: currentAsset,
      ));
    }
  }

  /// Notify error
  void _notifyError(CdnLoadingException error) {
    if (!_progressController.isClosed) {
      _progressController.add(LoadingProgress(
        loadedAssets: 0,
        totalAssets: 0,
        currentAsset: null,
        error: error,
      ));
    }
  }
}

/// Asset type enumeration
enum AssetType {
  /// CSS stylesheet
  css,

  /// JavaScript file
  js,
}

/// Asset information for loading
@immutable
class _AssetInfo {
  const _AssetInfo(this.path, this.type);

  final String path;
  final AssetType type;
}