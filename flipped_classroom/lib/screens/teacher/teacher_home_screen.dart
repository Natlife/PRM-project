import 'dart:math';
import 'package:flutter/material.dart';
import '../common/profile_screen.dart';
import '../common/notification_screen.dart';
import 'class_detail_screen.dart';
import 'create_class_screen.dart';
import 'create_activity_screen.dart';
import 'components/activity_detail_screen.dart';
import 'create_project_screen.dart';
import 'project_detail_screen.dart';
import '../../services/classroom_service.dart';
import '../../services/dashboard_service.dart';
import '../../services/activity_service.dart';
import '../../services/project_service.dart';

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  int _selectedIndex = 0;
  String _classSearchQuery = '';
  String _activitySearchQuery = '';

  List<Map<String, dynamic>> _classes = [];
  bool _isLoadingClasses = true;
  int _totalStudents = 0;
  int _pendingGrading = 0;
  int _activeGroups = 0;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() => _isLoadingClasses = true);
    try {
      final results = await Future.wait([
        ClassroomService().getTeacherClassrooms(),
        DashboardService().getTeacherDashboard(),
      ]);

      final loadedClasses = results[0] as List<Map<String, dynamic>>;
      final summary = results[1] as Map<String, dynamic>;
      List<Map<String, dynamic>> loadedActivities = [];
      List<Map<String, dynamic>> loadedProjects = [];

      try {
        loadedActivities = await _loadTeacherActivities(loadedClasses);
      } catch (e) {
        debugPrint('Error loading teacher activities: $e');
      }

      try {
        loadedProjects = await _loadTeacherProjects(loadedClasses);
      } catch (e) {
        debugPrint('Error loading teacher projects: $e');
      }

      if (!mounted) return;
      setState(() {
        _classes = loadedClasses;
        _activitiesList = loadedActivities;
        _projectsList = loadedProjects;
        _totalStudents = summary['totalStudentsCount'] ?? 0;
        _pendingGrading = summary['pendingGradingCount'] ?? 0;
        _activeGroups = summary['activeGroupsCount'] ?? 0;
        _isLoadingClasses = false;
      });
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      try {
        final loadedClasses = await ClassroomService().getTeacherClassrooms();
        List<Map<String, dynamic>> loadedActivities = [];
        List<Map<String, dynamic>> loadedProjects = [];

        try {
          loadedActivities = await _loadTeacherActivities(loadedClasses);
        } catch (e) {
          debugPrint('Error loading teacher activities in fallback: $e');
        }

        try {
          loadedProjects = await _loadTeacherProjects(loadedClasses);
        } catch (e) {
          debugPrint('Error loading teacher projects in fallback: $e');
        }

        if (!mounted) return;

        setState(() {
          _classes = loadedClasses;
          _activitiesList = loadedActivities;
          _projectsList = loadedProjects;
          _totalStudents = loadedClasses.fold<int>(
            0,
            (sum, item) => sum + ((item['studentsCount'] as int?) ?? 0),
          );
          _pendingGrading = 0;
          _activeGroups = 0;
          _isLoadingClasses = false;
        });
      } catch (innerError) {
        debugPrint('Error loading teacher classrooms: $innerError');
        if (!mounted) return;

        setState(() {
          _isLoadingClasses = false;
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _loadTeacherActivities(
    List<Map<String, dynamic>> classrooms,
  ) async {
    final List<Map<String, dynamic>> activities = [];

    for (final classroom in classrooms) {
      final classroomId = classroom['id'] as int?;
      if (classroomId == null) continue;

      try {
        final items = await ActivityService().getTeacherActivities(classroomId);
        for (final activity in items) {
          final dueAt = activity['dueAt']?.toString() ?? '';
          final date = dueAt.isNotEmpty
              ? () {
                  final rawDate = dueAt.split('T').first;
                  final parts = rawDate.split('-');
                  return parts.length == 3
                      ? '${parts[2]}/${parts[1]}/${parts[0]}'
                      : rawDate;
                }()
              : '';
          final status = (activity['status'] ?? '').toString();

          activities.add({
            'id': activity['id'],
            'classroomId': classroomId,
            'title': activity['title'] ?? 'Hoat dong',
            'className': classroom['className'] ?? classroom['title'] ?? classroom['code'] ?? '',
            'status': status,
            'statusColor': status == 'PUBLISHED'
                ? const Color(0xFF7EC07E)
                : Colors.amberAccent,
            'submissions': activity['activityType'] ?? 'Activity',
            'date': date,
            'description': activity['description'] ?? '',
          });
        }
      } catch (e) {
        debugPrint('Error loading activities for classroom $classroomId: $e');
      }
    }

    activities.sort((a, b) => (b['date'] ?? '').compareTo(a['date'] ?? ''));
    return activities;
  }

  Future<List<Map<String, dynamic>>> _loadTeacherProjects(
    List<Map<String, dynamic>> classrooms,
  ) async {
    final List<Map<String, dynamic>> projects = [];

    for (final classroom in classrooms) {
      final classroomId = classroom['id'] as int?;
      if (classroomId == null) continue;

      try {
        final groups = await ProjectService().getClassroomProjectGroups(classroomId);
        for (final group in groups) {
          final groupId = (group['id'] as num?)?.toInt();
          if (groupId == null) continue;

          List<Map<String, dynamic>> milestones = [];
          List<dynamic> members = [];
          String? leaderName;
          double progress = 0.0;

          try {
            final detail = await ProjectService().getTeacherProjectGroupDetail(groupId);
            members = detail['members'] as List<dynamic>? ?? [];
            leaderName = detail['leader']?['fullName']?.toString();
          } catch (e) {
            debugPrint('Error loading project group detail $groupId: $e');
          }

          try {
            final milestoneItems = await ProjectService().getGroupMilestones(groupId);
            milestones = milestoneItems;
            if (milestoneItems.isNotEmpty) {
              final total = milestoneItems.fold<int>(
                0,
                (sum, item) => sum + (((item['progressPercent'] as num?) ?? 0).toInt()),
              );
              progress = (total / milestoneItems.length) / 100.0;
            }
          } catch (e) {
            debugPrint('Error loading milestones for group $groupId: $e');
          }

          projects.add({
            'id': groupId,
            'classroomId': classroomId,
            'title': group['projectName'] ?? group['groupName'] ?? 'Du an',
            'projectName': group['projectName'] ?? group['groupName'] ?? 'Du an',
            'class': classroom['code'] ?? '',
            'className': classroom['title'] ?? classroom['className'] ?? '',
            'group': group['groupName'] ?? '',
            'groupName': group['groupName'] ?? '',
            'members': '${group['memberCount'] ?? 0} sinh vien',
            'membersList': members
                .map((member) => member['fullName'] ?? member['userName'] ?? 'Thanh vien')
                .toList(),
            'membersData': members,
            'leader': leaderName,
            'leaderData': group['leader'],
            'date': '',
            'progress': progress,
            'milestones': milestones,
          });
        }
      } catch (e) {
        debugPrint('Error loading projects for classroom $classroomId: $e');
      }
    }

    return projects;
  }

  List<Map<String, dynamic>> _activitiesList = [];

  String _projectSearchQuery = '';

  List<Map<String, dynamic>> _projectsList = [];

  Future<void> _navigateToCreateProject() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateProjectScreen(
          availableClassrooms: _classes,
        ),
      ),
    );
    if (result != null) {
      _loadClasses();
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _navigateToCreateActivity() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateActivityScreen(availableClassrooms: _classes),
      ),
    );
    if (result != null) {
      _loadClasses();
    }
  }

  Future<void> _navigateToCreateClass() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const CreateClassScreen()),
    );
    if (result != null) {
      final List<dynamic> schedulesRaw = result['schedules'] as List<dynamic>? ?? [];
      final List<Map<String, dynamic>> schedulesRequest = [];
      for (var s in schedulesRaw) {
        if (s is String) {
          // Split only at the FIRST ': ' to avoid splitting on times like '7:30'
          final sepIdx = s.indexOf(': ');
          if (sepIdx != -1) {
            final dayStr = s.substring(0, sepIdx).trim();
            final slotStr = s.substring(sepIdx + 2).trim();
            
            int dayOfWeek = 0;
            if (dayStr == 'Thứ 2') dayOfWeek = 0;
            else if (dayStr == 'Thứ 3') dayOfWeek = 1;
            else if (dayStr == 'Thứ 4') dayOfWeek = 2;
            else if (dayStr == 'Thứ 5') dayOfWeek = 3;
            else if (dayStr == 'Thứ 6') dayOfWeek = 4;
            else if (dayStr == 'Thứ 7') dayOfWeek = 5;
            else if (dayStr == 'Chủ nhật') dayOfWeek = 6;
            
            String slotLabel = 'Slot 1';
            String startTime = '07:30:00';
            String endTime = '09:50:00';
            
            if (slotStr.contains('Slot 1')) {
              slotLabel = 'Slot 1';
              startTime = '07:30:00';
              endTime = '09:50:00';
            } else if (slotStr.contains('Slot 2')) {
              slotLabel = 'Slot 2';
              startTime = '10:00:00';
              endTime = '12:20:00';
            } else if (slotStr.contains('Slot 3')) {
              slotLabel = 'Slot 3';
              startTime = '12:50:00';
              endTime = '15:10:00';
            } else if (slotStr.contains('Slot 4')) {
              slotLabel = 'Slot 4';
              startTime = '15:20:00';
              endTime = '17:40:00';
            } else if (slotStr.contains('Slot 5')) {
              slotLabel = 'Slot 5';
              startTime = '18:00:00';
              endTime = '20:20:00';
            }
            
            schedulesRequest.add({
              'dayOfWeek': dayOfWeek,
              'slotLabel': slotLabel,
              'startTime': startTime,
              'endTime': endTime,
              'roomName': 'Phòng học trực tuyến',
            });
          }
        }
      }

      final String titleRaw = result['title'] as String? ?? 'Lớp học';
      final String codeRaw = result['code'] as String? ?? 'SE1904-PRM393';
      
      final cleanCode = codeRaw
          .toUpperCase()
          .replaceAll(' - ', '-')
          .replaceAll(' ', '-')
          .replaceAll(RegExp(r'[^A-Z0-9-]'), '-');

      try {
        await ClassroomService().createClassroom(
          code: cleanCode,
          name: titleRaw,
          description: result['description'] as String? ?? '',
          semesterCode: result['semester'] as String? ?? 'SU26',
          schedules: schedulesRequest,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tạo lớp học thành công!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFF7EC07E),
          ),
        );
        _loadClasses();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tạo lớp học: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildDashboardTab(),
      _buildClassesTab(),
      _buildActivitiesTab(),
      _buildProjectsTab(),
      const NotificationScreen(showBackButton: false),
      const ProfileScreen(showBackButton: false),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: pages,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: const Color(0xFF0F172A).withOpacity(0.06),
              width: 1.2,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFFFFFFFF),
          selectedItemColor: const Color(0xFF7EC07E),
          unselectedItemColor: const Color(0xFF0F172A).withOpacity(0.4),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
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
              icon: Icon(Icons.work_outline),
              activeIcon: Icon(Icons.work),
              label: 'Dự án',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_outlined),
              activeIcon: Icon(Icons.notifications),
              label: 'Thông báo',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Cá nhân',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardTab() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 24.0, bottom: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dashboard',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Chào mừng giảng viên!',
                  style: TextStyle(fontSize: 14, color: const Color(0xFF0F172A).withOpacity(0.5)),
                ),
              ],
            ),
          ),
        ),
        
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard('${_classes.length}', 'Lớp học', const Color(0xFF7EC07E)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildStatCard('$_totalStudents', 'Sinh viên', const Color(0xFF7EC07E)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard('$_activeGroups', 'Nhóm dự án', const Color(0xFF7EC07E)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildStatCard('$_pendingGrading', 'Cần chấm điểm', const Color(0xFF7EC07E)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 28.0, bottom: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Lớp học sắp diễn ra',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                GestureDetector(
                  onTap: () => _onItemTapped(1),
                  child: const Text(
                    'Xem tất cả',
                    style: TextStyle(fontSize: 13, color: Color(0xFF7EC07E), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),

        _isLoadingClasses
            ? const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(color: Color(0xFF7EC07E)),
                  ),
                ),
              )
            : SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final upcomingClasses = _classes.take(3).toList();
                      if (upcomingClasses.isEmpty) {
                        return const Center(
                          child: Text(
                            'Không có lớp học nào sắp diễn ra',
                            style: TextStyle(color: Color(0xFF94A3B8)),
                          ),
                        );
                      }

                final item = upcomingClasses[index];
                return GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ClassDetailScreen(
                          classroomId: item['id'] as int?,
                          className: item['title'],
                          classCode: item['code'],
                          studentsCount: item['studentsCount'],
                        ),
                      ),
                    );
                    if (result != null) {
                      if (result is Map) {
                        setState(() {
                          item['title'] = result['className'];
                          item['code'] = result['classCode'];
                        });
                      } else if (result is int) {
                        _onItemTapped(result);
                      }
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.04)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item['title'],
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                            ),
                            Text(
                              item['date'] ?? 'Hôm nay',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF7EC07E), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${item['studentsCount']} sinh viên',
                              style: TextStyle(fontSize: 12, color: const Color(0xFF0F172A).withOpacity(0.4)),
                            ),
                            Text(
                              item['time'] ?? 'Slot 1',
                              style: TextStyle(fontSize: 12, color: const Color(0xFF0F172A).withOpacity(0.4)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: min(3, _classes.length),
            ),
          ),
        ),

        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(left: 20.0, top: 28.0, bottom: 12.0),
            child: Text(
              'Tác vụ nhanh',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ),
        
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildQuickActionRow(
                icon: Icons.add_circle_outline,
                title: 'Tạo lớp học mới',
                subtitle: 'Khởi tạo lớp học mới và phân nhóm sinh viên',
                color: const Color(0xFF7EC07E),
                onTap: _navigateToCreateClass,
              ),
              const SizedBox(height: 10),
              _buildQuickActionRow(
                icon: Icons.assignment_turned_in_outlined,
                title: 'Chấm điểm hoạt động',
                subtitle: 'Đánh giá các milestone và bài tập của sinh viên',
                color: const Color(0xFF7EC07E),
                onTap: () => _onItemTapped(2),
              ),
              const SizedBox(height: 30),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.04)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(fontSize: 13, color: const Color(0xFF0F172A).withOpacity(0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildClassesTab() {
    final filteredClasses = _classes.where((item) {
      final query = _classSearchQuery.toLowerCase();
      final titleMatch = item['title'].toString().toLowerCase().contains(query);
      final semMatch = item['semester'].toString().toLowerCase().contains(query);
      return titleMatch || semMatch;
    }).toList();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 24.0, bottom: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Quản lý lớp học',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                ElevatedButton(
                  onPressed: _navigateToCreateClass,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7EC07E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                  ),
                  child: const Text(
                    'Tạo lớp',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 16.0),
            child: TextField(
              onChanged: (val) {
                setState(() {
                  _classSearchQuery = val;
                });
              },
              decoration: InputDecoration(
                hintText: 'Tìm kiếm lớp học',
                hintStyle: TextStyle(color: const Color(0xFF0F172A).withOpacity(0.3), fontSize: 14),
                prefixIcon: Icon(Icons.search, color: const Color(0xFF0F172A).withOpacity(0.4), size: 20),
                fillColor: const Color(0xFFFFFFFF),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),

        _isLoadingClasses
            ? const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(color: Color(0xFF7EC07E)),
                  ),
                ),
              )
            : SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (filteredClasses.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Text(
                        'Không tìm thấy lớp học nào',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    ),
                  );
                }
                
                final item = filteredClasses[index];
                final String displayTitle = item['title'];
                final String displayCode = item['code'];
                final String displaySemester = item['semester'];
                final String displayType = item['type'];
                final int displayCount = item['studentsCount'];
                final Color displayColor = item['color'] ?? const Color(0xFF7EC07E);
                
                final String shorthand = displayTitle.split(' ').first;

                return GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ClassDetailScreen(
                          classroomId: item['id'] as int?,
                          className: displayTitle,
                          classCode: displayCode,
                          studentsCount: displayCount,
                        ),
                      ),
                    );
                    if (result != null) {
                      if (result is Map) {
                        setState(() {
                          item['title'] = result['className'];
                          item['code'] = result['classCode'];
                        });
                      } else if (result is int) {
                        _onItemTapped(result);
                      }
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.04)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: displayColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: displayColor.withOpacity(0.3)),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                shorthand,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: displayColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayTitle,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    displayType,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: const Color(0xFF0F172A).withOpacity(0.4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$displayCount sinh viên',
                              style: TextStyle(
                                fontSize: 13,
                                color: const Color(0xFF0F172A).withOpacity(0.5),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A).withOpacity(0.06),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.04)),
                              ),
                              child: Text(
                                displaySemester,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: filteredClasses.isEmpty ? 1 : filteredClasses.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 20),
        ),
      ],
    );
  }

  Widget _buildActivitiesTab() {
    final filteredActivities = _activitiesList.where((act) {
      final query = _activitySearchQuery.trim().toLowerCase();
      if (query.isEmpty) return true;
      final title = (act['title'] as String).toLowerCase();
      final className = (act['className'] as String).toLowerCase();
      return title.contains(query) || className.contains(query);
    }).toList();

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Quản lý hoạt động',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            ElevatedButton(
              onPressed: _navigateToCreateActivity,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7EC07E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text(
                'Tạo mới',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        TextField(
          onChanged: (val) => setState(() => _activitySearchQuery = val),
          style: const TextStyle(color: Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: 'Tìm kiếm hoạt động',
            hintStyle: TextStyle(color: const Color(0xFF0F172A).withOpacity(0.3), fontSize: 14),
            suffixIcon: const Icon(Icons.search, color: Color(0xFF7EC07E), size: 20),
            fillColor: const Color(0xFFFFFFFF),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 18),
        if (filteredActivities.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 40.0),
              child: Text(
                'Không tìm thấy hoạt động nào',
                style: TextStyle(color: Color(0xFF94A3B8)),
              ),
            ),
          )
        else
          ...filteredActivities.map((act) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildActivityItem(act),
            );
          }),
      ],
    );
  }

  Widget _buildProjectsTab() {
    final filteredProjects = _projectsList.where((proj) {
      final query = _projectSearchQuery.trim().toLowerCase();
      if (query.isEmpty) return true;
      final title = (proj['title'] as String).toLowerCase();
      final classCode = (proj['class'] as String).toLowerCase();
      final group = (proj['group'] as String).toLowerCase();
      return title.contains(query) || classCode.contains(query) || group.contains(query);
    }).toList();

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Quản lý Dự án',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            ElevatedButton(
              onPressed: _navigateToCreateProject,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7EC07E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text(
                'Thêm dự án',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        TextField(
          onChanged: (val) => setState(() => _projectSearchQuery = val),
          style: const TextStyle(color: Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: 'Tìm kiếm dự án',
            hintStyle: TextStyle(color: const Color(0xFF0F172A).withOpacity(0.3), fontSize: 14),
            suffixIcon: const Icon(Icons.search, color: Color(0xFF7EC07E), size: 20),
            fillColor: const Color(0xFFFFFFFF),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 18),
        if (filteredProjects.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 40.0),
              child: Text(
                'Không tìm thấy dự án nào',
                style: TextStyle(color: Color(0xFF94A3B8)),
              ),
            ),
          )
        else
          ...filteredProjects.map((proj) => _buildProjectItem(proj)),
      ],
    );
  }

  Widget _buildProjectItem(Map<String, dynamic> proj) {
    final String title = proj['title'] ?? '';
    final String group = proj['group'] ?? proj['groupName'] ?? '';
    final String date = proj['date'] ?? '';
    final String classCode = proj['class'] ?? '';
    final String members = proj['members'] ?? '0 sinh viên';

    return GestureDetector(
      onTap: () async {
        final availableClasses = _classes.map((c) => c['code'] as String).toList();
        final result = await Navigator.push<Map<String, dynamic>>(
          context,
          MaterialPageRoute(
            builder: (context) => ProjectDetailScreen(
              project: proj,
              availableClasses: availableClasses,
            ),
          ),
        );
        if (result != null) {
          setState(() {
            proj['title'] = result['title'];
            proj['group'] = result['group'];
            proj['groupName'] = result['groupName'];
            proj['class'] = result['class'];
            proj['className'] = result['class'];
            proj['date'] = result['date'];
            proj['members'] = result['members'];
            proj['membersList'] = result['membersList'];
            proj['leader'] = result['leader'];
            proj['progress'] = result['progress'];
            proj['milestones'] = result['milestones'];
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.04)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7EC07E).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    classCode,
                    style: const TextStyle(color: Color(0xFF7EC07E), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  group,
                  style: TextStyle(fontSize: 12, color: const Color(0xFF0F172A).withOpacity(0.5)),
                ),
                Text(
                  members,
                  style: TextStyle(fontSize: 12, color: const Color(0xFF0F172A).withOpacity(0.5)),
                ),
                Text(
                  date,
                  style: TextStyle(fontSize: 12, color: const Color(0xFF0F172A).withOpacity(0.5)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    final String title = activity['title'] ?? '';
    final String className = activity['className'] ?? '';
    final String submissions = activity['submissions'] ?? '';
    final String deadline = activity['date'] ?? '25/06/2026';
    final String description = activity['description'] ?? 'Hoàn thiện đầy đủ các yêu cầu của bài tập thực hành';

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push<Map<String, dynamic>>(
          context,
          MaterialPageRoute(
            builder: (context) => ActivityDetailScreen(
              activityId: activity['id'] as int?,
              activityTitle: title,
              deadline: deadline,
              submissions: submissions,
              description: description,
              className: className,
            ),
          ),
        );
        if (result != null) {
          setState(() {
            activity['title'] = result['title'];
            activity['date'] = result['deadline'];
            activity['description'] = result['description'];
            activity['status'] = 'Đang mở (Hạn chót: ${result['deadline']})';
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.04)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7EC07E).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.assignment, color: Color(0xFF7EC07E), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  submissions,
                  style: TextStyle(fontSize: 12, color: const Color(0xFF0F172A).withOpacity(0.5)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7EC07E).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF7EC07E).withOpacity(0.3)),
                  ),
                  child: Text(
                    className,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7EC07E)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.04)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: const Color(0xFF0F172A).withOpacity(0.4), fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: const Color(0xFF0F172A).withOpacity(0.3)),
          ],
        ),
      ),
    );
  }
}
