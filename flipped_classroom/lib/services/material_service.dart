import 'dart:convert';
import 'api_service.dart';

class MaterialService {
  static final MaterialService _instance = MaterialService._internal();
  factory MaterialService() => _instance;
  MaterialService._internal();

  final ApiService _apiService = ApiService();

  /// Get classroom materials
  Future<List<Map<String, dynamic>>> getClassroomMaterials(int classroomId) async {
    final response = await _apiService.get('/classrooms/$classroomId/materials');
    final responseBody = jsonDecode(response.body);
    final List<dynamic> data = responseBody['data'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }
}
