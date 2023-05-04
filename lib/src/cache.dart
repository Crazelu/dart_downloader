import 'dart:convert';
import 'dart:io';
import 'package:dart_downloader/src/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Cache {
  static const _key = "dart_downloader_cache";
  static const String cacheDirectory = "cacheDirectory";
  static final _logger = Logger(Cache);

  static SharedPreferences? _cache;

  Cache._();

  static Future<void> _init() async {
    _cache ??= await SharedPreferences.getInstance();
  }

  static Future<void> delete(String fileName) async {
    try {
      await _init();

      final dir = await getApplicationDocumentsDirectory();
      String fileDirectory = "${dir.path}/${Cache.cacheDirectory}/$fileName";
      final file = File(fileDirectory);
      if (await file.exists()) {
        await file.delete();
      }

      await _cache?.remove(_key);
    } catch (e) {
      _logger.log("$e");
    }
  }

  static Future<void> clearCache() async {
    final entries = await getEntries();

    await Future.forEach<String>(
      entries.keys,
      (fileName) async => await delete(fileName),
    ).onError((error, stackTrace) =>
        _logger.log("Batch cached item deletion error -> $error"));
  }

  static Future<void> save(String fileName) async {
    try {
      await _init();
      final entries = await getEntries();
      entries.addAll({fileName: DateTime.now().toIso8601String()});
      await _cache?.setString(_key, jsonEncode(entries));
    } catch (e) {
      _logger.log(e);
    }
  }

  static Future<Map<String, String>> getEntries() async {
    await _init();
    return Map<String, String>.from(
        jsonDecode(_cache?.getString(_key) ?? '{}'));
  }

  static Future<File?> getFile({
    required String fileName,
    String directory = Cache.cacheDirectory,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileDirectory = "${dir.path}/$directory/$fileName";

      final file = File(fileDirectory);
      if (await file.exists()) return file;
    } catch (e) {
      _logger.log(e);
    }
    return null;
  }
}
