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
  // Filters State
  String? _logType;
  String? _status;
  String? _eventType;
  DateTimeRange? _range;

  Query<Map<String, dynamic>>? _query;
  static const int pageSize = 50;

  // --- Localization Maps ---
  static const Map<String, String> _logTypeMap = {
    LogTypes.daily: 'দৈনিক',
    LogTypes.weekly: 'সাপ্তাহিক',
    LogTypes.monthly: 'মাসিক',
    LogTypes.quarterly: 'ত্রৈমাসিক',
    LogTypes.halfYearly: 'ষান্মাসিক',
    LogTypes.yearly: 'বার্ষিক',
  };

  static const Map<String, String> _eventMap = {
    EventTypes.general: 'সাধারণ',
    EventTypes.flooded: 'বন্যা-কালীন',
    EventTypes.new_connection: 'নতুন সংযোগ',
  };

  static const Map<String, String> _statusMap = {
    LogStatus.pending: 'পেন্ডিং',
    LogStatus.approved: 'অনুমোদিত',
    LogStatus.rejected: 'বাতিল',
    LogStatus.locked: 'লকড',
  };

  @override
  void initState() {
    super.initState();
    _refreshQuery();
  }

  void _refreshQuery() {
    final user = SessionStore.instance.currentUser!;
    Query<Map<String, dynamic>> q = logsRef;

    final isAuthority = user.roleId == RoleIds.admin ||
        user.roleId == RoleIds.supervisor ||
        user.roleId == RoleIds.wtp_operator;

    q = isAuthority
        ? q.where('districtId', isEqualTo: user.districtId)
        : q.where('userId', isEqualTo: user.uid);

    if (_logType != null) q = q.where('logType', isEqualTo: _logType);
    if (_status != null) q = q.where('status', isEqualTo: _status);
    if (_eventType != null) q = q.where('eventType', isEqualTo: _eventType);

    if (_range != null) {
      final start = Timestamp.fromDate(DateTime(_range!.start.year, _range!.start.month, _range!.start.day));
      final end = Timestamp.fromDate(DateTime(_range!.end.year, _range!.end.month, _range!.end.day).add(const Duration(days: 1)));
      q = q.where('createdAt', isGreaterThanOrEqualTo: start).where('createdAt', isLessThan: end);
    }

    _query = q.orderBy('createdAt', descending: true).limit(pageSize);
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionStore.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('No session found')));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: _buildAppBar(user),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _query!.snapshots(),
              builder: (context, snap) {
                if (snap.hasError) return _errorState(snap.error.toString());
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(strokeWidth: 3, color: AppAssets.tealWater));
                }

                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) return _emptyState();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  physics: const BouncingScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (_, i) => _historyCard(docs[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(dynamic user) {
    return AppBar(
      toolbarHeight: 85,
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      leadingWidth: 64,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Center(
          child: IconButton(
            style: IconButton.styleFrom(
              backgroundColor: AppAssets.tealWater.withOpacity(0.08),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppAssets.tealWater),
            onPressed: () => context.pop(),
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'History / ইতিহাস',
            style: GoogleFonts.notoSansBengali(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1D1D1D),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            user.name ?? 'User',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
          ),
        ],
      ),
      actions: [
        if (_logType != null || _status != null || _eventType != null || _range != null)
          TextButton.icon(
            onPressed: () => setState(() {
              _logType = _status = _eventType = _range = null;
              _refreshQuery();
            }),
            icon: const Icon(Icons.refresh_rounded, size: 18, color: Colors.redAccent),
            label: const Text('রিসেট', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2))),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _filterChip('টাইপ', _logType, _logTypeMap, (v) => _setFilter(() => _logType = v)),
          _filterChip('স্ট্যাটাস', _status, _statusMap, (v) => _setFilter(() => _status = v)),
          _filterChip('ইভেন্ট', _eventType, _eventMap, (v) => _setFilter(() => _eventType = v)),
          _dateChip(),
        ],
      ),
    );
  }

  void _setFilter(VoidCallback fn) {
    setState(() {
      fn();
      _refreshQuery();
    });
  }

  Widget _filterChip(String label, String? value, Map<String, String> items, Function(String?) onSelect) {
    bool isSelected = value != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      child: PopupMenuButton<String?>(
        onSelected: onSelect,
        itemBuilder: (_) => [
          const PopupMenuItem(value: null, child: Text('সবগুলো')),
          ...items.entries.map((e) => PopupMenuItem(value: e.key, child: Text(e.value))),
        ],
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppAssets.tealWater : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? AppAssets.tealWater : Colors.grey.shade300),
          ),
          alignment: Alignment.center,
          child: Row(
            children: [
              Text(
                isSelected ? items[value]! : label,
                style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
              ),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: isSelected ? Colors.white : Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateChip() {
    bool isSelected = _range != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      child: ActionChip(
        onPressed: _pickRange,
        backgroundColor: isSelected ? AppAssets.tealWater : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? AppAssets.tealWater : Colors.grey.shade300)),
        label: Text(
          isSelected ? '${_range!.start.day}/${_range!.start.month} - ${_range!.end.day}/${_range!.end.month}' : 'তারিখ',
          style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontSize: 12),
        ),
        avatar: Icon(Icons.calendar_month_rounded, size: 14, color: isSelected ? Colors.white : AppAssets.tealWater),
      ),
    );
  }

  Widget _historyCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data();
    final status = m['status'] ?? LogStatus.pending;
    final logType = m['logType'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () => context.push('/log-view/${doc.id}'),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppAssets.tealWater.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(_getIcon(logType), color: AppAssets.tealWater, size: 24),
        ),
        title: Text(
          '${_logTypeMap[logType] ?? '-'} • ${_eventMap[m['eventType']] ?? '-'}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2D3142)),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(_formatTime(m['createdAt']), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ),
        trailing: _statusBadge(status),
      ),
    );
  }

  IconData _getIcon(String type) {
    if (type == LogTypes.daily) return Icons.today_rounded;
    if (type == LogTypes.weekly) return Icons.date_range_rounded;
    if (type == LogTypes.monthly) return Icons.calendar_view_month_rounded;
    return Icons.assignment_outlined;
  }

  Widget _statusBadge(String status) {
    final color = LogStatus.getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
      child: Text(
        _statusMap[status] ?? status,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _emptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.history_toggle_off_rounded, size: 70, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        const Text('কোন তথ্য পাওয়া যায়নি', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey)),
      ],
    ),
  );

  Widget _errorState(String e) => Center(child: Padding(padding: const EdgeInsets.all(20), child: Text(e, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center)));

  String _formatTime(dynamic ts) {
    if (ts is Timestamp) {
      final d = ts.toDate();
      return '${d.day}/${d.month}/${d.year}';
    }
    return '-';
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: AppAssets.tealWater)),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        _range = picked;
        _refreshQuery();
      });
    }
  }
}