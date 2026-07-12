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
  static const Color _primaryColor = Color(0xFF22A06B);
  static const Color _primaryDarkColor = Color(0xFF167A52);
  static const Color _backgroundColor = Color(0xFFF5F7F6);
  static const Color _surfaceColor = Colors.white;
  static const Color _textPrimaryColor = Color(0xFF17211B);
  static const Color _textSecondaryColor = Color(0xFF66736B);
  static const Color _borderColor = Color(0xFFE2E8E4);
  static const Color _errorColor = Color(0xFFDC3D43);
  static const Color _inputBackgroundColor = Color(0xFFF9FBFA);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();

  final TextEditingController _descController = TextEditingController();

  final TextEditingController _deadlineController = TextEditingController();

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

    for (final Map<String, dynamic> classroom in widget.availableClassrooms) {
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
    final DateTime now = DateTime.now();

    final DateTime tomorrow = now.add(const Duration(days: 1));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? tomorrow,
      firstDate: tomorrow,
      lastDate: now.add(const Duration(days: 365)),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryColor,
              onPrimary: Colors.white,
              surface: _surfaceColor,
              onSurface: _textPrimaryColor,
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
          '${picked.day.toString().padLeft(2, '0')}/'
          '${picked.month.toString().padLeft(2, '0')}/'
          '${picked.year}';
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) {
      return;
    }

    final int? classroomId = _resolveClassroomId();

    if (classroomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không xác định được lớp học để tạo hoạt động.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _errorColor,
        ),
      );

      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final DateTime deadline = _selectedDeadline!;

      final String dueAt =
          '${deadline.year}-'
          '${deadline.month.toString().padLeft(2, '0')}-'
          '${deadline.day.toString().padLeft(2, '0')}'
          'T23:59:59';

      final Map<String, dynamic> created = await ActivityService()
          .createActivity(classroomId, {
            'title': _titleController.text.trim(),
            'description': _descController.text.trim(),
            'activityType': _selectedActivityType,
            'dueAt': dueAt,
            'maxScore': 10,
          });

      Map<String, dynamic> finalActivity = created;

      if (_publishImmediately && created['id'] != null) {
        try {
          final int activityId = (created['id'] as num).toInt();

          finalActivity = await ActivityService().updateActivity(activityId, {
            'status': 'PUBLISHED',
          });
        } catch (error) {
          debugPrint(
            'Error publishing activity right after create: '
            '$error',
          );
        }
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop({
        'id': finalActivity['id'] ?? created['id'],
        'title':
            finalActivity['title'] ??
            created['title'] ??
            _titleController.text.trim(),
        'description':
            finalActivity['description'] ??
            created['description'] ??
            _descController.text.trim(),
        'date': _deadlineController.text,
        'dueAt': finalActivity['dueAt'] ?? created['dueAt'],
        'submissions': '0 nguoi nop',
        'activityType':
            finalActivity['activityType'] ??
            created['activityType'] ??
            _selectedActivityType,
        'status': finalActivity['status'] ?? created['status'] ?? 'DRAFT',
        'className': _selectedClass ?? '',
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lỗi tạo hoạt động: '
            '${error is ApiException ? error.message : error.toString()}',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _surfaceColor,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      shadowColor: _borderColor,
      automaticallyImplyLeading: false,
      leading: IconButton(
        tooltip: 'Quay lại',
        onPressed: () {
          Navigator.of(context).pop();
        },
        icon: const Icon(Icons.arrow_back_rounded, color: _textPrimaryColor),
      ),
      titleSpacing: 0,
      title: const Text(
        'Tạo hoạt động mới',
        style: TextStyle(
          color: _textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: _textPrimaryColor.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7F0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.add_task_rounded,
              color: _primaryDarkColor,
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thông tin hoạt động',
                  style: TextStyle(
                    color: _textPrimaryColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Nhập đầy đủ thông tin để tạo hoạt động '
                  'mới cho lớp học.',
                  style: TextStyle(
                    color: _textSecondaryColor,
                    fontSize: 12,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildFieldLabel(String label, {bool required = false}) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _textPrimaryColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (required)
          const Text(
            ' *',
            style: TextStyle(
              color: _errorColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Color(0xFF9AA49E),
        fontSize: 13,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: prefixIcon == null
          ? null
          : Icon(prefixIcon, color: _textSecondaryColor, size: 20),
      filled: true,
      fillColor: _inputBackgroundColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _borderColor),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _errorColor, width: 1.5),
      ),
    );
  }

  Widget _buildClassField(List<String> classOptions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Lớp học', required: true),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedClass,
          isExpanded: true,
          dropdownColor: _surfaceColor,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: _textSecondaryColor,
          ),
          style: const TextStyle(
            color: _textPrimaryColor,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
          decoration: _buildInputDecoration(
            hintText: 'Chọn lớp học',
            prefixIcon: Icons.school_outlined,
          ),
          items: classOptions.map((String className) {
            return DropdownMenuItem<String>(
              value: className,
              child: Text(
                className,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: widget.classroomId != null
              ? null
              : (String? value) {
                  setState(() {
                    _selectedClass = value;
                  });
                },
        ),
      ],
    );
  }

  Widget _buildActivityTypeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Loại hoạt động', required: true),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedActivityType,
          isExpanded: true,
          dropdownColor: _surfaceColor,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: _textSecondaryColor,
          ),
          style: const TextStyle(
            color: _textPrimaryColor,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
          decoration: _buildInputDecoration(
            hintText: 'Chọn loại hoạt động',
            prefixIcon: Icons.category_outlined,
          ),
          items: _activityTypes.map((Map<String, String> type) {
            return DropdownMenuItem<String>(
              value: type['value'],
              child: Text(type['label']!),
            );
          }).toList(),
          onChanged: (String? value) {
            if (value != null) {
              setState(() {
                _selectedActivityType = value;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Tiêu đề', required: true),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          textInputAction: TextInputAction.next,
          style: const TextStyle(
            color: _textPrimaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: _buildInputDecoration(
            hintText: 'Nhập tiêu đề hoạt động',
            prefixIcon: Icons.title_rounded,
          ),
          validator: (String? value) {
            if (value == null || value.trim().isEmpty) {
              return 'Tiêu đề hoạt động là bắt buộc';
            }

            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Mô tả yêu cầu', required: true),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descController,
          minLines: 4,
          maxLines: 4,
          style: const TextStyle(
            color: _textPrimaryColor,
            fontSize: 13.5,
            height: 1.5,
          ),
          decoration: _buildInputDecoration(hintText: 'Nhập mô tả yêu cầu...'),
          validator: (String? value) {
            if (value == null || value.trim().isEmpty) {
              return 'Mô tả yêu cầu là bắt buộc';
            }

            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDeadlineField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Hạn nộp', required: true),
        const SizedBox(height: 8),
        TextFormField(
          controller: _deadlineController,
          readOnly: true,
          onTap: () {
            _selectDate(context);
          },
          style: const TextStyle(
            color: _textPrimaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration:
              _buildInputDecoration(
                hintText: 'Chọn ngày hạn nộp',
                prefixIcon: Icons.calendar_today_outlined,
              ).copyWith(
                suffixIcon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _textSecondaryColor,
                ),
              ),
          validator: (String? value) {
            if (value == null || value.isEmpty) {
              return 'Hạn nộp là bắt buộc';
            }

            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPublishOption() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _inputBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: SwitchListTile(
        value: _publishImmediately,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        activeColor: _primaryColor,
        title: const Text(
          'Publish ngay cho học viên',
          style: TextStyle(
            color: _textPrimaryColor,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text(
            'Tắt để lưu tạm ở DRAFT, bật để hiển thị '
            'cho học viên ngay.',
            style: TextStyle(
              color: _textSecondaryColor,
              fontSize: 11.5,
              height: 1.4,
            ),
          ),
        ),
        onChanged: (bool value) {
          setState(() {
            _publishImmediately = value;
          });
        },
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isSubmitting
                ? null
                : () {
                    Navigator.of(context).pop();
                  },
            style: OutlinedButton.styleFrom(
              foregroundColor: _textSecondaryColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: _borderColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Hủy',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _primaryColor.withOpacity(0.65),
              disabledForegroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Lưu hoạt động',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> classOptions = widget.availableClassrooms.isNotEmpty
        ? widget.availableClassrooms.map(_classLabel).toList()
        : widget.classNames;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 36),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderCard(),
                    const SizedBox(height: 14),
                    _buildFormSection(
                      children: [
                        _buildClassField(classOptions),
                        const SizedBox(height: 18),
                        _buildActivityTypeField(),
                        const SizedBox(height: 18),
                        _buildTitleField(),
                        const SizedBox(height: 18),
                        _buildDescriptionField(),
                        const SizedBox(height: 18),
                        _buildDeadlineField(),
                        const SizedBox(height: 18),
                        _buildPublishOption(),
                      ],
                    ),
                    const SizedBox(height: 22),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
