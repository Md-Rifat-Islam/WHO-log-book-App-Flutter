import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants.dart';
import '../core/firebase_refs.dart';

class ReviewService {
  Future<void> submitLog({
    required String logId,
    required String operatorUid,
    required String logType,
    required String periodKey,
  }) async {
    // Automatically approve the log when submitted
    await logsRef.doc(logId).update({
      'status': LogStatus.approved,  // Automatically approve
      'reviewedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Send notification to operator
    await FirebaseFirestore.instance.collection('notifications').doc(operatorUid)
        .collection('items').add({
      'title': 'লগ অনুমোদিত ✅',
      'body': 'আপনার $logType লগ ($periodKey) সফলভাবে জমা হয়েছে।',
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
      'logId': logId,
      'logType': logType,
      'periodKey': periodKey,
      'status': LogStatus.approved,
    });
  }
}
