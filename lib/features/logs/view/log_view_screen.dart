import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/firebase_refs.dart';
import '../../../models/form_template.dart';
import '../../../stores/session_store.dart';

class LogViewScreen extends StatelessWidget {
  final String logId;
  const LogViewScreen({super.key, required this.logId});

  static const Color tealWater = Color(0xFF0B6E69);
  static const Color bgColor = Color(0xFFF7F8FA);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: logsRef.doc(logId).get(),
      builder: (context, logSnap) {
        if (logSnap.hasError) return _errorScaffold(context, 'Error: ${logSnap.error}');
        if (!logSnap.hasData) return _loadingScaffold();

        final logDoc = logSnap.data!;
        if (!logDoc.exists) return _errorScaffold(context, 'Log not found.');

        final logData = logDoc.data()!;
        final templateId = (logData['formTemplateId'] ?? '').toString();

        return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: templatesRef.doc(templateId).get(),
          builder: (context, tempSnap) {
            if (tempSnap.hasError) return _errorScaffold(context, 'Template error.');
            if (!tempSnap.hasData) return _loadingScaffold();

            final tdoc = tempSnap.data!;
            if (!tdoc.exists) return _errorScaffold(context, 'Template missing.');

            final template = FormTemplate.fromMap(tdoc.id, tdoc.data()!);
            final data = Map<String, dynamic>.from(logData['data'] ?? {});

            return _LogViewBody(template: template, data: data, meta: logData);
          },
        );
      },
    );
  }

  Widget _loadingScaffold() => const Scaffold(
    backgroundColor: bgColor,
    body: Center(child: CircularProgressIndicator(color: tealWater)),
  );

  Widget _errorScaffold(BuildContext context, String msg) => Scaffold(
    appBar: AppBar(
      backgroundColor: const Color(0xFFF5F5F5),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => context.pop(),
      ),
    ),
    body: Center(child: Text(msg)),
  );
}

class _LogViewBody extends StatelessWidget {
  final FormTemplate template;
  final Map<String, dynamic> data;
  final Map<String, dynamic> meta;

  const _LogViewBody({
    required this.template,
    required this.data,
    required this.meta,
  });

