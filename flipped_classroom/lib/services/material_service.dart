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

  /// Get material detail
  Future<Map<String, dynamic>> getMaterialDetail(int materialId) async {
    final response = await _apiService.get('/materials/$materialId');
    final responseBody = jsonDecode(response.body);
    return Map<String, dynamic>.from(responseBody['data'] ?? {});
  }

  /// Delete material
  Future<void> deleteMaterial(int materialId) async {
    await _apiService.delete('/teacher/materials/$materialId');
  }
}
