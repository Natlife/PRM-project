import 'dart:convert';
import 'api_service.dart';

class DashboardService {
  static final DashboardService _instance = DashboardService._internal();
  factory DashboardService() => _instance;
  DashboardService._internal();

  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getStudentDashboard() async {
    final response = await _apiService.get('/student/dashboard/summary');
    final responseBody = jsonDecode(response.body);
    return Map<String, dynamic>.from(responseBody['data'] ?? {});
  }

  Future<List<Map<String, dynamic>>> getStudentDeadlines(
    int page,
    int size,
  ) async {
    final response = await _apiService.get(
      '/student/dashboard/deadlines?page=$page&size=$size',
    );
    final responseBody = jsonDecode(response.body);
    final list = List<dynamic>.from(responseBody['data'] ?? []);
    return list.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  Future<Map<String, dynamic>> getTeacherDashboard() async {
    final response = await _apiService.get('/teacher/dashboard/summary');
    final responseBody = jsonDecode(response.body);
    return Map<String, dynamic>.from(responseBody['data'] ?? {});
  }

  Future<Map<String, dynamic>> getTeacherDashboardOverview() async {
    final response = await _apiService.get('/teacher/dashboard/overview');
    final responseBody = jsonDecode(response.body);
    return Map<String, dynamic>.from(responseBody['data'] ?? {});
  }
}
