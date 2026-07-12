import 'dart:math';
import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/classroom_service.dart';

class CreateClassScreen extends StatefulWidget {
  const CreateClassScreen({super.key});

  @override
  State<CreateClassScreen> createState() => _CreateClassScreenState();
}

class _CreateClassScreenState extends State<CreateClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _subjectController = TextEditingController();

  String _selectedSemester = 'SU26';
  String _selectedDay = 'Thứ 2';
  String _selectedSlot = 'Slot 1 (7:30-9:50)';
  bool _isSubmitting = false;

  late String _classCodeSuffix;

  final List<String> _semesters = ['SU26', 'FA26', 'SP26', 'HK1 2026'];
  final List<String> _days = [
    'Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'Chủ nhật'
  ];
  final List<Map<String, String>> _slots = const [
    {
      'label': 'Slot 1 (7:30-9:50)',
      'startTime': '07:30:00',
      'endTime': '09:50:00',
    },
    {
      'label': 'Slot 2 (10:00-12:20)',
      'startTime': '10:00:00',
      'endTime': '12:20:00',
    },
    {
      'label': 'Slot 3 (12:50-15:10)',
      'startTime': '12:50:00',
      'endTime': '15:10:00',
    },
    {
      'label': 'Slot 4 (15:20-17:40)',
      'startTime': '15:20:00',
      'endTime': '17:40:00',
    },
    {
      'label': 'Slot 5 (18:00-20:20)',
      'startTime': '18:00:00',
      'endTime': '20:20:00',
    },
  ];

  final List<Map<String, dynamic>> _schedules = [];

  @override
  void initState() {
    super.initState();
    _classCodeSuffix = _generateRandomCode();
  }

  String _generateRandomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return List.generate(6, (index) => chars[rand.nextInt(chars.length)]).join();
  }

  String _sanitizeClassToken(String value) {
    final cleaned = value
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]+'), '-')
        .replaceAll(RegExp(r'-{2,}'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return cleaned;
  }

  String _buildBackendClassCode() {
    final base = _sanitizeClassToken(_nameController.text);
    if (base.isEmpty) {
      return 'CLASS-$_classCodeSuffix';
    }
    return '$base-$_classCodeSuffix';
  }

  Map<String, String> _slotConfig(String slotLabel) {
    return _slots.firstWhere(
      (slot) => slot['label'] == slotLabel,
      orElse: () => _slots.first,
    );
  }

  String _buildDescription() {
    final subject = _subjectController.text.trim();
    final description = _descController.text.trim();
    if (subject.isEmpty) {
      return description;
    }
    if (description.isEmpty) {
      return 'Môn học: $subject';
    }
    return 'Môn học: $subject\n\n$description';
  }

  ButtonStyle _primaryButtonStyle(Color backgroundColor) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    );
  }

  void _addSchedule() {
    final exists = _schedules.any(
      (s) => s['day'] == _selectedDay && s['slotLabel'] == _selectedSlot
    );
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lịch học này đã được thêm!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final slot = _slotConfig(_selectedSlot);
    setState(() {
      _schedules.add({
        'day': _selectedDay,
        'dayOfWeek': _days.indexOf(_selectedDay),
        'slotLabel': _selectedSlot,
        'startTime': slot['startTime'],
        'endTime': slot['endTime'],
        'roomName': '',
      });
    });
  }

  void _removeSchedule(int index) {
    setState(() {
      _schedules.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;
    if (_schedules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng thêm ít nhất một ngày và slot học!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final created = await ClassroomService().createClassroom(
        code: _buildBackendClassCode(),
        name: _nameController.text.trim(),
        description: _buildDescription(),
        semesterCode: _selectedSemester,
        schedules: _schedules
            .map(
              (schedule) => {
                'dayOfWeek': schedule['dayOfWeek'],
                'slotLabel': schedule['slotLabel'],
                'startTime': schedule['startTime'],
                'endTime': schedule['endTime'],
                'roomName': schedule['roomName'],
              },
            )
            .toList(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tạo lớp học thành công!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF22C55E),
        ),
      );
      Navigator.of(context).pop(created);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lỗi tạo lớp học: ${e is ApiException ? e.message : e.toString()}',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Tạo lớp học',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tên lớp học *',
                style: TextStyle(color: Color(0xFF334155), fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  hintText: 'Nhập tên lớp học (Ví dụ: SE1904)',
                  hintStyle: TextStyle(color: const Color(0xFF0F172A).withValues(alpha: 0.3)),
                  fillColor: const Color(0xFFFFFFFF),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Tên lớp học là bắt buộc';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              const Text(
                'Mô tả',
                style: TextStyle(color: Color(0xFF334155), fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                maxLines: 2,
                style: const TextStyle(color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  hintText: 'Mô tả lớp học',
                  hintStyle: TextStyle(color: const Color(0xFF0F172A).withValues(alpha: 0.3)),
                  fillColor: const Color(0xFFFFFFFF),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              const Text(
                'Kỳ học *',
                style: TextStyle(color: Color(0xFF334155), fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedSemester,
                    dropdownColor: const Color(0xFFFFFFFF),
                    icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF334155)),
                    isExpanded: true,
                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 15),
                    items: _semesters.map((sem) {
                      return DropdownMenuItem(
                        value: sem,
                        child: Text(sem),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedSemester = val);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 18),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ngày học *',
                    style: TextStyle(color: Color(0xFF334155), fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton(
                    onPressed: _addSchedule,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7EC07E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('Thêm', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedDay,
                    dropdownColor: const Color(0xFFFFFFFF),
                    icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF334155)),
                    isExpanded: true,
                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 15),
                    items: _days.map((day) {
                      return DropdownMenuItem(
                        value: day,
                        child: Text(day),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedDay = val);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 18),

              const Text(
                'Slot học *',
                style: TextStyle(color: Color(0xFF334155), fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedSlot,
                    dropdownColor: const Color(0xFFFFFFFF),
                    icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF334155)),
                    isExpanded: true,
                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 15),
                    items: _slots.map((slot) {
                      return DropdownMenuItem(
                        value: slot['label'],
                        child: Text(slot['label']!),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedSlot = val);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),

              if (_schedules.isNotEmpty) ...[
                const Text(
                  'Lịch đã chọn:',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                ...List.generate(_schedules.length, (index) {
                  final s = _schedules[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${s['day']} - ${s['slotLabel']}',
                          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                        ),
                        GestureDetector(
                          onTap: () => _removeSchedule(index),
                          child: const Icon(Icons.close, color: Colors.redAccent, size: 16),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              const SizedBox(height: 18),

              const Text(
                'Môn học *',
                style: TextStyle(color: Color(0xFF334155), fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _subjectController,
                style: const TextStyle(color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  hintText: 'Nhập tên môn học (Ví dụ: Lập trình Mobile)',
                  hintStyle: TextStyle(color: const Color(0xFF0F172A).withValues(alpha: 0.3)),
                  fillColor: const Color(0xFFFFFFFF),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Môn học là bắt buộc';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 22),

              const Text(
                'Mã lớp học',
                style: TextStyle(color: Color(0xFF334155), fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF0F172A).withValues(alpha: 0.08)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _buildBackendClassCode(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                        letterSpacing: 2,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Color(0xFF7EC07E), size: 20),
                      onPressed: () {
                        setState(() {
                          _classCodeSuffix = _generateRandomCode();
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: _primaryButtonStyle(const Color(0xFFEC4899)),
                      child: const Text(
                        'Hủy',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitForm,
                      style: _primaryButtonStyle(const Color(0xFF7EC07E)),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Tạo lớp',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
