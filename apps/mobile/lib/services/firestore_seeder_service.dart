import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/app_logger.dart';

/// Service to seed authentic operational demo data into Cloud Firestore
/// for live multi-device demonstration across Admin, Dindi, Varkari, Volunteer, NGO, and Map systems.
class FirestoreSeederService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Seeds complete real-time demo dataset into Firestore.
  static Future<bool> seedAllDemoData() async {
    try {
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

      // 4. Seed Virtual Dindis
      const dindiId = 'vd_alandi_mauli_01';
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
        'meeting_point_lat': 18.6775,
        'meeting_point_lng': 73.8967,
        'safe_radius_meters': 75.0,
        'separation_threshold_meters': 150.0,
        'critical_threshold_meters': 300.0,
        'active_member_count': 3,
        'created_at': now,
        'updated_at': now,
      }, SetOptions(merge: true));

      // 5. Seed Virtual Dindi Members
      final membersRef = _db.collection('virtual_dindis').doc(dindiId).collection('members');

      await membersRef.doc(adminUid).set({
        'uid': adminUid,
        'display_name': 'Executive Command Admin (Leader)',
        'role': 'DINDI_LEADER',
        'member_status': 'ACTIVE',
        'joined_at': now,
        'last_latitude': 18.6775,
        'last_longitude': 73.8967,
        'accuracy_meters': 5.0,
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
        'last_latitude': 18.6776,
        'last_longitude': 73.8968,
        'accuracy_meters': 10.0,
        'last_location_at': now,
        'is_inside_dindi': true,
        'distance_from_group_meters': 12.0,
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
        'last_latitude': 18.6774,
        'last_longitude': 73.8966,
        'accuracy_meters': 8.0,
        'last_location_at': now,
        'is_inside_dindi': true,
        'distance_from_group_meters': 18.0,
        'separation_state': 'SAFE',
        'trend': 'STABLE_SEPARATION',
        'last_online_at': now,
        'is_leader': false,
      }, SetOptions(merge: true));

      // 6. Seed Sample Incidents
      await _db.collection('incidents').doc('inc_med_01').set({
        'id': 'inc_med_01',
        'reporter_id': 'usr_varkari_001',
        'reporter_name': 'Ramesh Kulkarni',
        'category': 'MEDICAL_EMERGENCY',
        'severity': 'CRITICAL',
        'status': 'ASSIGNED',
        'description': 'Pilgrim experienced heat exhaustion near Pune Station Sector 4',
        'latitude': 18.5285,
        'longitude': 73.8745,
        'assigned_volunteer_id': 'usr_vol_01',
        'assigned_volunteer_name': 'Inspector Vikram Singh',
        'created_at': now,
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
        'latitude': 18.6778,
        'longitude': 73.8968,
        'created_at': now,
        'updated_at': now,
      }, SetOptions(merge: true));

      // 7. Seed Sample NGO Resource Deployments
      await _db.collection('ngo_distributions').doc('ngo_dist_01').set({
        'id': 'ngo_dist_01',
        'ngo_id': 'usr_ngo_01',
        'ngo_name': 'Shiv Seva Foundation',
        'title': 'Alandi Gate 2 Annadan Seva',
        'description': 'Fresh hot meals & water distribution for all pilgrims',
        'category': 'FOOD',
        'quantity': 1000,
        'unit': 'meals',
        'latitude': 18.6780,
        'longitude': 73.8970,
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
        'quantity': 2500,
        'unit': 'liters',
        'latitude': 18.6300,
        'longitude': 73.8750,
        'location_name': 'Dighi Chowk Hydration Point',
        'status': 'ACTIVE',
        'created_at': now,
      }, SetOptions(merge: true));

      // 8. Seed Services / Facilities
      await _db.collection('services').doc('srv_food_01').set({
        'id': 'srv_food_01',
        'name': 'Alandi Annadan Camp',
        'layer': 'food',
        'latitude': 18.6780,
        'longitude': 73.8970,
        'capacity': 500,
        'queue_time_mins': 5,
        'available_now': true,
      }, SetOptions(merge: true));

      await _db.collection('services').doc('srv_water_02').set({
        'id': 'srv_water_02',
        'name': 'Dighi Pure Water Station',
        'layer': 'water',
        'latitude': 18.6300,
        'longitude': 73.8750,
        'capacity': 1000,
        'queue_time_mins': 2,
        'available_now': true,
      }, SetOptions(merge: true));

      await _db.collection('services').doc('srv_med_03').set({
        'id': 'srv_med_03',
        'name': 'Vishrantwadi Medical Camp',
        'layer': 'medical',
        'latitude': 18.5600,
        'longitude': 73.8650,
        'capacity': 200,
        'queue_time_mins': 0,
        'available_now': true,
      }, SetOptions(merge: true));

      await _db.collection('services').doc('srv_toilet_04').set({
        'id': 'srv_toilet_04',
        'name': 'Pune Station Mobile Toilet Block',
        'layer': 'toilets',
        'latitude': 18.5280,
        'longitude': 73.8740,
        'capacity': 50,
        'queue_time_mins': 3,
        'available_now': true,
      }, SetOptions(merge: true));

      await _db.collection('services').doc('srv_shelter_05').set({
        'id': 'srv_shelter_05',
        'name': 'Hadapsar Relief Rest Pavilion',
        'layer': 'shelters',
        'latitude': 18.5000,
        'longitude': 73.9300,
        'capacity': 300,
        'queue_time_mins': 0,
        'available_now': true,
      }, SetOptions(merge: true));

      AppLogger.i('Successfully seeded live demonstration data into Cloud Firestore!');
      return true;
    } catch (e, stack) {
      AppLogger.e('Error seeding live demo data into Cloud Firestore', e, stack);
      return false;
    }
  }
}
