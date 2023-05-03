import 'package:dart_downloader/dart_downloader.dart';
import 'package:dart_downloader_demo/models/download_request.dart';
import 'package:dart_downloader_demo/presentation/widgets/file_download_widget.dart';
import 'package:flutter/material.dart';

class DartDownloaderView extends StatefulWidget {
  const DartDownloaderView({super.key});

  @override
  State<DartDownloaderView> createState() => _DartDownloaderViewState();
}

class _DartDownloaderViewState extends State<DartDownloaderView> {
  late final List<DartDownloader> _downloaders = [];
  bool _showButton = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadFiles);
  }

  @override
  void dispose() {
    for (final downloader in _downloaders) {
      downloader.dispose();
    }
    super.dispose();
  }

  void _loadFiles() {
    for (final _ in DownloadRequest.requests) {
      _downloaders.add(DartDownloader());
    }
    setState(() {});
  }

  void _download() {
    for (int i = 0; i < _downloaders.length; i++) {
      final downloader = _downloaders[i];
      downloader.download(url: DownloadRequest.requests[i].url);
    }
    setState(() {
      _showButton = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dart Downloader Demo"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            if (_showButton)
              Center(
                child: TextButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.resolveWith(
                      (states) => Theme.of(context).primaryColor,
                    ),
                    foregroundColor: MaterialStateProperty.resolveWith(
                      (states) => Theme.of(context).primaryColorLight,
                    ),
                  ),
                  child: const Text("Download Files"),
                  onPressed: () {
                    _download();
                  },
                ),
              ),
            const SizedBox(height: 20),
            for (int i = 0; i < _downloaders.length; i++)
              FileDownloadWidget(
                fileName: _downloaders[i].downloadFileName,
                downloader: _downloaders[i],
                showPlayButton: DownloadRequest.requests[i].canPlay,
              ),
          ],
        ),
      ),
    );
  }
}
