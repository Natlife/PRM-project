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

  /// Upload classroom material
  Future<Map<String, dynamic>> uploadMaterial({
    required int classroomId,
    required String title,
    required String description,
    required String materialType,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    final fields = {
      'title': title,
      'description': description,
      'materialType': materialType,
      'publishImmediately': 'true',
    };
    final response = await _apiService.upload(
      '/teacher/classrooms/$classroomId/materials',
      fields,
      'file',
      fileBytes,
      fileName,
    );
    final responseBody = jsonDecode(response.body);
    return Map<String, dynamic>.from(responseBody['data'] ?? {});
  }
}
