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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Filter classes based on query
    final filteredClasses = widget.myClasses.where((item) {
      final query = _searchQuery.toLowerCase();
      final classCodeWithName = (item['classCodeWithName'] ?? '').toString().toLowerCase();
      final className = (item['className'] ?? '').toString().toLowerCase();
      final instructor = (item['instructor'] ?? '').toString().toLowerCase();
      final semester = (item['semester'] ?? '').toString().toLowerCase();

      return classCodeWithName.contains(query) ||
          className.contains(query) ||
          instructor.contains(query) ||
          semester.contains(query);
    }).toList();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Header
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0, bottom: 8.0),
            child: Text(
              'Danh sách lớp học',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
          ),
        ),

        // Search Bar (thanh tìm kiếm lớp học)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Tìm kiếm lớp học (môn học, giảng viên, học kỳ)...',
                hintStyle: TextStyle(color: const Color(0xFF0F172A).withOpacity(0.3), fontSize: 14),
                prefixIcon: Icon(Icons.search, color: const Color(0xFF0F172A).withOpacity(0.4), size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: const Color(0xFF0F172A).withOpacity(0.04), width: 1.2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: const Color(0xFF0F172A).withOpacity(0.04), width: 1.2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF7EC07E), width: 1.5),
                ),
              ),
            ),
          ),
        ),

        // Classes list
        filteredClasses.isEmpty
            ? const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.0),
                  child: Center(
                    child: Text(
                      'Không tìm thấy lớp học nào!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              )
            : SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = filteredClasses[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: const Color(0xFF0F172A).withOpacity(0.06), width: 1.2),
                          ),
                          color: Colors.white,
                          child: InkWell(
                            onTap: () async {
                              final targetIndex = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StudentClassDetailScreen(
                                    classCodeWithName: item['classCodeWithName'] ?? '${item['classCode']} - SE1904',
                                    className: item['className'] ?? '',
                                    instructor: item['instructor'] ?? '',
                                    semester: item['semester'] ?? 'SU26',
                                  ),
                                ),
                              );
                              if (targetIndex != null && targetIndex is int) {
                                widget.onTabTapped?.call(targetIndex);
                              }
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Top Row: Class name + code, Semester on the right
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              item['classCodeWithName'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF0F172A),
                                              ),
                                            ),
                                            Text(
                                              item['semester'] ?? '',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF0F172A).withOpacity(0.4),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        // Instructor
                                        Text(
                                          item['instructor'] ?? '',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: const Color(0xFF0F172A).withOpacity(0.6),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        // Student count (e.g. 30 sinh viên)
                                        Text(
                                          '${item['studentCount'] ?? 0} sinh viên',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: const Color(0xFF0F172A).withOpacity(0.4),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(Icons.chevron_right, color: const Color(0xFF0F172A).withOpacity(0.3)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: filteredClasses.length,
                  ),
                ),
              ),

        // Bottom Join Class Button
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: OutlinedButton.icon(
              onPressed: widget.onJoinClassPressed,
              icon: const Icon(Icons.qr_code, color: Color(0xFF7EC07E)),
              label: const Text(
                'Quét mã tham gia lớp học mới',
                style: TextStyle(color: Color(0xFF7EC07E), fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF7EC07E), width: 1.2),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
