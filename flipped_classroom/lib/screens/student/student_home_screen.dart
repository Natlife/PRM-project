import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../common/profile_screen.dart';
import '../common/notification_screen.dart';
import 'student_class_detail_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _myClasses = [
    {
      'classCode': 'PRM',
      'classCodeWithName': 'PRM - SE1904',
      'className': 'Lập trình Thiết bị Di động',
      'instructor': 'GV: Vũ Trường Giang',
      'semester': 'SU26',
      'studentCount': 30,
      'nextSession': 'Thời gian: 28/05/2026',
      'progress': 0.85,
    },
    {
      'classCode': 'PRW301',
      'classCodeWithName': 'PRW301 - SE1905',
      'className': 'Thiết kế Web nâng cao',
      'instructor': 'GV: Trần Thị B',
      'semester': 'SU26',
      'studentCount': 28,
      'nextSession': 'Thời gian: 30/05/2026',
      'progress': 0.50,
    },
    {
      'classCode': 'FLC101',
      'classCodeWithName': 'FLC101 - SE1906',
      'className': 'Học thuyết Học tập Chủ động',
      'instructor': 'GV: Hoàng Văn C',
      'semester': 'SU26',
      'studentCount': 35,
      'nextSession': 'Thời gian: 02/06/2026',
      'progress': 0.20,
    },
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showJoinClassDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'Tham gia lớp học',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nhập mã lớp học để tham gia',
                style: TextStyle(color: const Color(0xFF0F172A).withOpacity(0.6), fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Nhập mã lớp (VD: PRM393)',
                  hintStyle: TextStyle(color: const Color(0xFF0F172A).withOpacity(0.3)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: const Color(0xFF0F172A).withOpacity(0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF7EC07E), width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Hủy',
                style: TextStyle(color: const Color(0xFF0F172A).withOpacity(0.5), fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final code = controller.text.trim();
                if (code.isNotEmpty) {
                  setState(() {
                    _myClasses.add({
                      'classCode': code.toUpperCase(),
                      'classCodeWithName': '${code.toUpperCase()} - SE1904',
                      'className': 'Lớp học $code',
                      'instructor': 'GV: Hướng Dẫn Viên',
                      'semester': 'SU26',
                      'studentCount': 30,
                      'nextSession': 'Thời gian: Chưa xếp lịch',
                      'progress': 0.0,
                    });
                    _selectedIndex = 1; // Direct to classes tab
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã tham gia lớp học ${code.toUpperCase()} thành công!'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: const Color(0xFF7EC07E),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng nhập mã lớp học!'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7EC07E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text('Tham gia', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
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
                          'Xin chào, ${user?.fullName ?? "Nguyễn Văn A"} !',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Bạn có 3 deadline',
                          style: TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        // Button Tham gia lớp học
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: ElevatedButton.icon(
              onPressed: _showJoinClassDialog,
              icon: const Icon(Icons.add, color: Colors.white, size: 20),
              label: const Text(
                'Tham gia lớp học',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7EC07E),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ),
        ),

        // Deadline sắp tới header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 28.0, bottom: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Deadline sắp tới',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '2',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Deadline Card
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.04)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.assignment_late_outlined, color: Colors.redAccent, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bài tập lập trình Dart',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Thực hiện các bài lab',
                          style: TextStyle(
                            color: const Color(0xFF0F172A).withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Còn 2 ngày',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Lớp học của bạn header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 28.0, bottom: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Lớp học của bạn',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                TextButton(
                  onPressed: () => _onItemTapped(1), // Jump to Classes tab
                  child: const Text(
                    'Xem tất cả',
                    style: TextStyle(
                      color: Color(0xFF7EC07E),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // List of up to 3 classes
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = _myClasses[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.04)),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () async {
                        final targetIndex = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StudentClassDetailScreen(
                              classCodeWithName: '${item['classCode']} - SE1904',
                              className: item['className'] ?? '',
                              instructor: item['instructor'] ?? '',
                              semester: item['semester'] ?? 'SU26',
                            ),
                          ),
                        );
                        if (targetIndex != null && targetIndex is int) {
                          _onItemTapped(targetIndex);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF7EC07E).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(Icons.school, color: Color(0xFF7EC07E), size: 22),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['classCode'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['instructor'] ?? '',
                                    style: TextStyle(
                                      color: const Color(0xFF0F172A).withOpacity(0.5),
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['nextSession'] ?? '',
                                    style: TextStyle(
                                      color: const Color(0xFF0F172A).withOpacity(0.4),
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
              childCount: _myClasses.length > 3 ? 3 : _myClasses.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 30),
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
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = _myClasses[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () async {
                      final targetIndex = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StudentClassDetailScreen(
                            classCodeWithName: '${item['classCode']} - SE1904',
                            className: item['className'] ?? '',
                            instructor: item['instructor'] ?? '',
                            semester: item['semester'] ?? 'SU26',
                          ),
                        ),
                      );
                      if (targetIndex != null && targetIndex is int) {
                        _onItemTapped(targetIndex);
                      }
                    },
                    child: _buildAttendedClassRow(
                      className: item['className'] ?? '',
                      classCode: item['classCode'] ?? '',
                      instructor: item['instructor'] ?? '',
                      progress: item['progress'] ?? 0.0,
                      color: const Color(0xFF7EC07E),
                    ),
                  ),
                );
              },
              childCount: _myClasses.length,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: OutlinedButton.icon(
              onPressed: _showJoinClassDialog,
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
                    onPressed: () => _showSimulatedFeature('Xem danh sách thành viên'),
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

  void _showSimulatedFeature(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tính năng "$feature" đang được phát triển!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
