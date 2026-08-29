import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/emergency_contact.dart';
import '../core/utils/app_logger.dart';

/// Service managing Emergency Contacts and Automated SMS Alert Dispatch (Extracted from WoShield2).
class EmergencyContactsService {
  static const String _contactsPrefKey = 'emergency_contacts';
  late final FirebaseFirestore? _firestore;

  EmergencyContactsService({FirebaseFirestore? firestore}) {
    try {
      _firestore = firestore ?? FirebaseFirestore.instance;
    } catch (_) {
      _firestore = null;
    }
  }

  /// Load emergency contacts from SharedPreferences with fallback to Firestore.
  Future<List<EmergencyContact>> loadContacts({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_contactsPrefKey);
    List<EmergencyContact> localContacts = [];

    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(jsonStr);
        localContacts = list.map((e) => EmergencyContact.fromJson(Map<String, dynamic>.from(e))).toList();
      } catch (e) {
        AppLogger.i('Error parsing local contacts: $e');
      }
    }

    if (localContacts.isNotEmpty) return localContacts;

    // Fetch from Firestore if local cache empty
    if (userId != null && _firestore != null) {
      try {
        final snap = await _firestore.collection('users').doc(userId).collection('emergency_contacts').get();
        final fetched = snap.docs.map((doc) => EmergencyContact.fromJson(doc.data())).toList();
        if (fetched.isNotEmpty) {
          await saveContacts(fetched, userId: userId);
          return fetched;
        }
      } catch (_) {}
    }

    // Default sample emergency contacts for instant readiness
    final defaultContacts = [
      EmergencyContact(
        id: 'cnt_01',
        name: 'Primary Family Guardian',
        phoneNumber: '+919822011111',
        relationship: 'Family',
        createdAt: DateTime.now().toIso8601String(),
      ),
      EmergencyContact(
        id: 'cnt_02',
        name: 'Palkhi Emergency Helpline',
        phoneNumber: '112',
        relationship: 'Official Helpline',
        createdAt: DateTime.now().toIso8601String(),
      ),
    ];
    await saveContacts(defaultContacts, userId: userId);
    return defaultContacts;
  }

  /// Save emergency contacts locally and sync to Firestore.
  Future<void> saveContacts(List<EmergencyContact> contacts, {String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = contacts.map((c) => c.toJson()).toList();
    await prefs.setString(_contactsPrefKey, jsonEncode(jsonList));

    if (userId != null && _firestore != null) {
      try {
        final batch = _firestore.batch();
        final colRef = _firestore.collection('users').doc(userId).collection('emergency_contacts');
        for (final contact in contacts) {
          batch.set(colRef.doc(contact.id), contact.toJson());
        }
        await batch.commit();
      } catch (e) {
        AppLogger.i('Firestore contact sync notice: $e');
      }
    }
  }

  /// Add a new emergency contact.
  Future<List<EmergencyContact>> addContact(EmergencyContact contact, {String? userId}) async {
    final current = await loadContacts(userId: userId);
    current.add(contact);
    await saveContacts(current, userId: userId);
    return current;
  }

  /// Delete an emergency contact by ID.
  Future<List<EmergencyContact>> deleteContact(String contactId, {String? userId}) async {
    final current = await loadContacts(userId: userId);
    current.removeWhere((c) => c.id == contactId);
    await saveContacts(current, userId: userId);

    if (userId != null && _firestore != null) {
      try {
        await _firestore.collection('users').doc(userId).collection('emergency_contacts').doc(contactId).delete();
      } catch (_) {}
    }
    return current;
  }

  /// Dispatch emergency SMS alert to all registered contacts with live Google Maps link.
  Future<void> dispatchEmergencySmsAlert({
    required List<EmergencyContact> contacts,
    required double latitude,
    required double longitude,
    required String categoryName,
    String? customMessage,
  }) async {
    if (contacts.isEmpty) return;

    final String mapsUrl = 'https://maps.google.com/?q=$latitude,$longitude';
    final String alertText =
        '🚨 EMERGENCY WARIVERSE ALERT! 🚨\n'
        'Type: $categoryName\n'
        'Live Location: $mapsUrl\n'
        'Details: ${customMessage ?? "Immediate assistance requested."}\n'
        'Please contact responder immediately!';

    for (final contact in contacts) {
      final phone = contact.phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
      if (phone.isEmpty) continue;

      final Uri smsUri = Uri(
        scheme: 'sms',
        path: phone,
        queryParameters: <String, String>{
          'body': alertText,
        },
      );

      try {
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        AppLogger.e('SMS dispatch warning for number $phone', e);
      }
    }
  }
}
