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

  /// Get teacher activity detail
  Future<Map<String, dynamic>> getTeacherActivityDetail(int activityId) async {
    final response = await _apiService.get('/teacher/activities/$activityId');
    final responseBody = jsonDecode(response.body);
    return Map<String, dynamic>.from(responseBody['data'] ?? {});
  }

  /// Get student activity detail
  Future<Map<String, dynamic>> getStudentActivityDetail(int activityId) async {
    final response = await _apiService.get('/student/activities/$activityId');
    final responseBody = jsonDecode(response.body);
    return Map<String, dynamic>.from(responseBody['data'] ?? {});
  }

  /// Get current student's submission for an activity
  Future<Map<String, dynamic>> getStudentSubmission(int activityId) async {
    final response = await _apiService.get('/student/activities/$activityId/submission');
    final responseBody = jsonDecode(response.body);
    return Map<String, dynamic>.from(responseBody['data'] ?? {});
  }

  /// Update a learning activity (Teacher only)
  Future<Map<String, dynamic>> updateActivity(
    int activityId,
    Map<String, dynamic> data,
  ) async {
    final response = await _apiService.put(
      '/teacher/activities/$activityId',
      body: data,
    );
    final responseBody = jsonDecode(response.body);
    return Map<String, dynamic>.from(responseBody['data'] ?? {});
  }

  /// Get all submissions for a teacher activity
  Future<List<Map<String, dynamic>>> getActivitySubmissions(int activityId) async {
    final response = await _apiService.get('/teacher/activities/$activityId/submissions');
    final responseBody = jsonDecode(response.body);
    final List<dynamic> data = responseBody['data'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }

  /// Get teacher submission detail
  Future<Map<String, dynamic>> getTeacherSubmissionDetail(int submissionId) async {
    final response = await _apiService.get('/teacher/submissions/$submissionId');
    final responseBody = jsonDecode(response.body);
    return Map<String, dynamic>.from(responseBody['data'] ?? {});
  }

  /// Grade a submission
  Future<Map<String, dynamic>> gradeSubmission(
    int submissionId, {
    required num score,
    String? feedback,
  }) async {
    final response = await _apiService.put(
      '/teacher/submissions/$submissionId/grade',
      body: {
        'score': score,
        'feedback': feedback,
      },
    );
    final responseBody = jsonDecode(response.body);
    return Map<String, dynamic>.from(responseBody['data'] ?? {});
  }

  /// Get comments for a submission
  Future<List<Map<String, dynamic>>> getSubmissionComments(int submissionId) async {
    final response = await _apiService.get('/submissions/$submissionId/comments');
    final responseBody = jsonDecode(response.body);
    final List<dynamic> data = responseBody['data'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }

  /// Add comment to a submission
  Future<Map<String, dynamic>> addSubmissionComment(
    int submissionId, {
    required String content,
    String scope = 'PUBLIC',
  }) async {
    final response = await _apiService.post(
      '/submissions/$submissionId/comments',
      body: {
        'content': content,
        'scope': scope,
      },
    );
    final responseBody = jsonDecode(response.body);
    return Map<String, dynamic>.from(responseBody['data'] ?? {});
  }
}
