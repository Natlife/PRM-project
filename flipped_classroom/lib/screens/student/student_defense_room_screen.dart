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
  State<StudentDefenseRoomScreen> createState() =>
      _StudentDefenseRoomScreenState();
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
    final bank = List<Map<String, dynamic>>.from(
      _detail['questionBank'] ?? const [],
    );
    final assignments = List<Map<String, dynamic>>.from(
      _detail['assignments'] ?? const [],
    );
    final assignment =
        assignments.cast<Map<String, dynamic>?>().firstWhere(
          (item) =>
              ((item?['id'] as num?)?.toInt() ?? 0) == widget.assignmentId,
          orElse: () =>
              Map<String, dynamic>.from(_detail['myAssignment'] ?? const {}),
        ) ??
        <String, dynamic>{};
    final isPresenter = assignment['myRole']?.toString() == 'PRESENTER';
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        int selectedBankIndex = -1;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isPresenter ? 'Trả lời câu hỏi' : 'Đặt câu hỏi'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.85,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isPresenter && bank.isNotEmpty) ...[
                        const Text(
                          'Chọn từ ngân hàng câu hỏi gợi ý:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 180),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: bank.length,
                            itemBuilder: (context, index) {
                              final questionItem = bank[index];
                              final isSelected = selectedBankIndex == index;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedBankIndex = index;
                                    controller.text =
                                        questionItem['content']?.toString() ??
                                        '';
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(
                                            0xFF7EC07E,
                                          ).withOpacity(0.12)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF7EC07E)
                                          : const Color(0xFFE2E8F0),
                                      width: isSelected ? 1.5 : 1.0,
                                    ),
                                  ),
                                  child: Text(
                                    questionItem['content'] ?? '',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: isSelected
                                          ? FontWeight.w500
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? const Color(0xFF2E7D32)
                                          : const Color(0xFF334155),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Hoặc tự nhập câu hỏi riêng:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      TextField(
                        controller: controller,
                        maxLines: 4,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: isPresenter
                              ? 'Nhập câu trả lời của bạn'
                              : 'Nhập nội dung câu hỏi...',
                          contentPadding: const EdgeInsets.all(12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF7EC07E),
                              width: 1.5,
                            ),
                          ),
                        ),
                        onChanged: (val) {
                          if (selectedBankIndex != -1) {
                            if (val != bank[selectedBankIndex]['content']) {
                              setState(() {
                                selectedBankIndex = -1;
                              });
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Hủy',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pop(context, controller.text.trim()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Gửi'),
                ),
              ],
            );
          },
        );
      },
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

  Future<void> _answerQuestion(Map<String, dynamic> question) async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Trả lời câu hỏi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Câu hỏi từ ${question['authorName']}:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              question['content'] ?? '',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Nhập câu trả lời của bạn',
                border: OutlineInputBorder(),
              ),
            ),
          ],
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
      await EventService().answerStudentLiveQuestion(
        widget.eventId,
        (question['id'] as num).toInt(),
        result,
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi gửi câu trả lời: $e'),
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
    final assignment =
        assignments.cast<Map<String, dynamic>?>().firstWhere(
          (item) =>
              ((item?['id'] as num?)?.toInt() ?? 0) == widget.assignmentId,
          orElse: () =>
              Map<String, dynamic>.from(_detail['myAssignment'] ?? const {}),
        ) ??
        <String, dynamic>{};
    final questions = List<Map<String, dynamic>>.from(
      assignment['questions'] ?? const [],
    );
    final evidences = List<Map<String, dynamic>>.from(
      assignment['evidences'] ?? const [],
    );
    final recording = assignment['recording'] as Map<String, dynamic>?;

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
                        Text(
                          'Phản biện: ${assignment['reviewerStudentName'] ?? ''}',
                        ),
                        const SizedBox(height: 8),
                        Text('Vai trò của bạn: ${_detail['myRole'] ?? ''}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (evidences.isNotEmpty || recording != null) ...[
                    const Text(
                      'Minh chứng đang xem',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (recording != null)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.play_circle_outline,
                          color: Colors.green,
                        ),
                        title: Text(recording['originalFileName'] ?? ''),
                        subtitle: const Text(
                          'Bản ghi/Minh chứng do giáo viên tải lên',
                        ),
                        trailing: IconButton(
                          onPressed: () async {
                            final url = recording['fileUrl']?.toString() ?? '';
                            if (url.isEmpty) return;
                            await launchUrl(
                              Uri.parse(url),
                              mode: LaunchMode.externalApplication,
                            );
                          },
                          icon: const Icon(Icons.open_in_new),
                        ),
                      ),
                    ...evidences.map(
                      (evidence) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.insert_drive_file_outlined,
                          color: Colors.blue,
                        ),
                        title: Text(evidence['originalFileName'] ?? ''),
                        subtitle: Text(
                          'Tải lên bởi ${evidence['uploadedByName'] ?? 'Sinh viên'}',
                        ),
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  question['authorName'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (question['authorRole'] == 'ROLE_TEACHER')
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Giáo viên',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                else if ((question['authorId'] as num?)
                                        ?.toInt() ==
                                    (assignment['reviewerStudentId'] as num?)
                                        ?.toInt())
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Phản biện',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Thuyết trình',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(question['content'] ?? ''),
                            if (question['answer'] != null &&
                                (question['answer'] as String).isNotEmpty) ...[
                              const Divider(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Trả lời: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      question['answer'] ?? '',
                                      style: const TextStyle(
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ] else if (assignment['myRole']?.toString() ==
                                'PRESENTER') ...[
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () => _answerQuestion(question),
                                  icon: const Icon(
                                    Icons.reply,
                                    size: 16,
                                    color: Colors.green,
                                  ),
                                  label: const Text(
                                    'Trả lời',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ),
                            ],
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
