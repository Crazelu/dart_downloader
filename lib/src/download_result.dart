import 'dart:io';

class DownloadResult {
  final File file;
  final bool isDownloadComplete;
  final String id;

  const DownloadResult({
    required this.file,
    required this.isDownloadComplete,
    required this.id,
  });

  @override
  bool operator ==(Object other) {
    if (other is DownloadResult) {
      return file.path == other.file.path &&
          isDownloadComplete == other.isDownloadComplete &&
          id == other.id;
    }
    return false;
  }

  @override
  int get hashCode => Object.hashAll([file, isDownloadComplete, id]);
}
