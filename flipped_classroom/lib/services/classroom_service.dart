import 'dart:convert';
import 'package:flutter/material.dart';
import 'api_service.dart';

class ClassroomService {
  static final ClassroomService _instance = ClassroomService._internal();
  factory ClassroomService() => _instance;
  ClassroomService._internal();

  final ApiService _apiService = ApiService();

  Map<String, dynamic> _mapClassroomListItem(Map<String, dynamic> item) {
    final code = item['code'] ?? '';
    final name = item['name'] ?? '';
    final semester = item['semesterCode'] ?? '';
    final teacherName = item['teacher']?['fullName'] ?? 'Chua cap nhat';
    final studentCount = item['studentCount'] ?? 0;

    return {
      'id': item['id'],
      'classCode': code,
      'classCodeWithName': '$code - $name',
      'className': name,
      'instructor': 'GV: $teacherName',
      'semester': semester,
      'studentCount': studentCount,
      'progress': 0.0,
      'nextSession': 'Thoi gian: Chua xep lich',
      'title': name,
      'code': code,
      'studentsCount': studentCount,
      'type': 'Chuyen nganh',
      'color': const Color(0xFF7EC07E),
      'time': 'Slot 1 (7:30-9:50)',
      'date': 'Hom nay',
    };
  }

  /// Fetch classrooms for teachers
  Future<List<Map<String, dynamic>>> getTeacherClassrooms() async {
    final response = await _apiService.get('/teacher/classrooms');
    final responseBody = jsonDecode(response.body);
    final List<dynamic> data = responseBody['data'] ?? [];

    return data
        .map<Map<String, dynamic>>(
          (item) => _mapClassroomListItem(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  /// Fetch classrooms for students
  Future<List<Map<String, dynamic>>> getStudentClassrooms() async {
    final response = await _apiService.get('/student/classrooms');
    final responseBody = jsonDecode(response.body);
    final List<dynamic> data = responseBody['data'] ?? [];

    return data
        .map<Map<String, dynamic>>(
          (item) => _mapClassroomListItem(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  /// Join a classroom using a join code (Students only)
  Future<Map<String, dynamic>> joinClassroom(String joinCode) async {
    final response = await _apiService.post(
      '/student/classrooms/join',
      body: {'joinCode': joinCode},
    );
    final responseBody = jsonDecode(response.body);
    final item = Map<String, dynamic>.from(responseBody['data'] ?? {});
    final code = item['classroomCode'] ?? '';
    final name = item['classroomName'] ?? '';

    return {
      'id': item['id'],
      'classCode': code,
      'classCodeWithName': '$code - $name',
      'className': name,
      'instructor': 'GV: ${item['teacherName'] ?? 'Chua cap nhat'}',
      'semester': item['semesterCode'] ?? '',
      'studentCount': item['studentCount'] ?? 0,
      'progress': 0.0,
      'nextSession': 'Thoi gian: Chua xep lich',
    };
  }

  /// Create a classroom (Teachers only)
  Future<Map<String, dynamic>> createClassroom({
    required String code,
    required String name,
    required String description,
    required String semesterCode,
    required List<Map<String, dynamic>> schedules,
  }) async {
    final response = await _apiService.post(
      '/teacher/classrooms',
      body: {
        'code': code,
        'name': name,
        'description': description,
        'semesterCode': semesterCode,
        'schedules': schedules,
      },
    );
    final responseBody = jsonDecode(response.body);
    return Map<String, dynamic>.from(responseBody['data'] ?? {});
  }

  /// Rotate join code (Teachers only)
  Future<Map<String, dynamic>> rotateJoinCode(int classroomId) async {
    final response =
        await _apiService.post('/teacher/classrooms/$classroomId/rotate-code');
    final responseBody = jsonDecode(response.body);
    return Map<String, dynamic>.from(responseBody['data'] ?? {});
  }

  /// Get classroom details by ID (Teacher)
  Future<Map<String, dynamic>> getTeacherClassroomDetail(int classroomId) async {
    final response = await _apiService.get('/teacher/classrooms/$classroomId');
    final responseBody = jsonDecode(response.body);
    return Map<String, dynamic>.from(responseBody['data'] ?? {});
  }

  /// Get active students in a teacher's classroom
  Future<List<Map<String, dynamic>>> getTeacherClassroomStudents(
    int classroomId,
  ) async {
    final response = await _apiService.get(
      '/teacher/classrooms/$classroomId/students',
    );
    final responseBody = jsonDecode(response.body);
    final List<dynamic> data = responseBody['data'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }

  /// Get classroom details by ID (Student)
  Future<Map<String, dynamic>> getStudentClassroomDetail(int classroomId) async {
    final response = await _apiService.get('/student/classrooms/$classroomId');
    final responseBody = jsonDecode(response.body);
    return Map<String, dynamic>.from(responseBody['data'] ?? {});
  }

  /// Update classroom details (Teachers only)
  Future<Map<String, dynamic>> updateClassroom({
    required int classroomId,
    required String name,
    required String description,
    required String semesterCode,
    required List<Map<String, dynamic>> schedules,
  }) async {
    final response = await _apiService.put(
      '/teacher/classrooms/$classroomId',
      body: {
        'name': name,
        'description': description,
        'semesterCode': semesterCode,
        'schedules': schedules,
      },
    );
    final responseBody = jsonDecode(response.body);
    return Map<String, dynamic>.from(responseBody['data'] ?? {});
  }
}
