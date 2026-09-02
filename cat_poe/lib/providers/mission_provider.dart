import 'package:flutter/foundation.dart';
import '../models/mission.dart';
import '../services/mission_service.dart';
import '../services/api_service.dart';
import '../services/logger_service.dart';

class MissionProvider with ChangeNotifier {
  final MissionService _missionService = MissionService(ApiService());

  List<Mission> _missions = [];
  bool _isLoading = false;
  String? _error;

  List<Mission> get missions => _missions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchMissions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _missions = await _missionService.getMissions();
    } catch (e) {
      _error = 'Failed to load missions. Please try again.';
      LoggerService.error('Error fetching missions', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> completeMission(String code, {String? verificationData}) async {
    try {
      await _missionService.completeMission(code,
          verificationData: verificationData);
      // Refresh list to update status
      await fetchMissions();
    } catch (e) {
      _error = 'Failed to complete mission. Please try again.';
      LoggerService.error('Error completing mission', e);
      rethrow;
    }
  }
}


