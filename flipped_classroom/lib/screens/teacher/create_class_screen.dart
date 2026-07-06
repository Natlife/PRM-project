import 'dart:math';
import 'package:flutter/material.dart';

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
  
  late String _classCode;
  
  final List<String> _semesters = ['SU26', 'FA26', 'SP26', 'HK1 2026'];
  final List<String> _days = [
    'Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'Chủ nhật'
  ];
  final List<String> _slots = [
    'Slot 1 (7:30-9:50)',
    'Slot 2 (10:00-12:20)',
    'Slot 3 (12:50-15:10)',
    'Slot 4 (15:20-17:40)',
    'Slot 5 (18:00-20:20)'
  ];

  final List<Map<String, String>> _schedules = [];

  @override
  void initState() {
    super.initState();
    _classCode = _generateRandomCode();
  }

  String _generateRandomCode() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random();
    return List.generate(6, (index) => chars[rand.nextInt(chars.length)]).join();
  }

  void _addSchedule() {
    final exists = _schedules.any(
      (s) => s['day'] == _selectedDay && s['slot'] == _selectedSlot
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
    setState(() {
      _schedules.add({
        'day': _selectedDay,
        'slot': _selectedSlot,
      });
    });
  }

  void _removeSchedule(int index) {
    setState(() {
      _schedules.removeAt(index);
    });
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;
    if (_schedules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng thêm ít nhất một ngày và slot học!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final newClass = {
      'title': _subjectController.text.trim(),
      'code': '${_nameController.text.trim()} - ${_classCode.toUpperCase()}',
      'description': _descController.text.trim(),
      'studentsCount': 0,
      'semester': _selectedSemester,
      'type': 'Chuyên ngành',
      'schedules': _schedules.map((s) => '${s['day']}: ${s['slot']}').toList(),
    };

    Navigator.of(context).pop(newClass);
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
                        value: slot,
                        child: Text(slot),
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
                          '${s['day']} - ${s['slot']}',
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
                      _classCode,
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
                          _classCode = _generateRandomCode();
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEC4899),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Hủy',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7EC07E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
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
