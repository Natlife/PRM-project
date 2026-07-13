import 'dart:convert';

import 'api_service.dart';

class EventService {
  static final EventService _instance = EventService._internal();
  factory EventService() => _instance;
  EventService._internal();

  final ApiService _apiService = ApiService();

  Future<List<Map<String, dynamic>>> getTeacherEvents() async {
    final response = await _apiService.get('/teacher/events');
    final body = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(body['data'] ?? const []);
  }

  Future<Map<String, dynamic>> createTeacherEvent(Map<String, dynamic> data) async {
    final response = await _apiService.post('/teacher/events', body: data);
    final body = jsonDecode(response.body);
    return Map<String, dynamic>.from(body['data'] ?? const {});
  }

  Future<Map<String, dynamic>> getTeacherEventDetail(int eventId) async {
    final response = await _apiService.get('/teacher/events/$eventId');
    final body = jsonDecode(response.body);
    return Map<String, dynamic>.from(body['data'] ?? const {});
  }

  Future<Map<String, dynamic>> updateTeacherEvent(int eventId, Map<String, dynamic> data) async {
    final response = await _apiService.put('/teacher/events/$eventId', body: data);
    final body = jsonDecode(response.body);
    return Map<String, dynamic>.from(body['data'] ?? const {});
  }

  Future<Map<String, dynamic>> createEventAssignment(int eventId, Map<String, dynamic> data) async {
    final response = await _apiService.post(
      '/teacher/events/$eventId/assignments',
      body: data,
    );
    final body = jsonDecode(response.body);
    return Map<String, dynamic>.from(body['data'] ?? const {});
  }

  Future<Map<String, dynamic>> addQuestionBankItem(int eventId, String content) async {
    final response = await _apiService.post(
      '/teacher/events/$eventId/question-bank',
      body: {'content': content},
    );
    final body = jsonDecode(response.body);
    return Map<String, dynamic>.from(body['data'] ?? const {});
  }

  Future<Map<String, dynamic>> addTeacherLiveQuestion(
    int eventId,
    String content, {
    int? assignmentId,
  }) async {
    final response = await _apiService.post(
      '/teacher/events/$eventId/questions',
      body: {
        'content': content,
        if (assignmentId != null) 'assignmentId': assignmentId,
      },
    );
    final body = jsonDecode(response.body);
    return Map<String, dynamic>.from(body['data'] ?? const {});
  }

  Future<Map<String, dynamic>> completeAssignment(int eventId, int assignmentId) async {
    final response = await _apiService.post(
      '/teacher/events/$eventId/assignments/$assignmentId/complete',
    );
    final body = jsonDecode(response.body);
    return Map<String, dynamic>.from(body['data'] ?? const {});
  }

  Future<Map<String, dynamic>> uploadRecording(
    int eventId,
    int assignmentId,
    List<int> fileBytes,
    String fileName,
  ) async {
    final response = await _apiService.upload(
      '/teacher/events/$eventId/assignments/$assignmentId/recording',
      const {},
      'file',
      fileBytes,
      fileName,
    );
    final body = jsonDecode(response.body);
    return Map<String, dynamic>.from(body['data'] ?? const {});
  }

  Future<List<Map<String, dynamic>>> getStudentEvents() async {
    final response = await _apiService.get('/student/events');
    final body = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(body['data'] ?? const []);
  }

  Future<Map<String, dynamic>> getStudentEventDetail(int eventId) async {
    final response = await _apiService.get('/student/events/$eventId');
    final body = jsonDecode(response.body);
    return Map<String, dynamic>.from(body['data'] ?? const {});
  }

  Future<Map<String, dynamic>> uploadStudentEvidence(
    int eventId,
    List<int> fileBytes,
    String fileName, {
    int? assignmentId,
  }) async {
    final response = await _apiService.upload(
      '/student/events/$eventId/evidences',
      {
        if (assignmentId != null) 'assignmentId': assignmentId.toString(),
      },
      'file',
      fileBytes,
      fileName,
    );
    final body = jsonDecode(response.body);
    return Map<String, dynamic>.from(body['data'] ?? const {});
  }

  Future<void> deleteStudentEvidence(int assetId) async {
    await _apiService.delete('/student/event-assets/$assetId');
  }

  Future<Map<String, dynamic>> addStudentLiveQuestion(
    int eventId,
    String content, {
    int? assignmentId,
  }) async {
    final response = await _apiService.post(
      '/student/events/$eventId/questions',
      body: {
        'content': content,
        if (assignmentId != null) 'assignmentId': assignmentId,
      },
    );
    final body = jsonDecode(response.body);
    return Map<String, dynamic>.from(body['data'] ?? const {});
  }

  Future<Map<String, dynamic>> answerStudentLiveQuestion(
    int eventId,
    int questionId,
    String answer,
  ) async {
    final response = await _apiService.post(
      '/student/events/$eventId/questions/$questionId/answer',
      body: {'answer': answer},
    );
    final body = jsonDecode(response.body);
    return Map<String, dynamic>.from(body['data'] ?? const {});
  }
}
