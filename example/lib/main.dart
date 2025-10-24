import 'package:flutter/material.dart';
import 'package:flutter_pdf_page_streamer/flutter_pdf_page_streamer.dart';

void main() {
  runApp(const PdfStreamerExampleApp());
}

class PdfStreamerExampleApp extends StatelessWidget {
  const PdfStreamerExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter PDF Page Streamer Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ExampleHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ExampleHomePage extends StatelessWidget {
  const ExampleHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('PDF Page Streamer Examples'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildExampleCard(
            context,
            'Basic PDF Viewer',
            'Simple PDF viewing with page-based streaming',
            Icons.picture_as_pdf,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const BasicPdfViewerExample(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            'Advanced PDF Viewer',
            'Full-featured viewer with controls and events',
            Icons.dashboard,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdvancedPdfViewerExample(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            'Performance Demo',
            'Large document performance showcase',
            Icons.speed,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PerformanceDemoExample(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildFeatures(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flash_on, color: Colors.amber[600], size: 28),
                const SizedBox(width: 8),
                const Text(
                  'Flutter PDF Page Streamer',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'High-performance page-based PDF streaming for Flutter Web',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                _PerformanceBadge(
                  icon: Icons.memory,
                  label: '~5-10MB',
                  description: 'Memory Usage',
                ),
                SizedBox(width: 16),
                _PerformanceBadge(
                  icon: Icons.timer,
                  label: '2-3 sec',
                  description: 'Load Time',
                ),
                SizedBox(width: 16),
                _PerformanceBadge(
                  icon: Icons.trending_up,
                  label: '500MB+',
                  description: 'File Support',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  Widget _buildFeatures() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Key Features',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildFeatureItem(Icons.stream, 'Page-Based Streaming'),
            _buildFeatureItem(Icons.memory, 'Memory Efficient'),
            _buildFeatureItem(Icons.speed, 'High Performance'),
            _buildFeatureItem(Icons.event, 'Event-Driven'),
            _buildFeatureItem(Icons.cloud, 'CDN Optimized'),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.green),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }
}

class _PerformanceBadge extends StatelessWidget {
  const _PerformanceBadge({
    required this.icon,
    required this.label,
    required this.description,
  });

  final IconData icon;
  final String label;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.blue),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        Text(
          description,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}

// Basic PDF Viewer Example
class BasicPdfViewerExample extends StatelessWidget {
  const BasicPdfViewerExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Basic PDF Viewer'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: PdfStreamerWidget(
        config: PdfConfig.development(
          pdfId: 'sample-document',
          backendUrl: 'http://localhost:3000/api/pdf',
          cdnUrl: 'http://localhost:3002',
          initialPage: 1,
          initialZoom: 1.0,
        ),
        eventListeners: PdfEventListeners(
          onPdfLoaded: (event) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('PDF loaded: ${event.pageCount} pages'),
                backgroundColor: Colors.green,
              ),
            );
          },
          onError: (event) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${event.message}'),
                backgroundColor: Colors.red,
              ),
            );
          },
        ),
      ),
    );
  }
}

// Advanced PDF Viewer Example
class AdvancedPdfViewerExample extends StatefulWidget {
  const AdvancedPdfViewerExample({super.key});

  @override
  State<AdvancedPdfViewerExample> createState() => _AdvancedPdfViewerExampleState();
}

