import 'dart:convert';
import 'api_service.dart';

class ProjectService {
  static final ProjectService _instance = ProjectService._internal();
  factory ProjectService() => _instance;
  ProjectService._internal();

  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getStudentProjectGroup(int classroomId) async {
    final response = await _apiService.get(
      '/student/classrooms/$classroomId/project-group',
    );
    final responseBody = jsonDecode(response.body);
    return Map<String, dynamic>.from(responseBody['data'] ?? {});
  }

  Future<List<Map<String, dynamic>>> getGroupMilestones(int groupId) async {
    final response = await _apiService.get(
      '/project-groups/$groupId/milestones',
    );
    final responseBody = jsonDecode(response.body);
    final List<dynamic> data = responseBody['data'] ?? [];
    return List<Map<String, dynamic>>.from(
      data.map((m) {
        final map = Map<String, dynamic>.from(m);
        final rawDesc = map['description']?.toString() ?? '';
        List<dynamic> tasks = [];
        List<dynamic> comments = [];
        String descText = rawDesc;
        if (rawDesc.trim().startsWith('{') && rawDesc.trim().endsWith('}')) {
          try {
            final parsed = jsonDecode(rawDesc);
            if (parsed is Map) {
              descText = parsed['description']?.toString() ?? '';
              final rawTasks = parsed['tasks'] ?? parsed['activities'] ?? [];
              tasks = rawTasks.map((t) {
                final taskMap = Map<String, dynamic>.from(t);
                final isDone =
                    taskMap['isDone'] == true ||
                    taskMap['status'] == 'Hoàn thành' ||
                    taskMap['status'] == 'Đã hoàn thành' ||
                    taskMap['status'] == 'COMPLETED';
                taskMap['isDone'] = isDone;
                taskMap['status'] = isDone ? 'Hoàn thành' : 'Chưa bắt đầu';
                return taskMap;
              }).toList();
              comments = parsed['comments'] ?? [];
            }
          } catch (_) {
            // Keep as raw text if parsing fails
          }
        }
        map['description'] = descText;
        map['tasks'] = tasks;
        map['activities'] = tasks;
        map['comments'] = comments;
        return map;
      }),
    );
  }

  Future<Map<String, dynamic>> getTeacherProjectGroupDetail(int groupId) async {
    final response = await _apiService.get('/teacher/project-groups/$groupId');
    final responseBody = jsonDecode(response.body);
    return Map<String, dynamic>.from(responseBody['data'] ?? {});
  }

  Future<Map<String, dynamic>> updateMilestoneProgress(
    int milestoneId,
    int progressPercent,
    String status, {
    String? description,
  }) async {
    final response = await _apiService.put(
      '/student/milestones/$milestoneId/progress',
      body: {
        'progressPercent': progressPercent,
        'status': status,
        if (description != null) 'description': description,
      },
    );
    final responseBody = jsonDecode(response.body);
    return Map<String, dynamic>.from(responseBody['data'] ?? {});
  }

  Future<Map<String, dynamic>> createMilestone(
    int groupId,
    Map<String, dynamic> data,
  ) async {
    final response = await _apiService.post(
      '/teacher/project-groups/$groupId/milestones',
      body: data,
    );
    final responseBody = jsonDecode(response.body);
    return Map<String, dynamic>.from(responseBody['data'] ?? {});
  }

  Future<Map<String, dynamic>> updateMilestone(
    int milestoneId,
    Map<String, dynamic> data,
  ) async {
    final response = await _apiService.put(
      '/teacher/milestones/$milestoneId',
      body: data,
    );
    final responseBody = jsonDecode(response.body);
    return Map<String, dynamic>.from(responseBody['data'] ?? {});
  }

  Future<List<Map<String, dynamic>>> getClassroomProjectGroups(
    int classroomId,
  ) async {
    final response = await _apiService.get(
      '/teacher/classrooms/$classroomId/project-groups',
    );
    final responseBody = jsonDecode(response.body);
    final List<dynamic> data = responseBody['data'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>> createProjectGroup(
    int classroomId,
    Map<String, dynamic> data,
  ) async {
    final response = await _apiService.post(
      '/teacher/classrooms/$classroomId/project-groups',
      body: data,
    );
    final responseBody = jsonDecode(response.body);
    return Map<String, dynamic>.from(responseBody['data'] ?? {});
  }

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

  Future<List<Map<String, dynamic>>> uploadMilestoneAttachment(
    int milestoneId,
    List<int> fileBytes,
    String fileName,
  ) async {
    final response = await _apiService.upload(
      '/student/milestones/$milestoneId/attachments',
      {},
      'files',
      fileBytes,
      fileName,
    );
    final responseBody = jsonDecode(response.body);
    final List<dynamic> data = responseBody['data'] ?? [];
    return List<Map<String, dynamic>>.from(
      data.map((x) => Map<String, dynamic>.from(x)),
    );
  }
}
