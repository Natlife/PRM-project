import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../common/profile_screen.dart';
import '../common/notification_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
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
              icon: Icon(Icons.group_work_outlined),
              activeIcon: Icon(Icons.group_work),
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
                        backgroundColor: const Color(0xFF7EC07E),
                        child: Text(
                          user?.fullName.split(' ').last.substring(0, 1).toUpperCase() ?? 'SV',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Xin chào, Sinh viên',
                          style: TextStyle(fontSize: 12, color: const Color(0xFF0F172A).withOpacity(0.5)),
                        ),
                        Text(
                          user?.fullName ?? 'Sinh viên mẫu',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
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
        
        // Project & Group Card
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7EC07E), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7EC07E).withOpacity(0.25),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Nhóm 1 • PRM393',
                          style: TextStyle(color: Color(0xFF0F172A), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Text(
                        'Milestone 1',
                        style: TextStyle(color: Color(0xFF334155), fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Ứng dụng Flipped Classroom',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                      letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tiến độ chuẩn bị bài',
                            style: TextStyle(color: Color(0xFF334155), fontSize: 12),
                          ),
                          Text(
                            '80%',
                            style: TextStyle(color: const Color(0xFF0F172A).withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: 0.8,
                          minHeight: 6,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(left: 20.0, top: 28.0, bottom: 12.0),
                child: Text(
                  'Lớp học đang tham gia',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ),

            // Attended Classes List Short
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildAttendedClassRow(
                    className: 'Lập trình Thiết bị Di động',
                    classCode: 'PRM393',
                    instructor: 'GV. Nguyễn Văn A',
                    progress: 0.85,
                    color: const Color(0xFF7EC07E),
                  ),
                  const SizedBox(height: 12),
                  _buildAttendedClassRow(
                    className: 'Thiết kế Web nâng cao',
                    classCode: 'PRW301',
                    instructor: 'GV. Trần Thị B',
                    progress: 0.50,
                    color: const Color(0xFF7EC07E),
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
                    icon: Icons.qr_code_scanner,
                    title: 'Tham gia lớp học mới',
                    subtitle: 'Nhập mã lớp học hoặc quét mã QR từ giảng viên',
                    color: const Color(0xFF7EC07E),
                    onTap: () => _onItemTapped(1), // go to Classes tab
                  ),
                  const SizedBox(height: 10),
                  _buildQuickActionRow(
                    icon: Icons.cloud_upload_outlined,
                    title: 'Nộp tài liệu chuẩn bị',
                    subtitle: 'Tải lên slides, videos hoặc báo cáo tự học',
                    color: const Color(0xFF7EC07E),
                    onTap: () => _onItemTapped(2), // go to Projects tab
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
              'Lớp học tham gia',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildAttendedClassRow(
                className: 'Lập trình Thiết bị Di động',
                classCode: 'PRM393',
                instructor: 'GV. Nguyễn Văn A',
                progress: 0.85,
                color: const Color(0xFF7EC07E),
              ),
              const SizedBox(height: 12),
              _buildAttendedClassRow(
                className: 'Thiết kế Web nâng cao',
                classCode: 'PRW301',
                instructor: 'GV. Trần Thị B',
                progress: 0.50,
                color: const Color(0xFF7EC07E),
              ),
              const SizedBox(height: 12),
              _buildAttendedClassRow(
                className: 'Học thuyết Học tập Chủ động',
                classCode: 'FLC101',
                instructor: 'GV. Hoàng Văn C',
                progress: 0.20,
                color: const Color(0xFF7EC07E),
              ),
            ]),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: OutlinedButton.icon(
              onPressed: () => _showSimulatedFeature(context, 'Tham gia lớp học mới'),
              icon: const Icon(Icons.qr_code),
              label: const Text('Quét mã tham gia lớp học mới'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF7EC07E)),
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // TAB 2: PROJECTS & MILESTONES
  Widget _buildProjectsTab() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Dự án & Mốc thời gian',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 20),
        
        // Project card summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.04)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dự án hiện tại',
                style: TextStyle(fontSize: 12, color: Color(0xFF7EC07E), fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Ứng dụng Flipped Classroom',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Nhóm: Nhóm 1 (4 thành viên)', style: TextStyle(fontSize: 12, color: const Color(0xFF0F172A).withOpacity(0.5))),
                  TextButton(
                    onPressed: () => _showSimulatedFeature(context, 'Xem danh sách thành viên'),
                    child: const Text('Xem nhóm', style: TextStyle(fontSize: 12, color: Color(0xFF7EC07E))),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Các mốc đánh giá (Milestones)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 12),
        _buildMilestoneItem(
          title: 'Milestone 1: Wireframe & Database Design',
          dueDate: 'Hạn chót: Đã nộp (01/06/2026)',
          status: 'Đã hoàn thành',
          statusColor: Colors.greenAccent,
          progress: 1.0,
        ),
        const SizedBox(height: 12),
        _buildMilestoneItem(
          title: 'Milestone 2: MVP Front-end & Auth',
          dueDate: 'Hạn chót: 15/06/2026',
          status: 'Đang thực hiện',
          statusColor: Colors.amberAccent,
          progress: 0.6,
        ),
        const SizedBox(height: 12),
        _buildMilestoneItem(
          title: 'Milestone 3: Final Submission & Demo',
          dueDate: 'Hạn chót: 30/06/2026',
          status: 'Chưa bắt đầu',
          statusColor: Colors.white24,
          progress: 0.0,
        ),
      ],
    );
  }

  Widget _buildMilestoneItem({
    required String title,
    required String dueDate,
    required String status,
    required Color statusColor,
    required double progress,
  }) {
    return Container(
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                status,
                style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(dueDate, style: TextStyle(fontSize: 11, color: const Color(0xFF0F172A).withOpacity(0.4))),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor == Colors.white24 ? Colors.white30 : statusColor),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('${(progress * 100).toInt()}%', style: TextStyle(fontSize: 11, color: const Color(0xFF0F172A).withOpacity(0.6))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIconButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, color: const Color(0xFF0F172A), size: 22),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildAttendedClassRow({
    required String className,
    required String classCode,
    required String instructor,
    required double progress,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.04)),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      classCode,
                      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Tự học: ${(progress * 100).toInt()}%',
                      style: TextStyle(color: const Color(0xFF0F172A).withOpacity(0.4), fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  className,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Text(
                  instructor,
                  style: TextStyle(color: const Color(0xFF0F172A).withOpacity(0.4), fontSize: 11),
                ),
              ],
            ),
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

  void _showSimulatedFeature(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tính năng "$feature" đang được phát triển!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
