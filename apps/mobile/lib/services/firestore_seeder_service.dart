import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/app_logger.dart';

/// Service to seed authentic operational demo data into Cloud Firestore
/// with dynamic real-time random variations and clean deduplication across Admin, Dindi, Varkari, Volunteer, NGO, and Map systems.
class FirestoreSeederService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Seeds complete real-time demo dataset into Firestore with dynamic random telemetry.
  static Future<bool> seedAllDemoData() async {
    try {
      final rng = Random();
      final now = DateTime.now().toIso8601String();

      // 1. Seed Admin User Account
      const adminUid = '0JNFDa2v1LcBfcDj2gsFwTRUtDd2';
      await _db.collection('users').doc(adminUid).set({
        'uid': adminUid,
        'email': 'admin@wariverse.demo',
        'display_name': 'Executive Command Admin',
        'role': 'ADMIN',
        'is_active': true,
        'volunteer_enabled': false,
        'volunteer_status': 'NONE',
        'volunteer_available': false,
        'dindi_leader_status': 'APPROVED',
        'sanitation_status': 'APPROVED',
        'ngo_status': 'APPROVED',
        'dindi_id': 'vd_alandi_mauli_01',
        'dindi_code': 'VDND-1008',
        'created_at': now,
        'updated_at': now,
      }, SetOptions(merge: true));

      await _db.collection('profiles').doc(adminUid).set({
        'uid': adminUid,
        'full_name': 'Executive Command Admin',
        'role': 'ADMIN',
        'created_at': now,
      }, SetOptions(merge: true));

      // 2. Seed Sample Varkari Users
      await _db.collection('users').doc('usr_varkari_001').set({
        'uid': 'usr_varkari_001',
        'email': 'varkari1@wariverse.ai',
        'display_name': 'Ramesh Kulkarni',
        'role': 'VARKARI',
        'is_active': true,
        'dindi_id': 'vd_alandi_mauli_01',
        'dindi_code': 'VDND-1008',
        'created_at': now,
      }, SetOptions(merge: true));

      await _db.collection('users').doc('usr_varkari_002').set({
        'uid': 'usr_varkari_002',
        'email': 'varkari2@wariverse.ai',
        'display_name': 'Sunita Patil',
        'role': 'VARKARI',
        'is_active': true,
        'dindi_id': 'vd_alandi_mauli_01',
        'dindi_code': 'VDND-1008',
        'created_at': now,
      }, SetOptions(merge: true));

      // 3. Seed Sample Volunteer & NGO Users
      await _db.collection('users').doc('usr_vol_01').set({
        'uid': 'usr_vol_01',
        'email': 'volunteer1@wariverse.ai',
        'display_name': 'Inspector Vikram Singh',
        'role': 'VOLUNTEER',
        'is_active': true,
        'volunteer_enabled': true,
        'volunteer_status': 'APPROVED',
        'volunteer_available': true,
        'created_at': now,
      }, SetOptions(merge: true));

      await _db.collection('users').doc('usr_ngo_01').set({
        'uid': 'usr_ngo_01',
        'email': 'ngo1@wariverse.ai',
        'display_name': 'Shiv Seva Foundation',
        'role': 'NGO',
        'is_active': true,
        'ngo_status': 'APPROVED',
        'created_at': now,
      }, SetOptions(merge: true));

      // 4. Seed Virtual Dindis with Dynamic Member Counts
      const dindiId = 'vd_alandi_mauli_01';
      final activeCount = rng.nextInt(50) + 120;
      await _db.collection('virtual_dindis').doc(dindiId).set({
        'dindi_id': dindiId,
        'name': 'Alandi Mauli Palkhi Dindi',
        'description': 'Main Palkhi Dindi procession traveling from Alandi to Pandharpur',
        'join_code': 'VDND-1008',
        'qr_token': 'WV_DINDI:$dindiId',
        'leader_uid': adminUid,
        'leader_name': 'Executive Command Admin',
        'leader_phone': '+91 98220 12345',
        'status': 'ACTIVE',
        'meeting_point_name': 'Alandi Temple Main Gate',
        'meeting_point_lat': 18.6775 + (rng.nextDouble() - 0.5) * 0.001,
        'meeting_point_lng': 73.8967 + (rng.nextDouble() - 0.5) * 0.001,
        'safe_radius_meters': 75.0,
        'separation_threshold_meters': 150.0,
        'critical_threshold_meters': 300.0,
        'active_member_count': activeCount,
        'created_at': now,
        'updated_at': now,
      }, SetOptions(merge: true));

      // 5. Seed Virtual Dindi Members with Real-Time Dynamic Location Variations
      final membersRef = _db.collection('virtual_dindis').doc(dindiId).collection('members');

      await membersRef.doc(adminUid).set({
        'uid': adminUid,
        'display_name': 'Executive Command Admin (Leader)',
        'role': 'DINDI_LEADER',
        'member_status': 'ACTIVE',
        'joined_at': now,
        'last_latitude': 18.6775 + (rng.nextDouble() - 0.5) * 0.0005,
        'last_longitude': 73.8967 + (rng.nextDouble() - 0.5) * 0.0005,
        'accuracy_meters': (rng.nextDouble() * 5.0 + 3.0),
        'last_location_at': now,
        'is_inside_dindi': true,
        'distance_from_group_meters': 0.0,
        'separation_state': 'SAFE',
        'trend': 'STABLE_SEPARATION',
        'last_online_at': now,
        'is_leader': true,
      }, SetOptions(merge: true));

      await membersRef.doc('usr_varkari_001').set({
        'uid': 'usr_varkari_001',
        'display_name': 'Ramesh Kulkarni',
        'role': 'VARKARI',
        'member_status': 'ACTIVE',
        'joined_at': now,
        'last_latitude': 18.6776 + (rng.nextDouble() - 0.5) * 0.0008,
        'last_longitude': 73.8968 + (rng.nextDouble() - 0.5) * 0.0008,
        'accuracy_meters': (rng.nextDouble() * 8.0 + 5.0),
        'last_location_at': now,
        'is_inside_dindi': true,
        'distance_from_group_meters': (rng.nextInt(25) + 5).toDouble(),
        'separation_state': 'SAFE',
        'trend': 'CLOSING_IN',
        'last_online_at': now,
        'is_leader': false,
      }, SetOptions(merge: true));

      await membersRef.doc('usr_varkari_002').set({
        'uid': 'usr_varkari_002',
        'display_name': 'Sunita Patil',
        'role': 'VARKARI',
        'member_status': 'ACTIVE',
        'joined_at': now,
        'last_latitude': 18.6774 + (rng.nextDouble() - 0.5) * 0.0008,
        'last_longitude': 73.8966 + (rng.nextDouble() - 0.5) * 0.0008,
        'accuracy_meters': (rng.nextDouble() * 6.0 + 4.0),
        'last_location_at': now,
        'is_inside_dindi': true,
        'distance_from_group_meters': (rng.nextInt(30) + 10).toDouble(),
        'separation_state': 'SAFE',
        'trend': 'STABLE_SEPARATION',
        'last_online_at': now,
        'is_leader': false,
      }, SetOptions(merge: true));

      // 6. Seed Incidents with Dynamic Timestamps & Coordinates
      await _db.collection('incidents').doc('inc_med_01').set({
        'id': 'inc_med_01',
        'reporter_id': 'usr_varkari_001',
        'reporter_name': 'Ramesh Kulkarni',
        'category': 'MEDICAL_EMERGENCY',
        'severity': 'CRITICAL',
        'status': 'ASSIGNED',
        'description': 'Pilgrim experienced heat exhaustion near Pune Station Sector 4',
        'latitude': 18.5285 + (rng.nextDouble() - 0.5) * 0.002,
        'longitude': 73.8745 + (rng.nextDouble() - 0.5) * 0.002,
        'assigned_volunteer_id': 'usr_vol_01',
        'assigned_volunteer_name': 'Inspector Vikram Singh',
        'created_at': DateTime.now().subtract(Duration(minutes: rng.nextInt(30) + 5)).toIso8601String(),
        'updated_at': now,
      }, SetOptions(merge: true));

      await _db.collection('incidents').doc('inc_lost_02').set({
        'id': 'inc_lost_02',
        'reporter_id': 'usr_varkari_002',
        'reporter_name': 'Sunita Patil',
        'category': 'LOST_PERSON',
        'severity': 'HIGH',
        'status': 'ACKNOWLEDGED',
        'description': 'Child missing near Alandi Gate 2 main pavilion',
        'latitude': 18.6778 + (rng.nextDouble() - 0.5) * 0.002,
        'longitude': 73.8968 + (rng.nextDouble() - 0.5) * 0.002,
        'created_at': DateTime.now().subtract(Duration(minutes: rng.nextInt(45) + 10)).toIso8601String(),
        'updated_at': now,
      }, SetOptions(merge: true));

      // 7. Seed Sample NGO Resource Deployments with Real-Time Dynamic Counts
      await _db.collection('ngo_distributions').doc('ngo_dist_01').set({
        'id': 'ngo_dist_01',
        'ngo_id': 'usr_ngo_01',
        'ngo_name': 'Shiv Seva Foundation',
        'title': 'Alandi Gate 2 Annadan Seva',
        'description': 'Fresh hot meals & water distribution for all pilgrims',
        'category': 'FOOD',
        'quantity': rng.nextInt(500) + 800,
        'unit': 'meals',
        'latitude': 18.6780 + (rng.nextDouble() - 0.5) * 0.001,
        'longitude': 73.8970 + (rng.nextDouble() - 0.5) * 0.001,
        'location_name': 'Alandi Gate 2 Main Pavilion',
        'status': 'ACTIVE',
        'created_at': now,
      }, SetOptions(merge: true));

      await _db.collection('ngo_distributions').doc('ngo_dist_02').set({
        'id': 'ngo_dist_02',
        'ngo_id': 'usr_ngo_01',
        'ngo_name': 'Wari Seva Trust',
        'title': 'Dighi ORS & Water Station',
        'description': 'Clean drinking water & electrolyte solution for walking pilgrims',
        'category': 'WATER',
        'quantity': rng.nextInt(1000) + 2000,
        'unit': 'liters',
        'latitude': 18.6300 + (rng.nextDouble() - 0.5) * 0.001,
        'longitude': 73.8750 + (rng.nextDouble() - 0.5) * 0.001,
        'location_name': 'Dighi Chowk Hydration Point',
        'status': 'ACTIVE',
        'created_at': now,
      }, SetOptions(merge: true));

      // 8. Seed Food Centers (Dynamic Capacities, Queue Times, Hygiene Ratings)
      await _db.collection('food_centers').doc('fc_01').set({
        'id': 'fc_01',
        'name': 'Alandi Annadan Seva Camp',
        'provider': 'Shiv Seva Foundation',
        'latitude': 18.6780 + (rng.nextDouble() - 0.5) * 0.001,
        'longitude': 73.8970 + (rng.nextDouble() - 0.5) * 0.001,
        'capacity': 500,
        'current_count': rng.nextInt(300) + 50,
        'estimated_queue_minutes': rng.nextInt(10) + 2,
        'available_now': true,
        'hygiene_rating': double.parse((4.5 + rng.nextDouble() * 0.5).toStringAsFixed(1)),
        'opening_time': '05:00',
        'closing_time': '23:00',
        'meal_types': ['MAHAPRASAD', 'TEA_SNACKS', 'FRUITS'],
        'address': 'Alandi Temple Ghat Road, Alandi',
      }, SetOptions(merge: true));

      await _db.collection('food_centers').doc('fc_02').set({
        'id': 'fc_02',
        'name': 'Vishrantwadi Mahaprasad Pavilion',
        'provider': 'Wari Seva Trust',
        'latitude': 18.5600 + (rng.nextDouble() - 0.5) * 0.001,
        'longitude': 73.8650 + (rng.nextDouble() - 0.5) * 0.001,
        'capacity': 800,
        'current_count': rng.nextInt(400) + 150,
        'estimated_queue_minutes': rng.nextInt(12) + 4,
        'available_now': true,
        'hygiene_rating': double.parse((4.4 + rng.nextDouble() * 0.5).toStringAsFixed(1)),
        'opening_time': '06:00',
        'closing_time': '22:00',
        'meal_types': ['MAHAPRASAD', 'PACKED_LUNCH'],
        'address': 'Vishrantwadi Main Chowk, Pune',
      }, SetOptions(merge: true));

      await _db.collection('food_centers').doc('fc_03').set({
        'id': 'fc_03',
        'name': 'Hadapsar Solapur Annadan Ground',
        'provider': 'Pandharpur Seva Mandal',
        'latitude': 18.5000 + (rng.nextDouble() - 0.5) * 0.001,
        'longitude': 73.9300 + (rng.nextDouble() - 0.5) * 0.001,
        'capacity': 1200,
        'current_count': rng.nextInt(600) + 200,
        'estimated_queue_minutes': rng.nextInt(15) + 3,
        'available_now': true,
        'hygiene_rating': double.parse((4.6 + rng.nextDouble() * 0.4).toStringAsFixed(1)),
        'opening_time': '05:30',
        'closing_time': '23:30',
        'meal_types': ['MAHAPRASAD', 'BREAKFAST', 'ORS_DRINKS'],
        'address': 'Hadapsar Solapur Highway Ground, Pune',
      }, SetOptions(merge: true));

      // 9. Seed Water Points
      await _db.collection('water_points').doc('wp_01').set({
        'id': 'wp_01',
        'name': 'Dighi Pure ORS & Water Tanker',
        'latitude': 18.6300 + (rng.nextDouble() - 0.5) * 0.001,
        'longitude': 73.8750 + (rng.nextDouble() - 0.5) * 0.001,
        'status': 'AVAILABLE',
        'water_type': 'DRINKING_WATER',
        'capacity_liters': (rng.nextInt(4) + 3) * 1000,
      }, SetOptions(merge: true));

      await _db.collection('water_points').doc('wp_02').set({
        'id': 'wp_02',
        'name': 'Pune Station Hydration Kiosk',
        'latitude': 18.5280 + (rng.nextDouble() - 0.5) * 0.001,
        'longitude': 73.8740 + (rng.nextDouble() - 0.5) * 0.001,
        'status': 'AVAILABLE',
        'water_type': 'DRINKING_WATER',
        'capacity_liters': (rng.nextInt(3) + 2) * 1000,
      }, SetOptions(merge: true));

      // 10. Seed Toilets & Sanitation Blocks
      await _db.collection('toilets').doc('tp_01').set({
        'id': 'tp_01',
        'name': 'Pune Station Mobile Sanitation Complex',
        'latitude': 18.5280 + (rng.nextDouble() - 0.5) * 0.001,
        'longitude': 73.8740 + (rng.nextDouble() - 0.5) * 0.001,
        'total_units': 30,
        'occupied_units': rng.nextInt(20) + 2,
        'clean_status': 'CLEAN',
        'gender': 'UNISEX',
        'is_accessible': true,
      }, SetOptions(merge: true));

      await _db.collection('toilets').doc('tp_02').set({
        'id': 'tp_02',
        'name': 'Alandi Ghat Sanitation Block',
        'latitude': 18.6775 + (rng.nextDouble() - 0.5) * 0.001,
        'longitude': 73.8980 + (rng.nextDouble() - 0.5) * 0.001,
        'total_units': 20,
        'occupied_units': rng.nextInt(12) + 1,
        'clean_status': 'CLEAN',
        'gender': 'UNISEX',
        'is_accessible': true,
      }, SetOptions(merge: true));

      // 11. Seed Shelters (Dynamic Available Bed Counts)
      await _db.collection('shelters').doc('sh_01').set({
        'id': 'sh_01',
        'name': 'Hadapsar Relief Rest Tent',
        'latitude': 18.5000 + (rng.nextDouble() - 0.5) * 0.001,
        'longitude': 73.9300 + (rng.nextDouble() - 0.5) * 0.001,
        'total_beds': 200,
        'available_beds': rng.nextInt(110) + 40,
        'has_medical_support': true,
      }, SetOptions(merge: true));

      // 12. Seed Medical Locations & Wellness Centers
      await _db.collection('medical_locations').doc('ml_01').set({
        'id': 'ml_01',
        'name': 'Vishrantwadi Emergency Medical Aid Post',
        'latitude': 18.5600 + (rng.nextDouble() - 0.5) * 0.001,
        'longitude': 73.8650 + (rng.nextDouble() - 0.5) * 0.001,
        'doctor_count': rng.nextInt(4) + 3,
        'ambulance_available': true,
        'emergency_contact': '108',
      }, SetOptions(merge: true));

      await _db.collection('wellness_centers').doc('wc_01').set({
        'id': 'wc_01',
        'name': 'Alandi Foot Massage & Seva Kendra',
        'latitude': 18.6780 + (rng.nextDouble() - 0.5) * 0.001,
        'longitude': 73.8970 + (rng.nextDouble() - 0.5) * 0.001,
        'volunteers_count': rng.nextInt(15) + 10,
        'is_free_service': true,
      }, SetOptions(merge: true));

      // 13. Seed Consolidated Services Collection for Map Filtering
      await _db.collection('services').doc('srv_food_01').set({
        'id': 'srv_food_01',
        'name': 'Alandi Annadan Camp',
        'layer': 'food',
        'latitude': 18.6780 + (rng.nextDouble() - 0.5) * 0.001,
        'longitude': 73.8970 + (rng.nextDouble() - 0.5) * 0.001,
        'capacity': 500,
        'queue_time_mins': rng.nextInt(10) + 2,
        'available_now': true,
      }, SetOptions(merge: true));

      await _db.collection('services').doc('srv_water_01').set({
        'id': 'srv_water_01',
        'name': 'Dighi Hydration Tanker',
        'layer': 'water',
        'latitude': 18.6300 + (rng.nextDouble() - 0.5) * 0.001,
        'longitude': 73.8750 + (rng.nextDouble() - 0.5) * 0.001,
        'available_now': true,
      }, SetOptions(merge: true));

      // 14. Seed CleanWari Sanitation Schedules
      await _db.collection('clean_wari_schedules').doc('clean_01').set({
        'id': 'clean_01',
        'sector': 'Alandi Ghat Sector 1',
        'cleaner_id': 'usr_cleaner_01',
        'cleaner_name': 'Santosh Jadhav',
        'status': 'IN_PROGRESS',
        'last_cleaned_at': now,
        'created_at': now,
      }, SetOptions(merge: true));

      // 15. Seed Community Announcements
      await _db.collection('palkhi_announcements').doc('anc_01').set({
        'id': 'anc_01',
        'title': 'Alandi Palkhi Departure Notice',
        'message': 'Palkhi procession moving towards Vishrantwadi. Please follow sector 2 route guidelines.',
        'author': 'Executive Command Admin',
        'priority': 'HIGH',
        'created_at': now,
      }, SetOptions(merge: true));

      AppLogger.i('Successfully seeded live dynamic real-time demonstration data into Cloud Firestore!');
      return true;
    } catch (e, stack) {
      AppLogger.e('Error seeding live demo data into Cloud Firestore', e, stack);
      return false;
    }
  }
}
