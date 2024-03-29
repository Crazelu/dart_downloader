import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dart_downloader/src/cache.dart';
import 'package:dart_downloader/src/cancel_or_pause_token.dart';
import 'package:dart_downloader/src/download_result.dart';
import 'package:dart_downloader/src/exception.dart';
import 'package:dart_downloader/src/logger.dart';
import 'package:dart_downloader/src/download_state.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/subjects.dart';

bool _enableLogs = true;

class DartDownloader {
  late final CancelOrPauseToken _cancelOrPauseToken;

  DartDownloader() {
    _cancelOrPauseToken = CancelOrPauseToken();
    _cancelOrPauseToken.eventNotifier.addListener(_tokenEventListener);
    _downloadResultNotifier.addListener(_downloadResultListener);
    if (!_enableLogs) _logger.disableLogs();
  }

  static final _logger = Logger(DartDownloader);

  static const _cacheDirectory = Cache.cacheDirectory;

  bool _isDownloading = false;
  bool _isPaused = false;
  bool _isCancelled = false;
  bool _canBuffer = false;
  bool _hasResumedDownload = false;
  bool _deleteIfDownloadedFilePathExists = false;
  bool _canRetryDownload = false;
  bool _pausedFromLostConnection = false;
  int _totalBytes = 0;
  int _maxRetries = 0;
  int _retryCount = 0;

  ///Size of partially (if download is in progress)
  ///or fully (if download is complete) downloaded file.
  int _downloadedBytesLength = 0;

  String _url = "";
  String? _path;
  String? _fileName;

  late final _downloadProgressController = BehaviorSubject<int>();
  late final _formattedDownloadProgressController = BehaviorSubject<String>();
  late final _downloadStateController = BehaviorSubject<DownloadState>();

  late Completer<File?> _downloadedFileCompleter = Completer<File?>();
  final _downloadResultNotifier = ValueNotifier<DownloadResult?>(null);

  late final _fileSizeCompleter = Completer<int>();

  final _canBufferNotifier = ValueNotifier<bool>(false);
  ValueNotifier<bool> get canPauseNotifier => _canBufferNotifier;

  StreamSubscription<List<int>>? _downloadResponseStreamSub;
  StreamSubscription<ConnectivityResult>? _connectivityStreamSub;

  ///Listener attached to [_downloadResultNotifier].
  void _downloadResultListener() {
    final result = _downloadResultNotifier.value;
    if (result != null && result.isDownloadComplete) {
      _hasResumedDownload = false;
      _isDownloading = false;
      if (!_isCancelled &&
          !_isPaused &&
          !_downloadedFileCompleter.isCompleted) {
        _connectivityStreamSub?.cancel();
        if (_path == null) Cache.save(_fileName ?? _getFileName);
        _downloadedFileCompleter.complete(result.file);
        _downloadStateController.add(const Completed());
      }
    }
  }

  ///Listener attached to [_cancelOrPauseToken].
  void _tokenEventListener() {
    if (_isCancelled) return;

    if (_cancelOrPauseToken.eventNotifier.value == Event.cancel) {
      _downloadResponseStreamSub?.cancel();
      _hasResumedDownload = false;
      _isDownloading = false;
      _isCancelled = true;
      _downloadStateController.add(const Cancelled());
      _downloadedFileCompleter.completeError(DownloadCancelException());
    }
    if (_cancelOrPauseToken.eventNotifier.value == Event.pause) {
      if (!_pausedFromLostConnection) _connectivityStreamSub?.cancel();
      _downloadResponseStreamSub?.cancel();
      _hasResumedDownload = false;
      _isDownloading = false;
      _isPaused = true;
      _downloadStateController.add(const Paused());
      _downloadedFileCompleter.completeError(DownloadPauseException());
      _downloadedFileCompleter = Completer<File?>();
    }
  }

  ///Listens to changes in connectivity state and pauses downloads
  ///when device is not connected to mobile or wifi network.
  ///Resumes download when connection is back if [_pausedFromLostConnection] is true.
  void _listenToConnectivityChanges() {
    _connectivityStreamSub?.cancel();
    _connectivityStreamSub = Connectivity().onConnectivityChanged.listen(
      (result) {
        _logger.log(result);
        if (_isCancelled) return;
        if ([ConnectivityResult.mobile, ConnectivityResult.wifi]
            .contains(result)) {
          if (_pausedFromLostConnection) {
            _logger.log("_listenToConnectivityChanges -> Connection available");
            _pausedFromLostConnection = false;
            resume();
          }
        } else {
          _logger.log(
            "_listenToConnectivityChanges -> Connection lost and downloading -> $_isDownloading",
          );
          if (_isDownloading) {
            _pausedFromLostConnection = true;
            pause();
          }
        }
      },
    );
  }

