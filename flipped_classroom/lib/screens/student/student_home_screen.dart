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
  static const Color _primaryColor = Color(0xFF7EC07E);
  static const Color _backgroundColor = Color(0xFFF8FAFC);
  static const Color _surfaceColor = Colors.white;
  static const Color _textColor = Color(0xFF0F172A);
  static const Color _borderColor = Color(0xFFE2E8F0);
  static const Color _dangerColor = Color(0xFFEF4444);

  final ClassroomService _classroomService = ClassroomService();

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
      final classes = await _classroomService.getStudentClassrooms();

      if (!mounted) return;

      setState(() {
        _myClasses = classes;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showSnackBar(
        message: 'Lỗi tải danh sách lớp học: $e',
        isError: true,
      );
    }
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
    });
  }

  void _showJoinClassDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return _JoinClassDialog(
          onJoinClass: (code) async {
            await _classroomService.joinClassroom(code);

            if (!mounted) return;

            _showSnackBar(
              message: 'Đã tham gia lớp học ${code.toUpperCase()} thành công.',
            );

            await _loadClassrooms();
          },
        );
      },
    );
  }

  void _showSnackBar({
    required String message,
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isError ? _dangerColor : _textColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: _isLoading ? const _LoadingView() : _buildCurrentPage(),
        ),
      ),
      bottomNavigationBar: _StudentBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
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
        return StudentEventsTab(
          key: const PageStorageKey('student-events-tab'),
          onTabTapped: _onItemTapped,
        );

      case 4:
        return const ProfileScreen(
          key: PageStorageKey('student-profile-tab'),
          showBackButton: false,
        );

      default:
        return StudentDashboardTab(
          key: const PageStorageKey('student-dashboard-tab-default'),
          myClasses: _myClasses,
          onJoinClassPressed: _showJoinClassDialog,
          onTabTapped: _onItemTapped,
        );
    }
  }
}

class _StudentBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  const _StudentBottomNavigationBar({
    required this.selectedIndex,
    required this.onItemTapped,
  });

  static const Color _primaryColor = Color(0xFF7EC07E);
  static const Color _surfaceColor = Colors.white;
  static const Color _textColor = Color(0xFF0F172A);
  static const Color _borderColor = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        border: const Border(
          top: BorderSide(
            color: _borderColor,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: _textColor.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            height: 72,
            backgroundColor: _surfaceColor,
            indicatorColor: _primaryColor.withOpacity(0.14),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final isSelected = states.contains(WidgetState.selected);

              return TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? _primaryColor
                    : _textColor.withOpacity(0.45),
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              final isSelected = states.contains(WidgetState.selected);

              return IconThemeData(
                size: 24,
                color: isSelected
                    ? _primaryColor
                    : _textColor.withOpacity(0.45),
              );
            }),
          ),
          child: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: onItemTapped,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded),
                label: 'Trang chủ',
              ),
              NavigationDestination(
                icon: Icon(Icons.school_outlined),
                selectedIcon: Icon(Icons.school_rounded),
                label: 'Lớp học',
              ),
              NavigationDestination(
                icon: Icon(Icons.group_work_outlined),
                selectedIcon: Icon(Icons.group_work_rounded),
                label: 'Dự án',
              ),
              NavigationDestination(
                icon: Icon(Icons.event_note_outlined),
                selectedIcon: Icon(Icons.event_note_rounded),
                label: 'Sự kiện',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Cá nhân',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JoinClassDialog extends StatefulWidget {
  final Future<void> Function(String code) onJoinClass;

  const _JoinClassDialog({
    required this.onJoinClass,
  });

  @override
  State<_JoinClassDialog> createState() => _JoinClassDialogState();
}

class _JoinClassDialogState extends State<_JoinClassDialog> {
  static const Color _primaryColor = Color(0xFF7EC07E);
  static const Color _backgroundColor = Color(0xFFF8FAFC);
  static const Color _surfaceColor = Colors.white;
  static const Color _textColor = Color(0xFF0F172A);
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE2E8F0);
  static const Color _dangerColor = Color(0xFFEF4444);

  final TextEditingController _controller = TextEditingController();

  String? _errorText;
  bool _isJoining = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleJoinClass() async {
    final code = _controller.text.trim();

    if (code.isEmpty) {
      setState(() {
        _errorText = 'Vui lòng nhập mã lớp học';
      });
      return;
    }

    setState(() {
      _errorText = null;
      _isJoining = true;
    });

    try {
      await widget.onJoinClass(code);

      if (!mounted) return;

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorText = 'Lỗi khi tham gia lớp học: $e';
        _isJoining = false;
      });
    }
  }

  void _handleCancel() {
    if (_isJoining) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isJoining,
      child: AlertDialog(
        backgroundColor: _surfaceColor,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        title: const Text(
          'Tham gia lớp học',
          style: TextStyle(
            color: _textColor,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập mã lớp học do giảng viên cung cấp để tham gia lớp.',
              style: TextStyle(
                color: _mutedTextColor,
                fontSize: 14,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _controller,
              autofocus: true,
              enabled: !_isJoining,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (!_isJoining) {
                  _handleJoinClass();
                }
              },
              onChanged: (value) {
                if (_errorText != null && value.trim().isNotEmpty) {
                  setState(() {
                    _errorText = null;
                  });
                }
              },
              style: const TextStyle(
                color: _textColor,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: 'VD: PRM393',
                hintStyle: const TextStyle(
                  color: _mutedTextColor,
                  fontWeight: FontWeight.w500,
                ),
                errorText: _errorText,
                errorMaxLines: 3,
                prefixIcon: const Icon(
                  Icons.key_rounded,
                  color: _primaryColor,
                ),
                filled: true,
                fillColor: _backgroundColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(
                    color: _borderColor,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(
                    color: _primaryColor,
                    width: 1.5,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(
                    color: _dangerColor,
                    width: 1.2,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(
                    color: _dangerColor,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isJoining ? null : _handleCancel,
            style: TextButton.styleFrom(
              foregroundColor: _mutedTextColor,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 11,
              ),
            ),
            child: const Text(
              'Hủy',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _isJoining ? null : _handleJoinClass,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: _primaryColor,
              disabledBackgroundColor: _primaryColor.withOpacity(0.5),
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 11,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
            child: _isJoining
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : const Text('Tham gia'),
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  static const Color _primaryColor = Color(0xFF7EC07E);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 30,
        height: 30,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: _primaryColor,
        ),
      ),
    );
  }
}