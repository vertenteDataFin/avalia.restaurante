import 'dart:typed_data';
import 'image_compressor_stub.dart'
    if (dart.library.html) 'image_compressor_web.dart';

Future<String?> getCompressedDataUrl(Uint8List bytes) async {
  return compressImageWeb(bytes);
}
