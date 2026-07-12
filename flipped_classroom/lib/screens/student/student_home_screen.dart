import 'package:flutter/material.dart';

import '../../services/classroom_service.dart';
import '../common/profile_screen.dart';
import 'student_classes_screen.dart';
import 'tabs/student_dashboard_tab.dart';
import 'tabs/student_events_tab.dart';
import 'tabs/student_projects_tab.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  static const Color _primaryColor = Color(0xFF22A06B);
  static const Color _primaryDarkColor = Color(0xFF167A52);
  static const Color _backgroundColor = Color(0xFFF5F7F6);
  static const Color _surfaceColor = Colors.white;
  static const Color _textPrimaryColor = Color(0xFF17211B);
  static const Color _textSecondaryColor = Color(0xFF66736B);
  static const Color _borderColor = Color(0xFFE2E8E4);
  static const Color _errorColor = Color(0xFFDC3D43);

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
      final List<Map<String, dynamic>> classes = await ClassroomService()
          .getStudentClassrooms();

      if (!mounted) {
        return;
      }

      setState(() {
        _myClasses = classes;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải danh sách lớp học: $error'),
          backgroundColor: _errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showJoinClassDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: _surfaceColor,
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
          contentPadding: const EdgeInsets.fromLTRB(22, 14, 22, 8),
          actionsPadding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
          title: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7F0),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.school_outlined,
                  color: _primaryDarkColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Text(
                  'Tham gia lớp học',
                  style: TextStyle(
                    color: _textPrimaryColor,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nhập mã lớp học được cung cấp để tham gia lớp.',
                style: TextStyle(
                  color: _textSecondaryColor,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.done,
                style: const TextStyle(
                  color: _textPrimaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'Nhập mã lớp, ví dụ: PRM393',
                  hintStyle: const TextStyle(
                    color: Color(0xFF9AA49E),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: const Icon(
                    Icons.tag_rounded,
                    color: _textSecondaryColor,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF9FBFA),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: _borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: _borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: _primaryColor,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _textSecondaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: const BorderSide(color: _borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Hủy',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      final String code = controller.text.trim();

                      if (code.isNotEmpty) {
                        try {
                          await ClassroomService().joinClassroom(code);

                          if (!mounted) {
                            return;
                          }

                          Navigator.pop(dialogContext);

                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Đã tham gia lớp học '
                                  '${code.toUpperCase()} thành công!',
                                ),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: _primaryDarkColor,
                              ),
                            );

                          _loadClassrooms();
                        } catch (error) {
                          if (!mounted) {
                            return;
                          }

                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Lỗi khi tham gia lớp học: '
                                  '$error',
                                ),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: _errorColor,
                              ),
                            );
                        }
                      } else {
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            const SnackBar(
                              content: Text('Vui lòng nhập mã lớp học!'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: _errorColor,
                            ),
                          );
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Tham gia',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    ).whenComplete(controller.dispose);
  }

  Widget _buildLoadingState() {
    return const Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          strokeWidth: 2.6,
          valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
        ),
      ),
    );
  }

  Widget _buildActiveNavigationIcon(IconData icon) {
    return Container(
      width: 38,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 22, color: _primaryDarkColor),
    );
  }

  BottomNavigationBarItem _buildNavigationItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    return BottomNavigationBarItem(
      icon: Icon(icon, size: 22),
      activeIcon: _buildActiveNavigationIcon(activeIcon),
      label: label,
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        border: const Border(top: BorderSide(color: _borderColor)),
        boxShadow: [
          BoxShadow(
            color: _textPrimaryColor.withOpacity(0.045),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: _surfaceColor,
          elevation: 0,
          selectedItemColor: _primaryDarkColor,
          unselectedItemColor: const Color(0xFF8B9690),
          selectedFontSize: 11,
          unselectedFontSize: 10.5,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            height: 1.6,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            height: 1.6,
          ),
          items: [
            _buildNavigationItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: 'Trang chủ',
            ),
            _buildNavigationItem(
              icon: Icons.school_outlined,
              activeIcon: Icons.school_rounded,
              label: 'Lớp học',
            ),
            _buildNavigationItem(
              icon: Icons.group_work_outlined,
              activeIcon: Icons.group_work_rounded,
              label: 'Dự án',
            ),
            _buildNavigationItem(
              icon: Icons.event_note_outlined,
              activeIcon: Icons.event_note_rounded,
              label: 'Sự kiện',
            ),
            _buildNavigationItem(
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
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
        return StudentEventsTab(onTabTapped: _onItemTapped);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        bottom: false,
        child: _isLoading ? _buildLoadingState() : _buildCurrentPage(),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
}
