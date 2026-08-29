import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/app_logger.dart';
import '../models/offline_map_snapshot.dart';

/// Production-ready Local Storage Service for Offline Wari Map Snapshots.
class OfflineMapStorageService {
  static final OfflineMapStorageService _instance = OfflineMapStorageService._internal();
  factory OfflineMapStorageService() => _instance;
  OfflineMapStorageService._internal();

  static const String _activeSnapshotKey = 'wari_active_offline_snapshot_id';
  static const String _snapshotIndexKey = 'wari_offline_snapshot_index';

  // In-memory fallback cache for fast retrieval and test environments
  OfflineMapSnapshot? _memoryCachedSnapshot;
  final Map<String, OfflineMapSnapshot> _memoryStore = {};

  /// Get directory for offline map files.
  Future<Directory?> _getStorageDir() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final offlineDir = Directory('${appDocDir.path}/offline_maps');
      if (!await offlineDir.exists()) {
        await offlineDir.create(recursive: true);
      }
      return offlineDir;
    } catch (e) {
      AppLogger.i('Storage directory notice (using in-memory fallback): $e');
      return null;
    }
  }

  /// Save snapshot atomically to local storage.
  Future<bool> saveSnapshot(OfflineMapSnapshot snapshot) async {
    try {
      final jsonString = jsonEncode(snapshot.toJson());
      _memoryStore[snapshot.snapshotId] = snapshot;
      _memoryCachedSnapshot = snapshot;

      final dir = await _getStorageDir();
      if (dir != null) {
        final tempFile = File('${dir.path}/temp_${snapshot.snapshotId}.json');
        final targetFile = File('${dir.path}/snapshot_${snapshot.snapshotId}.json');

        // Write temp file first for integrity
        await tempFile.writeAsString(jsonString, flush: true);

        // Validate JSON before replacing
        final checkContent = await tempFile.readAsString();
        final decoded = jsonDecode(checkContent);
        if (decoded is Map<String, dynamic> && decoded['snapshot_id'] == snapshot.snapshotId) {
          if (await targetFile.exists()) {
            await targetFile.delete();
          }
          await tempFile.rename(targetFile.path);
        } else {
          throw Exception('Corrupted snapshot file verification failed');
        }
      }

      // Update SharedPreferences index
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_activeSnapshotKey, snapshot.snapshotId);

      final indexList = prefs.getStringList(_snapshotIndexKey) ?? [];
      if (!indexList.contains(snapshot.snapshotId)) {
        indexList.add(snapshot.snapshotId);
        await prefs.setStringList(_snapshotIndexKey, indexList);
      }

      AppLogger.i('Offline map snapshot saved successfully: ${snapshot.snapshotId} (${snapshot.totalElementCount} elements)');
      return true;
    } catch (e) {
      AppLogger.i('Error saving offline map snapshot: $e');
      return false;
    }
  }

  /// Retrieve the latest valid offline snapshot.
  Future<OfflineMapSnapshot?> getLatestSnapshot() async {
    if (_memoryCachedSnapshot != null) {
      return _memoryCachedSnapshot;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final activeId = prefs.getString(_activeSnapshotKey);
      if (activeId == null) {
        if (_memoryStore.isNotEmpty) {
          return _memoryStore.values.last;
        }
        return null;
      }

      if (_memoryStore.containsKey(activeId)) {
        _memoryCachedSnapshot = _memoryStore[activeId];
        return _memoryCachedSnapshot;
      }

      final dir = await _getStorageDir();
      if (dir != null) {
        final file = File('${dir.path}/snapshot_$activeId.json');
        if (await file.exists()) {
          final content = await file.readAsString();
          final jsonMap = jsonDecode(content) as Map<String, dynamic>;
          final snapshot = OfflineMapSnapshot.fromJson(jsonMap);
          _memoryStore[activeId] = snapshot;
          _memoryCachedSnapshot = snapshot;
          return snapshot;
        }
      }
    } catch (e) {
      AppLogger.i('Error loading latest offline map snapshot: $e');
    }

    return _memoryStore.isNotEmpty ? _memoryStore.values.last : null;
  }

  /// Get list of all saved snapshot summaries.
  Future<List<OfflineMapSnapshot>> getAllSnapshots() async {
    final List<OfflineMapSnapshot> snapshots = [];

    try {
      final prefs = await SharedPreferences.getInstance();
      final indexList = prefs.getStringList(_snapshotIndexKey) ?? [];

      for (final id in indexList) {
        if (_memoryStore.containsKey(id)) {
          snapshots.add(_memoryStore[id]!);
          continue;
        }

        final dir = await _getStorageDir();
        if (dir != null) {
          final file = File('${dir.path}/snapshot_$id.json');
          if (await file.exists()) {
            final content = await file.readAsString();
            final snapshot = OfflineMapSnapshot.fromJson(jsonDecode(content));
            _memoryStore[id] = snapshot;
            snapshots.add(snapshot);
          }
        }
      }
    } catch (e) {
      AppLogger.i('Error retrieving snapshot index: $e');
    }

    if (snapshots.isEmpty && _memoryStore.isNotEmpty) {
      snapshots.addAll(_memoryStore.values);
    }

    snapshots.sort((a, b) => b.downloadedAt.compareTo(a.downloadedAt));
    return snapshots;
  }

  /// Delete a saved snapshot.
  Future<bool> deleteSnapshot(String snapshotId) async {
    try {
      _memoryStore.remove(snapshotId);
      if (_memoryCachedSnapshot?.snapshotId == snapshotId) {
        _memoryCachedSnapshot = null;
      }

      final dir = await _getStorageDir();
      if (dir != null) {
        final file = File('${dir.path}/snapshot_$snapshotId.json');
        if (await file.exists()) {
          await file.delete();
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final indexList = prefs.getStringList(_snapshotIndexKey) ?? [];
      indexList.remove(snapshotId);
      await prefs.setStringList(_snapshotIndexKey, indexList);

      if (prefs.getString(_activeSnapshotKey) == snapshotId) {
        await prefs.remove(_activeSnapshotKey);
      }

      return true;
    } catch (e) {
      AppLogger.i('Error deleting offline map snapshot: $e');
      return false;
    }
  }

  /// Clear all offline map data on user logout for security.
  Future<void> clearUserPrivateOfflineData() async {
    try {
      _memoryStore.clear();
      _memoryCachedSnapshot = null;

      final dir = await _getStorageDir();
      if (dir != null && await dir.exists()) {
        final files = dir.listSync();
        for (final entity in files) {
          if (entity is File) {
            await entity.delete();
          }
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_activeSnapshotKey);
      await prefs.remove(_snapshotIndexKey);
      AppLogger.i('Cleared private offline map data on logout.');
    } catch (e) {
      AppLogger.i('Notice during offline data purge: $e');
    }
  }
}
