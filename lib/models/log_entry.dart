import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/constants.dart';

class LogEntry {
  final String logId;
  final String userId;
  final String roleId;
  final String districtId;
  final String logType;
  final String eventType;
  final String periodKey;
  final String templateId;
  final int version;
  final Map<String, dynamic> data;
  final String status;
  final DateTime? createdAt;
  final String? rejectReason; // Added for the review workflow

  LogEntry({
    required this.logId,
    required this.userId,
    required this.roleId,
    required this.districtId,
    required this.logType,
    required this.eventType,
    required this.periodKey,
    required this.templateId,
    required this.version,
    required this.data,
    required this.status,
    this.createdAt,
    this.rejectReason,
  });

  factory LogEntry.fromMap(String id, Map<String, dynamic> m) {
    final ts = m['createdAt'];
    return LogEntry(
      logId: id,
      userId: (m['userId'] ?? '').toString(),
      roleId: (m['roleId'] ?? '').toString(),
      districtId: (m['districtId'] ?? '').toString(),
      logType: (m['logType'] ?? '').toString(),
      eventType: (m['eventType'] ?? 'general').toString(),
      periodKey: (m['periodKey'] ?? '').toString(),
      templateId: (m['formTemplateId'] ?? '').toString(),
      version: (m['formVersion'] is int) ? m['formVersion'] as int : 1,
      data: (m['data'] is Map) ? Map<String, dynamic>.from(m['data']) : {},
      status: (m['status'] ?? LogStatus.pending).toString(),
      createdAt: (ts is Timestamp) ? ts.toDate() : null,
      rejectReason: m['rejectReason']?.toString(),
    );
  }

  // --- HELPERS ---

  bool get isApproved => status == LogStatus.approved;
  bool get isRejected => status == LogStatus.rejected;
  bool get isPending => status == LogStatus.pending;

  /// Returns the color associated with the current status
  Color get statusColor {
    switch (status) {
      case LogStatus.approved: return Colors.green;
      case LogStatus.rejected: return Colors.red;
      default: return Colors.orange;
    }
  }

  // --- UTILITIES ---

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'roleId': roleId,
      'districtId': districtId,
      'logType': logType,
      'eventType': eventType,
      'periodKey': periodKey,
      'formTemplateId': templateId,
      'formVersion': version,
      'data': data,
      'status': status,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'rejectReason': rejectReason,
    };
  }
}