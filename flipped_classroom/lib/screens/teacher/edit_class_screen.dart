import 'dart:math';
import 'package:flutter/material.dart';

class EditClassScreen extends StatefulWidget {
  final String className;
  final String classCode;
  final String semester;
  final String description;
  final List<String> schedules;

  const EditClassScreen({
    super.key,
    required this.className,
    required this.classCode,
    required this.semester,
    required this.description,
    required this.schedules,
  });

  @override
  State<EditClassScreen> createState() => _EditClassScreenState();
}

class _EditClassScreenState extends State<EditClassScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _subjectController;
  
  late String _selectedSemester;
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

  late List<Map<String, String>> _schedulesList;

  @override
  void initState() {
    super.initState();
    
    // Parse subject name and class name
    // className format: e.g. "PRM - Lập trình mobile" -> subject shorthand is "PRM" or title is "PRM - Lập trình mobile"
    // classCode format: e.g. "PRM393 - SE1904" -> class name is "SE1904", code unique part is "PRM393"
    
    String subjectVal = widget.className;
    if (widget.className.contains(' - ')) {
      subjectVal = widget.className.split(' - ').first;
    }
    
    String classNameVal = widget.classCode;
    String codeVal = widget.classCode;
    if (widget.classCode.contains(' - ')) {
      final parts = widget.classCode.split(' - ');
      classNameVal = parts.last;
      codeVal = parts.first;
    }

    _nameController = TextEditingController(text: classNameVal);
    _descController = TextEditingController(text: widget.description);
    _subjectController = TextEditingController(text: subjectVal);
    _selectedSemester = _semesters.contains(widget.semester) ? widget.semester : 'SU26';
    _classCode = codeVal.toLowerCase();

    _schedulesList = widget.schedules.map((s) {
      if (s.contains(': ')) {
        final pts = s.split(': ');
        return {'day': pts.first, 'slot': pts.last};
      }
      return {'day': 'Thứ 2', 'slot': s};
    }).toList();
  }

  String _generateRandomCode() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random();
    return List.generate(6, (index) => chars[rand.nextInt(chars.length)]).join();
  }

  void _addSchedule() {
    final exists = _schedulesList.any(
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
      _schedulesList.add({
        'day': _selectedDay,
        'slot': _selectedSlot,
      });
    });
  }

  void _removeSchedule(int index) {
    setState(() {
      _schedulesList.removeAt(index);
    });
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;
    if (_schedulesList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng thêm ít nhất một ngày và slot học!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final updatedClass = {
      'title': _subjectController.text.trim().contains(' - ') 
          ? _subjectController.text.trim()
          : '${_subjectController.text.trim()} - Lớp học',
      'code': '${_classCode.toUpperCase()} - ${_nameController.text.trim()}',
      'semester': _selectedSemester,
      'description': _descController.text.trim(),
      'schedules': _schedulesList.map((s) => '${s['day']}: ${s['slot']}').toList(),
    };

    Navigator.of(context).pop(updatedClass);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Chỉnh sửa lớp học',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
                style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Nhập tên lớp học (Ví dụ: SE1904)',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                  fillColor: const Color(0xFF1E293B),
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
                style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                maxLines: 2,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Mô tả lớp học',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                  fillColor: const Color(0xFF1E293B),
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
                style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedSemester,
                    dropdownColor: const Color(0xFF1E293B),
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
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
                    style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton(
                    onPressed: _addSchedule,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5A57FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('Thêm', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedDay,
                    dropdownColor: const Color(0xFF1E293B),
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
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
                style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedSlot,
                    dropdownColor: const Color(0xFF1E293B),
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
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

              if (_schedulesList.isNotEmpty) ...[
                const Text(
                  'Lịch đã chọn:',
                  style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                ...List.generate(_schedulesList.length, (index) {
                  final s = _schedulesList[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${s['day']} - ${s['slot']}',
                          style: const TextStyle(color: Colors.white, fontSize: 13),
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
                style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _subjectController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Nhập tên môn học (Ví dụ: Lập trình Mobile)',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                  fillColor: const Color(0xFF1E293B),
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
                style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _classCode.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Color(0xFF5A57FF), size: 20),
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
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5A57FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Lưu',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
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
