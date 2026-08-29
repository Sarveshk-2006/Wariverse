/// Centralized mock data for WariVerse AI.
/// Mirrors the MOCK_DATA object from lib/api.ts exactly.
/// Used when the FastAPI backend is unreachable (demo / offline mode).
abstract class MockDataSource {

  // ── Weather ───────────────────────────────────────────────────

  static Map<String, dynamic> get weather => {
        'temperature_c': 34.2,
        'feels_like_c': 38.0,
        'humidity_pct': 72,
        'wind_kmh': 12.0,
        'condition': 'Partly Cloudy',
        'rain_probability_pct': 35,
        'alerts': [
          {
            'id': 'w1',
            'alert_type': 'HEAT',
            'message': 'Heat advisory: Stay hydrated. High humidity expected.',
          }
        ],
      };

  // ── Crowd Zones ───────────────────────────────────────────────

  static List<Map<String, dynamic>> get crowdCurrent => [
        {
          'id': 'z1',
          'name': 'Vitthal Mandir Ghat',
          'crowd_level': 'RED',
          'current_density': 0.92,
          'estimated_count': 45000,
          'latitude': 17.6741,
          'longitude': 75.3279,
          'zone_type': 'TEMPLE',
        },
        {
          'id': 'z2',
          'name': 'Wakhari Camp Zone',
          'crowd_level': 'ORANGE',
          'current_density': 0.68,
          'estimated_count': 28000,
          'latitude': 17.6845,
          'longitude': 75.3160,
          'zone_type': 'CAMP',
        },
        {
          'id': 'z3',
          'name': 'Solapur Road Entry Gate',
          'crowd_level': 'YELLOW',
          'current_density': 0.45,
          'estimated_count': 18000,
          'latitude': 17.6650,
          'longitude': 75.3200,
          'zone_type': 'GATE',
        },
        {
          'id': 'z4',
          'name': 'Chandrabagha River Bank',
          'crowd_level': 'GREEN',
          'current_density': 0.22,
          'estimated_count': 9000,
          'latitude': 17.6720,
          'longitude': 75.3250,
          'zone_type': 'RIVER',
        },
      ];

  static Map<String, dynamic> get crowdPrediction => {
        'predictions': [
          {
            'zone_id': 'z1',
            'zone_name': 'Vitthal Mandir Ghat',
            'current_density': 0.92,
            'predicted_density_30min': 0.97,
            'risk_level': 'CRITICAL',
            'recommendation': 'Activate surge crowd protocol immediately.',
          },
          {
            'zone_id': 'z2',
            'zone_name': 'Wakhari Camp Zone',
            'current_density': 0.68,
            'predicted_density_30min': 0.75,
            'risk_level': 'HIGH',
            'recommendation': 'Deploy 3 additional volunteers.',
          },
        ],
      };

  // ── SOS ───────────────────────────────────────────────────────

  static List<Map<String, dynamic>> get sos => [
        {
          'id': 'sos1',
          'user_id': 'u1',
          'latitude': 17.6741,
          'longitude': 75.3285,
          'category': 'MEDICAL',
          'status': 'ACKNOWLEDGED',
          'description': 'Elderly pilgrim collapsed near Ghat gate.',
          'blood_group': 'A+',
          'emergency_contact': '+91 98765 43210',
          'is_offline': false,
          'responder_name': 'Dr. Priya Kulkarni',
          'responder_distance_m': 250.0,
          'created_at': DateTime.now()
              .subtract(const Duration(minutes: 8))
              .toIso8601String(),
          'resolved_at': null,
        },
        {
          'id': 'sos2',
          'user_id': 'u2',
          'latitude': 17.6850,
          'longitude': 75.3160,
          'category': 'LOST',
          'status': 'CREATED',
          'description': 'Lost child, age 7, wearing yellow kurta.',
          'blood_group': null,
          'emergency_contact': '+91 94210 11234',
          'is_offline': false,
          'responder_name': null,
          'responder_distance_m': null,
          'created_at': DateTime.now()
              .subtract(const Duration(minutes: 2))
              .toIso8601String(),
          'resolved_at': null,
        },
      ];

