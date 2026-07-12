import 'package:flutter/material.dart';
import '../../services/notification_service.dart';

enum NotificationType {
  assignment,
  grade,
  announcement,
  urgent,
}

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

  const NotificationScreen({
    super.key,
    this.showBackButton = true,
  });

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  static const Color _primaryColor = Color(0xFF7EC07E);
  static const Color _backgroundColor = Color(0xFFF8FAFC);
  static const Color _surfaceColor = Colors.white;
  static const Color _textColor = Color(0xFF0F172A);
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE2E8F0);

  final NotificationService _notificationService = NotificationService();

  List<NotificationItem> _notifications = [];
  bool _isLoading = true;

  bool get _hasUnreadNotification {
    return _notifications.any((item) => !item.isRead);
  }

  int get _unreadCount {
    return _notifications.where((item) => !item.isRead).length;
  }

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final list = await _notificationService.getNotifications();

      if (!mounted) return;

      setState(() {
        _notifications = list.map(_mapToNotificationItem).toList();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showSnackBar(
        message: 'Không thể tải thông báo. Vui lòng thử lại.',
        isError: true,
      );
    }
  }

  NotificationItem _mapToNotificationItem(Map<String, dynamic> item) {
    return NotificationItem(
      id: item['id'].toString(),
      title: item['title'] ?? 'Thông báo',
      content: item['body'] ?? '',
      timeAgo: _formatCreatedAt(item['createdAt']),
      type: _parseNotificationType(item['notificationType']),
      isRead: item['readAt'] != null,
    );
  }

  NotificationType _parseNotificationType(dynamic value) {
    final type = value?.toString().toUpperCase();

    switch (type) {
      case 'ASSIGNMENT':
        return NotificationType.assignment;
      case 'GRADE':
        return NotificationType.grade;
      case 'URGENT':
        return NotificationType.urgent;
      case 'ANNOUNCEMENT':
      default:
        return NotificationType.announcement;
    }
  }

  String _formatCreatedAt(dynamic value) {
    if (value == null) return 'Vừa xong';

    return value.toString().replaceFirst('T', ' ');
  }

  Future<void> _markAllAsRead() async {
    if (!_hasUnreadNotification) return;

    try {
      await _notificationService.markAllAsRead();

      if (!mounted) return;

      setState(() {
        for (final item in _notifications) {
          item.isRead = true;
        }
      });

      _showSnackBar(
        message: 'Đã đánh dấu tất cả thông báo là đã đọc.',
      );
    } catch (e) {
      if (!mounted) return;

      _showSnackBar(
        message: 'Lỗi: $e',
        isError: true,
      );
    }
  }

  Future<void> _markAsRead(int index) async {
    final item = _notifications[index];

    if (item.isRead) return;

    try {
      await _notificationService.markAsRead(int.parse(item.id));

      if (!mounted) return;

      setState(() {
        item.isRead = true;
      });
    } catch (_) {
      if (!mounted) return;

      _showSnackBar(
        message: 'Không thể cập nhật trạng thái thông báo.',
        isError: true,
      );
    }
  }

  void _deleteNotification(int index) {
    setState(() {
      _notifications.removeAt(index);
    });

    _showSnackBar(
      message: 'Đã xoá thông báo khỏi danh sách.',
    );
  }

  void _showSnackBar({
    required String message,
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.redAccent : _textColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.urgent:
        return Icons.priority_high_rounded;
      case NotificationType.grade:
        return Icons.trending_up_rounded;
      case NotificationType.assignment:
        return Icons.task_alt_rounded;
      case NotificationType.announcement:
        return Icons.campaign_rounded;
    }
  }

  String _getLabelForType(NotificationType type) {
    switch (type) {
      case NotificationType.urgent:
        return 'Khẩn cấp';
      case NotificationType.grade:
        return 'Điểm số';
      case NotificationType.assignment:
        return 'Bài tập';
      case NotificationType.announcement:
        return 'Thông báo';
    }
  }

  Color _getColorForType(NotificationType type) {
    switch (type) {
      case NotificationType.urgent:
        return const Color(0xFFEF4444);
      case NotificationType.grade:
        return const Color(0xFF22C55E);
      case NotificationType.assignment:
        return const Color(0xFF3B82F6);
      case NotificationType.announcement:
        return _primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _backgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: widget.showBackButton,
      leading: widget.showBackButton
          ? IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _textColor,
                size: 20,
              ),
            )
          : null,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông báo',
            style: TextStyle(
              color: _textColor,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          if (!_isLoading && _notifications.isNotEmpty)
            Text(
              _unreadCount > 0
                  ? 'Bạn có $_unreadCount thông báo chưa đọc'
                  : 'Tất cả thông báo đã được đọc',
              style: const TextStyle(
                color: _mutedTextColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
      actions: [
        if (_notifications.isNotEmpty && _hasUnreadNotification)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _markAllAsRead,
              style: TextButton.styleFrom(
                foregroundColor: _primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: const Text(
                'Đọc tất cả',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_notifications.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: _primaryColor,
      backgroundColor: _surfaceColor,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: _notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = _notifications[index];

          return _NotificationCard(
            item: item,
            icon: _getIconForType(item.type),
            color: _getColorForType(item.type),
            typeLabel: _getLabelForType(item.type),
            onTap: () => _markAsRead(index),
            onDelete: () => _deleteNotification(index),
          );
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
          strokeWidth: 3,
          color: _primaryColor,
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
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.68,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 108,
                      height: 108,
                      decoration: BoxDecoration(
                        color: _surfaceColor,
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: _borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: _textColor.withOpacity(0.04),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.notifications_none_rounded,
                        size: 52,
                        color: _primaryColor.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Chưa có thông báo',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _textColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Khi có bài tập, điểm số hoặc thông báo mới, nội dung sẽ xuất hiện tại đây.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _mutedTextColor,
                        fontSize: 14,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationItem item;
  final IconData icon;
  final Color color;
  final String typeLabel;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.item,
    required this.icon,
    required this.color,
    required this.typeLabel,
    required this.onTap,
    required this.onDelete,
  });

  static const Color _surfaceColor = Colors.white;
  static const Color _textColor = Color(0xFF0F172A);
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: _buildDeleteBackground(),
      onDismissed: (_) => onDelete(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: item.isRead
                  ? _surfaceColor.withOpacity(0.72)
                  : _surfaceColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: item.isRead
                    ? _borderColor.withOpacity(0.8)
                    : color.withOpacity(0.22),
              ),
              boxShadow: [
                BoxShadow(
                  color: _textColor.withOpacity(item.isRead ? 0.025 : 0.06),
                  blurRadius: item.isRead ? 14 : 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIcon(),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildContent(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Icon(
        Icons.delete_outline_rounded,
        color: Colors.white,
        size: 26,
      ),
    );
  }

  Widget _buildIcon() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        if (!item.isRead)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _surfaceColor,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 8),
        Text(
          item.content,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: item.isRead
                ? _mutedTextColor.withOpacity(0.78)
                : _mutedTextColor,
            fontSize: 13.5,
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        _buildFooter(),
      ],
    );
  }

  Widget _buildHeader() {
    return Text(
      item.title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: item.isRead ? _textColor.withOpacity(0.72) : _textColor,
        fontSize: 15.5,
        height: 1.25,
        fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
        letterSpacing: -0.15,
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            typeLabel,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            item.timeAgo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _mutedTextColor.withOpacity(0.72),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}