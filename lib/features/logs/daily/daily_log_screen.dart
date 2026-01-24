import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/constants.dart';
import '../../../core/firebase_refs.dart';
import '../../../models/app_user.dart';
import '../../../models/form_template.dart';
import '../../../services/template_service.dart';
import '../../../stores/session_store.dart';
import '../widgets/repeater_field.dart';
import '../widgets/dynamic_input_field.dart'; // Ensure this is imported

class DailyLogScreen extends StatefulWidget {
  const DailyLogScreen({super.key});

  @override
  State<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends State<DailyLogScreen> {
  final _templateService = TemplateService();
  final _formKey = GlobalKey<FormState>();

  FormTemplate? _template;
  String? _error;
  bool _loading = true;
  bool _submitting = false;

  final Map<String, dynamic> _values = {};

  @override
  void initState() {
    super.initState();
    _loadTemplate();
  }

  Future<void> _loadTemplate() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final AppUser? user = SessionStore.instance.currentUser;
      if (user == null) throw StateError('No session user loaded.');

      final districtId = user.districtId;
      if (districtId == null || districtId.isEmpty) {
        throw StateError('districtId missing in user profile.');
      }

      final t = await _templateService.fetchActiveTemplate(
        roleId: user.roleId,
        districtId: districtId,
        logType: LogTypes.daily,
        eventType: EventTypes.general,
      );

      if (!mounted) return;

      setState(() {
        _template = t;
        _loading = false;
        _error = (t == null) ? 'No active Daily template found.' : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _todayPeriodKey(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Future<void> _submit() async {
    final t = _template;
    if (t == null) return;

    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    final user = SessionStore.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final periodKey = _todayPeriodKey(now);

    setState(() => _submitting = true);

    try {
      final existing = await logsRef
          .where('userId', isEqualTo: user.uid)
          .where('logType', isEqualTo: LogTypes.daily)
          .where('periodKey', isEqualTo: periodKey)
          .where('districtId', isEqualTo: user.districtId)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        throw StateError('আজকের দৈনিক লগ ইতিমধ্যে জমা হয়েছে ($periodKey).');
      }

      await logsRef.add({
        'userId': user.uid,
        'roleId': user.roleId,
        'districtId': user.districtId,
        'logType': LogTypes.daily,
        'periodKey': periodKey,
        'formTemplateId': t.id,
        'formVersion': t.version,
        'data': _values,
        'status': LogStatus.pending,
        'editable': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastActionBy': user.uid,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('দৈনিকলগ সফলভাবে জমা হয়েছে'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submit failed: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Log')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_error != null)
          ? Center(child: Text(_error!))
          : _buildForm(),
      bottomNavigationBar: (_template == null)
          ? null
          : Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting ? const CircularProgressIndicator() : const Text('Submit / জমা দিন'),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    final t = _template!;
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(t.titleBn, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...t.headerFields.map((f) => _buildField(f)),
          const SizedBox(height: 12),
          ...t.fields.map((f) => _buildField(f)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildField(Map<String, dynamic> f) {
    final key = (f['key'] ?? '').toString();
    final type = (f['type'] ?? 'text').toString();

    if (type == 'repeater') {
      final repeaterKey = (f['key'] ?? 'entries').toString();
      _values[repeaterKey] ??= <Map<String, dynamic>>[];
      return RepeaterField(
        label: (f['labelBn'] ?? 'এন্ট্রি').toString(),
        columns: List<Map<String, dynamic>>.from(f['columns'] ?? []),
        minRows: (f['minRows'] is int) ? f['minRows'] : 1, // Fix: Pass minRows
        values: _values,
        repeaterKey: repeaterKey,
      );
    }

    // Fix: Use DynamicInputField for wrapping and yesno logic
    return DynamicInputField(
      label: (f['labelBn'] ?? key).toString(),
      type: type,
      requiredField: f['required'] == true,
      initialValue: _values[key],
      onChanged: (v) => _values[key] = v,
    );
  }
}