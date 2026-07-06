import 'package:flutter/material.dart';
import '../../services/notification_service.dart';

enum NotificationType { assignment, grade, announcement, urgent }

class NotificationItem {
  final String id;
  final String title;
  final String content;
  final String timeAgo;
  final NotificationType type;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.content,
    required this.timeAgo,
    required this.type,
    this.isRead = false,
  });
}

class NotificationScreen extends StatefulWidget {
  final bool showBackButton;
  const NotificationScreen({super.key, this.showBackButton = true});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final list = await NotificationService().getNotifications();
      setState(() {
        _notifications = list.map((item) {
          final isRead = item['readAt'] != null;
          final typeStr = item['notificationType'] ?? '';
          NotificationType type = NotificationType.announcement;
          if (typeStr.toUpperCase() == 'ASSIGNMENT') {
            type = NotificationType.assignment;
          } else if (typeStr.toUpperCase() == 'GRADE') {
            type = NotificationType.grade;
          } else if (typeStr.toUpperCase() == 'URGENT') {
            type = NotificationType.urgent;
          }
          final createdAt = item['createdAt'] != null
              ? item['createdAt'].toString().split('T').join(' ')
              : 'Vừa xong';
          return NotificationItem(
            id: item['id'].toString(),
            title: item['title'] ?? 'Thông báo',
            content: item['body'] ?? '',
            timeAgo: createdAt,
            type: type,
            isRead: isRead,
          );
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await NotificationService().markAllAsRead();
      setState(() {
        for (var item in _notifications) {
          item.isRead = true;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã đánh dấu tất cả thông báo là đã đọc.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _toggleReadStatus(int index) async {
    final item = _notifications[index];
    if (!item.isRead) {
      try {
        await NotificationService().markAsRead(int.parse(item.id));
        setState(() {
          item.isRead = true;
        });
      } catch (e) {
        // Silently fail or show snackbar
      }
    }
  }

  void _deleteNotification(int index) {
    setState(() {
      _notifications.removeAt(index);
    });
  }

  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.urgent:
        return Icons.warning_amber_rounded;
      case NotificationType.grade:
        return Icons.analytics_outlined;
      case NotificationType.announcement:
        return Icons.chat_bubble_outline_rounded;
      case NotificationType.assignment:
        return Icons.assignment_outlined;
    }
  }

  Color _getColorForType(NotificationType type) {
    switch (type) {
      case NotificationType.urgent:
        return Colors.redAccent;
      case NotificationType.grade:
        return Colors.greenAccent;
      case NotificationType.announcement:
        return const Color(0xFF7EC07E); // Magenta
      case NotificationType.assignment:
        return const Color(0xFF7EC07E); // Violet
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _notifications.any((item) => !item.isRead);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A)),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        automaticallyImplyLeading: widget.showBackButton,
        title: const Text(
          'Thông báo',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_notifications.isNotEmpty && hasUnread)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Đọc tất cả',
                style: TextStyle(
                  color: Color(0xFF7EC07E),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF7EC07E),
              ),
            )
          : _notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  color: const Color(0xFF7EC07E),
                  child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final item = _notifications[index];
                        return Dismissible(
                          key: Key(item.id),
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: Colors.redAccent.withOpacity(0.8),
                            child: const Icon(Icons.delete, color: Color(0xFF0F172A)),
                          ),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => _deleteNotification(index),
                          child: GestureDetector(
                            onTap: () => _toggleReadStatus(index),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: item.isRead 
                                    ? const Color(0xFFFFFFFF).withOpacity(0.6) 
                                    : const Color(0xFFFFFFFF),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: item.isRead 
                                      ? const Color(0xFF0F172A).withOpacity(0.02)
                                      : const Color(0xFF7EC07E).withOpacity(0.2),
                                  width: 1.2,
                                ),
                                boxShadow: item.isRead 
                                    ? [] 
                                    : [
                                        BoxShadow(
                                          color: const Color(0xFF7EC07E).withOpacity(0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        )
                                      ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _getColorForType(item.type).withOpacity(0.12),
                                    ),
                                    child: Icon(
                                      _getIconForType(item.type),
                                      color: _getColorForType(item.type),
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.title,
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: item.isRead 
                                                      ? FontWeight.w500 
                                                      : FontWeight.bold,
                                                  color: item.isRead 
                                                      ? const Color(0xFF0F172A).withOpacity(0.7) 
                                                      : const Color(0xFF0F172A),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            if (!item.isRead)
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Color(0xFF7EC07E),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          item.content,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: item.isRead 
                                                ? const Color(0xFF0F172A).withOpacity(0.4) 
                                                : const Color(0xFF0F172A).withOpacity(0.7),
                                            height: 1.3,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          item.timeAgo,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: const Color(0xFF0F172A).withOpacity(0.3),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0F172A).withOpacity(0.03),
            ),
            child: Icon(
              Icons.notifications_off_outlined,
              size: 70,
              color: const Color(0xFF0F172A).withOpacity(0.2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Không có thông báo mới',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tất cả thông báo mới sẽ xuất hiện tại đây.',
            style: TextStyle(
              fontSize: 13,
              color: const Color(0xFF0F172A).withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
}
