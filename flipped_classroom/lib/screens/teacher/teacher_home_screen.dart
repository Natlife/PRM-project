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
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
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
    setState(() => _isLoading = true);
    try {
      final dashboard = await DashboardService().getTeacherDashboardOverview();
      final events = await EventService().getTeacherEvents();
      final classrooms = _sortNewestFirst(
        List<Map<String, dynamic>>.from(dashboard['classrooms'] ?? const []),
        ['createdAt', 'updatedAt', 'id'],
      );
      final projects = _mapProjects(
        List<Map<String, dynamic>>.from(dashboard['projects'] ?? const []),
      );
      final sortedEvents = _sortNewestFirst(
        List<Map<String, dynamic>>.from(events),
        ['startAt', 'createdAt', 'id'],
      );
      if (!mounted) return;
      setState(() {
        _classes = classrooms;
        _activities = _mapActivities(
          List<Map<String, dynamic>>.from(dashboard['activities'] ?? const []),
        );
        _projects = projects;
        _events = sortedEvents;
        _totalStudents = dashboard['totalStudentsCount'] ?? 0;
        _pendingGrading = dashboard['pendingGradingCount'] ?? 0;
        _activeGroups = dashboard['activeGroupsCount'] ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      try {
        final classes = _sortNewestFirst(
          await ClassroomService().getTeacherClassrooms(),
          ['createdAt', 'updatedAt', 'id'],
        );
        if (!mounted) return;
        setState(() {
          _classes = classes;
          _activities = [];
          _projects = [];
          _events = [];
          _totalStudents = classes.fold<int>(
            0,
            (sum, item) => sum + ((item['studentCount'] as int?) ?? 0),
          );
          _pendingGrading = 0;
          _activeGroups = 0;
          _isLoading = false;
        });
      } catch (inner) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải dữ liệu giảng viên: $inner'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      debugPrint('Teacher dashboard overview failed: $e');
    }
  }

  List<Map<String, dynamic>> _mapActivities(List<Map<String, dynamic>> raw) {
    return raw.map((activity) {
      final pending =
          (activity['submissionSummary']?['commentCount'] as num?)?.toInt() ??
          0;
      return {
        'id': activity['id'],
        'title': activity['title'] ?? '',
        'className':
            activity['classroomName'] ?? activity['classroomCode'] ?? '',
        'date': _formatDate(activity['dueAt']),
        'status': activity['status']?.toString() ?? '',
        'description': activity['description'] ?? '',
        'submissions': pending > 0
            ? '$pending bài chờ chấm'
            : (activity['activityType'] ?? 'Activity'),
      };
    }).toList();
  }

  List<Map<String, dynamic>> _mapProjects(List<Map<String, dynamic>> raw) {
    final mapped = raw.map((project) {
      final members = List<Map<String, dynamic>>.from(
        project['members'] ?? const [],
      );
      return {
        'id': project['id'],
        'createdAt': project['createdAt'],
        'latestMilestoneDueAt': project['latestMilestoneDueAt'],
        'title': project['projectName'] ?? project['groupName'] ?? '',
        'projectName': project['projectName'] ?? project['groupName'] ?? '',
        'group': project['groupName'] ?? '',
        'groupName': project['groupName'] ?? '',
        'class': project['classroomCode'] ?? '',
        'className': project['classroomName'] ?? '',
        'date': _formatDate(project['latestMilestoneDueAt']),
        'leader': project['leader']?['fullName'],
        'members': '${project['memberCount'] ?? members.length} sinh viên',
        'membersList': members
            .map((member) => member['fullName'] ?? member['userName'] ?? '')
            .toList(),
        'membersData': members,
        'progress':
            ((project['progressPercent'] ?? 0) as num).toDouble() / 100.0,
        'milestones': project['milestones'] ?? const [],
      };
    }).toList();

    return _sortNewestFirst(
      mapped,
      ['createdAt', 'latestMilestoneDueAt', 'id'],
    );
  }

  DateTime? _parseSortDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final raw = value.toString().trim();
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  List<Map<String, dynamic>> _sortNewestFirst(
    List<Map<String, dynamic>> items,
    List<String> candidateKeys,
  ) {
    final sorted = List<Map<String, dynamic>>.from(items);
    sorted.sort((a, b) {
      for (final key in candidateKeys) {
        final aDate = _parseSortDate(a[key]);
        final bDate = _parseSortDate(b[key]);
        if (aDate != null || bDate != null) {
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          final compare = bDate.compareTo(aDate);
          if (compare != 0) return compare;
        }
      }

      final aId = (a['id'] as num?)?.toInt() ?? -1;
      final bId = (b['id'] as num?)?.toInt() ?? -1;
      return bId.compareTo(aId);
    });
    return sorted;
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '';
    final value = raw.toString().split('T').first;
    final parts = value.split('-');
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
        return Colors.green;
      case 'COMPLETED':
        return Colors.grey;
      case 'CANCELLED':
        return Colors.redAccent;
      case 'SCHEDULED':
      default:
        return Colors.orange;
    }
  }

  ButtonStyle _toolbarButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF7EC07E),
      foregroundColor: const Color(0xFF0F172A),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Future<void> _openCreateClass() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const CreateClassScreen()),
    );
    if (result != null) {
      await _loadData();
    }
  }

  Future<void> _openCreateActivity() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CreateActivityScreen(availableClassrooms: _classes),
      ),
    );
    if (result != null) {
      await _loadData();
    }
  }

  Future<void> _openCreateProject() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CreateProjectScreen(availableClassrooms: _classes),
      ),
    );
    if (result != null) {
      await _loadData();
    }
  }

  Future<void> _openCreateEvent() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateEventScreen(classrooms: _classes),
      ),
    );
    if (result == null) return;
    try {
      await EventService().createTeacherEvent(result);
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tạo sự kiện: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF7EC07E)),
              )
            : _buildCurrentPage(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF7EC07E),
        unselectedItemColor: const Color(0xFF64748B),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            activeIcon: Icon(Icons.school),
            label: 'Lớp học',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Hoạt động',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_work_outlined),
            activeIcon: Icon(Icons.group_work),
            label: 'Dự án',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note_outlined),
            activeIcon: Icon(Icons.event_note),
            label: 'Sự kiện',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
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
        return const ProfileScreen(showBackButton: false);
      default:
        return _buildDashboard();
    }
  }

  Widget _buildHeader(String title, {VoidCallback? onRefresh}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const NotificationScreen(showBackButton: true),
                ),
              );
            },
            icon: const Icon(Icons.notifications_outlined),
          ),
          if (onRefresh != null)
            IconButton(onPressed: onRefresh, icon: const Icon(Icons.refresh)),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        children: [
          _buildHeader('Dashboard', onRefresh: _loadData),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard('${_classes.length}', 'Lớp học'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard('$_totalStudents', 'Sinh viên'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard('$_activeGroups', 'Nhóm dự án'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard('$_pendingGrading', 'Chờ chấm'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildQuickAction(
                  title: 'Tạo lớp học',
                  subtitle: 'Khởi tạo lớp mới với lịch học và mã tham gia',
                  onTap: _openCreateClass,
                ),
                const SizedBox(height: 12),
                _buildQuickAction(
                  title: 'Tạo hoạt động',
                  subtitle: 'Giao bài, quiz hoặc nhiệm vụ học tập mới',
                  onTap: _openCreateActivity,
                ),
                const SizedBox(height: 12),
                _buildQuickAction(
                  title: 'Tạo sự kiện phản biện',
                  subtitle: 'Tạo lịch review, defense hoặc demo cho lớp',
                  onTap: _openCreateEvent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClasses() {
    return Column(
      children: [
        _buildHeader('Lớp học', onRefresh: _loadData),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _openCreateClass,
              icon: const Icon(Icons.add),
              label: const Text('Tạo lớp'),
              style: _toolbarButtonStyle(),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _classes.length,
            itemBuilder: (context, index) {
              final item = _classes[index];
              return _buildSimpleCard(
                title: item['name'] ?? item['className'] ?? item['code'] ?? '',
                subtitle:
                    '${item['code'] ?? ''} • ${item['studentCount'] ?? item['studentsCount'] ?? 0} sinh viên',
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ClassDetailScreen(
                        classroomId: (item['id'] as num?)?.toInt(),
                        className: item['name'] ?? item['className'] ?? '',
                        classCode: item['code'] ?? '',
                        studentsCount:
                            (item['studentCount'] as num?)?.toInt() ??
                            (item['studentsCount'] as num?)?.toInt() ??
                            0,
                      ),
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
        _buildHeader('Hoạt động', onRefresh: _loadData),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _openCreateActivity,
              icon: const Icon(Icons.add),
              label: const Text('Tạo hoạt động'),
              style: _toolbarButtonStyle(),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _activities.length,
            itemBuilder: (context, index) {
              final item = _activities[index];
              return _buildSimpleCard(
                title: item['title'] ?? '',
                subtitle:
                    '${item['className'] ?? ''} • ${item['date'] ?? ''} • ${item['submissions'] ?? ''}',
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ActivityDetailScreen(
                        activityId: (item['id'] as num?)?.toInt(),
                        activityTitle: item['title'] ?? '',
                        deadline: item['date'] ?? '',
                        submissions: item['submissions'] ?? '',
                        description: item['description'] ?? '',
                        className: item['className'] ?? '',
                      ),
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
        _buildHeader('Dự án', onRefresh: _loadData),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _openCreateProject,
              icon: const Icon(Icons.add),
              label: const Text('Tạo dự án'),
              style: _toolbarButtonStyle(),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _projects.length,
            itemBuilder: (context, index) {
              final item = _projects[index];
              return _buildSimpleCard(
                title: item['title'] ?? '',
                subtitle:
                    '${item['group'] ?? ''} • ${item['class'] ?? ''} • ${item['members'] ?? ''}',
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProjectDetailScreen(
                        project: item,
                        availableClasses: _classes
                            .map(
                              (classroom) =>
                                  classroom['code']?.toString() ?? '',
                            )
                            .toList(),
                      ),
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
        _buildHeader('Sự kiện', onRefresh: _loadData),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _openCreateEvent,
              icon: const Icon(Icons.add),
              label: const Text('Tạo sự kiện'),
              style: _toolbarButtonStyle(),
            ),
          ),
        ),
        Expanded(
          child: _events.isEmpty
              ? const Center(
                  child: Text(
                    'Chưa có sự kiện nào',
                    style: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _events.length,
                  itemBuilder: (context, index) {
                    final event = _events[index];
                    final status = event['status']?.toString() ?? 'SCHEDULED';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: InkWell(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TeacherEventDetailScreen(
                                eventId: (event['id'] as num?)?.toInt() ?? 0,
                              ),
                            ),
                          );
                          if (result != null) {
                            await _loadData();
                          }
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    event['title'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                Text(
                                  _eventStatusLabel(status),
                                  style: TextStyle(
                                    color: _eventStatusColor(status),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${event['classroomCode'] ?? ''} • ${_formatDate(event['startAt'])}',
                              style: TextStyle(
                                color: const Color(
                                  0xFF0F172A,
                                ).withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: const Color(0xFF0F172A).withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF7EC07E).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.chevron_right, color: Color(0xFF7EC07E)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF0F172A).withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleCard({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: const Color(0xFF0F172A).withValues(alpha: 0.6),
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
