import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../core/firebase_refs.dart';
import '../core/time_period.dart';
import '../models/app_user.dart';
import '../models/form_template.dart';

class LogService {
  Future<void> submitLog({
    required AppUser user,
    required FormTemplate template,
    required String logType,
    required String eventType,
    required Map<String, dynamic> data,
  }) async {
    final now = DateTime.now();
    final periodKey = TimePeriod.makePeriodKey(logType, now);

    final logId = TimePeriod.makeLogId(
      uid: user.uid,
      districtId: user.districtId ?? 'unknown',
      logType: logType,
      eventType: eventType,
      periodKey: periodKey,
    );

    final docRef = logsRef.doc(logId);

    // Dynamic Logic: Auto-approve if the submitter is an Admin or Supervisor
    final isAdminOrSupervisor = user.roleId.toLowerCase() == 'admin' ||
        user.roleId.toLowerCase() == 'supervisor';

    final status = isAdminOrSupervisor ? LogStatus.approved : LogStatus.pending;

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // 1. Read check (within transaction to prevent race conditions)
        final snapshot = await transaction.get(docRef);
        if (snapshot.exists) {
          throw 'এই সময়ের জন্য ইতিমধ্যে লগ জমা হয়েছে ($periodKey)।';
        }

        // 2. Prepare Payload
        final payload = <String, dynamic>{
          'userId': user.uid,
          'userName': user.name,
          'roleId': user.roleId,
          'districtId': user.districtId,
          'logType': logType,
          'eventType': eventType,
          'periodKey': periodKey,
          'formTemplateId': template.id,
          'formVersion': template.version,
          'data': data,
          'status': status,
          'editable': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // 3. Write Log
        transaction.set(docRef, payload);

        // 4. Create Notification Reference
        final notificationRef = FirebaseFirestore.instance
            .collection('notifications')
            .doc(user.uid)
            .collection('items')
            .doc(); // Generate auto-ID

        // 5. Write Notification
        transaction.set(notificationRef, {
          'title': 'লগ জমা হয়েছে',
          'body': 'আপনার $logType (${template.titleBn}) সফলভাবে জমা হয়েছে।',
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
          'type': 'submission_success',
          'logId': logId,
          'status': status,
        });
      });

      if (kDebugMode) print("Transaction committed successfully");

    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print("Firebase Error Code: ${e.code}");
        print("Firebase Error Message: ${e.message}");
      }
      throw 'সার্ভার ত্রুটি: ${e.message}';
    } catch (e) {
      // Re-throw the custom duplicate message or others
      throw e.toString();
    }
  }
}