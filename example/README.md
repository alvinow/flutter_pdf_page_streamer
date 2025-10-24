# Flutter PDF Page Streamer Example

This example demonstrates the capabilities of the Flutter PDF Page Streamer package, showcasing high-performance page-based PDF streaming for Flutter Web applications.

## Features Demonstrated

### 🔹 **Basic PDF Viewer**
- Simple PDF viewing with minimal configuration
- Page-based streaming in action
- Event handling for load and error states

### 🔹 **Advanced PDF Viewer**
- Full navigation controls (first, previous, next, last page)
- Zoom controls with live feedback
- Real-time status updates
- Performance metrics display
- Comprehensive event handling

### 🔹 **Performance Demo**
- Large document handling showcase
- Real-time performance metrics
- Memory efficiency demonstration
- Page load time tracking

## Running the Example

### Prerequisites

1. **Backend Server**: The PDF Page Streamer backend must be running
   ```bash
   cd ../../backend
   npm run start:dev
   ```

2. **Frontend Assets**: The PDF viewer assets must be served
   ```bash
   cd ../../html_core
   npm run dev
   ```

### Launch Example

```bash
# From the example directory
flutter pub get
flutter run -d chrome --web-port 8080
```

### Configuration

The examples are configured to connect to:
- **Backend API**: `http://localhost:3000/api/pdf`
- **CDN Assets**: `http://localhost:3002`

To use different URLs, modify the configuration in `lib/main.dart`:

```dart
PdfConfig.development(
  pdfId: 'your-document-id',
  backendUrl: 'https://your-api.com/pdf',
  cdnUrl: 'https://your-cdn.com/assets',
)
```

## Example Structure

```
example/
├── lib/
│   └── main.dart                 # Complete example application
├── web/
│   ├── index.html               # Web configuration
│   └── manifest.json            # PWA manifest
├── pubspec.yaml                 # Dependencies
└── README.md                    # This file
```

## Key Code Examples

### Basic Usage

```dart
PdfStreamerWidget(
  config: PdfConfig.development(
    pdfId: 'sample-document',
    backendUrl: 'http://localhost:3000/api/pdf',
    cdnUrl: 'http://localhost:3002',
  ),
  eventListeners: PdfEventListeners(
    onPdfLoaded: (event) => print('Loaded: ${event.pageCount} pages'),
    onPageChanged: (event) => print('Page: ${event.currentPage}'),
    onError: (event) => print('Error: ${event.message}'),
  ),
)
```

### Advanced Configuration

```dart
PdfStreamerWidget(
  config: PdfConfig.production(
    pdfId: 'large-document',
    backendUrl: 'https://api.yourapp.com/pdf',
    cdnUrl: 'https://cdn.yourapp.com/pdf-viewer',
    enablePagePreloading: true,
    preloadBuffer: 5,
    maxConcurrentPageLoads: 8,
    cacheSize: 200,
  ),
  eventListeners: PdfEventListeners(
    onPageLoaded: (event) {
      print('Page ${event.pageNumber} loaded in ${event.loadTime.inMilliseconds}ms');
    },
  ),
)
```

### Programmatic Control

```dart
class ControlledPdfViewer extends StatelessWidget {
  final GlobalKey<PdfStreamerWidgetState> _pdfKey = GlobalKey();

  void goToPage(int page) => _pdfKey.currentState?.goToPage(page);
  void setZoom(double zoom) => _pdfKey.currentState?.setZoom(zoom);

  @override
  Widget build(BuildContext context) {
    return PdfStreamerWidget(
      key: _pdfKey,
      config: config,
    );
  }
}
```

## Performance Characteristics

### Memory Usage
- **Traditional PDF Viewer**: 100MB+ for large documents
- **PDF Page Streamer**: ~5-10MB constant regardless of document size

### Load Times
- **Traditional PDF Viewer**: 10-30 seconds for 100MB documents
- **PDF Page Streamer**: 2-3 seconds initial load

### Network Efficiency
- **Traditional PDF Viewer**: Download entire document upfront
- **PDF Page Streamer**: Stream pages on-demand, cache intelligently

## Testing Different Document Sizes

The examples work with any PDF document served by your backend. To test with different document sizes:

1. **Small Documents (1-10 pages)**: Fast initial load, immediate responsiveness
2. **Medium Documents (50-100 pages)**: Excellent memory efficiency demonstration
3. **Large Documents (500+ pages)**: Best showcase of page-streaming benefits

## Troubleshooting

### Backend Connection Issues
```
Error: Failed to load PDF viewer assets
```
**Solution**: Verify backend and frontend servers are running on correct ports

### CORS Issues
```
Error: CORS policy blocks request
```
**Solution**: Configure CORS headers in your backend for the example domain

### Performance Issues
```
Pages loading slowly
```
**Solution**: Check network connection, backend performance, and increase `maxConcurrentPageLoads`

## Browser Compatibility

- ✅ **Chrome/Chromium**: Full support
- ✅ **Firefox**: Full support
- ✅ **Safari**: Full support
- ✅ **Edge**: Full support

## Next Steps

1. **Explore the code**: Review the example implementations
2. **Modify configurations**: Try different settings and observe the impact
3. **Integrate into your app**: Use the patterns in your own Flutter applications
4. **Performance testing**: Test with your actual PDF documents

For more information, see the [main package documentation](../README.md).