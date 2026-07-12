import 'package:flutter/material.dart';

class CreateEventScreen extends StatefulWidget {
  final List<Map<String, dynamic>> classrooms;

  const CreateEventScreen({
    super.key,
    required this.classrooms,
  });

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _sessionDurationController = TextEditingController(text: '20');

  int? _selectedClassroomId;
  DateTime? _selectedStartAt;
  DateTime? _selectedEndAt;

  @override
  void initState() {
    super.initState();
    if (widget.classrooms.isNotEmpty) {
      _selectedClassroomId = (widget.classrooms.first['id'] as num?)?.toInt();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _sessionDurationController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart
        ? (_selectedStartAt ?? now.add(const Duration(days: 1)))
        : (_selectedEndAt ?? (_selectedStartAt ?? now).add(const Duration(hours: 2)));

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;

    final picked = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      if (isStart) {
        _selectedStartAt = picked;
        if (_selectedEndAt == null || !_selectedEndAt!.isAfter(picked)) {
          _selectedEndAt = picked.add(const Duration(hours: 2));
        }
      } else {
        _selectedEndAt = picked;
      }
    });
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return 'Chọn thời gian';
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} '
        '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClassroomId == null || _selectedStartAt == null || _selectedEndAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn lớp học và thời gian đầy đủ'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (!_selectedEndAt!.isAfter(_selectedStartAt!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thời gian kết thúc phải sau thời gian bắt đầu'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    Navigator.pop<Map<String, dynamic>>(context, {
      'classroomId': _selectedClassroomId,
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'startAt': _selectedStartAt!.toIso8601String(),
      'endAt': _selectedEndAt!.toIso8601String(),
      'sessionDurationMinutes': int.tryParse(_sessionDurationController.text.trim()) ?? 20,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tạo sự kiện mới',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            DropdownButtonFormField<int>(
              initialValue: _selectedClassroomId,
              decoration: const InputDecoration(labelText: 'Lớp học'),
              items: widget.classrooms
                  .map(
                    (classroom) => DropdownMenuItem<int>(
                      value: (classroom['id'] as num?)?.toInt(),
                      child: Text(
                        classroom['code']?.toString() ??
                            classroom['className']?.toString() ??
                            '',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedClassroomId = value),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Tên sự kiện'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Tên sự kiện là bắt buộc';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Mô tả'),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Bắt đầu'),
              subtitle: Text(_formatDateTime(_selectedStartAt)),
              trailing: const Icon(Icons.calendar_month),
              onTap: () => _pickDateTime(isStart: true),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Kết thúc'),
              subtitle: Text(_formatDateTime(_selectedEndAt)),
              trailing: const Icon(Icons.schedule),
              onTap: () => _pickDateTime(isStart: false),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sessionDurationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Thời lượng mỗi phiên (phút)',
              ),
              validator: (value) {
                final minutes = int.tryParse(value?.trim() ?? '');
                if (minutes == null || minutes <= 0) {
                  return 'Nhập thời lượng hợp lệ';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('Tạo sự kiện'),
            ),
          ],
        ),
      ),
    );
  }
}
