import 'package:flutter/material.dart';
// ignore_for_file: constant_identifier_names

class AppAssets {
  static const String logo = 'assets/images/app_logo.png';
  static const Color bdGreen = Color(0xFF006A4E);
  static const Color bdRed = Color(0xFFF42A41);
  static const Color tealWater = Color(0xFF0B6E69);
}

class Collections {
  static const users = 'users';
  static const logs = 'logs';
  static const formTemplates = 'formTemplates';
  static const roles = 'roles';
  static const districts = 'districts';
}

/// ১. LogTypes: এটি শুধুমাত্র টাইম পিরিয়ড নির্দেশ করবে
class LogTypes {
  static const daily = 'daily';
  static const weekly = 'weekly';
  static const monthly = 'monthly';
  static const quarterly = 'quarterly';
  static const halfYearly = 'half_yearly';
  static const yearly = 'yearly';

  static const all = [daily, weekly, monthly, quarterly, halfYearly, yearly];
}

/// ২. EventTypes: এটি রিপোর্ট বা ফর্মের ধরন নির্দেশ করবে
class EventTypes {
  static const general = 'general';
  static const flooded = 'flooded';
  static const new_connection = 'new_connection';
// treatment_plant removed as per instruction
}

/// ৩. RoleIds: আপনার ডাটাবেসের roleId ফিল্ডের সাথে মিলবে (সঠিক জায়গা)
class RoleIds {
  static const admin = 'admin';
  static const supervisor = 'supervisor';
  static const pump_operator = 'pump_operator';
  static const pipeline_mechanic = 'pipeline_mechanic';
  static const wtp_operator = 'wtp_operator';
  static const sanitary_inspector = 'sanitary_inspector';
  static const bill_distributor = 'bill_distributor';
}

class LogStatus {
  static const pending = 'Pending';
  static const approved = 'Approved';
  static const rejected = 'Rejected';
  static const locked = 'Locked';

  static Color getStatusColor(String status) {
    switch (status) {
      case approved:
        return AppAssets.bdGreen;
      case rejected:
        return AppAssets.bdRed;
      case locked:
        return Colors.blueGrey;
      case pending:
      default:
        return const Color(0xFFF9A825);
    }
  }
}