import 'dart:convert';
import 'api_service.dart';

class ActivityService {
  static final ActivityService _instance = ActivityService._internal();
  factory ActivityService() => _instance;
  ActivityService._internal();

  final ApiService _apiService = ApiService();

  /// Get classroom activities for students
  Future<List<Map<String, dynamic>>> getStudentActivities(int classroomId) async {
    final response = await _apiService.get('/student/classrooms/$classroomId/activities');
    final responseBody = jsonDecode(response.body);
    final List<dynamic> data = responseBody['data'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }

  /// Get classroom activities for teachers
  Future<List<Map<String, dynamic>>> getTeacherActivities(int classroomId) async {
    final response = await _apiService.get('/teacher/classrooms/$classroomId/activities');
    final responseBody = jsonDecode(response.body);
    final List<dynamic> data = responseBody['data'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }

  /// Create a learning activity in a classroom (Teacher only)
  Future<Map<String, dynamic>> createActivity(int classroomId, Map<String, dynamic> data) async {
    final response = await _apiService.post(
      '/teacher/classrooms/$classroomId/activities',
      body: data,
    );
    final responseBody = jsonDecode(response.body);
    return Map<String, dynamic>.from(responseBody['data'] ?? {});
  }
}
