/// Flutter PDF Page Streamer - High-performance page-based PDF streaming
///
/// A Flutter package that provides seamless PDF viewing for large documents
/// by streaming individual pages instead of loading entire files.
///
/// ## Key Features
///
/// - **Page-Based Streaming**: Load only the pages you need, when you need them
/// - **Memory Efficient**: ~5-10MB constant memory usage regardless of PDF size
/// - **High Performance**: 2-3 second load times for 100MB+ PDFs
/// - **Syncfusion Compatible**: Follows standard Flutter platform channel patterns
/// - **Event-Driven**: Comprehensive event system for real-time updates
/// - **CDN Optimized**: Smart asset loading with fallback support
///
/// ## Quick Start
///
/// ```dart
/// import 'package:flutter_pdf_page_streamer/flutter_pdf_page_streamer.dart';
///
/// PdfStreamerWidget(
///   config: PdfConfig.development(
///     pdfId: 'my-document-id',
///     backendUrl: 'http://localhost:3000/api/pdf',
///     cdnUrl: 'http://localhost:3002',
///   ),
///   eventListeners: PdfEventListeners(
///     onPdfLoaded: (event) => print('PDF loaded: ${event.pageCount} pages'),
///     onPageChanged: (event) => print('Page ${event.currentPage}/${event.totalPages}'),
///   ),
/// )
/// ```

/// @nodoc
library;

// Core widget
export 'src/widgets/pdf_streamer_widget.dart';

// Configuration
export 'src/models/pdf_config.dart';

// Events
export 'src/models/pdf_events.dart';

// Platform bridge (for advanced usage)
export 'src/bridge/pdf_bridge.dart';

// CDN management (for advanced usage)
export 'src/cdn/cdn_config.dart';
export 'src/cdn/cdn_manager.dart';
