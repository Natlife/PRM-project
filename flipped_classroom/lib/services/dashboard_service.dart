import 'dart:convert';
import 'api_service.dart';

class DashboardService {
  static final DashboardService _instance = DashboardService._internal();
  factory DashboardService() => _instance;
  DashboardService._internal();

  final ApiService _apiService = ApiService();

  /// Fetch dashboard summary for students
  Future<Map<String, dynamic>> getStudentDashboard() async {
    final response = await _apiService.get('/student/dashboard/summary');
    final responseBody = jsonDecode(response.body);
    return Map<String, dynamic>.from(responseBody['data'] ?? {});
  }

  /// Fetch dashboard summary for teachers
  Future<Map<String, dynamic>> getTeacherDashboard() async {
    final response = await _apiService.get('/teacher/dashboard/summary');
    final responseBody = jsonDecode(response.body);
    return Map<String, dynamic>.from(responseBody['data'] ?? {});
  }
}
