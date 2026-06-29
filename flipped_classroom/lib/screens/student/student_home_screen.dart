import 'package:flutter/material.dart';
import '../../services/classroom_service.dart';
import '../common/profile_screen.dart';
import '../common/notification_screen.dart';
import 'student_classes_screen.dart';
import 'tabs/student_dashboard_tab.dart';
import 'tabs/student_projects_tab.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _selectedIndex = 0;
  List<Map<String, dynamic>> _myClasses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClassrooms();
  }

  Future<void> _loadClassrooms() async {
    try {
      final classes = await ClassroomService().getStudentClassrooms();
      setState(() {
        _myClasses = classes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải danh sách lớp học: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

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
              onPressed: () async {
                final code = controller.text.trim();
                if (code.isNotEmpty) {
                  try {
                    await ClassroomService().joinClassroom(code);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã tham gia lớp học ${code.toUpperCase()} thành công!'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: const Color(0xFF7EC07E),
                      ),
                    );
                    _loadClassrooms();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi khi tham gia lớp học: $e'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF7EC07E)),
              )
            : _buildCurrentPage(),
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

  Widget _buildCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return StudentDashboardTab(
          key: const PageStorageKey('student-dashboard-tab'),
          myClasses: _myClasses,
          onJoinClassPressed: _showJoinClassDialog,
          onTabTapped: _onItemTapped,
        );
      case 1:
        return StudentClassesScreen(
          key: const PageStorageKey('student-classes-tab'),
          myClasses: _myClasses,
          onJoinClassPressed: _showJoinClassDialog,
          onTabTapped: _onItemTapped,
        );
      case 2:
        return StudentProjectsTab(
          key: const PageStorageKey('student-projects-tab'),
          onTabTapped: _onItemTapped,
        );
      case 3:
        return const NotificationScreen(showBackButton: false);
      case 4:
        return const ProfileScreen(showBackButton: false);
      default:
        return StudentDashboardTab(
          key: const PageStorageKey('student-dashboard-tab-default'),
          myClasses: _myClasses,
          onJoinClassPressed: _showJoinClassDialog,
          onTabTapped: _onItemTapped,
        );
    }
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
