// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

Future<String?> compressImageWeb(Uint8List bytes) async {
  try {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final img = html.ImageElement(src: url);
    await img.onLoad.first;
    html.Url.revokeObjectUrl(url);

    int width = img.width ?? 800;
    int height = img.height ?? 800;
    const maxDim = 600;

    if (width > maxDim || height > maxDim) {
      if (width > height) {
        height = (height * maxDim / width).round();
        width = maxDim;
      } else {
        width = (width * maxDim / height).round();
        height = maxDim;
      }
    }

    final canvas = html.CanvasElement(width: width, height: height);
    final ctx = canvas.context2D;
    ctx.drawImageScaled(img, 0, 0, width, height);
    return canvas.toDataUrl('image/jpeg', 0.5);
  } catch (e) {
    debugPrint('Web compression error: $e');
    return null;
  }
}
