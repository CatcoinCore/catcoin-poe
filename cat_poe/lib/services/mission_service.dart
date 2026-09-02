import '../models/mission.dart';
import 'api_service.dart';
import 'logger_service.dart';

class MissionService {
  final ApiService _apiService;

  MissionService(this._apiService);

  Future<List<Mission>> getMissions() async {
    try {
      final response = await _apiService.get('/missions/');
      final List<dynamic> data = response;
      return data.map((json) => Mission.fromJson(json)).toList();
    } catch (e) {
      LoggerService.error('Failed to fetch missions', e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> completeMission(String code,
      {String? verificationData}) async {
    try {
      final response = await _apiService.post('/missions/complete', body: {
        'code': code,
        if (verificationData != null) 'verification_data': verificationData,
      });
      return response;
    } catch (e) {
      LoggerService.error('Failed to complete mission: $code', e);
      rethrow;
    }
  }
}


