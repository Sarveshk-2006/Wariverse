import '../services/api_service.dart';
import '../models/models_exports.dart';

class LostFoundRepository {
  LostFoundRepository(this._api);

  final ApiService _api;

  Future<({List<LostPerson> persons, bool isFromMock})> getLostPersons() async {
    try {
      final data = await _api.get('/lost-persons');
      final persons = (data as List<dynamic>)
          .map((e) => LostPerson.fromJson(e as Map<String, dynamic>))
          .toList();
      return (persons: persons, isFromMock: false);
    } catch (_) {
      return (persons: <LostPerson>[], isFromMock: false);
    }
  }

  Future<LostPerson> reportLostPerson(LostPerson person) async {
    final data = await _api.post('/lost-persons', person.toJson());
    return LostPerson.fromJson(data as Map<String, dynamic>);
  }

  Future<LostPerson> markAsFound(String id) async {
    final data = await _api.patch('/lost-persons/$id', {'status': 'FOUND'});
    return LostPerson.fromJson(data as Map<String, dynamic>);
  }
}