  // ── Food ──────────────────────────────────────────────────────

  static List<Map<String, dynamic>> get food => [
        {
          'id': 'f1',
          'name': 'Maharshi Annadan Kendra #1',
          'provider': 'ISKCON Seva Trust',
          'available_now': true,
          'current_count': 14200,
          'capacity': 20000,
          'estimated_queue_minutes': 10,
          'hygiene_rating': 4.9,
          'opening_time': '06:00',
          'closing_time': '23:00',
          'distance_m': 150,
          'walk_minutes': 2,
          'meal_types': ['LUNCH', 'DINNER'],
          'latitude': 17.6735,
          'longitude': 75.3270,
        },
        {
          'id': 'f2',
          'name': 'Shri Vitthal Mahaprasad Hall',
          'provider': 'Pandharpur Devasthan',
          'available_now': true,
          'current_count': 28500,
          'capacity': 35000,
          'estimated_queue_minutes': 25,
          'hygiene_rating': 4.8,
          'opening_time': '05:00',
          'closing_time': '23:30',
          'distance_m': 300,
          'walk_minutes': 4,
          'meal_types': ['BREAKFAST', 'LUNCH', 'DINNER'],
          'latitude': 17.6750,
          'longitude': 75.3285,
        },
        {
          'id': 'f3',
          'name': 'Wakhari Free Food Seva',
          'provider': 'Varkari Seva Samiti',
          'available_now': true,
          'current_count': 8900,
          'capacity': 15000,
          'estimated_queue_minutes': 5,
          'hygiene_rating': 4.7,
          'opening_time': '07:00',
          'closing_time': '22:00',
          'distance_m': 450,
          'walk_minutes': 5,
          'meal_types': ['BREAKFAST', 'LUNCH'],
          'latitude': 17.6845,
          'longitude': 75.3160,
        },
      ];

  // ── Water ─────────────────────────────────────────────────────

  static List<Map<String, dynamic>> get water => [
        {
          'id': 'w1',
          'name': 'Ghat Water Station Alpha',
          'latitude': 17.6730,
          'longitude': 75.3272,
          'status': 'AVAILABLE',
          'water_type': 'RO Purified',
          'capacity_liters': 5000,
          'distance_m': 120,
          'walk_minutes': 2,
        },
        {
          'id': 'w2',
          'name': 'Wakhari Community Tap Row',
          'latitude': 17.6840,
          'longitude': 75.3158,
          'status': 'AVAILABLE',
          'water_type': 'Municipal Treated',
          'capacity_liters': 3000,
          'distance_m': 420,
          'walk_minutes': 5,
        },
        {
          'id': 'w3',
          'name': 'Temple Complex Water Kiosk',
          'latitude': 17.6745,
          'longitude': 75.3280,
          'status': 'LOW',
          'water_type': 'Mineral Water',
          'capacity_liters': 500,
          'distance_m': 200,
          'walk_minutes': 3,
        },
      ];

  // ── Toilets ───────────────────────────────────────────────────

  static List<Map<String, dynamic>> get toilets => [
        {
          'id': 't1',
          'name': 'Mobile Sanitation Complex A',
          'latitude': 17.6735,
          'longitude': 75.3265,
          'status': 'CLEAN',
          'total_units': 20,
          'gender': 'mixed',
          'rating': 4.2,
          'last_cleaned_at': DateTime.now()
              .subtract(const Duration(hours: 1))
              .toIso8601String(),
        },
        {
          'id': 't2',
          'name': 'Ghat Sanitation Block B',
          'latitude': 17.6740,
          'longitude': 75.3295,
          'status': 'NEEDS_CLEANING',
          'total_units': 16,
          'gender': 'female',
          'rating': 3.8,
          'last_cleaned_at': DateTime.now()
              .subtract(const Duration(hours: 4))
              .toIso8601String(),
        },
      ];

