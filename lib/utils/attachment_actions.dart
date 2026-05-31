import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

/// Helpers to open and download chat attachments (images, videos, files).
class AttachmentActions {
  AttachmentActions._();

  static final Dio _dio = Dio();

  static bool _isLocal(String url) =>
      url.startsWith('/') || url.startsWith('file://');

  static String _stripScheme(String url) =>
      url.startsWith('file://') ? url.replaceFirst('file://', '') : url;

  /// Opens an attachment in the device's default app.
  /// Remote files are downloaded to a cache directory first.
  static Future<void> open(
    BuildContext context,
    String url,
    String fileName,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      String path;
      if (_isLocal(url)) {
        path = _stripScheme(url);
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Opening…'),
            duration: Duration(milliseconds: 800),
          ),
        );
        final dir = await getTemporaryDirectory();
        path = '${dir.path}/${_safeName(fileName)}';
        if (!File(path).existsSync()) {
          await _dio.download(url, path);
        }
      }
      final result = await OpenFilex.open(path);
      if (result.type != ResultType.done) {
        messenger.showSnackBar(
          SnackBar(content: Text('Could not open file: ${result.message}')),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to open: $e')),
      );
    }
  }

  /// Downloads an attachment to the device's Downloads folder (Android) or the
  /// app documents directory as a fallback, then reports where it was saved.
  static Future<void> download(
    BuildContext context,
    String url,
    String fileName,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    if (_isLocal(url)) {
      messenger.showSnackBar(
        const SnackBar(content: Text('This file is already on your device.')),
      );
      return;
    }

    messenger.showSnackBar(
      const SnackBar(
        content: Text('Downloading…'),
        duration: Duration(milliseconds: 1200),
      ),
    );

    try {
      final dir = await _downloadDir();
      final path = '${dir.path}/${_safeName(fileName)}';
      await _dio.download(url, path);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Saved to ${dir.path}'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () => OpenFilex.open(path),
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Download failed: $e')),
      );
    }
  }

  /// Best-effort public Downloads directory on Android, with safe fallbacks.
  static Future<Directory> _downloadDir() async {
    if (Platform.isAndroid) {
      // Standard public Downloads path. Works on most devices for app writes
      // to the app's own files; falls back if not writable.
      const publicDownloads = '/storage/emulated/0/Download';
      final pub = Directory(publicDownloads);
      if (pub.existsSync()) return pub;

      final ext = await getExternalStorageDirectory();
      if (ext != null) {
        final d = Directory('${ext.path}/Download');
        if (!d.existsSync()) d.createSync(recursive: true);
        return d;
      }
    }
    // iOS / fallback: app documents directory (visible in Files app).
    return getApplicationDocumentsDirectory();
  }

  static String _safeName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[^\w\.\-]'), '_');
    return cleaned.isEmpty ? 'file_${DateTime.now().millisecondsSinceEpoch}' : cleaned;
  }
}
