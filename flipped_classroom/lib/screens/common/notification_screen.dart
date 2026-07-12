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
  static const Color _primaryColor = Color(0xFF22A06B);
  static const Color _primaryDarkColor = Color(0xFF167A52);
  static const Color _backgroundColor = Color(0xFFF5F7F6);
  static const Color _surfaceColor = Colors.white;
  static const Color _textPrimaryColor = Color(0xFF17211B);
  static const Color _textSecondaryColor = Color(0xFF66736B);
  static const Color _borderColor = Color(0xFFE2E8E4);
  static const Color _errorColor = Color(0xFFDC3D43);

  final NotificationService _notificationService = NotificationService();

  List<NotificationItem> _notifications = [];

  bool _isLoading = true;
  bool _isMarkingAllAsRead = false;

  bool get _hasUnreadNotifications {
    return _notifications.any((NotificationItem item) => !item.isRead);
  }

  int get _unreadCount {
    return _notifications.where((NotificationItem item) => !item.isRead).length;
  }

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  NotificationType _parseNotificationType(String value) {
    switch (value.toUpperCase()) {
      case 'ASSIGNMENT':
        return NotificationType.assignment;
      case 'GRADE':
        return NotificationType.grade;
      case 'URGENT':
        return NotificationType.urgent;
      default:
        return NotificationType.announcement;
    }
  }

  String _formatCreatedAt(dynamic value) {
    if (value == null) {
      return 'Vừa xong';
    }

    return value.toString().replaceFirst('T', ' ');
  }

  Future<void> _loadNotifications() async {
    try {
      final list = await _notificationService.getNotifications();

      final List<NotificationItem> notifications = list.map<NotificationItem>((
        dynamic item,
      ) {
        return NotificationItem(
          id: item['id'].toString(),
          title: item['title']?.toString() ?? 'Thông báo',
          content: item['body']?.toString() ?? '',
          timeAgo: _formatCreatedAt(item['createdAt']),
          type: _parseNotificationType(
            item['notificationType']?.toString() ?? '',
          ),
          isRead: item['readAt'] != null,
        );
      }).toList();

      if (!mounted) {
        return;
      }

      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    if (_isMarkingAllAsRead || !_hasUnreadNotifications) {
      return;
    }

    setState(() {
      _isMarkingAllAsRead = true;
    });

    try {
      await _notificationService.markAllAsRead();

      if (!mounted) {
        return;
      }

      setState(() {
        for (final NotificationItem item in _notifications) {
          item.isRead = true;
        }
      });

      _showSnackBar(
        message: 'Đã đánh dấu tất cả thông báo là đã đọc.',
        isError: false,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showSnackBar(
        message: 'Không thể đánh dấu thông báo: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isMarkingAllAsRead = false;
        });
      }
    }
  }

  Future<void> _toggleReadStatus(NotificationItem item) async {
    if (item.isRead) {
      return;
    }

    final int? notificationId = int.tryParse(item.id);

    if (notificationId == null) {
      return;
    }

    try {
      await _notificationService.markAsRead(notificationId);

      if (!mounted) {
        return;
      }

      setState(() {
        item.isRead = true;
      });
    } catch (_) {
      // Giữ nguyên trạng thái chưa đọc khi API thất bại.
    }
  }

  void _showSnackBar({required String message, required bool isError}) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? _errorColor : _primaryDarkColor,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.assignment:
        return Icons.assignment_outlined;
      case NotificationType.grade:
        return Icons.bar_chart_rounded;
      case NotificationType.announcement:
        return Icons.campaign_outlined;
      case NotificationType.urgent:
        return Icons.warning_amber_rounded;
    }
  }

  String _getLabelForType(NotificationType type) {
    switch (type) {
      case NotificationType.assignment:
        return 'Bài tập';
      case NotificationType.grade:
        return 'Điểm số';
      case NotificationType.announcement:
        return 'Thông báo';
      case NotificationType.urgent:
        return 'Khẩn cấp';
    }
  }

  Color _getColorForType(NotificationType type) {
    switch (type) {
      case NotificationType.assignment:
        return const Color(0xFF6366F1);
      case NotificationType.grade:
        return _primaryColor;
      case NotificationType.announcement:
        return const Color(0xFF3B82F6);
      case NotificationType.urgent:
        return _errorColor;
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _surfaceColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      shadowColor: _borderColor,
      automaticallyImplyLeading: false,
      leading: widget.showBackButton
          ? IconButton(
              tooltip: 'Quay lại',
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: _textPrimaryColor,
              ),
            )
          : null,
      titleSpacing: widget.showBackButton ? 0 : 20,
      title: Row(
        children: [
          const Text(
            'Thông báo',
            style: TextStyle(
              color: _textPrimaryColor,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          if (_unreadCount > 0) ...[
            const SizedBox(width: 9),
            Container(
              constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF7F0),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                '$_unreadCount',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _primaryDarkColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (_notifications.isNotEmpty && _hasUnreadNotifications)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _isMarkingAllAsRead ? null : _markAllAsRead,
              style: TextButton.styleFrom(
                foregroundColor: _primaryDarkColor,
                disabledForegroundColor: _primaryDarkColor.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: _isMarkingAllAsRead
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _primaryColor,
                        ),
                      ),
                    )
                  : const Text(
                      'Đọc tất cả',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
      ],
    );
  }

  Widget _buildNotificationCard(NotificationItem item) {
    final Color typeColor = _getColorForType(item.type);

    return Material(
      color: item.isRead ? _surfaceColor.withOpacity(0.72) : _surfaceColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _toggleReadStatus(item),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: item.isRead
                  ? _borderColor
                  : _primaryColor.withOpacity(0.24),
              width: item.isRead ? 1 : 1.2,
            ),
            boxShadow: item.isRead
                ? const []
                : [
                    BoxShadow(
                      color: _primaryColor.withOpacity(0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.11),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  _getIconForType(item.type),
                  color: typeColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: item.isRead
                                  ? _textPrimaryColor.withOpacity(0.7)
                                  : _textPrimaryColor,
                              fontSize: 15,
                              height: 1.35,
                              fontWeight: item.isRead
                                  ? FontWeight.w600
                                  : FontWeight.w700,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ),
                        if (!item.isRead) ...[
                          const SizedBox(width: 10),
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 6),
                            decoration: const BoxDecoration(
                              color: _primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (item.content.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.content,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: item.isRead
                              ? _textSecondaryColor.withOpacity(0.72)
                              : _textSecondaryColor,
                          fontSize: 13,
                          height: 1.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                    const SizedBox(height: 11),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: typeColor.withOpacity(0.09),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            _getLabelForType(item.type),
                            style: TextStyle(
                              color: typeColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: Color(0xFF9AA49E),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            item.timeAgo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF8B9690),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationList() {
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: _primaryColor,
      backgroundColor: _surfaceColor,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
        itemCount: _notifications.length,
        separatorBuilder: (BuildContext context, int index) {
          return const SizedBox(height: 8);
        },
        itemBuilder: (BuildContext context, int index) {
          return _buildNotificationCard(_notifications[index]);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          strokeWidth: 2.6,
          valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: _primaryColor,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.18),
          Center(
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF7F0),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 43,
                color: _primaryDarkColor,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Chưa có thông báo',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textPrimaryColor,
              fontSize: 19,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 9),
          const Text(
            'Các thông báo về bài tập, điểm số và hoạt động mới sẽ xuất hiện tại đây.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textSecondaryColor,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Kéo xuống để tải lại',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF9AA49E),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: _isLoading
            ? _buildLoadingState()
            : _notifications.isEmpty
            ? _buildEmptyState()
            : _buildNotificationList(),
      ),
    );
  }
}
