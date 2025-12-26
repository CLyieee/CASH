import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ImageFileUtils {
  static Future<File> materializeToFile(XFile xfile) async {
    final String sourcePath = xfile.path;

    // Common happy path: Android/iOS returns a real filesystem path.
    if (sourcePath.isNotEmpty && !sourcePath.startsWith('content://')) {
      final file = File(sourcePath);
      if (await file.exists()) {
        return file;
      }
    }

    // Fallback: some providers (e.g., Android photo picker) yield content:// URIs.
    // Materialize bytes into a temporary file so downstream code that expects
    // a real File path (e.g., MLKit InputImage.fromFile) can work.
    final bytes = await xfile.readAsBytes();
    final tempDir = await getTemporaryDirectory();

    final extension = _safeExtension(xfile.name, fallback: '.jpg');
    final outPath =
        '${tempDir.path}/picked_${DateTime.now().microsecondsSinceEpoch}$extension';

    final outFile = File(outPath);
    await outFile.writeAsBytes(bytes, flush: true);
    return outFile;
  }

  static String _safeExtension(String name, {required String fallback}) {
    final dot = name.lastIndexOf('.');
    if (dot <= 0 || dot == name.length - 1) {
      return fallback;
    }

    final ext = name.substring(dot);
    if (!ext.startsWith('.')) {
      return '.$ext';
    }

    return ext;
  }
}
