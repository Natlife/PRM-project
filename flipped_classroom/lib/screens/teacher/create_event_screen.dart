import 'package:flutter/material.dart';

class CreateEventScreen extends StatefulWidget {
  final List<String> classNames;

  const CreateEventScreen({
    super.key,
    required this.classNames,
  });

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedClass;
  final _eventNameController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _durationController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.classNames.isNotEmpty) {
      _selectedClass = widget.classNames.first;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime tomorrow = now.add(const Duration(days: 1));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: tomorrow,
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
        _startTimeController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    final newEvent = {
      'title': _eventNameController.text.trim(),
      'classCode': _selectedClass,
      'date': _startTimeController.text,
      'duration': _durationController.text.trim(),
      'description': _descController.text.trim(),
      'status': 'Chưa diễn ra',
    };

    Navigator.of(context).pop(newEvent);
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
          'Tạo sự kiện mới',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event Name
                const Text(
                  'Tên sự kiện *',
                  style: TextStyle(color: Color(0xFF334155), fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _eventNameController,
                  style: const TextStyle(color: Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    hintText: 'Ví dụ: review lần 1,...',
                    hintStyle: TextStyle(color: const Color(0xFF0F172A).withValues(alpha: 0.3)),
                    fillColor: const Color(0xFFFFFFFF),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF7EC07E), width: 1.5),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Tên sự kiện là bắt buộc';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Start Time
                const Text(
                  'Thời gian bắt đầu *',
                  style: TextStyle(color: Color(0xFF334155), fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _startTimeController,
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  style: const TextStyle(color: Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    hintText: 'dd/mm/yyyy',
                    hintStyle: TextStyle(color: const Color(0xFF0F172A).withValues(alpha: 0.3)),
                    suffixIcon: const Icon(Icons.calendar_today, color: Color(0xFF334155), size: 18),
                    fillColor: const Color(0xFFFFFFFF),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF7EC07E), width: 1.5),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Thời gian bắt đầu là bắt buộc';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Choose Class
                const Text(
                  'Chọn lớp *',
                  style: TextStyle(color: Color(0xFF334155), fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedClass,
                  dropdownColor: const Color(0xFFFFFFFF),
                  style: const TextStyle(color: Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    fillColor: const Color(0xFFFFFFFF),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF7EC07E), width: 1.5),
                    ),
                  ),
                  items: widget.classNames.map((code) {
                    return DropdownMenuItem<String>(
                      value: code,
                      child: Text(code),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedClass = val),
                  validator: (val) {
                    if (val == null) {
                      return 'Vui lòng chọn lớp học';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Duration per session
                const Text(
                  'Thời lượng mỗi phiên (phút) *',
                  style: TextStyle(color: Color(0xFF334155), fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    hintText: 'Ví dụ: 15, 30,...',
                    hintStyle: TextStyle(color: const Color(0xFF0F172A).withValues(alpha: 0.3)),
                    fillColor: const Color(0xFFFFFFFF),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF7EC07E), width: 1.5),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Thời lượng mỗi phiên là bắt buộc';
                    }
                    if (int.tryParse(val.trim()) == null) {
                      return 'Vui lòng nhập một số hợp lệ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Description
                const Text(
                  'Mô tả',
                  style: TextStyle(color: Color(0xFF334155), fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descController,
                  maxLines: 4,
                  style: const TextStyle(color: Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    hintText: 'Nhập mô tả sự kiện...',
                    hintStyle: TextStyle(color: const Color(0xFF0F172A).withValues(alpha: 0.3)),
                    fillColor: const Color(0xFFFFFFFF),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF7EC07E), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9E2C2C), // Burgundy/Red accent for Cancel
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
                          backgroundColor: const Color(0xFF7EC07E), // Green accent for Save
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
      ),
    );
  }
}