  // ── Shelters ──────────────────────────────────────────────────

  static List<Map<String, dynamic>> get shelters => [
        {
          'id': 's1',
          'name': 'Pandharpur Relief Camp Alpha',
          'latitude': 17.6660,
          'longitude': 75.3180,
          'capacity': 500,
          'current_occupancy': 312,
          'available_now': true,
          'provider': 'District Administration',
          'amenities': ['Drinking Water', 'Basic Medical', 'Charging'],
        },
        {
          'id': 's2',
          'name': 'Varkari Rest Dharmashala',
          'latitude': 17.6780,
          'longitude': 75.3310,
          'capacity': 200,
          'current_occupancy': 185,
          'available_now': true,
          'provider': 'Varkari Seva Samiti',
          'amenities': ['Food', 'Drinking Water'],
        },
      ];

  // ── Medical ───────────────────────────────────────────────────

  static List<Map<String, dynamic>> get medical => [
        {
          'id': 'm1',
          'name': 'Pandharpur Government Hospital',
          'location_type': 'hospital',
          'latitude': 17.6710,
          'longitude': 75.3230,
          'services': ['Emergency', 'ICU', 'Surgery', 'Ambulance'],
          'available': true,
          'capacity': 200,
          'contact': '+91 2166 222100',
          'operating_hours': '24/7',
        },
        {
          'id': 'm2',
          'name': 'Ghat Zone First Aid Camp #1',
          'location_type': 'camp',
          'latitude': 17.6745,
          'longitude': 75.3275,
          'services': ['First Aid', 'ORS', 'Stretcher'],
          'available': true,
          'capacity': 30,
          'contact': null,
          'operating_hours': '06:00-22:00',
        },
        {
          'id': 'm3',
          'name': 'Mobile Medical Van B',
          'location_type': 'ambulance',
          'latitude': 17.6848,
          'longitude': 75.3155,
          'services': ['Emergency Response', 'Patient Transport'],
          'available': true,
          'capacity': 2,
          'contact': '108',
          'operating_hours': '24/7',
        },
      ];

  // ── Wellness ──────────────────────────────────────────────────

  static List<Map<String, dynamic>> get wellness => [
        {
          'id': 'wl1',
          'name': 'Ayurvedic Foot Care Seva #1',
          'latitude': 17.6735,
          'longitude': 75.3268,
          'services': ['Foot Massage', 'Blister Care', 'Oil Treatment'],
          'status': 'OPEN',
          'available_now': true,
          'waiting_pilgrims': 12,
        },
        {
          'id': 'wl2',
          'name': 'Pilgrim Rest and Stretch Camp',
          'latitude': 17.6760,
          'longitude': 75.3290,
          'services': ['Yoga and Rest', 'Hydration Salt Solution'],
          'status': 'OPEN',
          'available_now': true,
          'waiting_pilgrims': 4,
        },
      ];

  // ── Lost Persons ──────────────────────────────────────────────

  static List<Map<String, dynamic>> get lostPersons => [
        {
          'id': 'lp1',
          'name': 'Ramesh Kale',
          'age': 68,
          'gender': 'male',
          'description': 'Wearing white dhoti, has a walking stick. Diabetic.',
          'last_seen_latitude': 17.6741,
          'last_seen_longitude': 75.3279,
          'last_seen_at': DateTime.now()
              .subtract(const Duration(hours: 3))
              .toIso8601String(),
          'reported_by': 'u1',
          'emergency_contact': '+91 98765 12345',
          'blood_group': 'B+',
          'status': 'MISSING',
          'photo_url': null,
          'created_at': DateTime.now()
              .subtract(const Duration(hours: 3))
              .toIso8601String(),
          'updated_at': DateTime.now()
              .subtract(const Duration(hours: 3))
              .toIso8601String(),
        },
        {
          'id': 'lp2',
          'name': 'Priya (age 8)',
          'age': 8,
          'gender': 'female',
          'description': 'Yellow salwar, has a small red backpack.',
          'last_seen_latitude': 17.6850,
          'last_seen_longitude': 75.3165,
          'last_seen_at': DateTime.now()
              .subtract(const Duration(minutes: 45))
              .toIso8601String(),
          'reported_by': 'u2',
          'emergency_contact': '+91 94210 88776',
          'blood_group': null,
          'status': 'MISSING',
          'photo_url': null,
          'created_at': DateTime.now()
              .subtract(const Duration(minutes: 45))
              .toIso8601String(),
          'updated_at': DateTime.now()
              .subtract(const Duration(minutes: 45))
              .toIso8601String(),
        },
      ];

