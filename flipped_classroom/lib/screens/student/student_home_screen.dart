import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../common/profile_screen.dart';
import '../common/notification_screen.dart';
import 'student_classes_screen.dart';
import 'tabs/student_dashboard_tab.dart';
import 'tabs/student_projects_tab.dart';
import 'tabs/student_events_tab.dart';

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
    final List<Widget> pages = [
      StudentDashboardTab(
        myClasses: _myClasses,
        onJoinClassPressed: _showJoinClassDialog,
        onTabTapped: _onItemTapped,
      ),
      StudentClassesScreen(
        myClasses: _myClasses,
        onJoinClassPressed: _showJoinClassDialog,
        onTabTapped: _onItemTapped,
      ),
      StudentProjectsTab(
        onTabTapped: _onItemTapped,
      ),
      StudentEventsTab(
        onTabTapped: _onItemTapped,
      ),
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
