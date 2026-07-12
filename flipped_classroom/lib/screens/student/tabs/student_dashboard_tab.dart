import 'package:flutter/material.dart';

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
  static const Color _primaryColor = Color(0xFF22A06B);
  static const Color _primaryDarkColor = Color(0xFF167A52);
  static const Color _surfaceColor = Colors.white;
  static const Color _textPrimaryColor = Color(0xFF17211B);
  static const Color _textSecondaryColor = Color(0xFF66736B);
  static const Color _borderColor = Color(0xFFE2E8E4);
  static const Color _errorColor = Color(0xFFDC3D43);

  final NotificationService _notificationService = NotificationService();

  bool _isLoading = true;
  int _unreadNotificationCount = 0;

  Map<String, dynamic>? _dashboardData;
  List<Map<String, dynamic>> _upcomingActivities = [];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    _loadUnreadNotificationCount();
  }

  Future<void> _loadDashboard() async {
    try {
      final data = await DashboardService().getStudentDashboard();

      final List<Map<String, dynamic>> rawUpcomingActivities =
          List<Map<String, dynamic>>.from(
            data['upcomingActivities'] ?? const [],
          );

      final List<Map<String, dynamic>> normalizedUpcomingActivities = [];

      for (final Map<String, dynamic> activity in rawUpcomingActivities) {
        final Map<String, dynamic> submission = Map<String, dynamic>.from(
          activity['submissionSummary'] ?? const {},
        );

        final String submissionStatus =
            submission['status']?.toString() ?? 'NOT_SUBMITTED';

        final bool isDone =
            submissionStatus == 'SUBMITTED' ||
            submissionStatus == 'LATE_SUBMITTED' ||
            submissionStatus == 'GRADED';

        normalizedUpcomingActivities.add({
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
        });
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _dashboardData = data;
        _upcomingActivities = normalizedUpcomingActivities;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Error loading student dashboard: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUnreadNotificationCount() async {
    try {
      final notifications = await _notificationService.getNotifications();

      final int unreadCount = notifications.where((dynamic notification) {
        return notification['readAt'] == null;
      }).length;

      if (!mounted) {
        return;
      }

      setState(() {
        _unreadNotificationCount = unreadCount;
      });
    } catch (error) {
      debugPrint('Error loading unread notification count: $error');
    }
  }

  Future<void> _refreshDashboard() async {
    await Future.wait([_loadDashboard(), _loadUnreadNotificationCount()]);
  }

  String _buildClassCodeWithName(Map<String, dynamic> item) {
    final String existing = item['classCodeWithName']?.toString().trim() ?? '';

    if (existing.isNotEmpty) {
      return existing;
    }

    final String code = item['classCode']?.toString().trim() ?? '';

    final String name = item['className']?.toString().trim() ?? '';

    if (code.isNotEmpty && name.isNotEmpty) {
      return '$code - $name';
    }

    return code.isNotEmpty ? code : name;
  }

  String _mapActivityType(dynamic value) {
    final String type = value?.toString() ?? '';

    if (type == 'PRE_CLASS' || type == 'BEFORE_CLASS') {
      return 'Trước buổi học';
    }

    return 'Trong buổi học';
  }

  String _mapActivityStatus(dynamic value) {
    final String status = value?.toString() ?? '';

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

    return 'Hạn: ${value.toString().split('T').join(' ')}';
  }

  Widget _buildHeader({
    required String userName,
    required String avatarText,
    required dynamic pendingCount,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => widget.onTabTapped(4),
            child: Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _primaryColor,
                borderRadius: BorderRadius.circular(17),
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withOpacity(0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Text(
                avatarText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
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
                  'Xin chào, $userName!',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textPrimaryColor,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Bạn có $pendingCount deadline cần xử lý',
                  style: const TextStyle(
                    color: _errorColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: 'Thông báo',
                onPressed: () async {
                  await Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) {
                        return const NotificationScreen(showBackButton: true);
                      },
                    ),
                  );

                  if (!mounted) {
                    return;
                  }

                  await _loadUnreadNotificationCount();
                },
                style: IconButton.styleFrom(
                  foregroundColor: _textPrimaryColor,
                  backgroundColor: _surfaceColor,
                  side: const BorderSide(color: _borderColor),
                ),
                icon: const Icon(Icons.notifications_none_rounded, size: 24),
              ),
              if (_unreadNotificationCount > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 19,
                      minHeight: 19,
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _errorColor,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: _surfaceColor, width: 2),
                    ),
                    child: Text(
                      _unreadNotificationCount > 99
                          ? '99+'
                          : '$_unreadNotificationCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        height: 1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJoinClassButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton.icon(
          onPressed: widget.onJoinClassPressed,
          style: FilledButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: const Icon(Icons.add_rounded, size: 21),
          label: const Text(
            'Tham gia lớp học',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required VoidCallback onViewAll,
    dynamic count,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 12, 12),
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
                      color: _textPrimaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: 9),
                  Container(
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFECEE),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: _errorColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          TextButton(
            onPressed: onViewAll,
            style: TextButton.styleFrom(foregroundColor: _primaryDarkColor),
            child: const Text(
              'Xem tất cả',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingDeadlines() {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.6,
              valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyDeadlines() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _borderColor),
          ),
          child: const Column(
            children: [
              Icon(
                Icons.event_available_outlined,
                color: _primaryDarkColor,
                size: 30,
              ),
              SizedBox(height: 10),
              Text(
                'Không có deadline nào sắp tới',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textSecondaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeadlineCard(Map<String, dynamic> activity) {
    final String dueAt =
        activity['deadline']?.toString() ?? _formatDueAt(activity['dueAt']);

    return Material(
      color: _surfaceColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (BuildContext context) {
                return StudentActivityDetailScreen(
                  activity: {
                    'id': activity['id'],
                    'title': activity['title'] ?? '',
                    'type':
                        activity['type'] ??
                        _mapActivityType(activity['activityType']),
                    'deadline': dueAt,
                    'status':
                        activity['status'] ??
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
                );
              },
            ),
          );
        },
        child: Ink(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _borderColor),
            boxShadow: [
              BoxShadow(
                color: _textPrimaryColor.withOpacity(0.035),
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
                  color: const Color(0xFFFFECEE),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.assignment_late_outlined,
                  color: _errorColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity['title']?.toString() ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _textPrimaryColor,
                        fontSize: 14.5,
                        height: 1.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if ((activity['description'] ?? '')
                        .toString()
                        .isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        activity['description'].toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _textSecondaryColor,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 11),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          color: _errorColor,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            dueAt,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _errorColor,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF9AA49E),
                  size: 21,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassCard(Map<String, dynamic> item) {
    return Material(
      color: _surfaceColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          final dynamic targetIndex = await Navigator.push(
            context,
            MaterialPageRoute<dynamic>(
              builder: (BuildContext context) {
                return StudentClassDetailScreen(
                  classroomId: item['id'],
                  classCodeWithName: _buildClassCodeWithName(item),
                  className: item['className'] ?? '',
                  instructor: item['instructor'] ?? '',
                  semester: item['semester'] ?? '',
                );
              },
            ),
          );

          if (targetIndex != null && targetIndex is int) {
            widget.onTabTapped(targetIndex);
          }
        },
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7F0),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.school_outlined,
                  color: _primaryDarkColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['classCode']?.toString() ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _textPrimaryColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item['instructor']?.toString() ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _textSecondaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item['semester']?.toString() ?? '',
                      style: const TextStyle(
                        color: Color(0xFF8B9690),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF9AA49E),
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    final dynamic pendingCount = _dashboardData?['pendingActivitiesCount'] ?? 0;

    final List<Map<String, dynamic>> upcomingActivities = _upcomingActivities;

    final String userName = user?.fullName ?? 'Sinh viên';

    final String avatarText =
        user?.fullName.split(' ').last.substring(0, 1).toUpperCase() ?? 'SV';

    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      color: _primaryColor,
      backgroundColor: _surfaceColor,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: _buildHeader(
              userName: userName,
              avatarText: avatarText,
              pendingCount: pendingCount,
            ),
          ),
          SliverToBoxAdapter(child: _buildJoinClassButton()),
          SliverToBoxAdapter(
            child: _buildSectionHeader(
              title: 'Deadline sắp tới',
              count: pendingCount,
              onViewAll: () async {
                final dynamic targetIndex = await Navigator.push(
                  context,
                  MaterialPageRoute<dynamic>(
                    builder: (BuildContext context) {
                      return const AllDeadlinesScreen();
                    },
                  ),
                );

                if (targetIndex != null && targetIndex is int) {
                  widget.onTabTapped(targetIndex);
                }
              },
            ),
          ),
          if (_isLoading)
            _buildLoadingDeadlines()
          else if (upcomingActivities.isEmpty)
            _buildEmptyDeadlines()
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.separated(
                itemCount: upcomingActivities.length > 3
                    ? 3
                    : upcomingActivities.length,
                separatorBuilder: (BuildContext context, int index) {
                  return const SizedBox(height: 12);
                },
                itemBuilder: (BuildContext context, int index) {
                  return _buildDeadlineCard(upcomingActivities[index]);
                },
              ),
            ),
          SliverToBoxAdapter(
            child: _buildSectionHeader(
              title: 'Lớp học của bạn',
              onViewAll: () {
                widget.onTabTapped(1);
              },
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.separated(
              itemCount: widget.myClasses.length > 3
                  ? 3
                  : widget.myClasses.length,
              separatorBuilder: (BuildContext context, int index) {
                return const SizedBox(height: 12);
              },
              itemBuilder: (BuildContext context, int index) {
                return _buildClassCard(widget.myClasses[index]);
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }
}
