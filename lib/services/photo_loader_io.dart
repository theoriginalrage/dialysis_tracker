import 'dart:io';
import 'dart:typed_data';

Future<Uint8List?> tryLoadBytesFromPath(String path) async {
  final file = File(path);
  if (await file.exists()) {
    return file.readAsBytes();
  }
  return null;
}
