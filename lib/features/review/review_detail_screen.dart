import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/firebase_refs.dart';
import '../../services/review_service.dart';
import '../../stores/session_store.dart'; // Ensure this is imported
import '../logs/view/log_view_screen.dart';

class ReviewDetailScreen extends StatefulWidget {
  final String logId;
  const ReviewDetailScreen({super.key, required this.logId});

  @override
  State<ReviewDetailScreen> createState() => _ReviewDetailScreenState();
}

class _ReviewDetailScreenState extends State<ReviewDetailScreen> {
  bool _busy = false;

  static const Color tealWater = Color(0xFF0B6E69);
  static const Color surfaceGray = Color(0xFFF8F9FA);

  Future<void> _submit(Map<String, dynamic> log) async {
    setState(() => _busy = true);
    try {
      await ReviewService().submitLog(
        logId: widget.logId,
        operatorUid: log['userId'] ?? '',
        logType: log['logType'] ?? '',
        periodKey: log['periodKey'] ?? '',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Log Approved Successfully ✅'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionStore.instance.currentUser;

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: logsRef.doc(widget.logId).get(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(child: Text('Error: ${snap.error}')),
          );
        }
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: tealWater)));
        }

        final doc = snap.data!;
        if (!doc.exists || doc.data() == null) {
          return const Scaffold(body: Center(child: Text('Log not found.')));
        }

        final log = doc.data()!;
        final status = (log['status'] ?? 'Pending').toString();

        return Scaffold(
          backgroundColor: surfaceGray,
          appBar: AppBar(
            backgroundColor: const Color(0xFFF5F5F5),
            foregroundColor: Colors.black87,
            elevation: 0.5,
            toolbarHeight: 95,
            centerTitle: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
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
                        size: 28,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // --- RESTORED 3-LINE TEXT LAYOUT ---
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Review Detail',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        user?.name ?? 'Unknown User',
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
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              _buildHeaderCard(log, status),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  'LOG SUBMISSION DATA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.blueGrey,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              // Main content area
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withOpacity(0.05)),
                ),
                clipBehavior: Clip.antiAlias,
                child: LogViewScreen(logId: widget.logId),
              ),
              const SizedBox(height: 100),
            ],
          ),
          bottomNavigationBar: _buildBottomActions(log, status),
        );
      },
    );
  }

  Widget _buildHeaderCard(Map<String, dynamic> log, String status) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoColumn('DISTRICT', log['districtId'] ?? 'N/A'),
              _buildStatusBadge(status),
            ],
          ),
          const Divider(height: 32, thickness: 0.8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoColumn('LOG TYPE', log['logType']?.toString().toUpperCase() ?? 'N/A'),
              _buildInfoColumn('PERIOD', log['periodKey'] ?? 'N/A'),
            ],
          ),
          if ((log['rejectReason'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Rejection Reason: ${log['rejectReason']}',
                      style: TextStyle(color: Colors.red.shade800, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.blueGrey, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'approved': color = Colors.green; break;
      case 'rejected': color = Colors.red; break;
      case 'locked': color = Colors.blueGrey; break;
      default: color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
      ),
    );
  }

  Widget _buildBottomActions(Map<String, dynamic> log, String status) {
    if (status.toLowerCase() == 'approved') return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, -5))],
      ),
      child: ElevatedButton(
        onPressed: _busy ? null : () => _submit(log),
        style: ElevatedButton.styleFrom(
          backgroundColor: tealWater,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _busy
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : const Text(
          'APPROVE SUBMISSION',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1),
        ),
      ),
    );
  }
}