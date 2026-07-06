import 'dart:convert';
import 'api_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final ApiService _apiService = ApiService();

  /// Get list of notifications for the current user
  Future<List<Map<String, dynamic>>> getNotifications() async {
    final response = await _apiService.get('/notifications');
    final responseBody = jsonDecode(response.body);
    final List<dynamic> data = responseBody['data'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }

  /// Get count of unread notifications
  Future<int> getUnreadCount() async {
    final response = await _apiService.get('/notifications/unread-count');
    final responseBody = jsonDecode(response.body);
    return responseBody['data'] as int? ?? 0;
  }

  /// Mark notification as read
  Future<void> markAsRead(int notificationId) async {
    await _apiService.put('/notifications/$notificationId/read');
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    await _apiService.put('/notifications/read-all');
  }
}
