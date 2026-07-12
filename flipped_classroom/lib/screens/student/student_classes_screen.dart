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
  static const Color _primaryColor = Color(0xFF7EC07E);
  static const Color _backgroundColor = Color(0xFFF8FAFC);
  static const Color _surfaceColor = Colors.white;
  static const Color _textColor = Color(0xFF0F172A);
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE2E8F0);
  static const Color _fieldColor = Color(0xFFF8FAFC);

  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  List<Map<String, dynamic>> get _filteredClasses {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return widget.myClasses;
    }

    return widget.myClasses.where((item) {
      final classCodeWithName = _buildClassCodeWithName(item).toLowerCase();
      final className = item['className']?.toString().toLowerCase() ?? '';
      final instructor = item['instructor']?.toString().toLowerCase() ?? '';
      final semester = item['semester']?.toString().toLowerCase() ?? '';

      return classCodeWithName.contains(query) ||
          className.contains(query) ||
          instructor.contains(query) ||
          semester.contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _buildClassCodeWithName(Map<String, dynamic> item) {
    final existing = item['classCodeWithName']?.toString().trim() ?? '';

    if (existing.isNotEmpty) {
      return existing;
    }

    final code = item['classCode']?.toString().trim() ?? '';
    final name = item['className']?.toString().trim() ?? '';

    if (code.isNotEmpty && name.isNotEmpty) {
      return '$code - $name';
    }

    return code.isNotEmpty ? code : name;
  }

  Future<void> _openClassDetail(Map<String, dynamic> item) async {
    final targetIndex = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => StudentClassDetailScreen(
          classroomId: item['id'],
          classCodeWithName: _buildClassCodeWithName(item),
          className: item['className'] ?? '',
          instructor: item['instructor'] ?? '',
          semester: item['semester'] ?? '',
        ),
      ),
    );

    if (targetIndex != null) {
      widget.onTabTapped?.call(targetIndex);
    }
  }

  void _clearSearch() {
    _searchController.clear();

    setState(() {
      _searchQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredClasses = _filteredClasses;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: _buildHeader(filteredClasses.length),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: _buildSearchField(),
          ),
        ),
        if (filteredClasses.isEmpty)
          SliverToBoxAdapter(
            child: _EmptyClassesView(
              isSearching: _searchQuery.trim().isNotEmpty,
              onJoinClassPressed: widget.onJoinClassPressed,
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.separated(
              itemCount: filteredClasses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = filteredClasses[index];

                return _ClassCard(
                  title: _buildClassCodeWithName(item),
                  instructor: item['instructor']?.toString() ?? '',
                  semester: item['semester']?.toString() ?? '',
                  studentCount: (item['studentCount'] as num?)?.toInt() ?? 0,
                  onTap: () => _openClassDetail(item),
                );
              },
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
            child: _JoinClassButton(
              onPressed: widget.onJoinClassPressed,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(int classCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Danh sách lớp học',
          style: TextStyle(
            color: _textColor,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          classCount > 0
              ? 'Bạn đang tham gia $classCount lớp học'
              : 'Chưa có lớp học nào được hiển thị',
          style: const TextStyle(
            color: _mutedTextColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
      style: const TextStyle(
        color: _textColor,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: 'Tìm kiếm lớp học...',
        hintStyle: const TextStyle(
          color: _mutedTextColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: _mutedTextColor,
          size: 22,
        ),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                onPressed: _clearSearch,
                icon: const Icon(
                  Icons.close_rounded,
                  color: _mutedTextColor,
                  size: 20,
                ),
              )
            : null,
        filled: true,
        fillColor: _surfaceColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: _borderColor,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: _borderColor,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: _primaryColor,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final String title;
  final String instructor;
  final String semester;
  final int studentCount;
  final VoidCallback onTap;

  const _ClassCard({
    required this.title,
    required this.instructor,
    required this.semester,
    required this.studentCount,
    required this.onTap,
  });

  static const Color _primaryColor = Color(0xFF7EC07E);
  static const Color _surfaceColor = Colors.white;
  static const Color _textColor = Color(0xFF0F172A);
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE2E8F0);
  static const Color _fieldColor = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    final displayTitle = title.trim().isEmpty ? 'Lớp học' : title;

    return Material(
      color: _surfaceColor,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _borderColor.withOpacity(0.85),
            ),
            boxShadow: [
              BoxShadow(
                color: _textColor.withOpacity(0.035),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: _primaryColor,
                  size: 25,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _textColor,
                        fontSize: 15.5,
                        height: 1.25,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.1,
                      ),
                    ),
                    if (instructor.trim().isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Text(
                        instructor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _mutedTextColor,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (semester.trim().isNotEmpty)
                          _ClassChip(
                            icon: Icons.calendar_month_rounded,
                            label: semester,
                          ),
                        _ClassChip(
                          icon: Icons.groups_2_outlined,
                          label: '$studentCount sinh viên',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.chevron_right_rounded,
                color: _mutedTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClassChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ClassChip({
    required this.icon,
    required this.label,
  });

  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _fieldColor = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 180),
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: _fieldColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: _mutedTextColor,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _mutedTextColor,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JoinClassButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _JoinClassButton({
    required this.onPressed,
  });

  static const Color _primaryColor = Color(0xFF7EC07E);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.qr_code_scanner_rounded),
        label: const Text('Nhập mã tham gia lớp học mới'),
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryColor,
          side: const BorderSide(
            color: _primaryColor,
            width: 1.3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _EmptyClassesView extends StatelessWidget {
  final bool isSearching;
  final VoidCallback onJoinClassPressed;

  const _EmptyClassesView({
    required this.isSearching,
    required this.onJoinClassPressed,
  });

  static const Color _primaryColor = Color(0xFF7EC07E);
  static const Color _surfaceColor = Colors.white;
  static const Color _textColor = Color(0xFF0F172A);
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    final title = isSearching
        ? 'Không tìm thấy lớp học'
        : 'Bạn chưa tham gia lớp học nào';

    final message = isSearching
        ? 'Thử tìm bằng mã lớp, tên lớp, giảng viên hoặc học kỳ khác.'
        : 'Bấm nút bên dưới để tham gia lớp học mới.';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _borderColor),
        ),
        child: Column(
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                isSearching
                    ? Icons.search_off_rounded
                    : Icons.school_outlined,
                color: _primaryColor,
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _textColor,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _mutedTextColor,
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (!isSearching) ...[
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: onJoinClassPressed,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Tham gia lớp học'),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}