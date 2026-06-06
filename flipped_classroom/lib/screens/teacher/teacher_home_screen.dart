import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../common/profile_screen.dart';
import '../common/notification_screen.dart';

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
    // List of screens to display in tabs
    final List<Widget> pages = [
      _buildDashboardTab(),
      _buildClassesTab(),
      _buildActivitiesTab(),
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
              color: Colors.white.withOpacity(0.06),
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
          unselectedItemColor: Colors.white.withOpacity(0.4),
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

  // TAB 0: DASHBOARD
  Widget _buildDashboardTab() {
    final user = AuthService().currentUser;
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Custom Header App Bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _onItemTapped(4), // Quick jump to Profile tab
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFF5A57FF),
                        child: Text(
                          user?.fullName.split(' ').last.substring(0, 1).toUpperCase() ?? 'GV',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Xin chào, Giảng viên',
                          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5)),
                        ),
                        Text(
                          user?.fullName ?? 'Giảng viên mẫu',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Notification Action -> jump to Notification tab
                    _buildHeaderIconButton(
                      icon: Icons.notifications_none_outlined,
                      onPressed: () => _onItemTapped(3),
                    ),
                    const SizedBox(width: 10),
                    // Profile Action -> jump to Profile tab
                    _buildHeaderIconButton(
                      icon: Icons.person_outline,
                      onPressed: () => _onItemTapped(4),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        // Statistics panel
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5A57FF), Color(0xFF2E8EFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5A57FF).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn('12', 'Lớp học'),
                  Container(width: 1, height: 40, color: Colors.white24),
                  _buildStatColumn('320', 'Học viên'),
                  Container(width: 1, height: 40, color: Colors.white24),
                  _buildStatColumn('15', 'Bài tập mới'),
                ],
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(left: 20.0, top: 28.0, bottom: 12.0),
            child: Text(
              'Tổng quan lớp học',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),

        // Class List Short overview
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
            ]),
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
                onTap: () => _onItemTapped(1), // go to Classes tab
              ),
              const SizedBox(height: 10),
              _buildQuickActionRow(
                icon: Icons.assignment_turned_in_outlined,
                title: 'Chấm điểm hoạt động',
                subtitle: 'Đánh giá các milestone và bài tập của sinh viên',
                color: const Color(0xFFD946EF),
                onTap: () => _onItemTapped(2), // go to Activities tab
              ),
              const SizedBox(height: 30),
            ]),
          ),
        ),
      ],
    );
  }

  // TAB 1: CLASSES
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

  // TAB 2: ACTIVITIES
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
        border: Border.all(color: Colors.white.withOpacity(0.04)),
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
                  color: statusColor.withOpacity(0.12),
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
              Icon(Icons.assignment_outlined, size: 14, color: Colors.white.withOpacity(0.4)),
              const SizedBox(width: 6),
              Text(
                submissions,
                style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.4)),
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

  Widget _buildHeaderIconButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 22),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildStatColumn(String val, String label) {
    return Column(
      children: [
        Text(
          val,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7)),
        ),
      ],
    );
  }

  Widget _buildClassCard({
    required String title,
    required String code,
    required int studentsCount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
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
              Icon(Icons.more_vert, color: Colors.white.withOpacity(0.3), size: 16),
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
                style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4)),
              ),
            ],
          ),
          Row(
            children: [
              Icon(Icons.people_outline, size: 14, color: Colors.white.withOpacity(0.4)),
              const SizedBox(width: 6),
              Text(
                '$studentsCount sinh viên',
                style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4)),
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
          border: Border.all(color: Colors.white.withOpacity(0.04)),
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
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.3)),
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
