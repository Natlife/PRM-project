import 'dart:convert';
import 'api_service.dart';

class ProjectService {
  static final ProjectService _instance = ProjectService._internal();
  factory ProjectService() => _instance;
  ProjectService._internal();

  final ApiService _apiService = ApiService();

  /// Get student's project group in a specific classroom
  Future<Map<String, dynamic>> getStudentProjectGroup(int classroomId) async {
    final response = await _apiService.get('/student/classrooms/$classroomId/project-group');
    final responseBody = jsonDecode(response.body);
    return Map<String, dynamic>.from(responseBody['data'] ?? {});
  }

  /// Get milestones for a project group
  Future<List<Map<String, dynamic>>> getGroupMilestones(int groupId) async {
    final response = await _apiService.get('/project-groups/$groupId/milestones');
    final responseBody = jsonDecode(response.body);
    final List<dynamic> data = responseBody['data'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }

  /// Get project group detail for teacher
  Future<Map<String, dynamic>> getTeacherProjectGroupDetail(int groupId) async {
    final response = await _apiService.get('/teacher/project-groups/$groupId');
    final responseBody = jsonDecode(response.body);
    return Map<String, dynamic>.from(responseBody['data'] ?? {});
  }

  /// Update milestone progress
  Future<Map<String, dynamic>> updateMilestoneProgress(
      int milestoneId, int progressPercent, String status) async {
    final response = await _apiService.put(
      '/student/milestones/$milestoneId/progress',
      body: {
        'progressPercent': progressPercent,
        'status': status,
      },
    );
    final responseBody = jsonDecode(response.body);
    return Map<String, dynamic>.from(responseBody['data'] ?? {});
  }

  /// Get project groups for a classroom (Teacher only)
  Future<List<Map<String, dynamic>>> getClassroomProjectGroups(int classroomId) async {
    final response = await _apiService.get('/teacher/classrooms/$classroomId/project-groups');
    final responseBody = jsonDecode(response.body);
    final List<dynamic> data = responseBody['data'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }

  /// Create a project group in a classroom (Teacher only)
  Future<Map<String, dynamic>> createProjectGroup(int classroomId, Map<String, dynamic> data) async {
    final response = await _apiService.post(
      '/teacher/classrooms/$classroomId/project-groups',
      body: data,
    );
    final responseBody = jsonDecode(response.body);
    return Map<String, dynamic>.from(responseBody['data'] ?? {});
  }

  /// Update project group (Teacher only)
  Future<Map<String, dynamic>> updateProjectGroup(
    int groupId,
    Map<String, dynamic> data,
  ) async {
    final response = await _apiService.put(
      '/teacher/project-groups/$groupId',
      body: data,
    );
    final responseBody = jsonDecode(response.body);
    return Map<String, dynamic>.from(responseBody['data'] ?? {});
  }
}
