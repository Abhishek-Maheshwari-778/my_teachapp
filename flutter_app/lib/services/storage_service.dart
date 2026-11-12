import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../constants/app_constants.dart';

class StorageService {
  /// Resolves the secure private internal app directory (context.filesDir)
  Future<String> _getSecureDirectoryPath() async {
    final directory = await getApplicationDocumentsDirectory();
    final secureDir = Directory('${directory.path}/secure_notes');
    if (!await secureDir.exists()) {
      await secureDir.create(recursive: true);
    }
    return secureDir.path;
  }

  /// Get the private sandboxed file path with obfuscated extension
  Future<File> getSandboxedFile(String noteId) async {
    final dirPath = await _getSecureDirectoryPath();
    return File('$dirPath/$noteId.tflock');
  }

  /// Check if the note is already downloaded locally
  Future<bool> isNoteDownloaded(String noteId) async {
    final file = await getSandboxedFile(noteId);
    return await file.exists();
  }

  /// Download PDF directly from Google Drive stream into internal private sandbox
  Future<bool> downloadAndSandboxNote({
    required String noteId,
    required String driveFileId,
    Function(double progress)? onProgress,
  }) async {
    try {
      final downloadUrl = AppConstants.getDriveDirectDownloadUrl(driveFileId);
      final request = http.Request('GET', Uri.parse(downloadUrl));
      final response = await http.Client().send(request);

      if (response.statusCode == 200 || response.statusCode == 302) {
        final targetFile = await getSandboxedFile(noteId);
        final contentLength = response.contentLength ?? 0;
        int receivedBytes = 0;

        final sink = targetFile.openWrite();

        await for (final chunk in response.stream) {
          sink.add(chunk);
          receivedBytes += chunk.length;
          if (contentLength > 0 && onProgress != null) {
            onProgress(receivedBytes / contentLength);
          }
        }

        await sink.flush();
        await sink.close();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Read the raw decrypted bytes into memory
  Future<List<int>> readSandboxedBytes(String noteId) async {
    final file = await getSandboxedFile(noteId);
    if (await file.exists()) {
      return await file.readAsBytes();
    }
    return [];
  }

  /// Calculate total cached storage used
  Future<String> getCachedStorageSize() async {
    final dirPath = await _getSecureDirectoryPath();
    final dir = Directory(dirPath);
    if (!await dir.exists()) return '0 MB';

    int totalBytes = 0;
    await for (final file in dir.list(recursive: false)) {
      if (file is File) {
        totalBytes += await file.length();
      }
    }

    final double mb = totalBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  /// Clear offline cached notes
  Future<void> clearAllCache() async {
    final dirPath = await _getSecureDirectoryPath();
    final dir = Directory(dirPath);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}

