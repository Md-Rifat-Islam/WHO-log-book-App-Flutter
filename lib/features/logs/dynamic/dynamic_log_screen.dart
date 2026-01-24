import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../templates/no_template_screen.dart';
import '../widgets/dynamic_input_field.dart';
import '../widgets/repeater_field.dart';
import '../../../core/constants.dart';
import '../../../models/app_user.dart';
import '../../../models/form_template.dart';
import '../../../services/log_service.dart';
import '../../../services/template_service.dart';
import '../../../stores/session_store.dart';

class DynamicLogScreen extends StatefulWidget {
  final String logType;
  final String eventType;

  const DynamicLogScreen({
    super.key,
    required this.logType,
    required this.eventType,
  });

  @override
  State<DynamicLogScreen> createState() => _DynamicLogScreenState();
}

class _DynamicLogScreenState extends State<DynamicLogScreen> {
  final _templateService = TemplateService();
  final _formKey = GlobalKey<FormState>();
  final _logService = LogService();

  FormTemplate? _template;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  final Map<String, dynamic> _values = {};

  final Color tealWater = const Color(0xFF0B6E69);
  final Color bgColor = const Color(0xFFF7F8FA);

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
      if (user == null) throw StateError('প্রোফাইল পাওয়া যায়নি (No user session).');

      if (user.districtId == null || user.districtId!.isEmpty) {
        throw StateError('ব্যবহারকারীর জেলা (District ID) পাওয়া যায়নি।');
      }

      final t = await _templateService.fetchActiveTemplate(
        roleId: user.roleId,
        districtId: user.districtId!,
        logType: widget.logType,
        eventType: widget.eventType,
      );

      if (t == null) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => NoTemplateScreen(
              logType: widget.logType,
              eventType: widget.eventType,
            ),
          ),
        );
        return;
      }

      if (!mounted) return;
      setState(() {
        _template = t;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_template == null) return;
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('অনুগ্রহ করে সঠিক তথ্য দিন।'), backgroundColor: Colors.orange),
      );
      return;
    }

    final user = SessionStore.instance.currentUser!;
    setState(() => _submitting = true);

    try {
      await _logService.submitLog(
        user: user,
        template: _template!,
        logType: widget.logType,
        eventType: widget.eventType,
        data: _values,
      );

      if (!mounted) return;

      // Success Feedback
      await _showSuccessDialog();

      if (mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _showSuccessDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Icon(Icons.check_circle, color: tealWater, size: 60),
        content: const Text(
          'আপনার লগ সফলভাবে জমা হয়েছে।',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ঠিক আছে', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(child: CircularProgressIndicator(color: tealWater)),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: tealWater,
          elevation: 0.5,

          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'ত্রুটি (Error)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ),
      );
    }

    final t = _template!;
    final user = SessionStore.instance.currentUser!;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        toolbarHeight: 90,
        centerTitle: false,
        // --- কাস্টম ব্যাক বাটন বামপাশে ---
        leadingWidth: 72,
        leading: Center(
          child: IconButton(
            style: IconButton.styleFrom(
              backgroundColor: tealWater.withOpacity(0.08),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.all(10),
            ),
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: tealWater),
            onPressed: () => context.pop(),
          ),
        ),
        // --- টাইটেল সেকশন ---
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t.titleBn,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 19,
                color: Color(0xFF1A1A1A),
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Flexible(
                  child: Text(
                    user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: tealWater.withOpacity(0.8),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 3,
                  height: 3,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: tealWater.withOpacity(0.4)),
                ),
                Text(
                  (user.districtId ?? '').toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
        // --- লোগো স্টাইল (আপনার দেওয়া কোড অনুযায়ী) ---
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: tealWater.withOpacity(0.1),
              child: ClipOval(
                child: Image.asset(
                  AppAssets.logo,
                  fit: BoxFit.cover,
                  width: 38,
                  height: 38,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.water_drop_rounded, color: tealWater, size: 24),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 120), // Large bottom padding for FAB/Sheet
          child: Column(
            children: [
              if (t.headerFields.isNotEmpty)
                _section(
                  'প্রাথমিক তথ্য (General Info)',
                  Icons.info_outline,
                  Column(
                    children: t.headerFields
                        .map((f) => _buildAnyField(f, store: _values))
                        .toList(),
                  ),
                ),
              const SizedBox(height: 16),
              _section(
                'বিবরণ (Entry Details)',
                Icons.edit_note_rounded,
                Column(
                  children: t.fields.map((f) => _buildAnyField(f, store: _values)).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      // Fixed Bottom Action Bar
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: tealWater,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _submitting
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : const Text(
                'জমা দিন (Submit Report)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets remain largely the same, but with consistent spacing ---
  Widget _section(String title, IconData icon, Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: tealWater.withOpacity(0.05),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: tealWater),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: tealWater)),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _buildAnyField(Map<String, dynamic> f, {required Map<String, dynamic> store}) {
    final key = (f['key'] ?? '').toString();
    final labelBn = (f['labelBn'] ?? key).toString();
    final type = (f['type'] ?? 'text').toString();
    final requiredField = f['required'] == true;

    if (type == 'repeater') {
      final colsRaw = f['columns'];
      final cols = (colsRaw is List)
          ? colsRaw.whereType<Map>().map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : <Map<String, dynamic>>[];

      store[key] ??= <Map<String, dynamic>>[];

      return RepeaterField(
        repeaterKey: key,
        label: labelBn,
        columns: cols,
        minRows: (f['minRows'] is int) ? f['minRows'] : 1,
        values: store,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DynamicInputField(
        label: labelBn,
        type: type,
        requiredField: requiredField,
        initialValue: store[key],
        onChanged: (v) => store[key] = v,
      ),
    );
  }
}