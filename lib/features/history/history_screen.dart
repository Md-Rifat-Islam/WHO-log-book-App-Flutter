import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/firebase_refs.dart';
import '../../stores/session_store.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Theme Colors
  static const Color tealWater = Color(0xFF0B6E69);
  static const Color bgColor = Color(0xFFF7F8FA);

  // Filters
  String? _logType;
  String? _status;
  String? _eventType;
  DateTimeRange? _range;

  // --- Display maps ---
  static const Map<String, String> _logTypeBn = {
    'daily': 'দৈনিক',
    'weekly': 'সাপ্তাহিক',
    'monthly': 'মাসিক',
    'quarterly': 'ত্রৈমাসিক',
    'half_yearly': 'ষান্মাসিক',
    'yearly': 'বার্ষিক',
    'flood': 'বন্যা',
    'new_connection': 'নতুন সংযোগ',
  };

  static const Map<String, String> _statusBn = {
    'Pending': 'পেন্ডিং',
    'Approved': 'অনুমোদিত',
    'Rejected': 'বাতিল',
    'Locked': 'লকড',
  };

  static const Map<String, String> _eventBn = {
    'general': 'সাধারণ',
    'flooded': 'বন্যা-কালীন',
    'new_connection': 'নতুন সংযোগ',
  };

  Query<Map<String, dynamic>> _buildQuery(String uid) {
    Query<Map<String, dynamic>> q = logsRef.where('userId', isEqualTo: uid);

    if (_logType != null) q = q.where('logType', isEqualTo: _logType);
    if (_status != null) q = q.where('status', isEqualTo: _status);
    if (_eventType != null) q = q.where('eventType', isEqualTo: _eventType);

    if (_range != null) {
      final start = Timestamp.fromDate(DateTime(_range!.start.year, _range!.start.month, _range!.start.day));
      final endExclusive = Timestamp.fromDate(DateTime(_range!.end.year, _range!.end.month, _range!.end.day).add(const Duration(days: 1)));
      q = q.where('createdAt', isGreaterThanOrEqualTo: start).where('createdAt', isLessThan: endExclusive);
    }

    return q.orderBy('createdAt', descending: true).limit(100);
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionStore.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('No profile loaded.')));

    return Scaffold(
      backgroundColor: bgColor,
      // --- Standardized Gray AppBar ---
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
                      color: tealWater,
                      size: 28),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'History / ইতিহাস',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontSize: 18,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    user.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.black.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    '(${user.districtId})',
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
        actions: [
          if (_logType != null || _status != null || _eventType != null || _range != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                tooltip: 'Clear filters',
                onPressed: () => setState(() {
                  _logType = _status = _eventType = _range = null;
                }),
                icon: const Icon(Icons.filter_alt_off_rounded, color: Colors.redAccent, size: 28),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _filtersBar(),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _buildQuery(user.uid).snapshots(),
              builder: (context, snap) {
                if (snap.hasError) return _buildErrorState(snap.error.toString());
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: tealWater));
                }

                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) return _buildEmptyState();

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, i) => _buildHistoryCard(docs[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- Enhanced Empty State ---
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          const Text(
            'কোন তথ্য পাওয়া যায়নি',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          const Text(
            'আপনার ফিল্টার পরিবর্তন করে পুনরায় চেষ্টা করুন।',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          if (_logType != null || _status != null || _eventType != null || _range != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => setState(() {
                _logType = _status = _eventType = _range = null;
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: tealWater,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('ফিল্টার মুছে ফেলুন'),
            ),
          ]
        ],
      ),
    );
  }

  // --- Enhanced Error State ---
  Widget _buildErrorState(String err) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text('সার্ভার ত্রুটি ঘটেছে', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(err, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.red.shade300)),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.replay_rounded),
              label: const Text('আবার চেষ্টা করুন'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data();
    final status = m['status']?.toString() ?? 'Pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/log-view/${doc.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildTypeIcon(m['logType']?.toString()),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_bnLogType(m['logType'] ?? '')} • ${_bnEvent(m['eventType'] ?? 'general')}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text('Period: ${m['periodKey']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    Text('Submitted: ${_prettyTimestamp(m['createdAt'])}', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                  ],
                ),
              ),
              _statusBadge(status),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeIcon(String? type) {
    IconData icon = Icons.description_outlined;
    if (type == 'daily') icon = Icons.today;
    if (type == 'flood') icon = Icons.water_drop_outlined;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: tealWater.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: tealWater, size: 24),
    );
  }

  Widget _statusBadge(String s) {
    Color color = Colors.orange;
    if (s == 'Approved') color = Colors.green;
    if (s == 'Rejected') color = Colors.red;
    if (s == 'Locked') color = Colors.blueGrey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(_bnStatus(s), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _filtersBar() {
    return Container(
      color: Colors.white,
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _filterChip(label: 'Log Type', value: _logType, items: _logTypeBn.keys.toList(), display: _bnLogType, onSelected: (v) => setState(() => _logType = v)),
          _filterChip(label: 'Status', value: _status, items: _statusBn.keys.toList(), display: _bnStatus, onSelected: (v) => setState(() => _status = v)),
          _filterChip(label: 'Event', value: _eventType, items: _eventBn.keys.toList(), display: _bnEvent, onSelected: (v) => setState(() => _eventType = v)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: ActionChip(
              backgroundColor: _range != null ? tealWater : Colors.white,
              label: Text(_range == null ? 'Date' : _rangeLabel(), style: TextStyle(color: _range != null ? Colors.white : Colors.black87)),
              avatar: Icon(Icons.calendar_month, size: 16, color: _range != null ? Colors.white : tealWater),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300)),
              onPressed: _pickRange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({required String label, required String? value, required List<String> items, required String Function(String) display, required Function(String?) onSelected}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      child: PopupMenuButton<String?>(
        onSelected: onSelected,
        itemBuilder: (ctx) => [
          const PopupMenuItem(value: null, child: Text('All')),
          ...items.map((e) => PopupMenuItem(value: e, child: Text(display(e))))
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: value != null ? tealWater : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: value != null ? tealWater : Colors.grey.shade300),
          ),
          alignment: Alignment.center,
          child: Row(
            children: [
              Text(value == null ? label : display(value), style: TextStyle(color: value != null ? Colors.white : Colors.black87, fontSize: 13)),
              const SizedBox(width: 4),
              Icon(Icons.arrow_drop_down, color: value != null ? Colors.white : Colors.grey, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  String _bnLogType(String v) => _logTypeBn[v] ?? v;
  String _bnStatus(String v) => _statusBn[v] ?? v;
  String _bnEvent(String v) => _eventBn[v] ?? v;
  String _rangeLabel() => '${_range!.start.day}/${_range!.start.month} - ${_range!.end.day}/${_range!.end.month}';
  String _prettyTimestamp(dynamic ts) => ts is Timestamp ? '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year} ${ts.toDate().hour}:${ts.toDate().minute}' : '-';

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(context: context, firstDate: DateTime(2023), lastDate: DateTime.now());
    if (picked != null) setState(() => _range = picked);
  }
}