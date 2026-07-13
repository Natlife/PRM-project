import 'dart:io' as io;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/event_service.dart';

class TeacherEventDetailScreen extends StatefulWidget {
  final int eventId;

  const TeacherEventDetailScreen({
    super.key,
    required this.eventId,
  });

  @override
  State<TeacherEventDetailScreen> createState() => _TeacherEventDetailScreenState();
}

class _TeacherEventDetailScreenState extends State<TeacherEventDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _detail = {};

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => _isLoading = true);
    try {
      final detail = await EventService().getTeacherEventDetail(widget.eventId);
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
          content: Text('Lỗi tải chi tiết sự kiện: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  String _formatDateTime(dynamic raw) {
    if (raw == null) return '';
    final value = raw.toString();
    final parts = value.split('T');
    if (parts.length != 2) return value;
    final date = parts.first.split('-');
    final time = parts.last.split(':');
    if (date.length == 3 && time.length >= 2) {
      return '${date[2]}/${date[1]}/${date[0]} ${time[0]}:${time[1]}';
    }
    return value;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'LIVE':
        return Colors.green;
      case 'COMPLETED':
        return Colors.grey;
      case 'CANCELLED':
        return Colors.redAccent;
      case 'SCHEDULED':
      default:
        return Colors.orange;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'LIVE':
        return 'Đang diễn ra';
      case 'COMPLETED':
        return 'Đã hoàn thành';
      case 'CANCELLED':
        return 'Đã hủy';
      case 'SCHEDULED':
      default:
        return 'Chưa diễn ra';
    }
  }

  ButtonStyle _dialogTextButtonStyle() {
    return TextButton.styleFrom(
      foregroundColor: const Color(0xFF64748B),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  ButtonStyle _primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF7EC07E),
      foregroundColor: const Color(0xFF0F172A),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      elevation: 0,
    );
  }

  ButtonStyle _darkButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF0F172A),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      elevation: 0,
    );
  }

  ButtonStyle _outlineActionButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF0F172A),
      side: const BorderSide(color: Color(0xFF7EC07E), width: 1.2),
      backgroundColor: const Color(0xFF7EC07E).withValues(alpha: 0.08),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  ButtonStyle _headerTextButtonStyle() {
    return TextButton.styleFrom(
      foregroundColor: const Color(0xFF0F172A),
      backgroundColor: const Color(0xFF7EC07E).withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Future<void> _updateStatus(String status) async {
    try {
      await EventService().updateTeacherEvent(widget.eventId, {'status': status});
      await _loadDetail();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã cập nhật trạng thái sự kiện'),
          backgroundColor: const Color(0xFF7EC07E),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi cập nhật trạng thái: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _showAddQuestionBankDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm câu hỏi mẫu'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Nhập câu hỏi vào ngân hàng câu hỏi',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: _dialogTextButtonStyle(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: _primaryButtonStyle(),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;

    try {
      await EventService().addQuestionBankItem(widget.eventId, result);
      await _loadDetail();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi thêm câu hỏi: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _showAddAssignmentDialog() async {
    final students = List<Map<String, dynamic>>.from(
      _detail['availableStudents'] ?? const [],
    );
    final groups = List<Map<String, dynamic>>.from(
      _detail['availableGroups'] ?? const [],
    );
    if (students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lớp hiện chưa có sinh viên để phân công'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    String assignmentType = 'INDIVIDUAL';
    int orderIndex =
        List<Map<String, dynamic>>.from(_detail['assignments'] ?? const []).length + 1;
    int? presenterStudentId = (students.first['id'] as num?)?.toInt();
    int? reviewerStudentId = students.length > 1
        ? (students[1]['id'] as num?)?.toInt()
        : (students.first['id'] as num?)?.toInt();
    int? presenterGroupId = groups.isNotEmpty
        ? (groups.first['id'] as num?)?.toInt()
        : null;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Tạo phiên phản biện'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: assignmentType,
                      decoration: const InputDecoration(labelText: 'Kiểu phiên'),
                      items: const [
                        DropdownMenuItem(
                          value: 'INDIVIDUAL',
                          child: Text('Cá nhân'),
                        ),
                        DropdownMenuItem(
                          value: 'GROUP',
                          child: Text('Nhóm'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => assignmentType = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: '$orderIndex',
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Thứ tự'),
                      onChanged: (value) {
                        orderIndex = int.tryParse(value) ?? orderIndex;
                      },
                    ),
                    const SizedBox(height: 12),
                    if (assignmentType == 'INDIVIDUAL')
                      DropdownButtonFormField<int>(
                        initialValue: presenterStudentId,
                        decoration: const InputDecoration(
                          labelText: 'Người thuyết trình',
                        ),
                        items: students
                            .map(
                              (student) => DropdownMenuItem<int>(
                                value: (student['id'] as num?)?.toInt(),
                                child: Text(student['fullName'] ?? student['userName'] ?? ''),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setDialogState(() => presenterStudentId = value);
                        },
                      )
                    else
                      DropdownButtonFormField<int>(
                        initialValue: presenterGroupId,
                        decoration: const InputDecoration(labelText: 'Nhóm thuyết trình'),
                        items: groups
                            .map(
                              (group) => DropdownMenuItem<int>(
                                value: (group['id'] as num?)?.toInt(),
                                child: Text(group['groupName'] ?? ''),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setDialogState(() => presenterGroupId = value);
                        },
                      ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: reviewerStudentId,
                      decoration: const InputDecoration(labelText: 'Người phản biện'),
                      items: students
                          .map(
                            (student) => DropdownMenuItem<int>(
                              value: (student['id'] as num?)?.toInt(),
                              child: Text(student['fullName'] ?? student['userName'] ?? ''),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() => reviewerStudentId = value);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: _dialogTextButtonStyle(),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: _primaryButtonStyle(),
                  child: const Text('Tạo'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) return;

    try {
      await EventService().createEventAssignment(
        widget.eventId,
        {
          'assignmentType': assignmentType,
          if (assignmentType == 'INDIVIDUAL')
            'presenterStudentId': presenterStudentId,
          if (assignmentType == 'GROUP') 'presenterGroupId': presenterGroupId,
          'reviewerStudentId': reviewerStudentId,
          'orderIndex': orderIndex,
        },
      );
      await _loadDetail();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tạo phiên phản biện: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _detail['title']?.toString() ?? 'Chi tiết sự kiện';
    final status = _detail['status']?.toString() ?? 'SCHEDULED';
    final assignments = List<Map<String, dynamic>>.from(
      _detail['assignments'] ?? const [],
    );
    final questionBank = List<Map<String, dynamic>>.from(
      _detail['questionBank'] ?? const [],
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
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF7EC07E)),
            )
          : OutlinedButtonTheme(
              data: OutlinedButtonThemeData(style: _outlineActionButtonStyle()),
              child: RefreshIndicator(
                onRefresh: _loadDetail,
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _detail['classroomCode']?.toString() ?? '',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF7EC07E),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _statusColor(status).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _statusLabel(status),
                                style: TextStyle(
                                  color: _statusColor(status),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _detail['description']?.toString().isNotEmpty == true
                              ? _detail['description'].toString()
                              : 'Chưa có mô tả sự kiện.',
                          style: TextStyle(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.7),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Bắt đầu: ${_formatDateTime(_detail['startAt'])}',
                          style: const TextStyle(color: Color(0xFF334155)),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Kết thúc: ${_formatDateTime(_detail['endAt'])}',
                          style: const TextStyle(color: Color(0xFF334155)),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Thời lượng mỗi phiên: ${_detail['sessionDurationMinutes'] ?? 0} phút',
                          style: const TextStyle(color: Color(0xFF334155)),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            if (status == 'SCHEDULED')
                              ElevatedButton(
                                onPressed: () => _updateStatus('LIVE'),
                                style: _primaryButtonStyle(),
                                child: const Text('Bắt đầu sự kiện'),
                              ),
                            if (status == 'LIVE')
                              ElevatedButton(
                                onPressed: () => _updateStatus('COMPLETED'),
                                style: _darkButtonStyle(),
                                child: const Text('Kết thúc sự kiện'),
                              ),
                            OutlinedButton(
                              onPressed: _showAddAssignmentDialog,
                              style: _outlineActionButtonStyle(),
                              child: const Text('Thêm phiên phản biện'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionHeader(
                    title: 'Ngân hàng câu hỏi',
                    actionLabel: 'Thêm',
                    onAction: _showAddQuestionBankDialog,
                  ),
                  const SizedBox(height: 12),
                  if (questionBank.isEmpty)
                    _buildEmptyCard('Chưa có câu hỏi mẫu nào')
                  else
                    ...questionBank.map(_buildQuestionCard),
                  const SizedBox(height: 20),
                  _buildSectionHeader(
                    title: 'Phiên phản biện',
                    actionLabel: 'Tạo phiên',
                    onAction: _showAddAssignmentDialog,
                  ),
                  const SizedBox(height: 12),
                  if (assignments.isEmpty)
                    _buildEmptyCard('Chưa có phiên phản biện nào')
                  else
                    ...assignments.map(_buildAssignmentCard),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        TextButton(
          onPressed: onAction,
          style: _headerTextButtonStyle(),
          child: Text(actionLabel),
        ),
      ],
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: const Color(0xFF0F172A).withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question['content']?.toString() ?? '',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tạo bởi ${question['authorName'] ?? ''}',
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF0F172A).withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(Map<String, dynamic> assignment) {
    final presenter = assignment['presenterGroupName'] ??
        assignment['presenterStudentName'] ??
        'Chưa xác định';
    final reviewer = assignment['reviewerStudentName'] ?? 'Chưa xác định';
    final recording = assignment['recording'] as Map<String, dynamic>?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
                'Phiên ${assignment['orderIndex'] ?? ''}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                assignment['status']?.toString() == 'REVIEWED'
                    ? 'Đã review'
                    : 'Chưa review',
                style: TextStyle(
                  color: assignment['status']?.toString() == 'REVIEWED'
                      ? Colors.green
                      : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('Thuyết trình: $presenter'),
          const SizedBox(height: 4),
          Text('Phản biện: $reviewer'),
          if (recording != null) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () async {
                final url = recording['fileUrl']?.toString() ?? '';
                if (url.isEmpty) return;
                await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              },
              child: Text(
                'Bản ghi: ${recording['originalFileName'] ?? ''}',
                style: const TextStyle(
                  color: Color(0xFF7EC07E),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TeacherEventRoomScreen(
                      eventId: widget.eventId,
                      assignmentId: (assignment['id'] as num?)?.toInt() ?? 0,
                    ),
                  ),
                );
                if (result == true) {
                  await _loadDetail();
                }
              },
              child: const Text('Mở phòng review'),
            ),
          ),
        ],
      ),
    );
  }
}

class TeacherEventRoomScreen extends StatefulWidget {
  final int eventId;
  final int assignmentId;

  const TeacherEventRoomScreen({
    super.key,
    required this.eventId,
    required this.assignmentId,
  });

  @override
  State<TeacherEventRoomScreen> createState() => _TeacherEventRoomScreenState();
}

class _TeacherEventRoomScreenState extends State<TeacherEventRoomScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _detail = {};
  Map<String, dynamic>? _assignment;

  ButtonStyle _dialogTextButtonStyle() {
    return TextButton.styleFrom(
      foregroundColor: const Color(0xFF64748B),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  ButtonStyle _primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF7EC07E),
      foregroundColor: const Color(0xFF0F172A),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      elevation: 0,
    );
  }

  ButtonStyle _outlineActionButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF0F172A),
      side: const BorderSide(color: Color(0xFF7EC07E), width: 1.2),
      backgroundColor: const Color(0xFF7EC07E).withValues(alpha: 0.08),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final detail = await EventService().getTeacherEventDetail(widget.eventId);
      final assignments = List<Map<String, dynamic>>.from(
        detail['assignments'] ?? const [],
      );
      final assignment = assignments.firstWhere(
        (item) => ((item['id'] as num?)?.toInt() ?? 0) == widget.assignmentId,
        orElse: () => <String, dynamic>{},
      );
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _assignment = assignment.isEmpty ? null : assignment;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải phòng review: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _addLiveQuestion() async {
    final bank = List<Map<String, dynamic>>.from(_detail['questionBank'] ?? const []);
    String selectedContent = bank.isNotEmpty ? (bank.first['content']?.toString() ?? '') : '';
    final controller = TextEditingController(text: selectedContent);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Đặt câu hỏi'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (bank.isNotEmpty)
                  DropdownButtonFormField<String>(
                    initialValue: selectedContent.isEmpty ? null : selectedContent,
                    decoration: const InputDecoration(labelText: 'Chọn từ ngân hàng'),
                    items: bank
                        .map(
                          (item) => DropdownMenuItem<String>(
                            value: item['content']?.toString() ?? '',
                            child: Text(
                              item['content']?.toString() ?? '',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() {
                        selectedContent = value;
                        controller.text = value;
                      });
                    },
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Nhập câu hỏi',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: _dialogTextButtonStyle(),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                style: _primaryButtonStyle(),
                child: const Text('Gửi'),
              ),
            ],
          );
        },
      ),
    );

    if (result == null || result.isEmpty) return;

    try {
      await EventService().addTeacherLiveQuestion(
        widget.eventId,
        result,
        assignmentId: widget.assignmentId,
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

  Future<void> _uploadRecording() async {
    try {
      final result = await FilePicker.pickFiles(withData: true);
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      List<int>? bytes = file.bytes;
      if (bytes == null && file.path != null) {
        bytes = await io.File(file.path!).readAsBytes();
      }
      if (bytes == null) return;

      await EventService().uploadRecording(
        widget.eventId,
        widget.assignmentId,
        bytes,
        file.name,
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi upload recording: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _completeAssignment() async {
    try {
      await EventService().completeAssignment(widget.eventId, widget.assignmentId);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi hoàn tất phiên: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignment = _assignment ?? const <String, dynamic>{};
    final presenter = assignment['presenterGroupName'] ??
        assignment['presenterStudentName'] ??
        'Chưa xác định';
    final reviewer = assignment['reviewerStudentName'] ?? 'Chưa xác định';
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
          onPressed: () => Navigator.pop(context, false),
        ),
        title: const Text(
          'Phòng review',
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
          : ListView(
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
                        presenter,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Phản biện: $reviewer'),
                      const SizedBox(height: 8),
                      Text('Trạng thái: ${assignment['status'] ?? ''}'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Minh chứng',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: _uploadRecording,
                      style: _outlineActionButtonStyle(),
                      child: const Text('Tải lên minh chứng/bản ghi'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (evidences.isEmpty)
                  const Text('Chưa có minh chứng nào')
                else
                  ...evidences.map(
                    (evidence) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(evidence['originalFileName'] ?? ''),
                      subtitle: Text(evidence['uploadedByName'] ?? ''),
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
                if (recording != null) ...[
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(recording['originalFileName'] ?? ''),
                    subtitle: const Text('Bản ghi hiện tại'),
                    trailing: IconButton(
                      onPressed: () async {
                        final url = recording['fileUrl']?.toString() ?? '';
                        if (url.isEmpty) return;
                        await launchUrl(
                          Uri.parse(url),
                          mode: LaunchMode.externalApplication,
                        );
                      },
                      icon: const Icon(Icons.play_circle_outline),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
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
                    ElevatedButton(
                      onPressed: _addLiveQuestion,
                      style: _primaryButtonStyle(),
                      child: const Text('Đặt câu hỏi'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (questions.isEmpty)
                  const Text('Chưa có câu hỏi nào')
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
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
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
                          ],
                        ],
                      ),
                    ),
                  ),
                if ((assignment['status']?.toString() ?? 'PENDING') != 'REVIEWED')
                  const SizedBox(height: 24),
                if ((assignment['status']?.toString() ?? 'PENDING') != 'REVIEWED')
                  ElevatedButton(
                  onPressed: _completeAssignment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Kết thúc phiên phản biện'),
                ),
              ],
            ),
    );
  }
}
