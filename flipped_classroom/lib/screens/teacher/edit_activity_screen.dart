import 'package:flutter/material.dart';

class EditActivityScreen extends StatefulWidget {
  final String activityTitle;
  final String description;
  final String deadline;
  final String currentStatus;

  const EditActivityScreen({
    super.key,
    required this.activityTitle,
    required this.description,
    required this.deadline,
    required this.currentStatus,
  });

  @override
  State<EditActivityScreen> createState() => _EditActivityScreenState();
}

class _EditActivityScreenState extends State<EditActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _deadlineController;
  late String _selectedStatus;

  final List<Map<String, String>> _statusOptions = const [
    {'value': 'DRAFT', 'label': 'Draft'},
    {'value': 'PUBLISHED', 'label': 'Published'},
    {'value': 'CLOSED', 'label': 'Closed'},
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.activityTitle);
    _descController = TextEditingController(text: widget.description);
    _deadlineController = TextEditingController(text: widget.deadline);
    _selectedStatus = widget.currentStatus.isNotEmpty ? widget.currentStatus : 'DRAFT';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime tomorrow = now.add(const Duration(days: 1));
    
    DateTime initial = tomorrow;
    try {
      final sourceDeadline = _deadlineController.text;
      if (sourceDeadline.contains('/')) {
        final parts = sourceDeadline.split('/');
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        final parsed = DateTime(year, month, day);
        if (parsed.isAfter(now)) {
          initial = parsed;
        }
      }
    } catch (_) {}

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: tomorrow,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF7EC07E),
              onPrimary: Colors.white,
              surface: Color(0xFFFFFFFF),
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _deadlineController.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    final updatedActivity = {
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
      'deadline': _deadlineController.text,
      'status': _selectedStatus,
    };

    Navigator.of(context).pop(updatedActivity);
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
          'Chỉnh sửa hoạt động',
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
                'Tiêu đề *',
                style: TextStyle(color: Color(0xFF334155), fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  hintText: 'Nhập tiêu đề hoạt động',
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
                    return 'Tiêu đề hoạt động là bắt buộc';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              const Text(
                'Mô tả yêu cầu',
                style: TextStyle(color: Color(0xFF334155), fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                style: const TextStyle(color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  hintText: 'Nhập mô tả yêu cầu...',
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
                'Hạn nộp *',
                style: TextStyle(color: Color(0xFF334155), fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _deadlineController,
                readOnly: true,
                onTap: () => _selectDate(context),
                style: const TextStyle(color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  hintText: 'Chọn ngày hạn nộp',
                  hintStyle: TextStyle(color: const Color(0xFF0F172A).withValues(alpha: 0.3)),
                  prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF334155), size: 18),
                  fillColor: const Color(0xFFFFFFFF),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Hạn nộp là bắt buộc';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              const Text(
                'Trang thai *',
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
                    value: _selectedStatus,
                    dropdownColor: const Color(0xFFFFFFFF),
                    isExpanded: true,
                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 15),
                    items: _statusOptions
                        .map(
                          (status) => DropdownMenuItem<String>(
                            value: status['value'],
                            child: Text(status['label']!),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedStatus = value);
                      }
                    },
                  ),
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
                        backgroundColor: const Color(0xFF22C55E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Lưu',
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
