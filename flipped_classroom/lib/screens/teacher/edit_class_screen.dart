import 'package:flutter/material.dart';

class EditClassScreen extends StatefulWidget {
  final String className;
  final String classCode;
  final String semester;
  final String description;
  final List<Map<String, dynamic>> schedules;

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
  final _semesters = const ['SU26', 'FA26', 'SP26', 'HK1 2026'];
  final _dayLabels = const [
    'Thu 2',
    'Thu 3',
    'Thu 4',
    'Thu 5',
    'Thu 6',
    'Thu 7',
    'Chu nhat',
  ];
  final _slots = const [
    {
      'slotLabel': 'Slot 1',
      'display': 'Slot 1 (7:30-9:50)',
      'startTime': '07:30:00',
      'endTime': '09:50:00',
    },
    {
      'slotLabel': 'Slot 2',
      'display': 'Slot 2 (10:00-12:20)',
      'startTime': '10:00:00',
      'endTime': '12:20:00',
    },
    {
      'slotLabel': 'Slot 3',
      'display': 'Slot 3 (12:50-15:10)',
      'startTime': '12:50:00',
      'endTime': '15:10:00',
    },
    {
      'slotLabel': 'Slot 4',
      'display': 'Slot 4 (15:20-17:40)',
      'startTime': '15:20:00',
      'endTime': '17:40:00',
    },
    {
      'slotLabel': 'Slot 5',
      'display': 'Slot 5 (18:00-20:20)',
      'startTime': '18:00:00',
      'endTime': '20:20:00',
    },
  ];

  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late String _selectedSemester;
  late String _selectedDay;
  late String _selectedSlot;
  late List<Map<String, dynamic>> _schedulesList;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.className);
    _descController = TextEditingController(text: widget.description);
    _selectedSemester = _semesters.contains(widget.semester)
        ? widget.semester
        : _semesters.first;
    _selectedDay = _dayLabels.first;
    _selectedSlot = _slots.first['display']!;
    _schedulesList = widget.schedules.map(_normalizeSchedule).toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _normalizeSchedule(Map<String, dynamic> raw) {
    final dayOfWeek = raw['dayOfWeek'] as int? ?? 0;
    final slotLabel = raw['slotLabel']?.toString() ?? 'Slot 1';
    final startTime = raw['startTime']?.toString() ?? '07:30:00';
    final endTime = raw['endTime']?.toString() ?? '09:50:00';
    final display = _slots.firstWhere(
      (slot) => slot['slotLabel'] == slotLabel,
      orElse: () => _slots.first,
    )['display']!;

    return {
      'dayOfWeek': dayOfWeek,
      'slotLabel': slotLabel,
      'startTime': startTime,
      'endTime': endTime,
      'displayDay': dayOfWeek >= 0 && dayOfWeek < _dayLabels.length
          ? _dayLabels[dayOfWeek]
          : _dayLabels.first,
      'displaySlot': display,
    };
  }

  Map<String, dynamic> _buildScheduleRequest(String dayLabel, String slotDisplay) {
    final dayOfWeek = _dayLabels.indexOf(dayLabel);
    final slot = _slots.firstWhere(
      (item) => item['display'] == slotDisplay,
      orElse: () => _slots.first,
    );

    return {
      'dayOfWeek': dayOfWeek < 0 ? 0 : dayOfWeek,
      'slotLabel': slot['slotLabel'],
      'startTime': slot['startTime'],
      'endTime': slot['endTime'],
      'displayDay': dayLabel,
      'displaySlot': slotDisplay,
    };
  }

  void _addSchedule() {
    final newSchedule = _buildScheduleRequest(_selectedDay, _selectedSlot);
    final exists = _schedulesList.any(
      (schedule) =>
          schedule['dayOfWeek'] == newSchedule['dayOfWeek'] &&
          schedule['slotLabel'] == newSchedule['slotLabel'],
    );
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lich hoc nay da ton tai.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _schedulesList.add(newSchedule);
    });
  }

  void _removeSchedule(int index) {
    setState(() {
      _schedulesList.removeAt(index);
    });
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_schedulesList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui long them it nhat mot lich hoc.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.of(context).pop({
      'name': _nameController.text.trim(),
      'description': _descController.text.trim(),
      'semesterCode': _selectedSemester,
      'schedules': _schedulesList
          .map(
            (schedule) => {
              'dayOfWeek': schedule['dayOfWeek'],
              'slotLabel': schedule['slotLabel'],
              'startTime': schedule['startTime'],
              'endTime': schedule['endTime'],
            },
          )
          .toList(),
    });
  }

  @override
  Widget build(BuildContext context) {
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
          'Chinh sua lop hoc',
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
                'Ten lop hoc *',
                style: TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  hintText: 'Nhap ten lop hoc',
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
                    return 'Ten lop hoc la bat buoc';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              const Text(
                'Mo ta',
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
                  hintText: 'Mo ta lop hoc',
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
              ),
              const SizedBox(height: 18),
              const Text(
                'Hoc ky *',
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
                    value: _selectedSemester,
                    dropdownColor: const Color(0xFFFFFFFF),
                    isExpanded: true,
                    items: _semesters
                        .map(
                          (semester) => DropdownMenuItem<String>(
                            value: semester,
                            child: Text(semester),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedSemester = value);
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
                    'Lich hoc *',
                    style: TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _addSchedule,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7EC07E),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                    child: const Text(
                      'Them',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
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
                    isExpanded: true,
                    items: _dayLabels
                        .map(
                          (day) => DropdownMenuItem<String>(
                            value: day,
                            child: Text(day),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedDay = value);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
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
                    isExpanded: true,
                    items: _slots
                        .map(
                          (slot) => DropdownMenuItem<String>(
                            value: slot['display'],
                            child: Text(slot['display']!),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedSlot = value);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_schedulesList.isNotEmpty) ...[
                const Text(
                  'Lich da chon',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...List.generate(_schedulesList.length, (index) {
                  final schedule = _schedulesList[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${schedule['displayDay']} - ${schedule['displaySlot']}',
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 13,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _removeSchedule(index),
                          child: const Icon(
                            Icons.close,
                            color: Colors.redAccent,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              const SizedBox(height: 18),
              const Text(
                'Ma lop hoc',
                style: TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                  ),
                ),
                child: Text(
                  widget.classCode,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
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
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7EC07E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
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
