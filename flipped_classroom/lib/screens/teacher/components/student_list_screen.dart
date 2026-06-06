import 'package:flutter/material.dart';

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
  final List<Map<String, String>> _students = [
    {'name': 'Nguyễn Văn A', 'code': 'HE170123', 'role': 'Nhóm trưởng Nhóm 1', 'email': 'anv@fpt.edu.vn'},
    {'name': 'Trần Thị B', 'code': 'HE170456', 'role': 'Thành viên Nhóm 1', 'email': 'btt@fpt.edu.vn'},
    {'name': 'Lê Văn C', 'code': 'HE170789', 'role': 'Thành viên Nhóm 1', 'email': 'clv@fpt.edu.vn'},
    {'name': 'Phạm Minh D', 'code': 'HE170999', 'role': 'Thành viên Nhóm 1', 'email': 'dpm@fpt.edu.vn'},
    {'name': 'Hoàng Văn E', 'code': 'HE171111', 'role': 'Nhóm trưởng Nhóm 2', 'email': 'ehv@fpt.edu.vn'},
    {'name': 'Đỗ Thị F', 'code': 'HE171222', 'role': 'Thành viên Nhóm 2', 'email': 'fdt@fpt.edu.vn'},
    {'name': 'Nguyễn Đức G', 'code': 'HE171333', 'role': 'Thành viên Nhóm 2', 'email': 'gnd@fpt.edu.vn'},
    {'name': 'Vũ Minh H', 'code': 'HE171444', 'role': 'Nhóm trưởng Nhóm 3', 'email': 'hvm@fpt.edu.vn'},
    {'name': 'Phan Thanh I', 'code': 'HE171555', 'role': 'Thành viên Nhóm 3', 'email': 'ipt@fpt.edu.vn'},
    {'name': 'Nguyễn Thị K', 'code': 'HE171666', 'role': 'Thành viên Nhóm 3', 'email': 'knt@fpt.edu.vn'},
    {'name': 'Lê Tuấn L', 'code': 'HE171777', 'role': 'Thành viên Nhóm 3', 'email': 'llt@fpt.edu.vn'},
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          children: [
            const Text(
              'Danh sách sinh viên',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 2),
            Text(
              widget.className,
              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm sinh viên...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.4), size: 20),
                fillColor: const Color(0xFF1E293B),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: filteredStudents.isEmpty
                ? Center(
                    child: Text(
                      'Không tìm thấy sinh viên nào',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = filteredStudents[index];
                      final isLeader = student['role']!.contains('Nhóm trưởng');
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isLeader ? const Color(0xFF5A57FF) : const Color(0xFF0F172A),
                              radius: 20,
                              child: Text(
                                student['name']!.split(' ').last.substring(0, 1).toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        student['name']!,
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '(${student['code']})',
                                        style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    student['email']!,
                                    style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4)),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isLeader ? const Color(0xFF5A57FF).withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                student['role']!,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isLeader ? const Color(0xFF8F8DFF) : Colors.white54,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