  @override
  Widget build(BuildContext context) {
    final user = SessionStore.instance.currentUser;

    return Scaffold(
      backgroundColor: LogViewScreen.bgColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        foregroundColor: Colors.black87,
        elevation: 0.5,
        toolbarHeight: 95,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white,
              child: ClipOval(
                child: Image.asset(
                  'assets/images/app_logo.png',
                  fit: BoxFit.cover,
                  width: 40,
                  height: 40,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.water_drop_rounded,
                    color: LogViewScreen.tealWater,
                    size: 28,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    template.titleBn,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    user?.name ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.black.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    '(${user?.districtId ?? "N/A"})',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: Colors.black.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: const [SizedBox(width: 16)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatusHeader(),
          const SizedBox(height: 20),
          if (template.headerFields.isNotEmpty) ...[
            _sectionLabel('প্রাথমিক তথ্য (General Info)'),
            _buildDataGrid(template.headerFields),
            const SizedBox(height: 24),
          ],
          _sectionLabel('রিপোর্ট বিবরণ (Report Details)'),
          ...template.fields.map((f) {
            final type = f['type']?.toString().toLowerCase() ?? 'text';
            if (type == 'repeater') {
              return _RepeaterTableView(
                label: (f['labelBn'] ?? 'এন্ট্রি').toString(),
                repeaterKey: (f['key'] ?? 'entries').toString(),
                columns: _asListOfMap(f['columns']),
                data: data,
              );
            }
            return _buildInfoTile(f);
          }),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatusHeader() {
    final status = (meta['status'] ?? 'Pending').toString();
    final period = (meta['periodKey'] ?? '-').toString();
    final district = (meta['districtId'] ?? '-').toString();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _metaItem(Icons.calendar_today_rounded, 'Period', period),
              _statusBadge(status),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Divider(height: 1, thickness: 0.5),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _metaItem(Icons.location_on_outlined, 'District', district),
              _metaItem(Icons.person_outline_rounded, 'Operator', meta['userName'] ?? 'N/A'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataGrid(List<Map<String, dynamic>> fields) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        children: fields.map((f) => _buildInfoTile(f)).toList(),
      ),
    );
  }

  Widget _buildInfoTile(Map<String, dynamic> f) {
    final label = (f['labelBn'] ?? f['key']).toString();
    final val = data[f['key']];
    final type = f['type']?.toString().toLowerCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Fix: Align to top
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              softWrap: true, // Fix: Wrap long text
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              _prettyValue(val, type),
              softWrap: true, // Fix: Wrap long text
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w900,
        color: LogViewScreen.tealWater,
        letterSpacing: 0.5,
      ),
    ),
  );

  Widget _metaItem(IconData icon, String label, String value) => Row(
    children: [
      Icon(icon, size: 16, color: LogViewScreen.tealWater.withOpacity(0.7)),
      const SizedBox(width: 8),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      )
    ],
  );

  Widget _statusBadge(String s) {
    Color color = Colors.orange;
    if (s == 'Approved') color = Colors.green;
    if (s == 'Rejected') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        s.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
      ),
    );
  }

  // Fix: Added type check for 'yesno' strings from DB
  String _prettyValue(dynamic v, [String? type]) {
    if (v == null || v.toString().isEmpty) return '-';
    if (type == 'yesno' || v is bool) {
      String str = v.toString().toLowerCase();
      if (str == 'true' || str == 'হ্যাঁ' || str == 'yes') return 'হ্যাঁ';
      if (str == 'false' || str == 'না' || str == 'no') return 'না';
    }
    return v.toString();
  }

  static List<Map<String, dynamic>> _asListOfMap(dynamic raw) =>
      (raw is List) ? raw.map((e) => Map<String, dynamic>.from(e)).toList() : [];
}

class _RepeaterTableView extends StatelessWidget {
  final String label;
  final String repeaterKey;
  final List<Map<String, dynamic>> columns;
  final Map<String, dynamic> data;

  const _RepeaterTableView({
    required this.label,
    required this.repeaterKey,
    required this.columns,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final rows = (data[repeaterKey] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 16, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: LogViewScreen.tealWater,
                fontSize: 13,
                letterSpacing: 0.5
            ),
          ),
        ),
        if (rows.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withOpacity(0.05)),
            ),
            child: const Text('কোন তথ্য নেই', style: TextStyle(color: Colors.grey)),
          )
        else
          ...rows.asMap().entries.map((entry) {
            int index = entry.key;
            Map<String, dynamic> rowData = entry.value;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: LogViewScreen.tealWater.withOpacity(0.05),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: Text(
                      'এন্ট্রি নং ${index + 1}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: LogViewScreen.tealWater,
                      ),
                    ),
                  ),
                  ...columns.map((col) {
                    final colLabel = col['labelBn']?.toString() ?? '';
                    final colValue = rowData[col['key']];
                    final colType = col['type']?.toString().toLowerCase();
                    final isLast = columns.last == col;

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: isLast ? null : Border(
                          bottom: BorderSide(color: Colors.grey.shade100),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start, // Fix: Align top
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              colLabel,
                              softWrap: true, // Fix: Wrap text
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: Text(
                              // Fix: Applying yesno logic here too
                              (colType == 'yesno' || colValue is bool)
                                  ? (colValue.toString().toLowerCase() == 'true' || colValue.toString() == 'হ্যাঁ' || colValue.toString().toLowerCase() == 'yes' ? 'হ্যাঁ' : 'না')
                                  : (colValue?.toString() ?? '-'),
                              softWrap: true, // Fix: Wrap text
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            );
          }).toList(),
      ],
    );
  }
}