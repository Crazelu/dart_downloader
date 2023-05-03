import "dart:io";
import "package:dart_downloader_demo/presentation/widgets/music_track_player_widget.dart";
import "package:flutter/material.dart";

class PlayAudioView extends StatelessWidget {
  const PlayAudioView({super.key, required this.file});

  final File file;

  String get _fileName {
    return file.path.split(Platform.pathSeparator).last;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Playing $_fileName"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MusicTrackPlayerWidget(file: file),
          ],
        ),
      ),
    );
  }
}