  // ── Community Posts ───────────────────────────────────────────

  static List<Map<String, dynamic>> get communityPosts => [
        {
          'id': 'cp1',
          'author_id': 'u2',
          'author_name': 'Anand Shinde',
          'post_type': 'WATER_AVAILABLE',
          'message': 'Free water pouches being distributed at Ghat Gate A. Come collect.',
          'latitude': 17.6740,
          'longitude': 75.3275,
          'radius_km': 1.0,
          'is_verified': true,
          'upvotes': 34,
          'created_at': DateTime.now()
              .subtract(const Duration(minutes: 20))
              .toIso8601String(),
          'expires_at': null,
        },
        {
          'id': 'cp2',
          'author_id': 'u1',
          'author_name': 'Santosh Tukaram',
          'post_type': 'ROUTE_WARNING',
          'message': 'Solapur Road entry is heavily congested. Use river route instead.',
          'latitude': 17.6660,
          'longitude': 75.3200,
          'radius_km': 3.0,
          'is_verified': false,
          'upvotes': 12,
          'created_at': DateTime.now()
              .subtract(const Duration(minutes: 45))
              .toIso8601String(),
          'expires_at': null,
        },
      ];

  // ── Notifications ─────────────────────────────────────────────

  static List<Map<String, dynamic>> get notifications => [
        {
          'id': 'n1',
          'user_id': 'u1',
          'title': 'Crowd Alert: Ghat Zone',
          'message':
              'Vitthal Mandir Ghat is at 92% capacity. Avoid the area for next 2 hours.',
          'notification_type': 'CROWD_ALERT',
          'priority': 'HIGH',
          'is_read': false,
          'data': null,
          'created_at': DateTime.now()
              .subtract(const Duration(minutes: 5))
              .toIso8601String(),
        },
        {
          'id': 'n2',
          'user_id': 'u1',
          'title': 'Food Seva Available',
          'message': 'Maharshi Annadan Kendra #1 has 6000 seats available now.',
          'notification_type': 'SERVICE_UPDATE',
          'priority': 'MEDIUM',
          'is_read': true,
          'data': null,
          'created_at': DateTime.now()
              .subtract(const Duration(hours: 1))
              .toIso8601String(),
        },
      ];

  // ── Admin Analytics ────────────────────────────────────────────

  static Map<String, dynamic> get adminAnalytics => {
        'total_pilgrims': 1400000,
        'active_volunteers': 3240,
        'open_sos_incidents': 8,
        'crowd_alerts': 3,
        'food_centres_active': 48,
        'water_points_active': 120,
        'medical_camps': 24,
      };

  // ── Police Routes ─────────────────────────────────────────────

  static List<Map<String, dynamic>> get policeRoutes => [
        {
          'id': 'r1',
          'route_name': 'Alandi - Pune - Pandharpur Palkhi Route',
          'status': 'HEAVY_CROWD',
          'advisory': 'Ringan procession active at Wakhari. Divert heavy vehicles via Bypass.',
          'active_pilgrims': 450000,
        },
        {
          'id': 'r2',
          'route_name': 'Dehu - Solapur - Pandharpur Route',
          'status': 'CLEAR',
          'advisory': 'Normal traffic movement.',
          'active_pilgrims': 280000,
        },
      ];

  // ── Volunteers (NGO) ──────────────────────────────────────────

