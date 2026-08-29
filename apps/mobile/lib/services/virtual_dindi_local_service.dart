import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/virtual_dindi_model.dart';
import '../core/utils/app_logger.dart';

/// Local Persistence and Offline Event Queue Service for Virtual Dindi.
class VirtualDindiLocalService {
  static const String _keyActiveDindi = 'wari_virtual_dindi_active';
  static const String _keyMembers = 'wari_virtual_dindi_members';
  static const String _keyOfflineEvents = 'wari_virtual_dindi_offline_events';
  static const String _keyGroupCenter = 'wari_virtual_dindi_group_center';

  /// Saves active Virtual Dindi metadata to local storage.
  static Future<void> saveActiveDindi(VirtualDindi dindi) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyActiveDindi, jsonEncode(dindi.toJson()));
      AppLogger.i('Saved active Virtual Dindi locally: ${dindi.dindiId}');
    } catch (e) {
      AppLogger.e('Failed to save active Virtual Dindi locally', e);
    }
  }

  /// Retrieves cached active Virtual Dindi from local storage.
  static Future<VirtualDindi?> getActiveDindi() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyActiveDindi);
      if (raw == null || raw.isEmpty) return null;
      return VirtualDindi.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      AppLogger.e('Failed to read cached Virtual Dindi', e);
      return null;
    }
  }

  /// Clears active Virtual Dindi from local storage.
  static Future<void> clearActiveDindi() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyActiveDindi);
      await prefs.remove(_keyMembers);
      await prefs.remove(_keyGroupCenter);
      AppLogger.i('Cleared local Virtual Dindi cache.');
    } catch (e) {
      AppLogger.e('Failed to clear Virtual Dindi local cache', e);
    }
  }

  /// Caches member list locally.
  static Future<void> saveMembers(List<VirtualDindiMember> members) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = members.map((m) => m.toJson()).toList();
      await prefs.setString(_keyMembers, jsonEncode(jsonList));
    } catch (e) {
      AppLogger.e('Failed to cache Dindi members locally', e);
    }
  }

  /// Retrieves cached member list.
  static Future<List<VirtualDindiMember>> getMembers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyMembers);
      if (raw == null || raw.isEmpty) return [];
      final List list = jsonDecode(raw) as List;
      return list.map((item) => VirtualDindiMember.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      AppLogger.e('Failed to read cached Dindi members', e);
      return [];
    }
  }

  /// Caches last known group center.
  static Future<void> saveGroupCenter(double lat, double lng) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyGroupCenter, jsonEncode({'lat': lat, 'lng': lng, 'timestamp': DateTime.now().toIso8601String()}));
    } catch (e) {
      AppLogger.e('Failed to save group center locally', e);
    }
  }

  /// Retrieves last known group center.
  static Future<Map<String, dynamic>?> getGroupCenter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyGroupCenter);
      if (raw == null || raw.isEmpty) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Queue an event generated while offline.
  static Future<void> queueOfflineEvent(VirtualDindiEvent event) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<VirtualDindiEvent> existing = await getQueuedOfflineEvents();
      
      // Avoid duplicate event queuing
      if (!existing.any((e) => e.eventId == event.eventId)) {
        existing.add(event);
        final jsonList = existing.map((e) => e.toJson()).toList();
        await prefs.setString(_keyOfflineEvents, jsonEncode(jsonList));
        AppLogger.i('Queued offline Virtual Dindi event: ${event.type.name} (ID: ${event.eventId})');
      }
    } catch (e) {
      AppLogger.e('Failed to queue offline Virtual Dindi event', e);
    }
  }

  /// Retrieves all queued offline events.
  static Future<List<VirtualDindiEvent>> getQueuedOfflineEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyOfflineEvents);
      if (raw == null || raw.isEmpty) return [];
      final List list = jsonDecode(raw) as List;
      return list.map((item) => VirtualDindiEvent.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      AppLogger.e('Failed to read queued offline events', e);
      return [];
    }
  }

  /// Clears queued offline events after successful sync.
  static Future<void> clearQueuedOfflineEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyOfflineEvents);
      AppLogger.i('Cleared queued offline Virtual Dindi events.');
    } catch (e) {
      AppLogger.e('Failed to clear queued offline events', e);
    }
  }
}
