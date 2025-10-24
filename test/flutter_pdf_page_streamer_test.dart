import 'package:flutter_test/flutter_test.dart';

// Import only the models to avoid web dependencies in tests
import 'package:flutter_pdf_page_streamer/src/models/pdf_config.dart';
import 'package:flutter_pdf_page_streamer/src/models/pdf_events.dart';

void main() {
  group('PdfConfig Tests', () {
    test('should create development configuration with default values', () {
      final config = PdfConfig.development(
        pdfId: 'test-document',
      );

      expect(config.pdfId, 'test-document');
      expect(config.backendUrl, 'http://localhost:3000/api/pdf');
      expect(config.cdnConfig.baseUrl, 'http://localhost:3002');
      expect(config.initialPage, 1);
      expect(config.initialZoom, 1.0);
    });

    test('should create production configuration', () {
      final config = PdfConfig.production(
        pdfId: 'prod-document',
        backendUrl: 'https://api.example.com/pdf',
        cdnUrl: 'https://cdn.example.com',
      );

      expect(config.pdfId, 'prod-document');
      expect(config.backendUrl, 'https://api.example.com/pdf');
      expect(config.cdnConfig.baseUrl, 'https://cdn.example.com');
    });

    test('should create local assets configuration', () {
      final config = PdfConfig.local(
        pdfId: 'local-document',
        backendUrl: 'https://api.example.com/pdf',
        assetsPath: 'assets',
      );

      expect(config.pdfId, 'local-document');
      expect(config.backendUrl, 'https://api.example.com/pdf');
      expect(config.cdnConfig.baseUrl, 'assets');
      expect(config.cdnConfig.version, 'local');
      expect(config.debugMode, false);
    });

    test('should generate correct asset URLs for local configuration', () {
      final config = PdfConfig.local(
        pdfId: 'test-doc',
        backendUrl: 'https://api.example.com/pdf',
        assetsPath: 'assets',
      );

      // Test CSS asset URL
      final cssUrl = config.cdnConfig.getAssetUrl('pdf-viewer.css');
      expect(cssUrl, 'assets/pdf-viewer.css'); // No version path for local

      // Test JS asset URL
      final jsUrl = config.cdnConfig.getAssetUrl('pdf-viewer.js');
      expect(jsUrl, 'assets/pdf-viewer.js'); // No version path for local
    });

    test('should generate correct asset URLs for development configuration', () {
      final config = PdfConfig.development(
        pdfId: 'test-doc',
      );

      // Test CSS asset URL (no version path for development)
      final cssUrl = config.cdnConfig.getAssetUrl('pdf-viewer.css');
      expect(cssUrl, 'http://localhost:3002/pdf-viewer.css');

      // Test JS asset URL (no version path for development)
      final jsUrl = config.cdnConfig.getAssetUrl('pdf-viewer.js');
      expect(jsUrl, 'http://localhost:3002/pdf-viewer.js');
    });

    test('should generate correct asset URLs for production configuration', () {
      final config = PdfConfig.production(
        pdfId: 'test-doc',
        backendUrl: 'https://api.example.com/pdf',
        cdnUrl: 'https://cdn.example.com',
      );

      // Test CSS asset URL (with version path for production)
      final cssUrl = config.cdnConfig.getAssetUrl('pdf-viewer.css');
      expect(cssUrl, 'https://cdn.example.com/latest/pdf-viewer.css');

      // Test JS asset URL (with version path for production)
      final jsUrl = config.cdnConfig.getAssetUrl('pdf-viewer.js');
      expect(jsUrl, 'https://cdn.example.com/latest/pdf-viewer.js');
    });

    // TODO: Add validation tests when validation is implemented
    // test('should validate PDF ID', () {
    //   expect(
    //     () => PdfConfig.development(pdfId: ''),
    //     throwsArgumentError,
    //   );
    // });
  });

  group('PdfEvent Tests', () {
    test('should create PdfLoadedEvent with timestamp', () {
      final event = PdfLoadedEvent(
        pdfId: 'test-doc',
        pageCount: 10,
        title: 'Test Document',
      );

      expect(event.pdfId, 'test-doc');
      expect(event.pageCount, 10);
      expect(event.title, 'Test Document');
      expect(event.timestamp, isA<DateTime>());
    });

    test('should create PageChangedEvent', () {
      final event = PageChangedEvent(
        currentPage: 5,
        totalPages: 10,
      );

      expect(event.currentPage, 5);
      expect(event.totalPages, 10);
    });
  });
}