  static List<Map<String, dynamic>> get volunteers => [
        {
          'id': 'v1',
          'name': 'Anand Shinde',
          'phone': '+91 98220 99887',
          'area': 'Ghat Zone A',
          'status': 'AVAILABLE',
          'tasks_completed': 14,
        },
        {
          'id': 'v2',
          'name': 'Sunita Patil',
          'phone': '+91 94210 33445',
          'area': 'Medical Camp 1',
          'status': 'ASSIGNED',
          'tasks_completed': 8,
        },
      ];

  // ── NGO Resources ─────────────────────────────────────────────

  static List<Map<String, dynamic>> get resources => [
        {
          'id': 'res1',
          'item_name': 'Drinking Water Pouches',
          'allocated': 50000,
          'remaining': 18500,
          'risk_level': 'LOW',
        },
        {
          'id': 'res2',
          'item_name': 'First Aid Medical Kits',
          'allocated': 500,
          'remaining': 80,
          'risk_level': 'MEDIUM',
        },
        {
          'id': 'res3',
          'item_name': 'Emergency Blankets',
          'allocated': 2000,
          'remaining': 1200,
          'risk_level': 'LOW',
        },
      ];

  // ── AI Recommendations ────────────────────────────────────────

  static Map<String, dynamic> get aiRecommendFood => {
        'explanation': 'Nearest food centres with shortest queue and best hygiene:',
        'recommendations': [
          {
            'name': 'Maharshi Annadan Kendra #1',
            'distance_m': 150,
            'walk_minutes': 2,
            'estimated_queue_minutes': 10,
            'ai_score': 9.8,
          },
          {
            'name': 'Wakhari Free Food Seva',
            'distance_m': 450,
            'walk_minutes': 5,
            'estimated_queue_minutes': 5,
            'ai_score': 9.4,
          },
          {
            'name': 'Shri Vitthal Mahaprasad Hall',
            'distance_m': 300,
            'walk_minutes': 4,
            'estimated_queue_minutes': 25,
            'ai_score': 8.2,
          },
        ],
      };

  static Map<String, dynamic> get aiRecommendWater => {
        'explanation': 'Nearest high-quality water stations:',
        'recommendations': [
          {
            'name': 'Ghat Water Station Alpha',
            'distance_m': 120,
            'walk_minutes': 2,
            'water_type': 'RO Purified',
            'ai_score': 9.9,
          },
        ],
      };

  // ── Mock Auth ─────────────────────────────────────────────────

  static const Map<String, Map<String, String>> demoUsers = {
    'varkari@wariverse.demo':   {'role': 'VARKARI', 'display_name': 'Santosh Tukaram'},
    'volunteer@wariverse.demo': {'role': 'VOLUNTEER', 'display_name': 'Anand Shinde'},
    'medical@wariverse.demo':   {'role': 'MEDICAL_TEAM', 'display_name': 'Dr. Priya Kulkarni'},
    'police@wariverse.demo':    {'role': 'POLICE', 'display_name': 'Inspector Deshmukh'},
    'ngo@wariverse.demo':       {'role': 'NGO', 'display_name': 'Seva Trust Coordinator'},
    'provider@wariverse.demo':  {'role': 'SERVICE_PROVIDER', 'display_name': 'Annadan Kendra Head'},
    'cleaner@wariverse.demo':   {'role': 'CLEANER', 'display_name': 'Swachhata Sevak Ramesh'},
    'admin@wariverse.demo':     {'role': 'ADMIN', 'display_name': 'Wari Control Admin'},
  };

  /// Returns mock login response for demo users.
  static Map<String, dynamic>? mockLogin(String email) {
    final user = demoUsers[email.toLowerCase()];
    if (user == null) return null;
    final role = user['role']!.toLowerCase();
    return {
      'access_token': 'demo-jwt-token-$role',
      'token_type': 'bearer',
      'user_id': 'demo-user-id-$role',
      'role': user['role'],
      'display_name': user['display_name'],
    };
  }
}
