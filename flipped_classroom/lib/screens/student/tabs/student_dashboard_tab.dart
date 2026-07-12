import 'package:flutter/material.dart';
import '../../../services/activity_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/dashboard_service.dart';
import '../../../services/notification_service.dart';
import '../../common/notification_screen.dart';
import '../all_deadlines_screen.dart';
import '../student_activity_detail_screen.dart';
import '../student_class_detail_screen.dart';

class StudentDashboardTab extends StatefulWidget {
  final List<Map<String, dynamic>> myClasses;
  final VoidCallback onJoinClassPressed;
  final ValueChanged<int> onTabTapped;

  const StudentDashboardTab({
    super.key,
    required this.myClasses,
    required this.onJoinClassPressed,
    required this.onTabTapped,
  });

  @override
  State<StudentDashboardTab> createState() => _StudentDashboardTabState();
}

class _StudentDashboardTabState extends State<StudentDashboardTab> {
  static const Color _primaryColor = Color(0xFF7EC07E);
  static const Color _backgroundColor = Color(0xFFF8FAFC);
  static const Color _surfaceColor = Colors.white;
  static const Color _textColor = Color(0xFF0F172A);
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE2E8F0);
  static const Color _dangerColor = Color(0xFFEF4444);

  final DashboardService _dashboardService = DashboardService();
  final ActivityService _activityService = ActivityService();
  final NotificationService _notificationService = NotificationService();

  bool _isLoading = true;
  int _unreadNotificationCount = 0;
  Map<String, dynamic>? _dashboardData;
  List<Map<String, dynamic>> _upcomingActivities = [];

  int get _pendingCount {
    final value = _dashboardData?['pendingActivitiesCount'];
    return value is num ? value.toInt() : 0;
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadDashboard(),
      _loadUnreadNotificationCount(),
    ]);
  }

  Future<void> _loadUnreadNotificationCount() async {
    try {
      final count = await _notificationService.getUnreadCount();

      if (!mounted) return;

      setState(() {
        _unreadNotificationCount = count;
      });
    } catch (e) {
      debugPrint('Error loading unread notification count: $e');
    }
  }

  Future<void> _loadDashboard() async {
    try {
      final data = await _dashboardService.getStudentDashboard();

      final rawUpcomingActivities = List<Map<String, dynamic>>.from(
        data['upcomingActivities'] ?? const [],
      );

      final normalizedUpcomingActivities = <Map<String, dynamic>>[];

      for (final activity in rawUpcomingActivities) {
        final normalizedActivity = await _normalizeActivity(activity);
        normalizedUpcomingActivities.add(normalizedActivity);
      }

      if (!mounted) return;

      setState(() {
        _dashboardData = data;
        _upcomingActivities = normalizedUpcomingActivities;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading student dashboard: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> _normalizeActivity(
    Map<String, dynamic> activity,
  ) async {
    Map<String, dynamic> submission = {};

    final activityId = (activity['id'] as num?)?.toInt();

    if (activityId != null) {
      try {
        submission = await _activityService.getStudentSubmission(activityId);
      } catch (e) {
        debugPrint(
          'Error loading submission for dashboard activity $activityId: $e',
        );
      }
    }

    final submissionStatus =
        submission['status']?.toString() ?? 'NOT_SUBMITTED';

    final isDone = submissionStatus == 'SUBMITTED' ||
        submissionStatus == 'LATE_SUBMITTED' ||
        submissionStatus == 'GRADED';

    return {
      'id': activity['id'],
      'title': activity['title'] ?? '',
      'description': activity['description'] ?? '',
      'activityType': activity['activityType'],
      'type': _mapActivityType(activity['activityType']),
      'dueAt': activity['dueAt'],
      'deadline': _formatDueAt(activity['dueAt']),
      'maxScore': activity['maxScore'],
      'activityWorkflowStatus': activity['status']?.toString() ?? '',
      'submissionStatus': submissionStatus,
      'status': isDone ? 'Đã làm' : 'Chưa làm',
      'submissionId': submission['id'],
      'submissionTime': submission['submittedAt']?.toString(),
      'attachmentCount': submission['attachmentCount'] ?? 0,
      'commentCount': submission['commentCount'] ?? 0,
      'teacherFeedback': submission['teacherFeedback'] ?? '',
      'score': submission['score'],
    };
  }

  String _buildClassCodeWithName(Map<String, dynamic> item) {
    final existing = item['classCodeWithName']?.toString().trim() ?? '';

    if (existing.isNotEmpty) {
      return existing;
    }

    final code = item['classCode']?.toString().trim() ?? '';
    final name = item['className']?.toString().trim() ?? '';

    if (code.isNotEmpty && name.isNotEmpty) {
      return '$code - $name';
    }

    return code.isNotEmpty ? code : name;
  }

  String _mapActivityType(dynamic value) {
    final type = value?.toString() ?? '';

    if (type == 'PRE_CLASS' || type == 'BEFORE_CLASS') {
      return 'Trước buổi học';
    }

    return 'Trong buổi học';
  }

  String _mapActivityStatus(dynamic value) {
    final status = value?.toString() ?? '';

    if (status == 'SUBMITTED' ||
        status == 'LATE_SUBMITTED' ||
        status == 'GRADED') {
      return 'Đã làm';
    }

    return 'Chưa làm';
  }

  String _formatDueAt(dynamic value) {
    if (value == null) {
      return 'Không có hạn';
    }

    return 'Hạn: ${value.toString().replaceFirst('T', ' ')}';
  }

  String _getInitials(String? fullName) {
    final name = fullName?.trim() ?? '';

    if (name.isEmpty) return 'SV';

    final parts = name.split(' ').where((part) => part.isNotEmpty).toList();

    if (parts.isEmpty) return 'SV';

    final first = parts.first[0].toUpperCase();
    final last = parts.length > 1 ? parts.last[0].toUpperCase() : '';

    return '$first$last';
  }

  Future<void> _openAllDeadlines() async {
    final targetIndex = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => const AllDeadlinesScreen(),
      ),
    );

    if (targetIndex != null) {
      widget.onTabTapped(targetIndex);
    }
  }

  Future<void> _openClassDetail(Map<String, dynamic> item) async {
    final targetIndex = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => StudentClassDetailScreen(
          classroomId: item['id'],
          classCodeWithName: _buildClassCodeWithName(item),
          className: item['className'] ?? '',
          instructor: item['instructor'] ?? '',
          semester: item['semester'] ?? '',
        ),
      ),
    );

    if (targetIndex != null) {
      widget.onTabTapped(targetIndex);
    }
  }

  void _openActivityDetail(Map<String, dynamic> activity) {
    final dueAtStr =
        activity['deadline']?.toString() ?? _formatDueAt(activity['dueAt']);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentActivityDetailScreen(
          activity: {
            'id': activity['id'],
            'title': activity['title'] ?? '',
            'type':
                activity['type'] ?? _mapActivityType(activity['activityType']),
            'deadline': dueAtStr,
            'status': activity['status'] ??
                _mapActivityStatus(activity['submissionStatus']),
            'description': activity['description'] ?? '',
            'submissionId': activity['submissionId'],
            'submissionStatus': activity['submissionStatus'],
            'submissionTime': activity['submissionTime'],
            'attachmentCount': activity['attachmentCount'],
            'commentCount': activity['commentCount'],
            'teacherFeedback': activity['teacherFeedback'],
            'score': activity['score'],
            'maxScore': activity['maxScore'],
          },
        ),
      ),
    );
  }

  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NotificationScreen(showBackButton: true),
      ),
    );

    await _loadUnreadNotificationCount();
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final displayedActivities = _upcomingActivities.take(3).toList();
    final displayedClasses = widget.myClasses.take(3).toList();

    return RefreshIndicator(
      onRefresh: _loadInitialData,
      color: _primaryColor,
      backgroundColor: _surfaceColor,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: _DashboardHeader(
                fullName: user?.fullName ?? 'Sinh viên',
                initials: _getInitials(user?.fullName),
                pendingCount: _pendingCount,
                unreadNotificationCount: _unreadNotificationCount,
                onProfilePressed: () => widget.onTabTapped(4),
                onNotificationPressed: _openNotifications,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
              child: _JoinClassButton(
                onPressed: widget.onJoinClassPressed,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _SectionHeader(
              title: 'Deadline sắp tới',
              badgeText: '$_pendingCount',
              badgeColor: _dangerColor,
              actionText: 'Xem tất cả',
              onActionPressed: _openAllDeadlines,
            ),
          ),
          if (_isLoading)
            const SliverToBoxAdapter(
              child: _DashboardLoading(),
            )
          else if (displayedActivities.isEmpty)
            const SliverToBoxAdapter(
              child: _EmptyCard(
                icon: Icons.task_alt_rounded,
                title: 'Không có deadline nào sắp tới',
                message: 'Bạn đang kiểm soát tiến độ rất tốt.',
              ),
            )
          else
            SliverList.separated(
              itemCount: displayedActivities.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final activity = displayedActivities[index];

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _DeadlineCard(
                    title: activity['title'] ?? '',
                    description: activity['description'] ?? '',
                    deadline:
                        activity['deadline']?.toString() ?? 'Không có hạn',
                    onTap: () => _openActivityDetail(activity),
                  ),
                );
              },
            ),
          SliverToBoxAdapter(
            child: _SectionHeader(
              title: 'Lớp học của bạn',
              actionText: 'Xem tất cả',
              onActionPressed: () => widget.onTabTapped(1),
            ),
          ),
          if (displayedClasses.isEmpty)
            const SliverToBoxAdapter(
              child: _EmptyCard(
                icon: Icons.school_outlined,
                title: 'Bạn chưa tham gia lớp học nào',
                message: 'Bấm “Tham gia lớp học” để bắt đầu.',
              ),
            )
          else
            SliverList.separated(
              itemCount: displayedClasses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = displayedClasses[index];

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _ClassCard(
                    classCode: item['classCode'] ?? '',
                    instructor: item['instructor'] ?? '',
                    semester: item['semester'] ?? '',
                    onTap: () => _openClassDetail(item),
                  ),
                );
              },
            ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 32),
          ),
        ],
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final String fullName;
  final String initials;
  final int pendingCount;
  final int unreadNotificationCount;
  final VoidCallback onProfilePressed;
  final VoidCallback onNotificationPressed;

  const _DashboardHeader({
    required this.fullName,
    required this.initials,
    required this.pendingCount,
    required this.unreadNotificationCount,
    required this.onProfilePressed,
    required this.onNotificationPressed,
  });

  static const Color _primaryColor = Color(0xFF7EC07E);
  static const Color _surfaceColor = Colors.white;
  static const Color _textColor = Color(0xFF0F172A);
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _dangerColor = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _textColor.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onProfilePressed,
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: _primaryColor,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withOpacity(0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xin chào, $fullName!',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  pendingCount > 0
                      ? 'Bạn có $pendingCount deadline cần xử lý'
                      : 'Hôm nay chưa có deadline cần xử lý',
                  style: TextStyle(
                    color: pendingCount > 0 ? _dangerColor : _mutedTextColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _NotificationButton(
            count: unreadNotificationCount,
            onPressed: onNotificationPressed,
          ),
        ],
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  final int count;
  final VoidCallback onPressed;

  const _NotificationButton({
    required this.count,
    required this.onPressed,
  });

  static const Color _textColor = Color(0xFF0F172A);
  static const Color _dangerColor = Color(0xFFEF4444);
  static const Color _fieldColor = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton.filledTonal(
          onPressed: onPressed,
          style: IconButton.styleFrom(
            backgroundColor: _fieldColor,
            foregroundColor: _textColor,
          ),
          icon: const Icon(Icons.notifications_none_rounded),
        ),
        if (count > 0)
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: _dangerColor,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Text(
                count > 9 ? '9+' : '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _JoinClassButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _JoinClassButton({
    required this.onPressed,
  });

  static const Color _primaryColor = Color(0xFF7EC07E);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tham gia lớp học'),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? badgeText;
  final Color? badgeColor;
  final String actionText;
  final VoidCallback onActionPressed;

  const _SectionHeader({
    required this.title,
    required this.actionText,
    required this.onActionPressed,
    this.badgeText,
    this.badgeColor,
  });

  static const Color _primaryColor = Color(0xFF7EC07E);
  static const Color _textColor = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    final showBadge = badgeText != null && badgeText!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _textColor,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                if (showBadge) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor ?? _primaryColor,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      badgeText!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          TextButton(
            onPressed: onActionPressed,
            style: TextButton.styleFrom(
              foregroundColor: _primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text(
              actionText,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeadlineCard extends StatelessWidget {
  final String title;
  final String description;
  final String deadline;
  final VoidCallback onTap;

  const _DeadlineCard({
    required this.title,
    required this.description,
    required this.deadline,
    required this.onTap,
  });

  static const Color _textColor = Color(0xFF0F172A);
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _dangerColor = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    return _TapCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _dangerColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.assignment_late_outlined,
              color: _dangerColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? 'Hoạt động chưa có tiêu đề' : title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textColor,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (description.trim().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _mutedTextColor,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 9),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _dangerColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: _dangerColor.withOpacity(0.12),
                    ),
                  ),
                  child: Text(
                    deadline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _dangerColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(
            Icons.chevron_right_rounded,
            color: _mutedTextColor,
          ),
        ],
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final String classCode;
  final String instructor;
  final String semester;
  final VoidCallback onTap;

  const _ClassCard({
    required this.classCode,
    required this.instructor,
    required this.semester,
    required this.onTap,
  });

  static const Color _primaryColor = Color(0xFF7EC07E);
  static const Color _textColor = Color(0xFF0F172A);
  static const Color _mutedTextColor = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return _TapCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: _primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  classCode.isEmpty ? 'Lớp học' : classCode,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textColor,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (instructor.trim().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    instructor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _mutedTextColor,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (semester.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    semester,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _mutedTextColor.withOpacity(0.78),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(
            Icons.chevron_right_rounded,
            color: _mutedTextColor,
          ),
        ],
      ),
    );
  }
}

class _TapCard extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _TapCard({
    required this.child,
    required this.onTap,
  });

  static const Color _surfaceColor = Colors.white;
  static const Color _textColor = Color(0xFF0F172A);
  static const Color _borderColor = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _surfaceColor,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _borderColor.withOpacity(0.75),
            ),
            boxShadow: [
              BoxShadow(
                color: _textColor.withOpacity(0.035),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  static const Color _primaryColor = Color(0xFF7EC07E);
  static const Color _surfaceColor = Colors.white;
  static const Color _textColor = Color(0xFF0F172A);
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _borderColor),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: _primaryColor,
              size: 34,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _textColor,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _mutedTextColor,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  static const Color _primaryColor = Color(0xFF7EC07E);

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(28),
      child: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: _primaryColor,
          ),
        ),
      ),
    );
  }
}