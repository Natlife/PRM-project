import 'package:flutter/material.dart';

import '../../services/activity_service.dart';
import '../../services/api_service.dart';

class CreateActivityScreen extends StatefulWidget {
  final int? classroomId;
  final List<String> classNames;
  final List<Map<String, dynamic>> availableClassrooms;

  const CreateActivityScreen({
    super.key,
    this.classroomId,
    this.classNames = const [],
    this.availableClassrooms = const [],
  });

  @override
  State<CreateActivityScreen> createState() => _CreateActivityScreenState();
}

class _CreateActivityScreenState extends State<CreateActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _deadlineController = TextEditingController();

  String? _selectedClass;
  String _selectedActivityType = 'PRE_CLASS';
  DateTime? _selectedDeadline;
  bool _publishImmediately = true;
  bool _isSubmitting = false;

  final List<Map<String, String>> _activityTypes = const [
    {'value': 'PRE_CLASS', 'label': 'Trước buổi học'},
    {'value': 'IN_CLASS', 'label': 'Trong buổi học'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.availableClassrooms.isNotEmpty) {
      _selectedClass = _classLabel(widget.availableClassrooms.first);
    } else if (widget.classNames.isNotEmpty) {
      _selectedClass = widget.classNames.first;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _deadlineController.dispose();
    super.dispose();
  }

  String _classLabel(Map<String, dynamic> classroom) {
    return classroom['className']?.toString() ??
        classroom['title']?.toString() ??
        classroom['code']?.toString() ??
        '';
  }

  int? _resolveClassroomId() {
    if (widget.classroomId != null) {
      return widget.classroomId;
    }
    if (_selectedClass == null) {
      return null;
    }

    for (final classroom in widget.availableClassrooms) {
      if (_classLabel(classroom) == _selectedClass) {
        final dynamic id = classroom['id'];
        if (id is int) {
          return id;
        }
        return int.tryParse(id?.toString() ?? '');
      }
    }
    return null;
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? tomorrow,
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
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _selectedDeadline = picked;
      _deadlineController.text =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) {
      return;
    }

    final classroomId = _resolveClassroomId();
    if (classroomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Khong xac dinh duoc lop hoc de tao activity.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final deadline = _selectedDeadline!;
      final dueAt =
          '${deadline.year}-${deadline.month.toString().padLeft(2, '0')}-${deadline.day.toString().padLeft(2, '0')}T23:59:59';

      final created = await ActivityService().createActivity(classroomId, {
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'activityType': _selectedActivityType,
        'dueAt': dueAt,
        'maxScore': 10,
      });

      Map<String, dynamic> finalActivity = created;
      if (_publishImmediately && created['id'] != null) {
        try {
          final activityId = (created['id'] as num).toInt();
          finalActivity = await ActivityService().updateActivity(
            activityId,
            {
              'status': 'PUBLISHED',
            },
          );
        } catch (e) {
          debugPrint('Error publishing activity right after create: $e');
        }
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop({
        'id': finalActivity['id'] ?? created['id'],
        'title': finalActivity['title'] ?? created['title'] ?? _titleController.text.trim(),
        'description': finalActivity['description'] ?? created['description'] ?? _descController.text.trim(),
        'date': _deadlineController.text,
        'dueAt': finalActivity['dueAt'] ?? created['dueAt'],
        'submissions': '0 nguoi nop',
        'activityType': finalActivity['activityType'] ?? created['activityType'] ?? _selectedActivityType,
        'status': finalActivity['status'] ?? created['status'] ?? 'DRAFT',
        'className': _selectedClass ?? '',
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Loi tao hoat dong: ${e is ApiException ? e.message : e.toString()}',
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
    final classOptions = widget.availableClassrooms.isNotEmpty
        ? widget.availableClassrooms.map(_classLabel).toList()
        : widget.classNames;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: Color(0xFF0F172A),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Tao hoat dong moi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lop hoc *',
                style: TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
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
                ),
                items: classOptions
                    .map(
                      (code) => DropdownMenuItem<String>(
                        value: code,
                        child: Text(code),
                      ),
                    )
                    .toList(),
                onChanged: widget.classroomId != null
                    ? null
                    : (value) => setState(() => _selectedClass = value),
              ),
              const SizedBox(height: 18),
              const Text(
                'Loai hoat dong *',
                style: TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
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
                    value: _selectedActivityType,
                    dropdownColor: const Color(0xFFFFFFFF),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Color(0xFF334155),
                    ),
                    isExpanded: true,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 15,
                    ),
                    items: _activityTypes
                        .map(
                          (type) => DropdownMenuItem<String>(
                            value: type['value'],
                            child: Text(type['label']!),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedActivityType = value);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Tieu de *',
                style: TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  hintText: 'Nhap tieu de hoat dong',
                  hintStyle: TextStyle(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.3),
                  ),
                  fillColor: const Color(0xFFFFFFFF),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Tieu de hoat dong la bat buoc';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              const Text(
                'Mo ta yeu cau *',
                style: TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                style: const TextStyle(color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  hintText: 'Nhap mo ta yeu cau...',
                  hintStyle: TextStyle(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.3),
                  ),
                  fillColor: const Color(0xFFFFFFFF),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Mo ta yeu cau la bat buoc';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              const Text(
                'Han nop *',
                style: TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _deadlineController,
                readOnly: true,
                onTap: () => _selectDate(context),
                style: const TextStyle(color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  hintText: 'Chon ngay han nop',
                  hintStyle: TextStyle(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.3),
                  ),
                  prefixIcon: const Icon(
                    Icons.calendar_today,
                    color: Color(0xFF334155),
                    size: 18,
                  ),
                  fillColor: const Color(0xFFFFFFFF),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Han nop la bat buoc';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _publishImmediately,
                activeColor: const Color(0xFF22C55E),
                title: const Text(
                  'Publish ngay cho hoc vien',
                  style: TextStyle(
                    color: Color(0xFF334155),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  'Tat de luu tam o DRAFT, bat de hien cho hoc vien ngay.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                onChanged: (value) {
                  setState(() => _publishImmediately = value);
                },
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
                        'Huy',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22C55E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
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
                              'Luu',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
