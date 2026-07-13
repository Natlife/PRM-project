import 'dart:convert';
import 'api_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final ApiService _apiService = ApiService();

  Future<List<Map<String, dynamic>>> getNotifications() async {
    final response = await _apiService.get('/notifications');
    final responseBody = jsonDecode(response.body);
    final List<dynamic> data = responseBody['data'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }

  Future<int> getUnreadCount() async {
    final response = await _apiService.get('/notifications/unread-count');
    final responseBody = jsonDecode(response.body);
    return responseBody['data'] as int? ?? 0;
  }

  Future<void> markAsRead(int notificationId) async {
    await _apiService.put('/notifications/$notificationId/read');
  }

  Future<void> markAllAsRead() async {
    await _apiService.put('/notifications/read-all');
  }
}
