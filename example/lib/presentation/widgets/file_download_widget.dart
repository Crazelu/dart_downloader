import 'package:dart_downloader/dart_downloader.dart';
import 'package:dart_downloader_demo/presentation/views/play_audio_view.dart';
import 'package:dart_downloader_demo/presentation/widgets/custom_text.dart';
import 'package:flutter/material.dart';

class FileDownloadWidget extends StatefulWidget {
  const FileDownloadWidget({
    super.key,
    required this.fileName,
    required this.downloader,
    this.showPlayButton = false,
  });

  final String fileName;
  final DartDownloader downloader;
  final bool showPlayButton;

  @override
  State<FileDownloadWidget> createState() => _FileDownloadWidgetState();
}

class _FileDownloadWidgetState extends State<FileDownloadWidget> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: _DownloadRow(
        fileName: widget.fileName,
        downloader: widget.downloader,
        showPlayButton: widget.showPlayButton,
      ),
    );
  }
}

class _DownloadRow extends StatelessWidget {
  const _DownloadRow({
    super.key,
    required this.fileName,
    required this.downloader,
    this.showPlayButton = false,
  });

  final String fileName;
  final DartDownloader downloader;
  final bool showPlayButton;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DownloadState>(
        stream: downloader.downloadState,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        softWrap: true,
                        text: fileName,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).primaryColorDark,
                      ),
                      const SizedBox(height: 6),
                      _DownloadProgress(
                        downloader: downloader,
                        state: snapshot.data!,
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _DownloadControls(
                  downloader: downloader,
                  state: snapshot.data!,
                  showPlayButton: showPlayButton,
                ),
                const SizedBox(width: 8),
              ],
            );
          }
          return const SizedBox();
        });
  }
}

class _DownloadProgress extends StatelessWidget {
  const _DownloadProgress({
    super.key,
    required this.state,
    required this.downloader,
  });

  final DownloadState state;
  final DartDownloader downloader;

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case Paused():
        return StreamBuilder<String>(
          stream: downloader.formattedProgress,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              return CustomText(
                softWrap: true,
                text: "${snapshot.data!}, paused",
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Theme.of(context).primaryColorDark.withOpacity(.8),
              );
            }

            return const SizedBox();
          },
        );
      case Cancelled():
        return CustomText(
          softWrap: true,
          text: "Download cancelled",
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Theme.of(context).primaryColorDark.withOpacity(.8),
        );
      case Completed():
        return CustomText(
          softWrap: true,
          text: "Downloaded",
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Theme.of(context).primaryColorDark.withOpacity(.8),
        );
      default:
        return StreamBuilder<String>(
          stream: downloader.formattedProgress,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              return CustomText(
                softWrap: true,
                text: snapshot.data!,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Theme.of(context).primaryColorDark.withOpacity(.8),
              );
            }

            return const SizedBox();
          },
        );
    }
  }
}

class _DownloadControls extends StatelessWidget {
  const _DownloadControls({
    super.key,
    required this.state,
    required this.downloader,
    this.showPlayButton = false,
  });

  final DownloadState state;
  final DartDownloader downloader;
  final bool showPlayButton;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
        valueListenable: downloader.canPauseNotifier,
        builder: (context, canPause, _) {
          return Row(
            children: [
              if (canPause && state is Paused) ...{
                _ControlIcon(
                  icon: Icons.restart_alt_outlined,
                  onTap: () {
                    downloader.resume();
                  },
                ),
                const SizedBox(width: 8),
                _ControlIcon(
                  icon: Icons.close,
                  onTap: () {
                    downloader.cancel();
                  },
                ),
              },
              if (canPause && state is Downloading) ...{
                _ControlIcon(
                  icon: Icons.pause_outlined,
                  onTap: () {
                    downloader.pause();
                  },
                ),
                const SizedBox(width: 8),
                _ControlIcon(
                  icon: Icons.close,
                  onTap: () {
                    downloader.cancel();
                  },
                ),
              },
              if (state is Completed) ...{
                if (showPlayButton) ...{
                  _ControlIcon(
                    icon: Icons.play_arrow_outlined,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PlayAudioView(
                            file: downloader.downloadedFile!,
                          ),
                        ),
                      );
                    },
                  ),
                },
                if (!showPlayButton)
                  _ControlIcon(
                    icon: Icons.done_all,
                    onTap: () {},
                  ),
              },
              if (!canPause && state is Downloading) ...{
                _ControlIcon(
                  icon: Icons.cancel,
                  onTap: () {
                    downloader.cancel();
                  },
                ),
              }
            ],
          );
        });
  }
}

class _ControlIcon extends StatelessWidget {
  const _ControlIcon({
    super.key,
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  BorderSide _borderSide(BuildContext context) => BorderSide(
        color: Theme.of(context).primaryColor.withOpacity(.9),
        width: 1,
      );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 21,
        width: 21,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border(
            top: _borderSide(context),
            bottom: _borderSide(context),
            left: _borderSide(context),
            right: _borderSide(context),
          ),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).primaryColor.withOpacity(.8),
          size: 16,
        ),
      ),
    );
  }
}
