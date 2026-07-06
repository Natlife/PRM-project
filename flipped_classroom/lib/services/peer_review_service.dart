import 'dart:convert';
import 'api_service.dart';

class PeerReviewService {
  static final PeerReviewService _instance = PeerReviewService._internal();
  factory PeerReviewService() => _instance;
  PeerReviewService._internal();

  final ApiService _apiService = ApiService();

  Future<List<Map<String, dynamic>>> getPeerReviewTargets(int classroomId) async {
    final response = await _apiService.get(
      '/student/classrooms/$classroomId/peer-review/targets',
    );
    final responseBody = jsonDecode(response.body);
    final List<dynamic> data = responseBody['data'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getMyPeerReviews(int classroomId) async {
    final response = await _apiService.get(
      '/student/classrooms/$classroomId/peer-reviews/me',
    );
    final responseBody = jsonDecode(response.body);
    final List<dynamic> data = responseBody['data'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>> submitPeerReview({
    required int reviewedGroupId,
    required int codeQualityScore,
    required int uiUxScore,
    required int featureScore,
    required int presentationScore,
    String? comment,
  }) async {
    final response = await _apiService.post(
      '/student/peer-reviews',
      body: {
        'reviewedGroupId': reviewedGroupId,
        'codeQualityScore': codeQualityScore,
        'uiUxScore': uiUxScore,
        'featureScore': featureScore,
        'presentationScore': presentationScore,
        'comment': comment,
      },
    );
    final responseBody = jsonDecode(response.body);
    return Map<String, dynamic>.from(responseBody['data'] ?? {});
  }
}
