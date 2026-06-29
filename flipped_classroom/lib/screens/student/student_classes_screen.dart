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

  @override
  Widget build(BuildContext context) {
    final filteredClasses = widget.myClasses.where((item) {
      final query = _searchQuery.toLowerCase();
      final classCodeWithName = _buildClassCodeWithName(item).toLowerCase();
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
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 8),
            child: Text(
              'Danh sach lop hoc',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Tim kiem lop hoc...',
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
        if (filteredClasses.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'Khong tim thay lop hoc nao!',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = filteredClasses[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: const Color(0xFF0F172A).withOpacity(0.06), width: 1.2),
                      ),
                      color: Colors.white,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () async {
                          final targetIndex = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StudentClassDetailScreen(
                                classroomId: item['id'],
                                classCodeWithName: _buildClassCodeWithName(item),
                                className: item['className'] ?? '',
                                instructor: item['instructor'] ?? '',
                                semester: item['semester'] ?? '',
                              ),
                            ),
                          );
                          if (targetIndex != null && targetIndex is int) {
                            widget.onTabTapped?.call(targetIndex);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _buildClassCodeWithName(item),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
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
                                    Text(
                                      item['instructor'] ?? '',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: const Color(0xFF0F172A).withOpacity(0.6),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${item['studentCount'] ?? 0} sinh vien',
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
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: OutlinedButton.icon(
              onPressed: widget.onJoinClassPressed,
              icon: const Icon(Icons.qr_code, color: Color(0xFF7EC07E)),
              label: const Text(
                'Quet ma tham gia lop hoc moi',
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