  ///Downloaded file. This is null when download isn't complete.
  File? get downloadedFile => _downloadResultNotifier.value?.file;

  ///Stream of download progress in bytes.
  Stream<int> get progress => _downloadProgressController.stream;

  ///Stream of download progress formatted for readability (e.g 5.3MB/8.5 MB).
  Stream<String> get formattedProgress =>
      _formattedDownloadProgressController.stream;

  ///Stream of downloader state (PAUSED, DOWNLOADING, CANCELLED, COMPLETED).
  Stream<DownloadState> get downloadState => _downloadStateController.stream;

  ///Size of file to be downloaded in bytes.
  Future<int> get getFileSize async {
    if (_fileSizeCompleter.isCompleted) {
      return _totalBytes;
    }
    return _fileSizeCompleter.future;
  }

  ///Disables logs.
  static void disableLogs() {
    _enableLogs = false;
    _logger.disableLogs();
  }

  ///Deletes all files in [Cache.cacheDirectory].
  static Future<void> clearCache() async {
    return Cache.clearCache();
  }

  ///Downloads a file from [url].
  ///If [path] is specified, the downloaded file is saved there.
  ///
  ///[DartDownloader] will attempt to get the file name from the url.
  ///If that will fail, pass a [fileName].
  ///[retries] is the maximum number of times download should be retried in
  ///the event of download failures. If [retries] is `null`, no retries are allowed.
  Future<File?> download({
    required String url,
    bool deleteIfDownloadedFilePathExists = false,
    int? retries,
    String? path,
    String? fileName,
  }) async {
    try {
      _downloadResponseStreamSub?.cancel();
      _listenToConnectivityChanges();

      if (_hasResumedDownload) {
        _isPaused = false;
        _retryCount = 0;
        _handleDownload();
        return _downloadedFileCompleter.future;
      }

      _url = url;
      _path = path;
      _fileName = fileName;
      _downloadedBytesLength = 0;
      _retryCount = 0;
      _canRetryDownload = retries != null;
      _maxRetries = retries ?? 0;
      _deleteIfDownloadedFilePathExists = deleteIfDownloadedFilePathExists;

      await _loadMetadata();

      if (_totalBytes == 0) {
        //unable to fetch metadata
        throw DownloadCancelException();
      }

      _handleDownload();

      return _downloadedFileCompleter.future;
    } on DownloaderException catch (e) {
      _logger.log(e.message);
      return null;
    } catch (e) {
      _logger.log("download -> $e");
      rethrow;
    }
  }

  ///Filename of content at [_url].
  String get downloadFileName => _fileName ?? _getFileName;

  ///Retrieves file name from [_url].
  String get _getFileName {
    try {
      return _url.split('/').last;
    } catch (e) {
      return "";
    }
  }

  ///Creates and returns a [File] with [fileName] in [_cacheDirectory]
  ///if [_path] is `null`. Otherwise, a [File] is created at [_path].
  Future<File> _getFile(String fileName) async {
    if (_path != null) return File(_path!);

    final dir = await getApplicationDocumentsDirectory();
    String fileDirectory = "${dir.path}/$_cacheDirectory";

    await Directory(fileDirectory).create(recursive: true);

    return File("$fileDirectory/$fileName");
  }

  ///Downloads with ranges if buffering is supported.
  ///Otherwise, the entire file is downloaded once.
  Future<void> _handleDownload() async {
    try {
      final fileName = _fileName ?? _getFileName;
      if (fileName.isEmpty) {
        throw const DownloaderException(
          message: "Unable to determine file name",
        );
      }

      _isDownloading = true;
      _downloadStateController.add(const Downloading());

      if (!_canBuffer) {
        _logger.log("Can't buffer. Downloading entire file instead");

        await _downloadEntireFile();
        return;
      }

      int start = _hasResumedDownload
          ? _downloadedBytesLength + 1
          : _downloadedBytesLength;

      if (start >= _totalBytes) {
        _isDownloading = false;
        _logger.log("Download should have terminated");
        return;
      }

      final bytes = await _downloadInRange(start, _totalBytes);

      if (!_isDownloading) {
        _logger.log("Download terminated");
        return;
      }

      if (bytes.isNotEmpty) {
        //write to file
        final downloadedFile =
            _downloadResultNotifier.value?.file ?? await _getFile(fileName);

        await downloadedFile.writeAsBytes(
          bytes,
          mode: _hasResumedDownload ? FileMode.append : FileMode.write,
        );

        _downloadResultNotifier.value = DownloadResult(
          file: downloadedFile,
          id: DateTime.now().toIso8601String(),
          isDownloadComplete: _downloadedBytesLength >= _totalBytes - 1,
        );
      } else {
        if (_canRetryDownload && _retryCount < _maxRetries) {
          _logger.log("Retrying for $_getFileName -> ${_retryCount + 1}");
          _retryCount++;
          _handleDownload();
        } else {
          _cancelOrPauseToken.cancel();
        }
      }
    } catch (e) {
      _logger.log("_handleDownload -> $e");
      _handleError(e);
    }
  }

