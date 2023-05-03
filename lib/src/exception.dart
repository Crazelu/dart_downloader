class DownloaderException {
  final String message;
  final StackTrace? trace;

  const DownloaderException({required this.message, this.trace});

  @override
  String toString() => "DownloaderException(message: $message)";
}

class DownloadCancelException extends DownloaderException {
  DownloadCancelException({super.message = "Download cancelled", super.trace});
}

class DownloadPauseException extends DownloaderException {
  DownloadPauseException({super.message = "Download paused", super.trace});
}
