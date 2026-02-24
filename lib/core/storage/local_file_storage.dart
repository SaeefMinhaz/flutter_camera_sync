import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Handles where and how image files are stored on disk.
///
/// The methods here are intentionally straightforward so they are easy
/// to follow and debug when something goes wrong.
class LocalFileStorage {
  /// Returns the root directory used for all image files.
  Future<Directory> _rootDir() async {
    final Directory baseDir = await getApplicationDocumentsDirectory();
    final Directory imagesDir = Directory(p.join(baseDir.path, 'images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    return imagesDir;
  }

  /// Returns the directory used for a single batch.
  Future<Directory> batchDir(String batchId) async {
    final Directory root = await _rootDir();
    final Directory dir = Directory(p.join(root.path, 'batches', batchId));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Copies an existing image file into this app's storage area.
  ///
  /// Returns the new absolute file path.
  Future<String> copyImageIntoStorage({
    required String sourcePath,
    required String batchId,
    required String fileName,
  }) async {
    final Directory dir = await batchDir(batchId);
    final String targetPath = p.join(dir.path, fileName);
    final File source = File(sourcePath);
    final File target = await source.copy(targetPath);
    return target.path;
  }
}