  ///Adds download progress to streams.
  void _setDownloadProgress(int byteLength) {
    _downloadedBytesLength += byteLength;
    _downloadProgressController.add(byteLength);

    final formattedFileSize = _formatByte(_totalBytes);
    final formattedPartialDownloadedFileSize =
        _formatByte(_downloadedBytesLength);

    _formattedDownloadProgressController
        .add("$formattedPartialDownloadedFileSize/$formattedFileSize");
  }

  ///Formats bytes to a readable form
  String _formatByte(int value) {
    try {
      if (value == 0) return '0 B';

      const int K = 1024;
      const int M = K * K;
      const int G = M * K;
      const int T = G * K;

      final List<int> dividers = [T, G, M, K, 1];
      final List<String> units = ["TB", "GB", "MB", "KB", "B"];

      if (value < 0) value = value * -1;
      String result = '';
      for (int i = 0; i < dividers.length; i++) {
        final divider = dividers[i];
        if (value >= divider) {
          result = _format(value, divider, units[i]);
          break;
        }
      }
      return result;
    } catch (e) {
      return '0 B';
    }
  }

  String _format(int value, int divider, String unit) {
    final result = divider > 1 ? value / divider : value;

    return '${result.toStringAsFixed(1)} $unit';
  }

  ///Downloads file chunk from [_url] in range specified by
  ///[start] and [end] and returns the downloaded bytes.
  Future<Uint8List> _downloadInRange(int start, int end) async {
    try {
      final fileName = _fileName ?? _getFileName;
      if (fileName.isEmpty) {
        throw const DownloaderException(
          message: "Unable to determine file name",
        );
      }

      final bytesCompleter = Completer<Uint8List>();

      _logger
          .log("($fileName) -> Starting chunk download for range $start-$end");

      final request = http.Request("GET", Uri.parse(_url));
      request.headers.addAll({"Range": "bytes=$start-$end"});
      final response = await http.Client().send(request);
      List<int> fileBytes = [];

      _downloadResponseStreamSub = response.stream.listen(
        (bytes) {
          if (_isPaused || _isCancelled) return;

          _setDownloadProgress(bytes.length);
          fileBytes.addAll(bytes);
        },
        onDone: () {
          bytesCompleter.complete(Uint8List.fromList(fileBytes));
        },
        onError: (e) {
          _logger.log(
              "_downloadInRange StreamedResponse onError-> ${e.runtimeType} $e");

          if (e is http.ClientException &&
              e.message == "Connection closed while receiving data") {
            _isDownloading = false;
            _pausedFromLostConnection = true;
            _cancelOrPauseToken.pause();
            return;
          }

          if (_canRetryDownload && _retryCount < _maxRetries) {
            _downloadResponseStreamSub?.cancel();
            // _logger.log("Skipping error. Going to retry");
          } else {
            _handleError(e);
          }
        },
        cancelOnError: true,
      );

      return bytesCompleter.future;
    } catch (e) {
      _logger.log("_downloadInRange -> $e");

      if (_canRetryDownload && _retryCount < _maxRetries) {
        _downloadResponseStreamSub?.cancel();
        // _logger.log("Skipping error. Going to retry");
      } else {
        _handleError(e);
      }
    }
    return Uint8List.fromList([]);
  }

