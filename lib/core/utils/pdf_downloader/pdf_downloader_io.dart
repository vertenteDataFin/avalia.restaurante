import 'dart:typed_data';
import 'package:printing/printing.dart';

Future<void> downloadBytesImpl(List<int> bytes, String filename) async {
  final uint8Bytes = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
  await Printing.sharePdf(
    bytes: uint8Bytes,
    filename: filename,
  );
}
