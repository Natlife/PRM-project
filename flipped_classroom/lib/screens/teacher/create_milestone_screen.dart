import 'package:flutter/material.dart';

class CreateMilestoneScreen extends StatefulWidget {
  const CreateMilestoneScreen({super.key});

  @override
  State<CreateMilestoneScreen> createState() => _CreateMilestoneScreenState();
}

class _CreateMilestoneScreenState extends State<CreateMilestoneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _deadlineController = TextEditingController();
  final _activityInputController = TextEditingController();
  
  String _selectedStatus = 'Chưa bắt đầu';
  final List<Map<String, dynamic>> _activitiesList = [];

  @override
  void dispose() {
    _titleController.dispose();
    _deadlineController.dispose();
    _activityInputController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF5A57FF),
              onPrimary: Colors.white,
              surface: Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _deadlineController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  void _addActivity() {
    final text = _activityInputController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _activitiesList.add({
        'title': text,
        'status': 'Chưa bắt đầu',
      });
      _activityInputController.clear();
    });
  }

  void _removeActivity(int index) {
    setState(() {
      _activitiesList.removeAt(index);
    });
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;
    
    Navigator.of(context).pop({
      'title': _titleController.text.trim(),
      'date': _deadlineController.text,
      'status': _selectedStatus,
      'activities': _activitiesList,
      'comments': <Map<String, String>>[],
      'evidences': <Map<String, String>>[],
    });
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
          'Tạo mốc thời gian',
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
                'Tên mốc',
                style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Nhập tên mốc thời gian (ví dụ: Thiết kế UI)',
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
                    return 'Tên mốc là bắt buộc';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              const Text(
                'Hạn hoàn thành',
                style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _deadlineController,
                readOnly: true,
                onTap: () => _selectDate(context),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Chọn ngày hạn hoàn thành',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                  prefixIcon: const Icon(Icons.calendar_today, color: Colors.white70, size: 18),
                  fillColor: const Color(0xFF1E293B),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Hạn hoàn thành là bắt buộc';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              const Text(
                'Trạng thái',
                style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  fillColor: const Color(0xFF1E293B),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'Chưa bắt đầu', child: Text('Chưa bắt đầu')),
                  DropdownMenuItem(value: 'Đang thực hiện', child: Text('Đang thực hiện')),
                  DropdownMenuItem(value: 'Hoàn thành', child: Text('Hoàn thành')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedStatus = val);
                  }
                },
              ),
              const SizedBox(height: 18),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Hoạt động',
                    style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: _addActivity,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E8EFF),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.add, size: 14, color: Colors.white),
                    label: const Text(
                      'Thêm',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _activityInputController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Nhập hoạt động trong milestone này',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                  fillColor: const Color(0xFF1E293B),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onFieldSubmitted: (v) => _addActivity(),
              ),
              const SizedBox(height: 12),

              if (_activitiesList.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _activitiesList.length,
                    itemBuilder: (context, index) {
                      final act = _activitiesList[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                act['title'],
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFEC4899), size: 20),
                              onPressed: () => _removeActivity(index),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],

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
                        backgroundColor: const Color(0xFF22C55E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Tạo mới',
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