  ///Downloads the entire file from [_url].
  Future<File?> _downloadEntireFile() async {
    try {
      String fileName = _fileName ?? _getFileName;
      if (fileName.isEmpty) {
        throw const DownloaderException(
          message: "Unable to determine file name",
        );
      }

      final request = http.Request("GET", Uri.parse(_url));
      final response = await http.Client().send(request);
      List<int> fileBytes = [];

      _downloadResponseStreamSub = response.stream.listen(
        (bytes) {
          if (_isPaused || _isCancelled) return;

          _setDownloadProgress(bytes.length);
          fileBytes.addAll(bytes);
        },
        onDone: () async {
          try {
            if (_isPaused || _isCancelled) return;

            File downloadedFile;

            if (_path != null) {
              downloadedFile = File(_path!);
            } else {
              final dir = await getApplicationDocumentsDirectory();
              String fileDirectory = "${dir.path}/$_cacheDirectory";

              await Directory(fileDirectory).create(recursive: true);
              downloadedFile = File("$fileDirectory/$fileName");
            }

            if (await downloadedFile.exists()) {
              if (_deleteIfDownloadedFilePathExists) {
                await downloadedFile.delete();
              } else {
                throw DownloaderException(
                  message: "File at ${downloadedFile.path} already exists",
                );
              }
            }

            await downloadedFile.writeAsBytes(fileBytes);

            _downloadResultNotifier.value = DownloadResult(
              file: downloadedFile,
              id: DateTime.now().toIso8601String(),
              isDownloadComplete: true,
            );
          } catch (e) {
            _logger.log("_downloadEntireFile StreamedResponse onDone -> $e");
            _handleError(e);
          }
        },
        onError: (e) {
          _logger.log("_downloadEntireFile StreamedResponse onError-> $e");

          if (_canRetryDownload && _retryCount < _maxRetries) {
            // _logger.log("Retrying for $_getFileName -> ${_retryCount + 1}");
            _downloadResponseStreamSub?.cancel();
            _retryCount++;
            _downloadEntireFile();
          } else {
            _handleError(e);
          }
        },
        cancelOnError: true,
      );

      return _downloadedFileCompleter.future;
    } catch (e) {
      _logger.log("_downloadEntireFile -> $e");

      if (_canRetryDownload && _retryCount < _maxRetries) {
        // _logger.log("Retrying for $_getFileName -> ${_retryCount + 1}");
        _downloadResponseStreamSub?.cancel();
        _retryCount++;
        _downloadEntireFile();
      } else {
        _handleError(e);
      }
    }

    return null;
  }

  void _handleError(
    Object error, {
    bool rethrowOnlyOwnedException = true,
  }) {
    _cancelOrPauseToken.cancel();
    if (rethrowOnlyOwnedException && error is DownloaderException) {
      throw error;
    } else if (!rethrowOnlyOwnedException) {
      throw error;
    }
  }

  ///Loads file metadata including file size in bytes and flag for whether
  ///buffered download is possible.
  Future<void> _loadMetadata() async {
    try {
      final response = await http.head(Uri.parse(_url));
      final headers = response.headers;

      _canBuffer = headers["accept-ranges"] == "bytes";
      _totalBytes = int.parse(headers["content-length"] ?? "0");

      if (!_fileSizeCompleter.isCompleted) {
        _fileSizeCompleter.complete(_totalBytes);
      }

      _canBufferNotifier.value = _canBuffer;
    } catch (e) {
      _logger.log("_loadMetadata -> $e");
      _handleError(e);
    }
  }

  ///Pauses download.
  void pause() {
    if (_canBuffer && _isDownloading) {
      _isDownloading = false;
      _cancelOrPauseToken.pause();
    }

    if (!_canBuffer) {
      _logger.log(
        "This download cannot be paused and resumed as the file server doesn't support buffering.",
      );
    }
  }

  ///Resumes download.
  ///This must be called only when a download has been paused.
  ///Calling this in a non paused state will throw [DownloaderException].
  Future<File?> resume() async {
    try {
      if (_isCancelled || !_isPaused) {
        throw const DownloaderException(
          message:
              "No active download session found. Only call this when there's a paused download.",
        );
      }

      if (_downloadedFileCompleter.isCompleted) {
        _downloadedFileCompleter = Completer<File?>();
      }
      _cancelOrPauseToken.resume();
      _hasResumedDownload = true;
      return await download(url: _url);
    } catch (e) {
      _logger.log("resume -> $e");
    }
    return null;
  }

  ///Cancels download.
  void cancel() {
    if (!_isCancelled) _cancelOrPauseToken.cancel();
  }

  ///Releases resources.
  void dispose() {
    _connectivityStreamSub?.cancel();
    _downloadResponseStreamSub?.cancel();
    _cancelOrPauseToken.eventNotifier.removeListener(_tokenEventListener);
    _downloadResultNotifier.removeListener(_downloadResultListener);
    _cancelOrPauseToken.dispose();
    _downloadProgressController.close();
    _formattedDownloadProgressController.close();
    _downloadStateController.close();
    _downloadResultNotifier.dispose();
    _canBufferNotifier.dispose();
  }
}
