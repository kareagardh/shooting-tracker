import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/shooting_result.dart';
import 'database_service.dart';

class BackupService {
  /// Zips all results + photos and opens the native share sheet.
  static Future<void> createBackup() async {
    final results = await DatabaseService.loadResults();
    final archive = Archive();

    // Build JSON with relative photo filenames so it works on any device.
    final backupJson = results.map((r) {
      final map = r.toJson();
      if (r.photoPath != null) {
        map['photoPath'] = File(r.photoPath!).uri.pathSegments.last;
      }
      return map;
    }).toList();

    final jsonBytes = utf8.encode(jsonEncode(backupJson));
    archive.addFile(ArchiveFile('shooting_results.json', jsonBytes.length, jsonBytes));

    // Add each photo that still exists on disk.
    for (final r in results) {
      if (r.photoPath == null) continue;
      final f = File(r.photoPath!);
      if (!f.existsSync()) continue;
      final bytes = f.readAsBytesSync();
      final name = f.uri.pathSegments.last;
      archive.addFile(ArchiveFile('photos/$name', bytes.length, bytes));
    }

    final zipBytes = ZipEncoder().encode(archive);
    if (zipBytes == null) throw Exception('Failed to encode backup ZIP');

    final tmp = await getTemporaryDirectory();
    final stamp = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
    final zipFile = File('${tmp.path}/shooting_backup_$stamp.zip');
    await zipFile.writeAsBytes(zipBytes);

    await Share.shareXFiles(
      [XFile(zipFile.path, mimeType: 'application/zip')],
      subject: 'Shooting Tracker backup $stamp',
    );
  }

  /// Lets the user pick a backup ZIP, extracts it and merges with existing data.
  /// Returns the number of new results added (duplicates by ID are skipped).
  /// Throws [FormatException] if the file is not a valid backup.
  static Future<int> restoreBackup() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      withData: true,
    );
    if (picked == null || picked.files.single.bytes == null) return 0;

    final archive = ZipDecoder().decodeBytes(picked.files.single.bytes!);

    final jsonEntry = archive.findFile('shooting_results.json');
    if (jsonEntry == null) {
      throw const FormatException('Not a valid backup — shooting_results.json missing');
    }

    final backupList =
        jsonDecode(utf8.decode(jsonEntry.content as List<int>)) as List<dynamic>;

    final existing = await DatabaseService.loadResults();
    final existingIds = {for (final r in existing) r.id};
    final docsDir = await getApplicationDocumentsDirectory();

    int added = 0;
    for (final raw in backupList) {
      final map = Map<String, dynamic>.from(raw as Map);
      final id = map['id'] as String;
      if (existingIds.contains(id)) continue;

      // Restore photo if present in the archive.
      String? newPhotoPath;
      final photoName = map['photoPath'] as String?;
      if (photoName != null) {
        final photoEntry = archive.findFile('photos/$photoName');
        if (photoEntry != null) {
          final dest = '${docsDir.path}/$photoName';
          await File(dest).writeAsBytes(photoEntry.content as List<int>);
          newPhotoPath = dest;
        }
      }

      existing.add(ShootingResult.fromJson({...map, 'photoPath': newPhotoPath}));
      existingIds.add(id);
      added++;
    }

    await DatabaseService.saveResults(existing);
    return added;
  }
}
