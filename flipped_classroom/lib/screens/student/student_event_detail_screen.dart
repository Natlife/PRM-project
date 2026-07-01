import 'package:flutter/material.dart';
import 'student_event_review_screen.dart';
import 'student_defense_room_screen.dart';

class StudentEventDetailScreen extends StatefulWidget {
  final Map<String, dynamic> event;

  const StudentEventDetailScreen({
    super.key,
    required this.event,
  });

  @override
  State<StudentEventDetailScreen> createState() => _StudentEventDetailScreenState();
}

class _StudentEventDetailScreenState extends State<StudentEventDetailScreen> {
  late String _role;
  late String _status;
  List<String> _evidences = ['Ảnh evidence 1'];

  @override
  void initState() {
    super.initState();
    _role = widget.event['role'] ?? 'Người thuyết trình';
    _status = widget.event['status'] ?? 'Sắp diễn ra';
  }

  void _showDeleteConfirmation(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'Xác nhận xóa',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          content: const Text(
            'Bạn có chắc chắn muốn xóa?',
            style: TextStyle(color: Color(0xFF0F172A), fontSize: 15),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Quay lại trang chi tiết và không xóa
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF0F172A).withOpacity(0.6),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text('Hủy', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _evidences.removeAt(index);
                });
                Navigator.pop(context); // Quay lại trang chi tiết và xóa
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã xóa tài liệu thành công!'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.redAccent,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text('Xác nhận', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _uploadDocument() {
    setState(() {
      _evidences.add('Ảnh evidence ${_evidences.length + 1}');
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã tải lên tài liệu thành công!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF7EC07E),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color statusColor = widget.event['statusColor'] ?? Colors.amber[800];
    final String presenterName = widget.event['presenterName'] ?? 'Nguyễn Minh Anh';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context), // Quay lại trang danh sách
        ),
        title: const Text(
          'Chi tiết sự kiện',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Democase Toggle Role just for testing/presentation purposes
          TextButton.icon(
            onPressed: () {
              setState(() {
                _role = _role == 'Người thuyết trình' ? 'Người phản biện' : 'Người thuyết trình';
              });
            },
            icon: const Icon(Icons.swap_horiz, size: 16, color: Color(0xFF7EC07E)),
            label: Text(
              _role == 'Người thuyết trình' ? 'Presenter' : 'Reviewer',
              style: const TextStyle(fontSize: 12, color: Color(0xFF7EC07E), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Main Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.06)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          _role == 'Người thuyết trình' ? presenterName : 'Nguyễn Vân Anh',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      Text(
                        _status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.event['classCode'] ?? 'PRM - SE1904',
                    style: TextStyle(
                      fontSize: 15,
                      color: const Color(0xFF0F172A).withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.event['date'] ?? '25/6/2026',
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF0F172A).withOpacity(0.4),
                    ),
                  ),
                  const Divider(height: 24, thickness: 1),
                  Row(
                    children: [
                      Icon(Icons.assignment_ind_outlined, size: 18, color: const Color(0xFF0F172A).withOpacity(0.5)),
                      const SizedBox(width: 8),
                      Text(
                        'Vai trò của bạn: ',
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF0F172A).withOpacity(0.5),
                        ),
                      ),
                      Text(
                        _role,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7EC07E),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Content dynamically based on Role
            if (_role == 'Người thuyết trình') ...[
              // Evidences list
              if (_evidences.isNotEmpty)
                ..._evidences.asMap().entries.map((entry) {
                  int index = entry.key;
                  String evidence = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.06)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.image_outlined, color: Colors.blue, size: 22),
                            const SizedBox(width: 12),
                            Text(
                              evidence,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => _showDeleteConfirmation(index), // Mở popup xóa
                        ),
                      ],
                    ),
                  );
                }),

              const SizedBox(height: 12),

              // Upload Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _uploadDocument,
                  icon: const Icon(Icons.upload_file, color: Color(0xFF7EC07E)),
                  label: const Text(
                    'Tải lên tài liệu',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF7EC07E)),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    surfaceTintColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFF7EC07E), width: 1.5),
                    ),
                    elevation: 0,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Enter Room Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StudentDefenseRoomScreen(
                          event: widget.event,
                          role: _role,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7EC07E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Vào phòng phản biện',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Policy Info Note
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.withOpacity(0.15)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tài liệu khi giảng viên chưa bắt đầu sự kiện thì status là private chỉ bạn và giảng viên xem được còn khi bắt đầu sự kiện rồi thì tài liệu được public cho tất cả mọi người xem.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue[900],
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Review / Viewer mode
              // Review Room / Replay Event button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StudentEventReviewScreen(
                          event: widget.event,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7EC07E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Xem lại sự kiện',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
