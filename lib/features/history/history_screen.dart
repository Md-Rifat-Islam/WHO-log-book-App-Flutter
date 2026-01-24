import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants.dart';
import '../../core/firebase_refs.dart';
import '../../stores/session_store.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const Color tealWater = Color(0xFF0B6E69);
  static const Color bgColor = Color(0xFFF7F8FA);

  String? _logType;
  String? _status;
  String? _eventType;
  DateTimeRange? _range;

  final Map<String, String> _logTypeMap = {
    LogTypes.daily: 'দৈনিক',
    LogTypes.weekly: 'সাপ্তাহিক',
    LogTypes.monthly: 'মাসিক',
    LogTypes.quarterly: 'ত্রৈমাসিক',
    LogTypes.halfYearly: 'ষান্মাসিক',
    LogTypes.yearly: 'বার্ষিক',
  };

  final Map<String, String> _eventMap = {
    EventTypes.general: 'সাধারণ',
    EventTypes.flooded: 'বন্যা-কালীন',
    EventTypes.new_connection: 'নতুন সংযোগ',
  };

  final Map<String, String> _statusMap = {
    LogStatus.pending: 'পেন্ডিং',
    LogStatus.approved: 'অনুমোদিত',
    LogStatus.rejected: 'বাতিল',
    LogStatus.locked: 'লকড',
  };

  Query<Map<String, dynamic>> _buildQuery() {
    final user = SessionStore.instance.currentUser!;
    Query<Map<String, dynamic>> q = logsRef;

    bool isAuthority = user.roleId == RoleIds.admin ||
        user.roleId == RoleIds.supervisor ||
        user.roleId == RoleIds.wtp_operator;

    if (isAuthority) {
      q = q.where('districtId', isEqualTo: user.districtId);
    } else {
      q = q.where('userId', isEqualTo: user.uid);
    }

    if (_logType != null) q = q.where('logType', isEqualTo: _logType);
    if (_status != null) q = q.where('status', isEqualTo: _status);
    if (_eventType != null) q = q.where('eventType', isEqualTo: _eventType);

    if (_range != null) {
      final start = Timestamp.fromDate(DateTime(_range!.start.year, _range!.start.month, _range!.start.day));
      final end = Timestamp.fromDate(DateTime(_range!.end.year, _range!.end.month, _range!.end.day).add(const Duration(days: 1)));
      q = q.where('createdAt', isGreaterThanOrEqualTo: start).where('createdAt', isLessThan: end);
    }

    return q.orderBy('createdAt', descending: true).limit(100);
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionStore.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('No session found.')));

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(user),
      body: Column(
        children: [
          _buildFilterBar(), // static version
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _buildQuery().snapshots(),
              builder: (context, snap) {
                if (snap.hasError) return _buildErrorState(snap.error.toString());
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: tealWater));
                }

                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) return _buildEmptyState();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

  // --- UI Components below remain as you designed ---
  PreferredSizeWidget _buildAppBar(dynamic user) {
    return AppBar(
      toolbarHeight: 95,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      backgroundColor: Colors.white,
      leadingWidth: 72,
      leading: Center(
        child: IconButton(
          style: IconButton.styleFrom(
            backgroundColor: tealWater.withOpacity(0.08),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.all(10),
          ),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: tealWater),
          onPressed: () => context.pop(),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'History / ইতিহাস',
            style: GoogleFonts.notoSansBengali(
              fontWeight: FontWeight.bold,
              fontSize: 19,
              color: const Color(0xFF1A1A1A),
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Flexible(
                child: Text(
                  user.name ?? 'Unknown',
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
      actions: [
        if (_logType != null || _status != null || _eventType != null || _range != null)
          IconButton(
            tooltip: 'রিসেট ফিল্টার',
            onPressed: () => setState(() => _logType = _status = _eventType = _range = null),
            icon: const Icon(Icons.filter_alt_off_rounded, color: Colors.redAccent),
          ),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: tealWater.withOpacity(0.1),
            child: ClipOval(
              child: Image.asset(
                'assets/images/app_logo.png',
                fit: BoxFit.cover,
                width: 38,
                height: 38,
                errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.water_drop_rounded, color: tealWater, size: 24),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _filterChip(label: 'লগ টাইপ', value: _logType, items: _logTypeMap, onSelected: (v) => setState(() => _logType = v)),
          _filterChip(label: 'স্ট্যাটাস', value: _status, items: _statusMap, onSelected: (v) => setState(() => _status = v)),
          _filterChip(label: 'ইভেন্ট', value: _eventType, items: _eventMap, onSelected: (v) => setState(() => _eventType = v)),
          _dateRangeChip(),
        ],
      ),
    );
  }

  Widget _filterChip({required String label, required String? value, required Map<String, String> items, required Function(String?) onSelected}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      child: PopupMenuButton<String?>(
        onSelected: onSelected,
        itemBuilder: (ctx) => [
          const PopupMenuItem(value: null, child: Text('সবগুলো (All)')),
          ...items.entries.map((e) => PopupMenuItem(value: e.key, child: Text(e.value)))
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: value != null ? tealWater : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: value != null ? tealWater : Colors.grey.shade300),
            boxShadow: value != null ? [BoxShadow(color: tealWater.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))] : null,
          ),
          alignment: Alignment.center,
          child: Row(
            children: [
              Text(
                value == null ? label : (items[value] ?? label),
                style: TextStyle(color: value != null ? Colors.white : Colors.black87, fontSize: 12),
              ),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down_rounded, color: value != null ? Colors.white : Colors.grey, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateRangeChip() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: ActionChip(
        backgroundColor: _range != null ? tealWater : Colors.white,
        avatar: Icon(Icons.calendar_month, size: 16, color: _range != null ? Colors.white : tealWater),
        label: Text(_range == null ? 'তারিখ' : '${_range!.start.day}/${_range!.start.month} - ${_range!.end.day}/${_range!.end.month}',
            style: TextStyle(color: _range != null ? Colors.white : Colors.black87, fontSize: 13)),
        onPressed: _pickRange,
      ),
    );
  }

  Widget _buildHistoryCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data();
    final status = m['status']?.toString() ?? LogStatus.pending;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.03)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        onTap: () => context.push('/log-view/${doc.id}'),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: tealWater.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(_getIcon(m['logType']), color: tealWater),
        ),
        title: Text(
          '${_logTypeMap[m['logType']] ?? 'Unknown'} • ${_eventMap[m['eventType']] ?? 'General'}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Period: ${m['periodKey'] ?? '-'}', style: const TextStyle(fontSize: 13)),
            Text(_prettyTimestamp(m['createdAt']), style: const TextStyle(fontSize: 11, color: Colors.grey)),
            if (m['userName'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text('By: ${m['userName']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: tealWater)),
              ),
          ],
        ),
        trailing: _statusBadge(status),
      ),
    );
  }

  Widget _statusBadge(String s) {
    final color = LogStatus.getStatusColor(s);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(_statusMap[s] ?? s, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  IconData _getIcon(String? type) {
    if (type == LogTypes.daily) return Icons.today;
    if (type == LogTypes.weekly) return Icons.date_range;
    return Icons.description_outlined;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('কোন তথ্য পাওয়া যায়নি', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(height: 8),
          const Text('অন্য ফিল্টার দিয়ে চেষ্টা করুন।', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildErrorState(String err) => Center(child: Padding(
    padding: const EdgeInsets.all(20.0),
    child: Text('Error: $err', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
  ));

  String _prettyTimestamp(dynamic ts) {
    if (ts is Timestamp) {
      final d = ts.toDate();
      return '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
    }
    return '-';
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: tealWater),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _range = picked);
  }
}