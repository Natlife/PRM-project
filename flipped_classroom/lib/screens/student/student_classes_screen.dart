import 'package:flutter/material.dart';

import 'student_class_detail_screen.dart';

class StudentClassesScreen extends StatefulWidget {
  final List<Map<String, dynamic>> myClasses;
  final VoidCallback onJoinClassPressed;
  final ValueChanged<int>? onTabTapped;

  const StudentClassesScreen({
    super.key,
    required this.myClasses,
    required this.onJoinClassPressed,
    this.onTabTapped,
  });

  @override
  State<StudentClassesScreen> createState() => _StudentClassesScreenState();
}

class _StudentClassesScreenState extends State<StudentClassesScreen> {
  static const Color _primaryColor = Color(0xFF22A06B);
  static const Color _primaryDarkColor = Color(0xFF167A52);
  static const Color _surfaceColor = Colors.white;
  static const Color _textPrimaryColor = Color(0xFF17211B);
  static const Color _textSecondaryColor = Color(0xFF66736B);
  static const Color _borderColor = Color(0xFFE2E8E4);

  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _buildClassCodeWithName(Map<String, dynamic> item) {
    final String existing = item['classCodeWithName']?.toString().trim() ?? '';

    if (existing.isNotEmpty) {
      return existing;
    }

    final String code = item['classCode']?.toString().trim() ?? '';

    final String name = item['className']?.toString().trim() ?? '';

    if (code.isNotEmpty && name.isNotEmpty) {
      return '$code - $name';
    }

    return code.isNotEmpty ? code : name;
  }

  Widget _buildHeader(int classCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lớp học của bạn',
                  style: TextStyle(
                    color: _textPrimaryColor,
                    fontSize: 23,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Quản lý và truy cập các lớp đang tham gia.',
                  style: TextStyle(
                    color: _textSecondaryColor,
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7F0),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              '$classCount lớp',
              style: const TextStyle(
                color: _primaryDarkColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onChanged: (String value) {
          setState(() {
            _searchQuery = value;
          });
        },
        style: const TextStyle(
          color: _textPrimaryColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Tìm kiếm lớp học...',
          hintStyle: const TextStyle(
            color: Color(0xFF9AA49E),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: _textSecondaryColor,
            size: 21,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  tooltip: 'Xóa tìm kiếm',
                  onPressed: () {
                    _searchController.clear();

                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                    color: _textSecondaryColor,
                    size: 19,
                  ),
                )
              : null,
          filled: true,
          fillColor: _surfaceColor,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide: const BorderSide(color: _borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide: const BorderSide(color: _borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide: const BorderSide(color: _primaryColor, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildClassCard(Map<String, dynamic> item) {
    final String classCodeWithName = _buildClassCodeWithName(item);

    final String instructor = item['instructor']?.toString() ?? '';

    final String semester = item['semester']?.toString() ?? '';

    final dynamic studentCount = item['studentCount'] ?? 0;

    return Material(
      color: _surfaceColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          final dynamic targetIndex = await Navigator.push(
            context,
            MaterialPageRoute<dynamic>(
              builder: (BuildContext context) {
                return StudentClassDetailScreen(
                  classroomId: item['id'],
                  classCodeWithName: classCodeWithName,
                  className: item['className'] ?? '',
                  instructor: item['instructor'] ?? '',
                  semester: item['semester'] ?? '',
                );
              },
            ),
          );

          if (targetIndex != null && targetIndex is int) {
            widget.onTabTapped?.call(targetIndex);
          }
        },
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _borderColor),
            boxShadow: [
              BoxShadow(
                color: _textPrimaryColor.withOpacity(0.035),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7F0),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.school_outlined,
                  color: _primaryDarkColor,
                  size: 23,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            classCodeWithName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _textPrimaryColor,
                              fontSize: 15,
                              height: 1.4,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ),
                        if (semester.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F4F2),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              semester,
                              style: const TextStyle(
                                color: _textSecondaryColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (instructor.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline_rounded,
                            color: Color(0xFF8B9690),
                            size: 16,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              instructor,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _textSecondaryColor,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        const Icon(
                          Icons.groups_outlined,
                          color: Color(0xFF8B9690),
                          size: 16,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          '$studentCount sinh viên',
                          style: const TextStyle(
                            color: _textSecondaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(top: 13),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF9AA49E),
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(32, 52, 32, 30),
        child: Column(
          children: [
            _EmptyStateIcon(),
            SizedBox(height: 22),
            Text(
              'Không tìm thấy lớp học',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textPrimaryColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Hãy kiểm tra lại từ khóa tìm kiếm của bạn.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textSecondaryColor,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinClassButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton.icon(
          onPressed: widget.onJoinClassPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: _primaryDarkColor,
            backgroundColor: _surfaceColor,
            side: const BorderSide(color: _primaryColor, width: 1.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
          label: const Text(
            'Quét mã tham gia lớp học mới',
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String query = _searchQuery.toLowerCase();

    final List<Map<String, dynamic>> filteredClasses = widget.myClasses.where((
      Map<String, dynamic> item,
    ) {
      final String classCodeWithName = _buildClassCodeWithName(
        item,
      ).toLowerCase();

      final String className = (item['className'] ?? '')
          .toString()
          .toLowerCase();

      final String instructor = (item['instructor'] ?? '')
          .toString()
          .toLowerCase();

      final String semester = (item['semester'] ?? '').toString().toLowerCase();

      return classCodeWithName.contains(query) ||
          className.contains(query) ||
          instructor.contains(query) ||
          semester.contains(query);
    }).toList();

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(widget.myClasses.length)),
        SliverToBoxAdapter(child: _buildSearchField()),
        if (filteredClasses.isEmpty)
          _buildEmptyState()
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.separated(
              itemCount: filteredClasses.length,
              separatorBuilder: (BuildContext context, int index) {
                return const SizedBox(height: 12);
              },
              itemBuilder: (BuildContext context, int index) {
                return _buildClassCard(filteredClasses[index]);
              },
            ),
          ),
        SliverToBoxAdapter(child: _buildJoinClassButton()),
      ],
    );
  }
}

class _EmptyStateIcon extends StatelessWidget {
  const _EmptyStateIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7F0),
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Icon(
        Icons.search_off_rounded,
        color: Color(0xFF167A52),
        size: 40,
      ),
    );
  }
}
