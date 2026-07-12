import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/event_service.dart';

class StudentDefenseRoomScreen extends StatefulWidget {
  final int eventId;
  final int assignmentId;

  const StudentDefenseRoomScreen({
    super.key,
    required this.eventId,
    required this.assignmentId,
  });

  @override
  State<StudentDefenseRoomScreen> createState() => _StudentDefenseRoomScreenState();
}

class _StudentDefenseRoomScreenState extends State<StudentDefenseRoomScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _detail = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final detail = await EventService().getStudentEventDetail(widget.eventId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải phòng phản biện: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _askQuestion() async {
    final bank = List<Map<String, dynamic>>.from(_detail['questionBank'] ?? const []);
    final assignments = List<Map<String, dynamic>>.from(
      _detail['assignments'] ?? const [],
    );
    final assignment = assignments.cast<Map<String, dynamic>?>().firstWhere(
          (item) => ((item?['id'] as num?)?.toInt() ?? 0) == widget.assignmentId,
          orElse: () => Map<String, dynamic>.from(_detail['myAssignment'] ?? const {}),
        ) ??
        <String, dynamic>{};
    final controller = TextEditingController(
      text: bank.isNotEmpty ? (bank.first['content']?.toString() ?? '') : '',
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đặt câu hỏi'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Nhập câu hỏi dành cho người thuyết trình',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Gửi'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;
    try {
      await EventService().addStudentLiveQuestion(
        widget.eventId,
        result,
        assignmentId: (assignment['id'] as num?)?.toInt(),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi gửi câu hỏi: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignments = List<Map<String, dynamic>>.from(
      _detail['assignments'] ?? const [],
    );
    final assignment = assignments.cast<Map<String, dynamic>?>().firstWhere(
          (item) => ((item?['id'] as num?)?.toInt() ?? 0) == widget.assignmentId,
          orElse: () => Map<String, dynamic>.from(_detail['myAssignment'] ?? const {}),
        ) ??
        <String, dynamic>{};
    final questions = List<Map<String, dynamic>>.from(
      assignment['questions'] ?? const [],
    );
    final evidences = List<Map<String, dynamic>>.from(
      assignment['evidences'] ?? const [],
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: const Text(
          'Phòng phản biện',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF7EC07E)),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          assignment['presenterGroupName'] ??
                              assignment['presenterStudentName'] ??
                              '',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Phản biện: ${assignment['reviewerStudentName'] ?? ''}'),
                        const SizedBox(height: 8),
                        Text('Vai trò của bạn: ${_detail['myRole'] ?? ''}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (evidences.isNotEmpty) ...[
                    const Text(
                      'Minh chứng đang xem',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...evidences.map(
                      (evidence) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(evidence['originalFileName'] ?? ''),
                        trailing: IconButton(
                          onPressed: () async {
                            final url = evidence['fileUrl']?.toString() ?? '';
                            if (url.isEmpty) return;
                            await launchUrl(
                              Uri.parse(url),
                              mode: LaunchMode.externalApplication,
                            );
                          },
                          icon: const Icon(Icons.open_in_new),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Câu hỏi live',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      if (_detail['status']?.toString() == 'LIVE' &&
                          assignment['myRole']?.toString() == 'REVIEWER')
                        ElevatedButton(
                          onPressed: _askQuestion,
                          child: const Text('Đặt câu hỏi'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (questions.isEmpty)
                    const Text('Chưa có câu hỏi nào trong phiên này')
                  else
                    ...questions.map(
                      (question) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              question['authorName'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(question['content'] ?? ''),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
