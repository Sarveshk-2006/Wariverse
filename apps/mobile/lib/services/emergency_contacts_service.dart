import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/emergency_contact.dart';
import '../core/utils/app_logger.dart';

/// Service managing Emergency Contacts and Automated SMS Alert Dispatch (Ported & Extracted from WoShield2).
class EmergencyContactsService {
  static const String _contactsPrefKey = 'emergency_contacts';
  static const MethodChannel _smsChannel = MethodChannel('com.wariverse.mobile/sms');
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
    String? userId,
  }) async {
    final targetContacts = contacts.isNotEmpty ? contacts : await loadContacts(userId: userId);
    if (targetContacts.isEmpty) return;

    final String mapsUrl = 'https://maps.google.com/?q=$latitude,$longitude';
    final String alertText =
        'EMERGENCY ALERT!\n'
        'Type: $categoryName\n'
        'I am in danger. My real-time location: $mapsUrl\n'
        'Details: ${customMessage ?? "Immediate assistance requested."}';

    final phoneNumbers = targetContacts
        .map((c) => c.phoneNumber.replaceAll(RegExp(r'[^0-9+]'), ''))
        .where((p) => p.isNotEmpty)
        .toList();

    if (phoneNumbers.isEmpty) return;

    // 1. Attempt Native Direct Background SMS via SmsManager (WoShield Pattern)
    bool directSentAny = false;
    for (final phone in phoneNumbers) {
      try {
        final bool? ok = await _smsChannel.invokeMethod<bool>('sendDirectSMS', {
          'phoneNumber': phone,
          'message': alertText,
        });
        if (ok == true) {
          directSentAny = true;
          AppLogger.i('Direct background SMS dispatched via native SmsManager to $phone');
        }
      } catch (e) {
        AppLogger.w('Native SmsManager dispatch notice for $phone: $e');
      }
    }

    if (directSentAny) return;

    // 2. Fallback to URI intent launch if native SmsManager is unavailable
    final recipientString = phoneNumbers.join(',');
    final alertEncoded = Uri.encodeComponent(alertText);
    final Uri smsUri = Uri.parse('sms:$recipientString?body=$alertEncoded');

    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri, mode: LaunchMode.externalApplication);
      } else {
        final fallbackUri = Uri(
          scheme: 'sms',
          path: recipientString,
          queryParameters: <String, String>{'body': alertText},
        );
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      AppLogger.e('SMS dispatch notice for $recipientString: $e');
    }
  }

  /// Send direct custom SMS to a specific phone number.
  Future<bool> sendDirectSms({
    required String phoneNumber,
    required String message,
  }) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.isEmpty) return false;

    try {
      final bool? ok = await _smsChannel.invokeMethod<bool>('sendDirectSMS', {
        'phoneNumber': cleanPhone,
        'message': message,
      });
      if (ok == true) return true;
    } catch (_) {}

    final Uri smsUri = Uri(
      scheme: 'sms',
      path: cleanPhone,
      queryParameters: <String, String>{
        'body': message,
      },
    );

    try {
      if (await canLaunchUrl(smsUri)) {
        return await launchUrl(smsUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      AppLogger.e('Direct SMS launch failed for $cleanPhone', e);
    }
    return false;
  }
}
