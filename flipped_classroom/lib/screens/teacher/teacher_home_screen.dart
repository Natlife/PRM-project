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

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  int _selectedIndex = 0;
  String _classSearchQuery = '';
  String _activitySearchQuery = '';

  final List<Map<String, dynamic>> _classes = [
    {
      'title': 'PRM - Lập trình mobile',
      'code': 'PRM393 - SE1904',
      'studentsCount': 30,
      'semester': 'SU26',
      'type': 'Chuyên ngành hẹp',
      'color': const Color(0xFF5A57FF),
      'time': 'Slot 1 (7:30-9:50)',
      'date': 'Hôm nay',
    },
    {
      'title': 'PRW - Phát triển web',
      'code': 'PRW301 - SE1902',
      'studentsCount': 28,
      'semester': 'FA26',
      'type': 'Chuyên ngành hẹp',
      'color': const Color(0xFFD946EF),
      'time': 'Slot 2 (10:00-12:20)',
      'date': 'Hôm nay',
    },
    {
      'title': 'IOT - Nhập môn IoT',
      'code': 'IOT102 - SE1901',
      'studentsCount': 35,
      'semester': 'SU26',
      'type': 'Nhập môn',
      'color': const Color(0xFF10B981),
      'time': 'Slot 4 (15:00-17:20)',
      'date': 'Ngày mai',
    },
    {
      'title': 'PRO - Đồ án Tốt nghiệp',
      'code': 'PRO391 - SE1801',
      'studentsCount': 25,
      'semester': 'SP26',
      'type': 'Chuyên ngành',
      'color': const Color(0xFFF59E0B),
      'time': 'Slot 3 (12:50-15:10)',
      'date': 'Ngày mai',
    },
  ];

  final List<Map<String, dynamic>> _activitiesList = [
    {
      'title': 'Đánh giá Milestone 1 - Dự án cuối kỳ',
      'className': 'PRM393 - SE1904',
      'status': 'Đã hoàn thành',
      'statusColor': Colors.greenAccent,
      'submissions': '8/8 nhóm đã nộp',
      'date': '15/03/2026',
    },
    {
      'title': 'Bài tập Chuẩn bị bài 4: Flutter Widget',
      'className': 'PRM393 - SE1904',
      'status': 'Đang mở (Trễ hạn: 23:59 hôm nay)',
      'statusColor': Colors.amberAccent,
      'submissions': '28/32 học viên đã nộp',
      'date': '19/03/2026',
    },
    {
      'title': 'Đánh giá Báo cáo nghiên cứu công nghệ',
      'className': 'PRW301 - SE1902',
      'status': 'Đang mở (Hạn chót: 3 ngày nữa)',
      'statusColor': const Color(0xFF2E8EFF),
      'submissions': '15/28 học viên đã nộp',
      'date': '22/03/2026',
    },
  ];

  String _projectSearchQuery = '';

  final List<Map<String, dynamic>> _projectsList = [
    {
      'title': 'Hệ thống quản lý Flipped Classroom',
      'class': 'PRM393 - SE1904',
      'className': 'PRM - Lập trình mobile',
      'group': 'Nhóm 1',
      'groupName': 'Nhóm 1',
      'members': '5 sinh viên',
      'membersList': ['Nguyễn Văn A', 'Trần Thị B', 'Lê Văn C', 'Phạm Văn D', 'Vũ Thị E'],
      'leader': 'Nguyễn Văn A',
      'date': '20/08/2026',
      'progress': 0.8,
      'milestones': [
        {
          'title': 'Phân tích yêu cầu',
          'date': '15/03/2026',
          'status': 'Hoàn thành',
        },
      ],
    },
    {
      'title': 'Ứng dụng theo dõi sức khỏe Gymtelligent',
      'class': 'PRM393 - SE1904',
      'className': 'PRM - Lập trình mobile',
      'group': 'Nhóm 2',
      'groupName': 'Nhóm 2',
      'members': '3 sinh viên',
      'membersList': ['Hoàng Văn F', 'Đỗ Thị G', 'Lê Văn C'],
      'leader': 'Hoàng Văn F',
      'date': '25/08/2026',
      'progress': 0.6,
      'milestones': [
        {
          'title': 'Phân tích yêu cầu',
          'date': '15/03/2026',
          'status': 'Hoàn thành',
        },
      ],
    },
    {
      'title': 'Hệ thống Đặt đồ ăn trực tuyến',
      'class': 'PRW301 - SE1902',
      'className': 'PRW - Phát triển web',
      'group': 'Nhóm 3',
      'groupName': 'Nhóm 3',
      'members': '4 sinh viên',
      'membersList': ['Lê Văn C', 'Phạm Văn D', 'Vũ Thị E', 'Nguyễn Văn A'],
      'leader': 'Lê Văn C',
      'date': '30/08/2026',
      'progress': 0.45,
      'milestones': [
        {
          'title': 'Phân tích yêu cầu',
          'date': '15/03/2026',
          'status': 'Đang thực hiện',
        },
      ],
    },
  ];

  Future<void> _navigateToCreateProject() async {
    final availableClasses = _classes.map((c) => c['code'] as String).toList();
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateProjectScreen(
          availableClasses: availableClasses,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _projectsList.insert(0, {
          'title': result['title'] as String,
          'class': result['className'] as String,
          'className': result['className'] as String,
          'group': result['group'] as String,
          'groupName': result['groupName'] as String,
          'members': result['members'] as String,
          'membersList': result['membersList'],
          'leader': result['leader'],
          'date': result['date'] as String,
          'progress': result['progress'] as double,
          'milestones': result['milestones'],
        });
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _navigateToCreateActivity() async {
    final classNames = _classes.map((c) => c['code'] as String).toList();
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateActivityScreen(classNames: classNames),
      ),
    );
    if (result != null) {
      setState(() {
        _activitiesList.insert(0, {
          'title': result['title'] as String,
          'className': result['className'] as String,
          'status': result['status'] as String,
          'statusColor': result['statusColor'] as Color,
          'submissions': result['submissions'] as String,
          'date': result['date'] as String,
          'description': result['description'] as String,
        });
      });
    }
  }

  Future<void> _navigateToCreateClass() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const CreateClassScreen()),
    );
    if (result != null) {
      setState(() {
        _classes.insert(0, {
          'title': result['title'] as String,
          'code': result['code'] as String,
          'studentsCount': result['studentsCount'] as int,
          'semester': result['semester'] as String,
          'type': result['type'] as String,
          'color': Colors.primaries[Random().nextInt(Colors.primaries.length)],
          'time': result['schedules'] != null && (result['schedules'] as List).isNotEmpty
              ? (result['schedules'] as List).first as String
              : 'Slot 1 (7:30-9:50)',
          'date': 'Hôm nay',
        });
      });
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
      backgroundColor: const Color(0xFF0F172A),
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
              color: Colors.white.withValues(alpha: 0.06),
              width: 1.2,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF1E293B),
          selectedItemColor: const Color(0xFF5A57FF),
          unselectedItemColor: Colors.white.withValues(alpha: 0.4),
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
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'Chào mừng giảng viên!',
                  style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
        ),
        
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard('${_classes.length}', 'Lớp học', const Color(0xFF5A57FF)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildStatCard('300', 'Sinh viên', const Color(0xFF2E8EFF)),
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                GestureDetector(
                  onTap: () => _onItemTapped(1),
                  child: const Text(
                    'Xem tất cả',
                    style: TextStyle(fontSize: 13, color: Color(0xFF5A57FF), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final upcomingClasses = _classes.take(3).toList();
                if (upcomingClasses.isEmpty) {
                  return const Center(
                    child: Text(
                      'Không có lớp học nào sắp diễn ra',
                      style: TextStyle(color: Colors.white38),
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
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
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
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                            Text(
                              item['date'] ?? 'Hôm nay',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF5A57FF), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${item['studentsCount']} sinh viên',
                              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4)),
                            ),
                            Text(
                              item['time'] ?? 'Slot 1',
                              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4)),
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
                color: Colors.white,
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
                color: const Color(0xFF5A57FF),
                onTap: _navigateToCreateClass,
              ),
              const SizedBox(height: 10),
              _buildQuickActionRow(
                icon: Icons.assignment_turned_in_outlined,
                title: 'Chấm điểm hoạt động',
                subtitle: 'Đánh giá các milestone và bài tập của sinh viên',
                color: const Color(0xFFD946EF),
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
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.5)),
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
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                ElevatedButton(
                  onPressed: _navigateToCreateClass,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E8EFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                  ),
                  child: const Text(
                    'Tạo lớp',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
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
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.4), size: 20),
                fillColor: const Color(0xFF1E293B),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),

        SliverPadding(
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
                        style: TextStyle(color: Colors.white54),
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
                final Color displayColor = item['color'] ?? const Color(0xFF5A57FF);
                
                final String shorthand = displayTitle.split(' ').first;

                return GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ClassDetailScreen(
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
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
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
                                color: displayColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: displayColor.withValues(alpha: 0.3)),
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
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    displayType,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withValues(alpha: 0.4),
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
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                              ),
                              child: Text(
                                displaySemester,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
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
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            ElevatedButton(
              onPressed: _navigateToCreateActivity,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E8EFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text(
                'Tạo mới',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        TextField(
          onChanged: (val) => setState(() => _activitySearchQuery = val),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Tìm kiếm hoạt động',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
            suffixIcon: const Icon(Icons.search, color: Color(0xFF2E8EFF), size: 20),
            fillColor: const Color(0xFF1E293B),
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
                style: TextStyle(color: Colors.white38),
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
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            ElevatedButton(
              onPressed: _navigateToCreateProject,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E8EFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text(
                'Thêm dự án',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        TextField(
          onChanged: (val) => setState(() => _projectSearchQuery = val),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Tìm kiếm dự án',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
            suffixIcon: const Icon(Icons.search, color: Color(0xFF2E8EFF), size: 20),
            fillColor: const Color(0xFF1E293B),
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
                style: TextStyle(color: Colors.white38),
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
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
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
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E8EFF).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    classCode,
                    style: const TextStyle(color: Color(0xFF2E8EFF), fontSize: 11, fontWeight: FontWeight.bold),
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
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5)),
                ),
                Text(
                  members,
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5)),
                ),
                Text(
                  date,
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5)),
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

    final classShorthand = className.split(' ').first.split('-').first.replaceAll(RegExp(r'\d'), '');

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push<Map<String, dynamic>>(
          context,
          MaterialPageRoute(
            builder: (context) => ActivityDetailScreen(
              activityTitle: title,
              deadline: deadline,
              submissions: submissions,
              description: description,
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
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E8EFF).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.assignment, color: Color(0xFF2E8EFF), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
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
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                  ),
                  child: Text(
                    classShorthand.isNotEmpty ? classShorthand : className,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
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
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
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
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }
}