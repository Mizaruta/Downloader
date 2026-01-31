import 'dart:convert';
import 'dart:io';
import 'package:modern_downloader/core/logger/logger_service.dart';
import 'package:modern_downloader/features/downloader/domain/entities/download_item.dart';
import 'package:path_provider/path_provider.dart';

class PersistenceService {
  static const String _fileName = 'downloads_v1.json';

  Future<void> saveDownloads(List<DownloadItem> downloads) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_fileName');

      final data = downloads.map((e) => e.toJson()).toList();
      final jsonString = jsonEncode(data);

      await file.writeAsString(jsonString);
      LoggerService.debug('Saved ${downloads.length} downloads to disk.');
    } catch (e) {
      LoggerService.e('Failed to save downloads', e);
    }
  }

  Future<List<DownloadItem>> loadDownloads() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_fileName');

      if (!await file.exists()) {
        LoggerService.i('No saved downloads found.');
        return [];
      }

      final jsonString = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(jsonString);

      final downloads = jsonList
          .map((e) => DownloadItem.fromJson(e as Map<String, dynamic>))
          .toList();

      LoggerService.i('Loaded ${downloads.length} downloads from disk.');
      return downloads;
    } catch (e) {
      LoggerService.e('Failed to load downloads', e);
      return [];
    }
  }
}
