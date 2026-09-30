import 'pdf_downloader_stub.dart'
    if (dart.library.js_interop) 'pdf_downloader_web.dart'
    if (dart.library.io) 'pdf_downloader_io.dart' as impl;

class PdfDownloader {
  /// Baixa ou compartilha os bytes do PDF com o nome de arquivo informado
  static Future<void> downloadBytes(List<int> bytes, String filename) async {
    await impl.downloadBytesImpl(bytes, filename);
  }
}
