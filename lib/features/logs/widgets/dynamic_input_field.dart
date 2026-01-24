import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DynamicInputField extends StatelessWidget {
  final String label;
  final String type; // Handles 'yesno', 'text', 'number', 'date', etc.
  final bool requiredField;
  final dynamic initialValue;
  final void Function(dynamic value) onChanged;

  const DynamicInputField({
    super.key,
    required this.label,
    required this.type,
    required this.requiredField,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // --- 1. HANDLE YES/NO LOGIC (Matched strictly to 'yesno' type from DB) ---
    if (type == 'yesno' || type == 'select' || label.contains('হ্যাঁ/না')) {
      return _YesNoField(
        label: label,
        requiredField: requiredField,
        initialValue: initialValue,
        onChanged: onChanged,
      );
    }

    // --- 2. HANDLE OTHER TYPES ---
    switch (type) {
      case 'date':
        return _DateField(
          label: label,
          requiredField: requiredField,
          initialValue: initialValue,
          onChanged: onChanged,
        );
      case 'time':
        return _TimeField(
          label: label,
          requiredField: requiredField,
          initialValue: initialValue,
          onChanged: onChanged,
        );
      case 'textarea':
        return _TextField(
          label: label,
          requiredField: requiredField,
          initialValue: initialValue,
          onChanged: onChanged,
          maxLines: 4,
          keyboardType: TextInputType.multiline,
        );
      case 'number':
        return _TextField(
          label: label,
          requiredField: requiredField,
          initialValue: initialValue,
          onChanged: onChanged,
          maxLines: 1,
          keyboardType: TextInputType.number,
        );
      default:
        return _TextField(
          label: label,
          requiredField: requiredField,
          initialValue: initialValue,
          onChanged: onChanged,
          maxLines: 1,
          keyboardType: TextInputType.text,
        );
    }
  }
}

// --- WRAPPER FOR LONG LABELS (Ensures text wraps and stays on screen) ---

class _FieldWrapper extends StatelessWidget {
  final String label;
  final bool required;
  final Widget child;

  const _FieldWrapper({required this.label, required this.required, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text widget wraps automatically within a Column
          Text.rich(
            TextSpan(
              text: label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
              children: [
                if (required) const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

// --- YES/NO FIELD ---

class _YesNoField extends StatefulWidget {
  final String label;
  final bool requiredField;
  final dynamic initialValue;
  final void Function(dynamic value) onChanged;

  const _YesNoField({required this.label, required this.requiredField, required this.initialValue, required this.onChanged});

  @override
  State<_YesNoField> createState() => _YesNoFieldState();
}

class _YesNoFieldState extends State<_YesNoField> {
  String? _selected;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) _selected = widget.initialValue.toString();
  }

  @override
  Widget build(BuildContext context) {
    return _FieldWrapper(
      label: widget.label,
      required: widget.requiredField,
      child: FormField<String>(
        validator: (v) => widget.requiredField && _selected == null ? 'একটি অপশন বাছাই করুন' : null,
        builder: (state) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: ['হ্যাঁ', 'না'].map((opt) {
                bool isSel = _selected == opt;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selected = opt);
                      widget.onChanged(opt);
                      state.didChange(opt);
                    },
                    child: Container(
                      margin: EdgeInsets.only(right: opt == 'হ্যাঁ' ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFF0B6E69) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSel ? const Color(0xFF0B6E69) : Colors.grey.shade300),
                      ),
                      child: Center(
                        child: Text(opt, style: TextStyle(color: isSel ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (state.hasError) Padding(padding: const EdgeInsets.only(top: 5, left: 4), child: Text(state.errorText!, style: const TextStyle(color: Colors.red, fontSize: 12))),
          ],
        ),
      ),
    );
  }
}

// --- TEXT / NUMBER FIELD ---

class _TextField extends StatelessWidget {
  final String label;
  final bool requiredField;
  final dynamic initialValue;
  final void Function(dynamic value) onChanged;
  final TextInputType keyboardType;
  final int maxLines;

  const _TextField({required this.label, required this.requiredField, required this.initialValue, required this.onChanged, required this.keyboardType, required this.maxLines});

  @override
  Widget build(BuildContext context) {
    return _FieldWrapper(
      label: label,
      required: requiredField,
      child: TextFormField(
        initialValue: initialValue?.toString(),
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: _FieldStyle.buildDecoration('উত্তর লিখুন...'),
        validator: (v) => (requiredField && (v == null || v.trim().isEmpty)) ? 'এই ঘরটি পূরণ করুন' : null,
        onChanged: (v) => onChanged(keyboardType == TextInputType.number ? (num.tryParse(v) ?? v) : v),
      ),
    );
  }
}

// --- DATE FIELD ---

class _DateField extends StatefulWidget {
  final String label;
  final bool requiredField;
  final dynamic initialValue;
  final void Function(dynamic value) onChanged;

  const _DateField({required this.label, required this.requiredField, required this.initialValue, required this.onChanged});

  @override
  State<_DateField> createState() => _DateFieldState();
}

class _DateFieldState extends State<_DateField> {
  DateTime? _date;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue is DateTime) _date = widget.initialValue;
    else if (widget.initialValue != null) _date = DateTime.tryParse(widget.initialValue.toString());
  }

  @override
  Widget build(BuildContext context) {
    final text = _date == null ? 'তারিখ নির্বাচন করুন' : DateFormat('dd-MMM-yyyy').format(_date!);
    return _FieldWrapper(
      label: widget.label,
      required: widget.requiredField,
      child: InkWell(
        onTap: () async {
          final p = await showDatePicker(context: context, initialDate: _date ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100), builder: (c, child) => _FieldStyle.applyTheme(child!));
          if (p != null) {
            setState(() => _date = p);
            widget.onChanged(DateFormat('yyyy-MM-dd').format(p));
          }
        },
        child: InputDecorator(
          decoration: _FieldStyle.buildDecoration('', icon: Icons.calendar_today_outlined),
          child: Text(text),
        ),
      ),
    );
  }
}

// --- TIME FIELD ---

class _TimeField extends StatefulWidget {
  final String label;
  final bool requiredField;
  final dynamic initialValue;
  final void Function(dynamic value) onChanged;

  const _TimeField({required this.label, required this.requiredField, required this.initialValue, required this.onChanged});

  @override
  State<_TimeField> createState() => _TimeFieldState();
}

class _TimeFieldState extends State<_TimeField> {
  TimeOfDay? _time;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      final p = widget.initialValue.toString().split(':');
      if (p.length == 2) _time = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = _time?.format(context) ?? 'সময় নির্বাচন করুন';
    return _FieldWrapper(
      label: widget.label,
      required: widget.requiredField,
      child: InkWell(
        onTap: () async {
          final p = await showTimePicker(context: context, initialTime: _time ?? TimeOfDay.now(), builder: (c, child) => _FieldStyle.applyTheme(child!));
          if (p != null) {
            setState(() => _time = p);
            widget.onChanged('${p.hour.toString().padLeft(2, '0')}:${p.minute.toString().padLeft(2, '0')}');
          }
        },
        child: InputDecorator(
          decoration: _FieldStyle.buildDecoration('', icon: Icons.access_time_filled_rounded),
          child: Text(text),
        ),
      ),
    );
  }
}

// --- STYLE HELPER ---

class _FieldStyle {
  static const primaryColor = Color(0xFF0B6E69);

  static InputDecoration buildDecoration(String hint, {IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, color: primaryColor, size: 20) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: primaryColor, width: 2)),
    );
  }

  static Widget applyTheme(Widget child) => Theme(
    data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: primaryColor)),
    child: child,
  );
}