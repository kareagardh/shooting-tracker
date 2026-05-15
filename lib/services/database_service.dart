import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/shooting_result.dart';

class DatabaseService {
  static const String _fileName = 'shooting_results.json';

  static Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  static Future<List<ShootingResult>> loadResults() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return [];
      final contents = await file.readAsString();
      final list = jsonDecode(contents) as List<dynamic>;
      return list
          .map((j) => ShootingResult.fromJson(j as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveResults(List<ShootingResult> results) async {
    final file = await _getFile();
    await file.writeAsString(jsonEncode(results.map((r) => r.toJson()).toList()));
  }

  static Future<void> addResult(ShootingResult result) async {
    final results = await loadResults();
    results.add(result);
    await saveResults(results);
  }

  static Future<void> deleteResult(String id) async {
    final results = await loadResults();
    final target = results.where((r) => r.id == id).firstOrNull;
    if (target?.photoPath != null) {
      final photo = File(target!.photoPath!);
      if (photo.existsSync()) photo.deleteSync();
    }
    results.removeWhere((r) => r.id == id);
    await saveResults(results);
  }
}
