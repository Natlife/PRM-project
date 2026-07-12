import 'package:flutter/material.dart';

import '../../services/classroom_service.dart';
import '../../services/dashboard_service.dart';
import '../../services/event_service.dart';
import '../common/notification_screen.dart';
import '../common/profile_screen.dart';
import 'class_detail_screen.dart';
import 'components/activity_detail_screen.dart';
import 'create_activity_screen.dart';
import 'create_class_screen.dart';
import 'create_event_screen.dart';
import 'create_project_screen.dart';
import 'project_detail_screen.dart';
import 'teacher_event_detail_screen.dart';

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() =>
      _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  static const Color _primaryColor = Color(0xFF22A06B);
  static const Color _primaryDarkColor = Color(0xFF167A52);
  static const Color _backgroundColor = Color(0xFFF5F7F6);
  static const Color _surfaceColor = Colors.white;
  static const Color _softGreenColor = Color(0xFFEAF7F0);
  static const Color _inputBackgroundColor = Color(0xFFF9FBFA);
  static const Color _textPrimaryColor = Color(0xFF17211B);
  static const Color _textSecondaryColor = Color(0xFF66736B);
  static const Color _borderColor = Color(0xFFE2E8E4);
  static const Color _errorColor = Color(0xFFDC3D43);
  static const Color _warningColor = Color(0xFFF59E0B);

  int _selectedIndex = 0;
  bool _isLoading = true;

  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _activities = [];
  List<Map<String, dynamic>> _projects = [];
  List<Map<String, dynamic>> _events = [];

  int _totalStudents = 0;
  int _pendingGrading = 0;
  int _activeGroups = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final Map<String, dynamic> dashboard =
          await DashboardService()
              .getTeacherDashboardOverview();

      final List<Map<String, dynamic>> events =
          await EventService().getTeacherEvents();

      final List<Map<String, dynamic>> classrooms =
          _sortNewestFirst(
        List<Map<String, dynamic>>.from(
          dashboard['classrooms'] ?? const [],
        ),
        [
          'createdAt',
          'updatedAt',
          'id',
        ],
      );

      final List<Map<String, dynamic>> projects =
          _mapProjects(
        List<Map<String, dynamic>>.from(
          dashboard['projects'] ?? const [],
        ),
      );

      final List<Map<String, dynamic>> sortedEvents =
          _sortNewestFirst(
        List<Map<String, dynamic>>.from(events),
        [
          'startAt',
          'createdAt',
          'id',
        ],
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _classes = classrooms;

        _activities = _mapActivities(
          List<Map<String, dynamic>>.from(
            dashboard['activities'] ?? const [],
          ),
        );

        _projects = projects;
        _events = sortedEvents;

        _totalStudents =
            dashboard['totalStudentsCount'] ?? 0;

        _pendingGrading =
            dashboard['pendingGradingCount'] ?? 0;

        _activeGroups =
            dashboard['activeGroupsCount'] ?? 0;

        _isLoading = false;
      });
    } catch (error) {
      try {
        final List<Map<String, dynamic>> classes =
            _sortNewestFirst(
          await ClassroomService()
              .getTeacherClassrooms(),
          [
            'createdAt',
            'updatedAt',
            'id',
          ],
        );

        if (!mounted) {
          return;
        }

        setState(() {
          _classes = classes;
          _activities = [];
          _projects = [];
          _events = [];

          _totalStudents = classes.fold<int>(
            0,
            (
              int sum,
              Map<String, dynamic> item,
            ) {
              return sum +
                  ((item['studentCount'] as int?) ??
                      0);
            },
          );

          _pendingGrading = 0;
          _activeGroups = 0;
          _isLoading = false;
        });
      } catch (innerError) {
        if (!mounted) {
          return;
        }

        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lỗi tải dữ liệu giảng viên: '
              '$innerError',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: _errorColor,
          ),
        );
      }

      debugPrint(
        'Teacher dashboard overview failed: $error',
      );
    }
  }

  List<Map<String, dynamic>> _mapActivities(
    List<Map<String, dynamic>> raw,
  ) {
    return raw.map(
      (Map<String, dynamic> activity) {
        final int pending =
            (activity['submissionSummary']
                        ?['commentCount']
                    as num?)
                ?.toInt() ??
            0;

        return {
          'id': activity['id'],
          'title': activity['title'] ?? '',
          'className':
              activity['classroomName'] ??
              activity['classroomCode'] ??
              '',
          'date': _formatDate(
            activity['dueAt'],
          ),
          'status':
              activity['status']?.toString() ?? '',
          'description':
              activity['description'] ?? '',
          'submissions': pending > 0
              ? '$pending bài chờ chấm'
              : activity['activityType'] ??
                  'Activity',
        };
      },
    ).toList();
  }

  List<Map<String, dynamic>> _mapProjects(
    List<Map<String, dynamic>> raw,
  ) {
    final List<Map<String, dynamic>> mapped =
        raw.map(
      (Map<String, dynamic> project) {
        final List<Map<String, dynamic>> members =
            List<Map<String, dynamic>>.from(
          project['members'] ?? const [],
        );

        return {
          'id': project['id'],
          'createdAt': project['createdAt'],
          'latestMilestoneDueAt':
              project['latestMilestoneDueAt'],
          'title':
              project['projectName'] ??
              project['groupName'] ??
              '',
          'projectName':
              project['projectName'] ??
              project['groupName'] ??
              '',
          'group': project['groupName'] ?? '',
          'groupName':
              project['groupName'] ?? '',
          'class':
              project['classroomCode'] ?? '',
          'className':
              project['classroomName'] ?? '',
          'date': _formatDate(
            project['latestMilestoneDueAt'],
          ),
          'leader':
              project['leader']?['fullName'],
          'members':
              '${project['memberCount'] ?? members.length} '
              'sinh viên',
          'membersList': members.map(
            (Map<String, dynamic> member) {
              return member['fullName'] ??
                  member['userName'] ??
                  '';
            },
          ).toList(),
          'membersData': members,
          'progress':
              ((project['progressPercent'] ?? 0)
                          as num)
                      .toDouble() /
                  100.0,
          'milestones':
              project['milestones'] ?? const [],
        };
      },
    ).toList();

    return _sortNewestFirst(
      mapped,
      [
        'createdAt',
        'latestMilestoneDueAt',
        'id',
      ],
    );
  }

  DateTime? _parseSortDate(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    final String raw = value.toString().trim();

    if (raw.isEmpty) {
      return null;
    }

    return DateTime.tryParse(raw);
  }

  List<Map<String, dynamic>> _sortNewestFirst(
    List<Map<String, dynamic>> items,
    List<String> candidateKeys,
  ) {
    final List<Map<String, dynamic>> sorted =
        List<Map<String, dynamic>>.from(items);

    sorted.sort(
      (
        Map<String, dynamic> first,
        Map<String, dynamic> second,
      ) {
        for (final String key in candidateKeys) {
          final DateTime? firstDate =
              _parseSortDate(first[key]);

          final DateTime? secondDate =
              _parseSortDate(second[key]);

          if (firstDate != null ||
              secondDate != null) {
            if (firstDate == null) {
              return 1;
            }

            if (secondDate == null) {
              return -1;
            }

            final int comparison =
                secondDate.compareTo(firstDate);

            if (comparison != 0) {
              return comparison;
            }
          }
        }

        final int firstId =
            (first['id'] as num?)?.toInt() ?? -1;

        final int secondId =
            (second['id'] as num?)?.toInt() ?? -1;

        return secondId.compareTo(firstId);
      },
    );

    return sorted;
  }

  String _formatDate(dynamic raw) {
    if (raw == null) {
      return '';
    }

    final String value =
        raw.toString().split('T').first;

    final List<String> parts = value.split('-');

    if (parts.length == 3) {
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    }

    return value;
  }

  String _eventStatusLabel(String status) {
    switch (status) {
      case 'LIVE':
        return 'Đang diễn ra';

      case 'COMPLETED':
        return 'Đã hoàn thành';

      case 'CANCELLED':
        return 'Đã hủy';

      case 'SCHEDULED':
      default:
        return 'Chưa diễn ra';
    }
  }

  Color _eventStatusColor(String status) {
    switch (status) {
      case 'LIVE':
        return _primaryColor;

      case 'COMPLETED':
        return const Color(0xFF718078);

      case 'CANCELLED':
        return _errorColor;

      case 'SCHEDULED':
      default:
        return _warningColor;
    }
  }

  IconData _eventStatusIcon(String status) {
    switch (status) {
      case 'LIVE':
        return Icons.play_circle_outline_rounded;

      case 'COMPLETED':
        return Icons.check_circle_outline_rounded;

      case 'CANCELLED':
        return Icons.cancel_outlined;

      case 'SCHEDULED':
      default:
        return Icons.schedule_outlined;
    }
  }

  ButtonStyle _toolbarButtonStyle() {
    return ElevatedButton.styleFrom(
      elevation: 0,
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  Future<void> _openCreateClass() async {
    final Map<String, dynamic>? result =
        await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute<Map<String, dynamic>>(
        builder: (BuildContext context) {
          return const CreateClassScreen();
        },
      ),
    );

    if (result != null) {
      await _loadData();
    }
  }

  Future<void> _openCreateActivity() async {
    final Map<String, dynamic>? result =
        await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute<Map<String, dynamic>>(
        builder: (BuildContext context) {
          return CreateActivityScreen(
            availableClassrooms: _classes,
          );
        },
      ),
    );

    if (result != null) {
      await _loadData();
    }
  }

  Future<void> _openCreateProject() async {
    final Map<String, dynamic>? result =
        await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute<Map<String, dynamic>>(
        builder: (BuildContext context) {
          return CreateProjectScreen(
            availableClassrooms: _classes,
          );
        },
      ),
    );

    if (result != null) {
      await _loadData();
    }
  }

  Future<void> _openCreateEvent() async {
    final Map<String, dynamic>? result =
        await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute<Map<String, dynamic>>(
        builder: (BuildContext context) {
          return CreateEventScreen(
            classrooms: _classes,
          );
        },
      ),
    );

    if (result == null) {
      return;
    }

    try {
      await EventService().createTeacherEvent(
        result,
      );

      await _loadData();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lỗi tạo sự kiện: $error',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingState()
            : _buildCurrentPage(),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: SizedBox(
        width: 30,
        height: 30,
        child: CircularProgressIndicator(
          color: _primaryColor,
          strokeWidth: 2.8,
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        border: const Border(
          top: BorderSide(
            color: _borderColor,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: _textPrimaryColor.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: _surfaceColor,
        elevation: 0,
        selectedItemColor: _primaryColor,
        unselectedItemColor: _textSecondaryColor,
        selectedFontSize: 10.5,
        unselectedFontSize: 10,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.dashboard_outlined,
            ),
            activeIcon: Icon(
              Icons.dashboard_rounded,
            ),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.school_outlined,
            ),
            activeIcon: Icon(
              Icons.school_rounded,
            ),
            label: 'Lớp học',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.assignment_outlined,
            ),
            activeIcon: Icon(
              Icons.assignment_rounded,
            ),
            label: 'Hoạt động',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.group_work_outlined,
            ),
            activeIcon: Icon(
              Icons.group_work_rounded,
            ),
            label: 'Dự án',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.event_note_outlined,
            ),
            activeIcon: Icon(
              Icons.event_note_rounded,
            ),
            label: 'Sự kiện',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.person_outline_rounded,
            ),
            activeIcon: Icon(
              Icons.person_rounded,
            ),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();

      case 1:
        return _buildClasses();

      case 2:
        return _buildActivities();

      case 3:
        return _buildProjects();

      case 4:
        return _buildEvents();

      case 5:
        return const ProfileScreen(
          showBackButton: false,
        );

      default:
        return _buildDashboard();
    }
  }

  Widget _buildHeader(
    String title, {
    VoidCallback? onRefresh,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        22,
        20,
        16,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: _textPrimaryColor,
                fontSize: 25,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ),
          _buildHeaderAction(
            icon: Icons.notifications_outlined,
            tooltip: 'Thông báo',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (BuildContext context) {
                    return const NotificationScreen(
                      showBackButton: true,
                    );
                  },
                ),
              );
            },
          ),
          if (onRefresh != null) ...[
            const SizedBox(width: 8),
            _buildHeaderAction(
              icon: Icons.refresh_rounded,
              tooltip: 'Làm mới',
              onTap: onRefresh,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: _surfaceColor,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: _borderColor,
            ),
          ),
          child: Tooltip(
            message: tooltip,
            child: Icon(
              icon,
              color: _textPrimaryColor,
              size: 21,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    return RefreshIndicator(
      color: _primaryColor,
      onRefresh: _loadData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: [
          _buildHeader(
            'Dashboard',
            onRefresh: _loadData,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              0,
              20,
              32,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 720,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            value:
                                '${_classes.length}',
                            label: 'Lớp học',
                            icon:
                                Icons.school_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            value: '$_totalStudents',
                            label: 'Sinh viên',
                            icon:
                                Icons.people_outline_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            value: '$_activeGroups',
                            label: 'Nhóm dự án',
                            icon:
                                Icons.groups_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            value:
                                '$_pendingGrading',
                            label: 'Chờ chấm',
                            icon: Icons
                                .pending_actions_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    _buildDashboardSectionTitle(),
                    const SizedBox(height: 12),
                    _buildQuickAction(
                      title: 'Tạo lớp học',
                      subtitle:
                          'Khởi tạo lớp mới với lịch học '
                          'và mã tham gia',
                      icon: Icons.add_business_outlined,
                      onTap: _openCreateClass,
                    ),
                    const SizedBox(height: 10),
                    _buildQuickAction(
                      title: 'Tạo hoạt động',
                      subtitle:
                          'Giao bài, quiz hoặc nhiệm vụ '
                          'học tập mới',
                      icon:
                          Icons.assignment_add,
                      onTap: _openCreateActivity,
                    ),
                    const SizedBox(height: 10),
                    _buildQuickAction(
                      title:
                          'Tạo sự kiện phản biện',
                      subtitle:
                          'Tạo lịch review, defense hoặc '
                          'demo cho lớp',
                      icon:
                          Icons.event_available_outlined,
                      onTap: _openCreateEvent,
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

  Widget _buildDashboardSectionTitle() {
    return const Row(
      children: [
        Expanded(
          child: Text(
            'Thao tác nhanh',
            style: TextStyle(
              color: _textPrimaryColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClasses() {
    return Column(
      children: [
        _buildHeader(
          'Lớp học',
          onRefresh: _loadData,
        ),
        _buildToolbar(
          buttonLabel: 'Tạo lớp',
          onPressed: _openCreateClass,
        ),
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              20,
              16,
              20,
              30,
            ),
            itemCount: _classes.length,
            itemBuilder: (
              BuildContext context,
              int index,
            ) {
              final Map<String, dynamic> item =
                  _classes[index];

              return _buildSimpleCard(
                icon: Icons.school_outlined,
                title:
                    item['name'] ??
                    item['className'] ??
                    item['code'] ??
                    '',
                subtitle:
                    '${item['code'] ?? ''} • '
                    '${item['studentCount'] ?? item['studentsCount'] ?? 0} '
                    'sinh viên',
                onTap: () async {
                  final dynamic result =
                      await Navigator.push(
                    context,
                    MaterialPageRoute<dynamic>(
                      builder: (
                        BuildContext context,
                      ) {
                        return ClassDetailScreen(
                          classroomId:
                              (item['id'] as num?)
                                  ?.toInt(),
                          className:
                              item['name'] ??
                              item['className'] ??
                              '',
                          classCode:
                              item['code'] ?? '',
                          studentsCount:
                              (item['studentCount']
                                          as num?)
                                      ?.toInt() ??
                                  (item['studentsCount']
                                          as num?)
                                      ?.toInt() ??
                                  0,
                        );
                      },
                    ),
                  );

                  if (result != null) {
                    await _loadData();
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActivities() {
    return Column(
      children: [
        _buildHeader(
          'Hoạt động',
          onRefresh: _loadData,
        ),
        _buildToolbar(
          buttonLabel: 'Tạo hoạt động',
          onPressed: _openCreateActivity,
        ),
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              20,
              16,
              20,
              30,
            ),
            itemCount: _activities.length,
            itemBuilder: (
              BuildContext context,
              int index,
            ) {
              final Map<String, dynamic> item =
                  _activities[index];

              return _buildSimpleCard(
                icon:
                    Icons.assignment_outlined,
                title: item['title'] ?? '',
                subtitle:
                    '${item['className'] ?? ''} • '
                    '${item['date'] ?? ''} • '
                    '${item['submissions'] ?? ''}',
                onTap: () async {
                  final dynamic result =
                      await Navigator.push(
                    context,
                    MaterialPageRoute<dynamic>(
                      builder: (
                        BuildContext context,
                      ) {
                        return ActivityDetailScreen(
                          activityId:
                              (item['id'] as num?)
                                  ?.toInt(),
                          activityTitle:
                              item['title'] ?? '',
                          deadline:
                              item['date'] ?? '',
                          submissions:
                              item['submissions'] ??
                              '',
                          description:
                              item['description'] ??
                              '',
                          className:
                              item['className'] ?? '',
                        );
                      },
                    ),
                  );

                  if (result != null) {
                    await _loadData();
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProjects() {
    return Column(
      children: [
        _buildHeader(
          'Dự án',
          onRefresh: _loadData,
        ),
        _buildToolbar(
          buttonLabel: 'Tạo dự án',
          onPressed: _openCreateProject,
        ),
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              20,
              16,
              20,
              30,
            ),
            itemCount: _projects.length,
            itemBuilder: (
              BuildContext context,
              int index,
            ) {
              final Map<String, dynamic> item =
                  _projects[index];

              return _buildSimpleCard(
                icon: Icons.group_work_outlined,
                title: item['title'] ?? '',
                subtitle:
                    '${item['group'] ?? ''} • '
                    '${item['class'] ?? ''} • '
                    '${item['members'] ?? ''}',
                onTap: () async {
                  final dynamic result =
                      await Navigator.push(
                    context,
                    MaterialPageRoute<dynamic>(
                      builder: (
                        BuildContext context,
                      ) {
                        return ProjectDetailScreen(
                          project: item,
                          availableClasses: _classes
                              .map(
                                (
                                  Map<String, dynamic>
                                      classroom,
                                ) {
                                  return classroom['code']
                                          ?.toString() ??
                                      '';
                                },
                              )
                              .toList(),
                        );
                      },
                    ),
                  );

                  if (result != null) {
                    await _loadData();
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEvents() {
    return Column(
      children: [
        _buildHeader(
          'Sự kiện',
          onRefresh: _loadData,
        ),
        _buildToolbar(
          buttonLabel: 'Tạo sự kiện',
          onPressed: _openCreateEvent,
        ),
        Expanded(
          child: _events.isEmpty
              ? _buildEmptyEvents()
              : ListView.builder(
                  physics:
                      const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    30,
                  ),
                  itemCount: _events.length,
                  itemBuilder: (
                    BuildContext context,
                    int index,
                  ) {
                    final Map<String, dynamic>
                        event = _events[index];

                    final String status =
                        event['status']
                                ?.toString() ??
                            'SCHEDULED';

                    return _buildEventCard(
                      event: event,
                      status: status,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildToolbar({
    required String buttonLabel,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          style: _toolbarButtonStyle(),
          icon: const Icon(
            Icons.add_rounded,
            size: 19,
          ),
          label: Text(
            buttonLabel,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyEvents() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.symmetric(
          horizontal: 28,
          vertical: 30,
        ),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _borderColor,
          ),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_note_outlined,
              color: Color(0xFF9AA49E),
              size: 34,
            ),
            SizedBox(height: 10),
            Text(
              'Chưa có sự kiện nào',
              style: TextStyle(
                color: _textSecondaryColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard({
    required Map<String, dynamic> event,
    required String status,
  }) {
    final Color statusColor =
        _eventStatusColor(status);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 11),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _borderColor,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () async {
            final dynamic result =
                await Navigator.push(
              context,
              MaterialPageRoute<dynamic>(
                builder: (BuildContext context) {
                  return TeacherEventDetailScreen(
                    eventId:
                        (event['id'] as num?)
                                ?.toInt() ??
                            0,
                  );
                },
              ),
            );

            if (result != null) {
              await _loadData();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color:
                        statusColor.withOpacity(0.10),
                    borderRadius:
                        BorderRadius.circular(13),
                  ),
                  child: Icon(
                    _eventStatusIcon(status),
                    color: statusColor,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        event['title'] ?? '',
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _textPrimaryColor,
                          fontSize: 14,
                          height: 1.4,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.school_outlined,
                            color:
                                _textSecondaryColor,
                            size: 14,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              '${event['classroomCode'] ?? ''} • '
                              '${_formatDate(event['startAt'])}',
                              maxLines: 1,
                              overflow:
                                  TextOverflow.ellipsis,
                              style: const TextStyle(
                                color:
                                    _textSecondaryColor,
                                fontSize: 11.5,
                                fontWeight:
                                    FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor
                              .withOpacity(0.10),
                          borderRadius:
                              BorderRadius.circular(
                            100,
                          ),
                        ),
                        child: Text(
                          _eventStatusLabel(status),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10.5,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF9AA49E),
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _softGreenColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: _primaryDarkColor,
              size: 20,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _textPrimaryColor,
              fontSize: 23,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _textSecondaryColor,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _borderColor,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: _softGreenColor,
                    borderRadius:
                        BorderRadius.circular(13),
                  ),
                  child: Icon(
                    icon,
                    color: _primaryDarkColor,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: _textPrimaryColor,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color:
                              _textSecondaryColor,
                          fontSize: 11.5,
                          height: 1.4,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFF9AA49E),
                  size: 15,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 11),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _borderColor,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: _softGreenColor,
                    borderRadius:
                        BorderRadius.circular(13),
                  ),
                  child: Icon(
                    icon,
                    color: _primaryDarkColor,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _textPrimaryColor,
                          fontSize: 13.5,
                          height: 1.4,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          color:
                              _textSecondaryColor,
                          fontSize: 11.5,
                          height: 1.4,
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
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}