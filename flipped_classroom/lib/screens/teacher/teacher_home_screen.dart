import 'dart:math';
import 'package:flutter/material.dart';
import '../common/profile_screen.dart';
import '../common/notification_screen.dart';
import 'class_detail_screen.dart';
import 'create_class_screen.dart';

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  int _selectedIndex = 0;
  String _classSearchQuery = '';

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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Đánh giá & Hoạt động',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 20),
        _buildActivityItem(
          title: 'Đánh giá Milestone 1 - Dự án cuối kỳ',
          className: 'PRM393 - Lập trình Mobile',
          status: 'Đã hoàn thành',
          statusColor: Colors.greenAccent,
          submissions: '8/8 nhóm đã nộp',
        ),
        const SizedBox(height: 12),
        _buildActivityItem(
          title: 'Bài tập Chuẩn bị bài 4: Flutter Widget',
          className: 'PRM393 - Lập trình Mobile',
          status: 'Đang mở (Trễ hạn: 23:59 hôm nay)',
          statusColor: Colors.amberAccent,
          submissions: '28/32 học viên đã nộp',
        ),
        const SizedBox(height: 12),
        _buildActivityItem(
          title: 'Đánh giá Báo cáo nghiên cứu công nghệ',
          className: 'PRW301 - Phát triển Web',
          status: 'Đang mở (Hạn chót: 3 ngày nữa)',
          statusColor: const Color(0xFF2E8EFF),
          submissions: '15/28 học viên đã nộp',
        ),
      ],
    );
  }

  Widget _buildProjectsTab() {
    final List<Map<String, dynamic>> mockProjects = [
      {
        'title': 'Ứng dụng Flipped Classroom',
        'class': 'PRM393 - SE1904',
        'group': 'Nhóm 1',
        'progress': 0.8,
      },
      {
        'title': 'Hệ thống Đặt đồ ăn trực tuyến',
        'class': 'PRW301 - SE1902',
        'group': 'Nhóm 2',
        'progress': 0.6,
      },
      {
        'title': 'Mạng xã hội học tập sinh viên',
        'class': 'PRM393 - SE1904',
        'group': 'Nhóm 3',
        'progress': 0.45,
      },
    ];

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Quản lý Dự án',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 20),
        ...mockProjects.map((proj) => _buildProjectItem(proj)),
      ],
    );
  }

  Widget _buildProjectItem(Map<String, dynamic> proj) {
    return Container(
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
              Text(
                proj['class'],
                style: const TextStyle(color: Color(0xFF8F8DFF), fontSize: 11, fontWeight: FontWeight.bold),
              ),
              Text(
                proj['group'],
                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            proj['title'],
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Text('Tiến độ:', style: TextStyle(fontSize: 12, color: Colors.white54)),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: proj['progress'],
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5A57FF)),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(proj['progress'] * 100).toInt()}%',
                style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required String title,
    required String className,
    required String status,
    required Color statusColor,
    required String submissions,
  }) {
    return Container(
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
                  className,
                  style: TextStyle(color: const Color(0xFF8F8DFF), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.assignment_outlined, size: 14, color: Colors.white.withValues(alpha: 0.4)),
              const SizedBox(width: 6),
              Text(
                submissions,
                style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4)),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _showSimulatedFeature(context, 'Chi tiết bài nộp'),
                child: const Text('Xem bài nộp', style: TextStyle(fontSize: 12, color: Color(0xFF5A57FF))),
              ),
            ],
          ),
        ],
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

  void _showSimulatedFeature(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tính năng "$feature" đang được phát triển!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}