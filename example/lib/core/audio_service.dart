import 'package:dart_downloader_demo/core/logger.dart';
import 'package:just_audio/just_audio.dart';

class AudioService {
  late final _player = AudioPlayer();

  late final _logger = Logger(AudioService);

  Future<Duration?> load(String filePath) async {
    try {
      await _player.setFilePath(filePath);
      return await _player.load();
    } catch (e) {
      _logger.log(e);
    }
    return null;
  }

  Future<void> playAudio(String path) async {
    try {
      await pauseAudio();
      await _player.setFilePath(path);
      await _player.play();
    } catch (e) {
      _logger.log(e);
    }
  }

  Future<void> pauseAudio() async {
    try {
      await _player.pause();
    } catch (e) {
      _logger.log(e);
    }
  }

  Future<void> seek(int seconds) async {
    try {
      await _player.seek(Duration(seconds: seconds));
    } catch (e) {
      _logger.log(e);
    }
  }

  Future<void> stopAudio() async {
    try {
      await _player.stop();
    } catch (e) {
      _logger.log(e);
    }
  }

  Stream<int> playingElapsedTimeStream() {
    return _player.positionStream.map((event) => event.inSeconds);
  }

  Stream<bool> playingStateStream() {
    return _player.playingStream;
  }

  Future<void> resume() async {
    await _player.play();
  }
}
