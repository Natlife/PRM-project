import 'dart:math';
import 'package:flutter/material.dart';
import 'student_detail_screen.dart';

class StudentListScreen extends StatefulWidget {
  final String className;
  final int studentsCount;

  const StudentListScreen({
    super.key,
    required this.className,
    required this.studentsCount,
  });

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  String _searchQuery = '';

  final List<Map<String, dynamic>> _students = [
    {
      'name': 'Nguyễn Văn B',
      'code': 'HE170123',
      'role': 'Nhóm trưởng Nhóm 1',
      'email': 'abchf@gmail.com',
      'progress': 85,
      'submissions': 12,
    },
    {
      'name': 'Trần Thị B',
      'code': 'HE170456',
      'role': 'Thành viên Nhóm 1',
      'email': 'btt@fpt.edu.vn',
      'progress': 90,
      'submissions': 14,
    },
    {
      'name': 'Lê Văn C',
      'code': 'HE170789',
      'role': 'Thành viên Nhóm 1',
      'email': 'clv@fpt.edu.vn',
      'progress': 75,
      'submissions': 10,
    },
    {
      'name': 'Phạm Minh D',
      'code': 'HE170999',
      'role': 'Thành viên Nhóm 1',
      'email': 'dpm@fpt.edu.vn',
      'progress': 60,
      'submissions': 8,
    },
    {
      'name': 'Hoàng Văn E',
      'code': 'HE171111',
      'role': 'Nhóm trưởng Nhóm 2',
      'email': 'ehv@fpt.edu.vn',
      'progress': 95,
      'submissions': 15,
    },
    {
      'name': 'Đỗ Thị F',
      'code': 'HE171222',
      'role': 'Thành viên Nhóm 2',
      'email': 'fdt@fpt.edu.vn',
      'progress': 50,
      'submissions': 6,
    },
    {
      'name': 'Nguyễn Đức G',
      'code': 'HE171333',
      'role': 'Thành viên Nhóm 2',
      'email': 'gnd@fpt.edu.vn',
      'progress': 80,
      'submissions': 11,
    },
    {
      'name': 'Vũ Minh H',
      'code': 'HE171444',
      'role': 'Nhóm trưởng Nhóm 3',
      'email': 'hvm@fpt.edu.vn',
      'progress': 70,
      'submissions': 9,
    },
    {
      'name': 'Phan Thanh I',
      'code': 'HE171555',
      'role': 'Thành viên Nhóm 3',
      'email': 'ipt@fpt.edu.vn',
      'progress': 85,
      'submissions': 12,
    },
    {
      'name': 'Nguyễn Thị K',
      'code': 'HE171666',
      'role': 'Thành viên Nhóm 3',
      'email': 'knt@fpt.edu.vn',
      'progress': 88,
      'submissions': 13,
    },
    {
      'name': 'Lê Tuấn L',
      'code': 'HE171777',
      'role': 'Thành viên Nhóm 3',
      'email': 'llt@fpt.edu.vn',
      'progress': 65,
      'submissions': 9,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredStudents = _students.where((student) {
      final query = _searchQuery.toLowerCase();
      return student['name']!.toLowerCase().contains(query) ||
          student['code']!.toLowerCase().contains(query) ||
          student['email']!.toLowerCase().contains(query) ||
          student['role']!.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header with Blue Back Button matching mockup
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E8EFF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Danh sách sinh viên',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Search Bar matching mockup
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm sinh viên',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
                  suffixIcon: Icon(Icons.search, color: const Color(0xFF2E8EFF), size: 20),
                  fillColor: const Color(0xFF1E293B),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: filteredStudents.isEmpty
                  ? Center(
                      child: Text(
                        'Không tìm thấy sinh viên nào',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14),
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filteredStudents.length,
                      itemBuilder: (context, index) {
                        final student = filteredStudents[index];
                        final String name = student['name'];
                        final String email = student['email'];
                        final int progress = student['progress'];
                        final int submissions = student['submissions'];

                        // Extract initials for the AVT icon
                        final words = name.split(' ');
                        final initials = words.length > 1
                            ? '${words[words.length - 2][0]}${words.last[0]}'.toLowerCase()
                            : name.substring(0, min(name.length, 3)).toLowerCase();

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StudentDetailScreen(
                                  studentName: name,
                                  studentEmail: email,
                                  submissionsCount: submissions,
                                  progressPercentage: progress,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                            ),
                            child: Row(
                              children: [
                                // Circular AVT matching mockup
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white30, width: 1.5),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    initials,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        email,
                                        style: const TextStyle(fontSize: 12, color: Colors.white38),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Text(
                                            'Tiến độ: $progress%',
                                            style: const TextStyle(fontSize: 11, color: Colors.white70),
                                          ),
                                          const SizedBox(width: 16),
                                          Text(
                                            'Submissions: $submissions',
                                            style: const TextStyle(fontSize: 11, color: Colors.white70),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