class _AdvancedPdfViewerExampleState extends State<AdvancedPdfViewerExample> {
  // Note: Programmatic control will be added in future versions
  // final GlobalKey<PdfStreamerWidget> _pdfKey = GlobalKey();
  int _currentPage = 1;
  int _totalPages = 0;
  double _zoomLevel = 1.0;
  bool _isLoading = false;
  String _statusText = 'Initializing...';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced PDF Viewer'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: _showInfo,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildControlBar(),
          _buildStatusBar(),
          Expanded(
            child: PdfStreamerWidget(
              config: PdfConfig.development(
                pdfId: 'advanced-sample',
                backendUrl: 'http://localhost:3000/api/pdf',
                cdnUrl: 'http://localhost:3002',
              ),
              eventListeners: PdfEventListeners(
                onPdfLoaded: (event) {
                  setState(() {
                    _totalPages = event.pageCount;
                    _statusText = 'PDF loaded successfully';
                  });
                },
                onPageChanged: (event) {
                  setState(() {
                    _currentPage = event.currentPage;
                    _totalPages = event.totalPages;
                    _statusText = 'Page ${event.currentPage} of ${event.totalPages}';
                  });
                },
                onZoomChanged: (event) {
                  setState(() {
                    _zoomLevel = event.zoomLevel;
                    _statusText = 'Zoom: ${event.zoomPercentage}%';
                  });
                },
                onLoadingStateChanged: (event) {
                  setState(() {
                    _isLoading = event.isLoading;
                    if (event.isLoading) {
                      _statusText = 'Loading... ${event.progressPercentage}%';
                    }
                  });
                },
                onError: (event) {
                  setState(() {
                    _statusText = 'Error: ${event.message}';
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error ${event.code}: ${event.message}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
                onPageLoaded: (event) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Page ${event.pageNumber} loaded in ${event.loadTime.inMilliseconds}ms',
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlBar() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.first_page),
              onPressed: _totalPages > 0 ? () => _goToPage(1) : null,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
            ),
            Expanded(
              child: Text(
                'Page $_currentPage of $_totalPages',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _currentPage < _totalPages ? () => _goToPage(_currentPage + 1) : null,
            ),
            IconButton(
              icon: const Icon(Icons.last_page),
              onPressed: _totalPages > 0 ? () => _goToPage(_totalPages) : null,
            ),
            const VerticalDivider(),
            IconButton(
              icon: const Icon(Icons.zoom_out),
              onPressed: _zoomLevel > 0.5 ? () => _setZoom(_zoomLevel - 0.25) : null,
            ),
            Text('${(_zoomLevel * 100).round()}%'),
            IconButton(
              icon: const Icon(Icons.zoom_in),
              onPressed: _zoomLevel < 4.0 ? () => _setZoom(_zoomLevel + 0.25) : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[100],
      child: Row(
        children: [
          if (_isLoading) ...[
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
          ],
          Text(_statusText, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  void _goToPage(int page) {
    // TODO: Implement programmatic page navigation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Go to page $page (programmatic control coming soon)')),
    );
  }

  void _setZoom(double zoom) {
    // TODO: Implement programmatic zoom control
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Set zoom to ${(zoom * 100).toInt()}% (programmatic control coming soon)')),
    );
  }

  void _showInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PDF Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Page: $_currentPage'),
            Text('Total Pages: $_totalPages'),
            Text('Zoom Level: ${(_zoomLevel * 100).round()}%'),
            Text('Status: $_statusText'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// Performance Demo Example
class PerformanceDemoExample extends StatefulWidget {
  const PerformanceDemoExample({super.key});

  @override
  State<PerformanceDemoExample> createState() => _PerformanceDemoExampleState();
}

class _PerformanceDemoExampleState extends State<PerformanceDemoExample> {
  final List<Map<String, dynamic>> _performanceMetrics = [];
  DateTime? _loadStartTime;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _showMetrics,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPerformanceInfo(),
          Expanded(
            child: PdfStreamerWidget(
              config: PdfConfig.development(
                pdfId: 'large-document',
                backendUrl: 'http://localhost:3000/api/pdf',
                cdnUrl: 'http://localhost:3002',
              ),
              eventListeners: PdfEventListeners(
                onPdfLoaded: (event) {
                  final loadTime = DateTime.now().difference(_loadStartTime!);
                  _addMetric('PDF Load Time', '${loadTime.inMilliseconds}ms');
                  _addMetric('Total Pages', '${event.pageCount}');
                  _addMetric('Memory Efficiency', '~5-10MB constant');
                },
                onPageLoaded: (event) {
                  _addMetric(
                    'Page ${event.pageNumber} Load',
                    '${event.loadTime.inMilliseconds}ms ${event.fromCache ? "(cached)" : "(network)"}',
                  );
                },
                onLoadingStateChanged: (event) {
                  if (event.isLoading && _loadStartTime == null) {
                    _loadStartTime = DateTime.now();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceInfo() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Showcase',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'This demo shows page-based streaming performance with a large PDF document. '
              'Notice how quickly the first page loads compared to traditional PDF viewers.',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildMetricChip('Memory', '~8MB'),
                const SizedBox(width: 8),
                _buildMetricChip('Cache', '200 pages'),
                const SizedBox(width: 8),
                _buildMetricChip('Preload', '5 pages'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricChip(String label, String value) {
    return Chip(
      label: Text('$label: $value'),
      backgroundColor: Colors.blue[50],
    );
  }

  void _addMetric(String name, String value) {
    setState(() {
      _performanceMetrics.add({
        'name': name,
        'value': value,
        'timestamp': DateTime.now(),
      });
    });
  }

  void _showMetrics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Performance Metrics'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _performanceMetrics.length,
            itemBuilder: (context, index) {
              final metric = _performanceMetrics[index];
              return ListTile(
                title: Text(metric['name']),
                subtitle: Text(metric['value']),
                trailing: Text(
                  '${metric['timestamp'].hour}:${metric['timestamp'].minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 12),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Example demonstrating PDF viewer with local assets
/// This shows how to use PDF viewer assets bundled with your Flutter web app
class LocalAssetsPdfViewerExample extends StatelessWidget {
  const LocalAssetsPdfViewerExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Assets PDF Viewer'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📁 Local Assets Configuration',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'This example uses PDF viewer assets stored locally in your Flutter web app directory.',
                ),
                Text(
                  'Assets path: web/assets/ (same directory as index.html)',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ],
            ),
          ),
          Expanded(
            child: PdfStreamerWidget(
              config: PdfConfig.local(
                pdfId: 'local-sample',
                backendUrl: 'http://localhost:3000/api/pdf',
                assetsPath: 'assets', // Relative to index.html
                debugMode: true,
              ),
              eventListeners: PdfEventListeners(
                onPdfLoaded: (event) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('PDF loaded: ${event.pageCount} pages'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                onError: (event) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${event.message}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
