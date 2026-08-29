import '../models/models_exports.dart';
import '../services/api_service.dart';
import '../services/mock_dindi_data.dart';

/// Repository handling Dindi operations and micro-schedules with mock data fallback.
class DindiRepository {
  final ApiService _apiService;

  DindiRepository(this._apiService);

  /// Returns all available Dindis along the Wari route.
  Future<List<Dindi>> fetchDindis() async {
    try {
      final res = await _apiService.get('/dindis');
      if (res is List) {
        return res.map((item) => Dindi.fromJson(item as Map<String, dynamic>)).toList();
      }
      return MockDindiData.dindis;
    } catch (_) {
      // Backend Dindi endpoints not available yet -> seamless mock fallback
      return MockDindiData.dindis;
    }
  }

  /// Returns a specific Dindi by ID.
  Future<Dindi?> getDindiById(String dindiId) async {
    final list = await fetchDindis();
    return list.firstWhere(
      (d) => d.id == dindiId,
      orElse: () => MockDindiData.dindis.first,
    );
  }

  /// Returns active Dindi membership for the user if joined.
  Future<DindiMember?> getUserMembership(String userId, {String? activeDindiId}) async {
    if (activeDindiId == null || activeDindiId.isEmpty) return null;
    return MockDindiData.mockMember(dindiId: activeDindiId, userId: userId);
  }

  /// Registers user membership to a Dindi (local demo state handling).
  Future<DindiMember> joinDindi(String dindiId, String userId, {String userName = 'Pilgrim'}) async {
    return DindiMember(
      dindiId: dindiId,
      userId: userId,
      userName: userName,
      userRole: 'VARKARI',
      status: DindiMembershipStatus.active,
      joinedAt: DateTime.now(),
      isLeader: false,
    );
  }

  /// Retrieves Digital Dindi Pass for the member.
  Future<DindiPass> getDindiPass(String dindiId, String userId, String dindiName) async {
    return MockDindiData.mockPass(dindiId: dindiId, userId: userId, dindiName: dindiName);
  }

  /// Fetches the micro-schedule itinerary for a specific Dindi.
  Future<List<DindiScheduleItem>> fetchDindiSchedule(String dindiId) async {
    try {
      final res = await _apiService.get('/dindis/$dindiId/schedule');
      if (res is List) {
        return res.map((item) => DindiScheduleItem.fromJson(item as Map<String, dynamic>)).toList();
      }
      return MockDindiData.getScheduleForDindi(dindiId);
    } catch (_) {
      // Backend endpoint missing -> mock itinerary fallback
      return MockDindiData.getScheduleForDindi(dindiId);
    }
  }
}
