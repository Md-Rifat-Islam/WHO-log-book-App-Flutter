import 'package:flutter/material.dart';

class RepeaterField extends StatefulWidget {
  final String label;
  final String repeaterKey;
  final List<Map<String, dynamic>> columns;
  final int minRows;
  final Map<String, dynamic> values;

  const RepeaterField({
    super.key,
    required this.label,
    required this.repeaterKey,
    required this.columns,
    required this.minRows,
    required this.values,
  });

  @override
  State<RepeaterField> createState() => _RepeaterFieldState();
}

class _RepeaterFieldState extends State<RepeaterField> {
  Widget _timePickerField({
    required int rowIndex,
    required String fieldKey,
    required String labelBn,
    required bool requiredField,
  }) {
    final row = rows[rowIndex];
    final current = row[fieldKey]?.toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: FormField<String>(
        key: ValueKey('${widget.repeaterKey}-$rowIndex-$fieldKey-time'),
        initialValue: current,
        validator: (v) {
          if (!requiredField) return null;
          if (v == null || v.trim().isEmpty) return 'সময় নির্বাচন করুন';
          return null;
        },
        builder: (state) {
          return InkWell(
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (picked == null) return;

              final hh = picked.hour.toString().padLeft(2, '0');
              final mm = picked.minute.toString().padLeft(2, '0');
              final val = '$hh:$mm';

              setState(() {
                row[fieldKey] = val;
                _commitRow(rowIndex, row);
              });
              state.didChange(val);
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: labelBn,
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                errorText: state.errorText,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    (row[fieldKey] ?? '').toString().isEmpty
                        ? 'সময় নির্বাচন করুন'
                        : row[fieldKey].toString(),
                    style: TextStyle(
                      color: (row[fieldKey] ?? '').toString().isEmpty
                          ? Colors.grey.shade600
                          : Colors.black87,
                    ),
                  ),
                  const Icon(Icons.access_time, size: 18, color: Color(0xFF0B6E69)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  // Theme Color
  static const Color tealWater = Color(0xFF0B6E69);

  List<Map<String, dynamic>> get rows {
    final v = widget.values[widget.repeaterKey];
    if (v is List) {
      return v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return <Map<String, dynamic>>[];
  }

  void _ensureMinRows() {
    final r = rows;
    while (r.length < widget.minRows) {
      r.add(<String, dynamic>{});
    }
    widget.values[widget.repeaterKey] = r;
  }

  @override
  void initState() {
    super.initState();
    _ensureMinRows();
  }

  @override
  Widget build(BuildContext context) {
    _ensureMinRows();
    final r = rows;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              const Icon(Icons.list_alt_rounded, color: tealWater, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: tealWater,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Repeated Rows
        ...List.generate(
          r.length,
              (index) => _rowCard(index, key: ValueKey('${widget.repeaterKey}-row-$index')),
        ),

        const SizedBox(height: 12),

        // Add Row Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() {
                final all = rows;
                all.add(<String, dynamic>{});
                widget.values[widget.repeaterKey] = all;
              });
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: tealWater, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              foregroundColor: tealWater,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text(
              'আরও সারি যোগ করুন',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _rowCard(int rowIndex, {required Key key}) {
    final row = rows[rowIndex];

    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: tealWater.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: tealWater,
                  child: Text(
                    '${rowIndex + 1}',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'বিবরণ',
                  style: TextStyle(fontWeight: FontWeight.w700, color: tealWater),
                ),
                const Spacer(),
                if (rows.length > widget.minRows)
                  IconButton(
                    tooltip: 'Remove row',
                    onPressed: () {
                      setState(() {
                        final all = rows;
                        all.removeAt(rowIndex);
                        widget.values[widget.repeaterKey] = all;
                      });
                    },
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: widget.columns.map((c) => _buildDynamicField(rowIndex, row, c)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicField(int rowIndex, Map<String, dynamic> row, Map<String, dynamic> c) {
    final fieldKey = (c['key'] ?? '').toString();
    final labelBn = (c['labelBn'] ?? fieldKey).toString();
    final type = (c['type'] ?? 'text').toString();
    final requiredField = c['required'] == true;

    if (type == 'yesno') {
      final current = row[fieldKey];
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(labelBn, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              children: [
                _customChoiceChip(
                  label: 'হ্যাঁ',
                  selected: current == true,
                  onSelected: () {
                    setState(() {
                      row[fieldKey] = true;
                      _commitRow(rowIndex, row);
                    });
                  },
                ),
                const SizedBox(width: 12),
                _customChoiceChip(
                  label: 'না',
                  selected: current == false,
                  onSelected: () {
                    setState(() {
                      row[fieldKey] = false;
                      _commitRow(rowIndex, row);
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (type == 'date') return _datePickerField(rowIndex: rowIndex, fieldKey: fieldKey, labelBn: labelBn, requiredField: requiredField);
    if (type == 'time') return _timePickerField(rowIndex: rowIndex, fieldKey: fieldKey, labelBn: labelBn, requiredField: requiredField);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        key: ValueKey('${widget.repeaterKey}-$rowIndex-$fieldKey'),
        initialValue: row[fieldKey]?.toString(),
        decoration: InputDecoration(
          labelText: labelBn,
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: tealWater, width: 2)),
        ),
        keyboardType: (type == 'number') ? TextInputType.number : TextInputType.text,
        validator: (v) => (requiredField && (v == null || v.trim().isEmpty)) ? 'এই ঘরটি পূরণ করুন' : null,
        onChanged: (v) {
          row[fieldKey] = (type == 'number') ? num.tryParse(v) ?? v : v;
          _commitRow(rowIndex, row);
        },
      ),
    );
  }

  Widget _customChoiceChip({required String label, required bool selected, required VoidCallback onSelected}) {
    return Expanded(
      child: InkWell(
        onTap: onSelected,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? tealWater : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? tealWater : Colors.grey.shade300),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: selected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // Reuse logic from your date/time pickers but with updated InputDecoration style...
  // (Omitted updated Date/Time code for brevity, but use the same InputDecoration as TextFormField above)

  Widget _datePickerField({required int rowIndex, required String fieldKey, required String labelBn, required bool requiredField}) {
    final row = rows[rowIndex];
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: FormField<String>(
        initialValue: row[fieldKey]?.toString(),
        validator: (v) => (requiredField && (v == null || v.trim().isEmpty)) ? 'তারিখ নির্বাচন করুন' : null,
        builder: (state) => InkWell(
          onTap: () async {
            final picked = await showDatePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2030), initialDate: DateTime.now());
            if (picked != null) {
              final val = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
              setState(() { row[fieldKey] = val; _commitRow(rowIndex, row); });
              state.didChange(val);
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: labelBn,
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              errorText: state.errorText,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(row[fieldKey]?.toString() ?? 'তারিখ নির্বাচন করুন'),
                const Icon(Icons.calendar_today, size: 18, color: tealWater),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Time picker would follow the same InputDecorator style as Date picker.

  void _commitRow(int rowIndex, Map<String, dynamic> row) {
    final all = rows;
    all[rowIndex] = row;
    widget.values[widget.repeaterKey] = all;
  }
}