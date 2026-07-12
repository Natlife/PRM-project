import 'dart:math';

import 'package:flutter/material.dart';

import '../../../services/classroom_service.dart';
import 'student_detail_screen.dart';

class StudentListScreen extends StatefulWidget {
  final int classroomId;
  final String className;

  const StudentListScreen({
    super.key,
    required this.classroomId,
    required this.className,
  });

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  static const Color _primaryColor = Color(0xFF22A06B);
  static const Color _primaryDarkColor = Color(0xFF167A52);
  static const Color _backgroundColor = Color(0xFFF5F7F6);
  static const Color _surfaceColor = Colors.white;
  static const Color _textPrimaryColor = Color(0xFF17211B);
  static const Color _textSecondaryColor = Color(0xFF66736B);
  static const Color _borderColor = Color(0xFFE2E8E4);
  static const Color _errorColor = Color(0xFFDC3D43);

  String _searchQuery = '';
  bool _isLoading = true;

  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    try {
      final List<Map<String, dynamic>> students = await ClassroomService()
          .getTeacherClassroomStudents(widget.classroomId);

      if (!mounted) {
        return;
      }

      setState(() {
        _students = students;
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
          content: Text('Không tải được danh sách sinh viên: $error'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _errorColor,
        ),
      );
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _surfaceColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      shadowColor: _borderColor,
      automaticallyImplyLeading: false,
      leading: IconButton(
        tooltip: 'Quay lại',
        onPressed: () {
          Navigator.of(context).pop();
        },
        icon: const Icon(Icons.arrow_back_rounded, color: _textPrimaryColor),
      ),
      titleSpacing: 0,
      title: const Text(
        'Danh sách sinh viên',
        style: TextStyle(
          color: _textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  Widget _buildClassOverview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7F0),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.groups_2_outlined,
              color: _primaryDarkColor,
              size: 23,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lớp học',
                  style: TextStyle(
                    color: _textSecondaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.className,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textPrimaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7F0),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              '${_students.length} sinh viên',
              style: const TextStyle(
                color: _primaryDarkColor,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      onChanged: (String value) {
        setState(() {
          _searchQuery = value;
        });
      },
      textInputAction: TextInputAction.search,
      style: const TextStyle(
        color: _textPrimaryColor,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: 'Tìm theo tên, mã hoặc email',
        hintStyle: const TextStyle(
          color: Color(0xFF9AA49E),
          fontSize: 13.5,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: _textSecondaryColor,
          size: 21,
        ),
        filled: true,
        fillColor: _surfaceColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _primaryColor, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildSectionTitle({required int studentCount}) {
    return Row(
      children: [
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF7F0),
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(
            Icons.people_outline_rounded,
            color: _primaryDarkColor,
            size: 18,
          ),
        ),
        const SizedBox(width: 11),
        const Expanded(
          child: Text(
            'Sinh viên trong lớp',
            style: TextStyle(
              color: _textPrimaryColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
        Text(
          '$studentCount kết quả',
          style: const TextStyle(
            color: _textSecondaryColor,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final String name = student['fullName']?.toString() ?? 'Sinh viên';

    final String email = student['email']?.toString() ?? '';

    final String code =
        student['institutionalId']?.toString() ??
        student['userName']?.toString() ??
        '';

    final String initials = _getInitials(name);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: _textPrimaryColor.withOpacity(0.025),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(19),
        child: InkWell(
          borderRadius: BorderRadius.circular(19),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (BuildContext context) {
                  return StudentDetailScreen(
                    studentName: name,
                    studentEmail: email,
                    submissionsCount: 0,
                    progressPercentage: 0,
                  );
                },
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7F0),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: _primaryDarkColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _textPrimaryColor,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (email.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(
                              Icons.mail_outline_rounded,
                              color: _textSecondaryColor,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _textSecondaryColor,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (code.isNotEmpty) ...[
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            const Icon(
                              Icons.badge_outlined,
                              color: _textSecondaryColor,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                code,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _textSecondaryColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF9AA49E),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentList(List<Map<String, dynamic>> filteredStudents) {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 14, bottom: 36),
      physics: const BouncingScrollPhysics(),
      itemCount: filteredStudents.length,
      separatorBuilder: (BuildContext context, int index) {
        return const SizedBox(height: 11);
      },
      itemBuilder: (BuildContext context, int index) {
        return _buildStudentCard(filteredStudents[index]);
      },
    );
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

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _borderColor),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_search_outlined,
              color: Color(0xFF9AA49E),
              size: 34,
            ),
            SizedBox(height: 12),
            Text(
              'Không tìm thấy sinh viên',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textPrimaryColor,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Hãy kiểm tra lại tên, mã sinh viên hoặc địa chỉ email.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textSecondaryColor,
                fontSize: 12.5,
                height: 1.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final String normalizedName = name.trim();

    if (normalizedName.isEmpty) {
      return 'SV';
    }

    final List<String> words = normalizedName
        .split(RegExp(r'\s+'))
        .where((String word) => word.isNotEmpty)
        .toList();

    if (words.length > 1) {
      return '${words[words.length - 2][0]}'
              '${words.last[0]}'
          .toUpperCase();
    }

    return normalizedName
        .substring(0, min(normalizedName.length, 2))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final String query = _searchQuery.trim().toLowerCase();

    final List<Map<String, dynamic>> filteredStudents = _students.where((
      Map<String, dynamic> student,
    ) {
      final String name = (student['fullName'] ?? '').toString().toLowerCase();

      final String code = (student['institutionalId'] ?? '')
          .toString()
          .toLowerCase();

      final String email = (student['email'] ?? '').toString().toLowerCase();

      return name.contains(query) ||
          code.contains(query) ||
          email.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
              child: Column(
                children: [
                  _buildClassOverview(),
                  const SizedBox(height: 14),
                  _buildSearchField(),
                  const SizedBox(height: 24),
                  _buildSectionTitle(studentCount: filteredStudents.length),
                  const SizedBox(height: 2),
                  Expanded(
                    child: _isLoading
                        ? _buildLoadingState()
                        : filteredStudents.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(top: 14, bottom: 36),
                            child: _buildEmptyState(),
                          )
                        : _buildStudentList(filteredStudents),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
