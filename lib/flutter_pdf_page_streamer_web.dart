// Web-specific implementation for flutter_pdf_page_streamer
library flutter_pdf_page_streamer_web;

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'src/bridge/web_implementation.dart';

/// Registers the web implementation of [PdfPageStreamerWebPlugin].
void registerWith(Registrar registrar) {
  PdfPageStreamerWebPlugin.registerWith(registrar);
}