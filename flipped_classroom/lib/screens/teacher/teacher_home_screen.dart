import 'package:flutter/material.dart';
import '../common/profile_screen.dart';
import '../common/notification_screen.dart';
import 'class_detail_screen.dart';

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
                  child: _buildStatCard('10', 'Lớp học', const Color(0xFF5A57FF)),
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
                final List<Map<String, dynamic>> upcomingClasses = [
                  {
                    'title': 'PRM - Lập trình mobile',
                    'code': 'PRM393 - SE1904',
                    'date': 'Hôm nay',
                    'students': 30,
                    'time': 'Slot 1 (7:30-9:50)',
                  },
                  {
                    'title': 'PRW - Phát triển web',
                    'code': 'PRW301 - SE1902',
                    'date': 'Hôm nay',
                    'students': 28,
                    'time': 'Slot 2 (10:00-12:20)',
                  },
                  {
                    'title': 'IOT - Nhập môn IoT',
                    'code': 'IOT102 - SE1901',
                    'date': 'Ngày mai',
                    'students': 35,
                    'time': 'Slot 4 (15:00-17:20)',
                  },
                ];

                final item = upcomingClasses[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ClassDetailScreen(
                          className: item['title'],
                          classCode: item['code'],
                          studentsCount: item['students'],
                        ),
                      ),
                    );
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
                              item['date'],
                              style: const TextStyle(fontSize: 12, color: Color(0xFF5A57FF), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${item['students']} sinh viên',
                              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4)),
                            ),
                            Text(
                              item['time'],
                              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: 3,
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
                onTap: () => _onItemTapped(1),
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
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              'Quản lý Lớp học',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.1,
            ),
            delegate: SliverChildListDelegate([
              _buildClassCard(
                title: 'Lập trình Mobile',
                code: 'PRM393 - SE1904',
                studentsCount: 32,
                color: const Color(0xFF5A57FF),
              ),
              _buildClassCard(
                title: 'Phát triển Web',
                code: 'PRW301 - SE1902',
                studentsCount: 28,
                color: const Color(0xFFD946EF),
              ),
              _buildClassCard(
                title: 'Nhập môn IoT',
                code: 'IOT102 - SE1901',
                studentsCount: 35,
                color: const Color(0xFF10B981),
              ),
              _buildClassCard(
                title: 'Đồ án Tốt nghiệp',
                code: 'PRO391 - SE1801',
                studentsCount: 25,
                color: const Color(0xFFF59E0B),
              ),
            ]),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton.icon(
              onPressed: () => _showSimulatedFeature(context, 'Tạo lớp học mới'),
              icon: const Icon(Icons.add),
              label: const Text('Tạo lớp học mới'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ),
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

  Widget _buildClassCard({
    required String title,
    required String code,
    required int studentsCount,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClassDetailScreen(
              className: title,
              classCode: code,
              studentsCount: studentsCount,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                  ),
                ),
                Icon(Icons.more_vert, color: Colors.white.withValues(alpha: 0.3), size: 16),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  code,
                  style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4)),
                ),
              ],
            ),
            Row(
              children: [
                Icon(Icons.people_outline, size: 14, color: Colors.white.withValues(alpha: 0.4)),
                const SizedBox(width: 6),
                Text(
                  '$studentsCount sinh viên',
                  style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4)),
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

  void _showSimulatedFeature(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tính năng "$feature" đang được phát triển!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}