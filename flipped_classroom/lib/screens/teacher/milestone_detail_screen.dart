import 'package:flutter/material.dart';
import 'edit_milestone_screen.dart';

class MilestoneDetailScreen extends StatefulWidget {
  final Map<String, dynamic> milestone;

  const MilestoneDetailScreen({
    super.key,
    required this.milestone,
  });

  @override
  State<MilestoneDetailScreen> createState() => _MilestoneDetailScreenState();
}

class _MilestoneDetailScreenState extends State<MilestoneDetailScreen> {
  late Map<String, dynamic> _milestoneData;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _milestoneData = Map<String, dynamic>.from(widget.milestone);
    
    // Setup some defaults if missing
    if (_milestoneData['activities'] == null) {
      _milestoneData['activities'] = [
        {
          'title': 'Code 3 màn hình chính',
          'status': 'Đã hoàn thành',
        },
        {
          'title': 'Thiết kế Mockup UI',
          'status': 'Đã hoàn thành',
        },
      ];
    }
    
    if (_milestoneData['comments'] == null) {
      _milestoneData['comments'] = [
        {
          'sender': 'Giáo viên',
          'text': 'Em làm bài tốt!',
        },
        {
          'sender': 'Học viên',
          'text': 'Em cảm ơn thầy!',
        },
      ];
    }

    if (_milestoneData['evidences'] == null) {
      _milestoneData['evidences'] = [
        {
          'fileName': 'Ảnh màn hình.jpg',
        },
      ];
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Hoàn thành':
        return const Color(0xFF22C55E);
      case 'Đang thực hiện':
        return const Color(0xFF2E8EFF);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  Future<void> _navigateToEditMilestone() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => EditMilestoneScreen(milestone: _milestoneData),
      ),
    );
    if (result != null) {
      setState(() {
        _milestoneData = result;
      });
    }
  }

  void _sendComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    
    setState(() {
      final list = List<Map<String, String>>.from(_milestoneData['comments'] ?? []);
      list.add({
        'sender': 'Giáo viên',
        'text': text,
      });
      _milestoneData['comments'] = list;
      _commentController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> activities = _milestoneData['activities'] ?? [];
    final List<dynamic> comments = _milestoneData['comments'] ?? [];
    final List<dynamic> evidences = _milestoneData['evidences'] ?? [];
    final String title = _milestoneData['title'] ?? 'Mốc thời gian';
    final String status = _milestoneData['status'] ?? 'Chưa bắt đầu';
    final String date = _milestoneData['date'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(_milestoneData),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2E8EFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
            ),
          ),
        ),
        title: const Text(
          'Chi tiết mốc thời gian',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Milestone Title Header
                  Text(
                    title,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  
                  // Status & Deadline
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            status,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(status),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Hạn: $date',
                            style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4)),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: _navigateToEditMilestone,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E8EFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: const Text(
                          'Chỉnh sửa',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Activities
                  Text(
                    'Hoạt động (${activities.length})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  if (activities.isEmpty)
                    const Center(
                      child: Text(
                        'Chưa có hoạt động nào',
                        style: TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                    )
                  else
                    ...activities.map((act) {
                      final actTitle = act['title'] ?? '';
                      final actStatus = act['status'] ?? 'Chưa bắt đầu';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                actTitle,
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(
                              actStatus,
                              style: TextStyle(color: _getStatusColor(actStatus), fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 24),

                  // Evidence
                  const Text(
                    'Evidence',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  if (evidences.isEmpty)
                    const Center(
                      child: Text(
                        'Chưa tải lên minh chứng nào',
                        style: TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                    )
                  else
                    ...evidences.map((ev) {
                      final fName = ev['fileName'] ?? 'minh_chung.pdf';
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                fName,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Đang tải và mở: $fName'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Xem',
                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 24),

                  // Comments
                  const Text(
                    'Trao đổi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  if (comments.isEmpty)
                    const Center(
                      child: Text(
                        'Chưa có thảo luận nào',
                        style: TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                    )
                  else
                    ...comments.map((comment) {
                      final sender = comment['sender'] ?? '';
                      final text = comment['text'] ?? '';
                      final isTeacher = sender == 'Giáo viên';

                      return Align(
                        alignment: isTeacher ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isTeacher ? const Color(0xFF2E8EFF) : const Color(0xFF1E293B),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(14),
                              topRight: const Radius.circular(14),
                              bottomLeft: isTeacher ? const Radius.circular(14) : Radius.zero,
                              bottomRight: isTeacher ? Radius.zero : const Radius.circular(14),
                            ),
                          ),
                          child: Text(
                            text,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          
          // Bottom Comment Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Nhập nhận xét của bạn...',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                      fillColor: const Color(0xFF0F172A),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (v) => _sendComment(),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF2E8EFF)),
                  onPressed: _sendComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
