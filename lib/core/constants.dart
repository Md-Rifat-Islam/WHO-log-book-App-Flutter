import 'package:flutter/material.dart';

/// Asset and Brand Colors
class AppAssets {
  static const String logo = 'assets/images/app_logo.png';

  // Bangladesh Flag Inspired Branding
  static const Color bdGreen = Color(0xFF006A4E);
  static const Color bdRed = Color(0xFFF42A41);
  static const Color tealWater = Color(0xFF0B6E69);
}

/// Firestore Collection Names
class Collections {
  static const users = 'users';
  static const logs = 'logs';
  static const formTemplates = 'formTemplates';
  static const roles = 'roles';
  static const districts = 'districts';
}

/// Types of Logs (Mapped to official WHO Water Safety Plan categories)
class LogTypes {
  static const daily = 'daily';
  static const weekly = 'weekly';
  static const monthly = 'monthly';
  static const quarterly = 'quarterly';
  static const halfYearly = 'half_yearly';
  static const yearly = 'yearly';

  // Specialized Operational Logs
  static const flood = 'flood';             // বন্যাকালীন লগ
  static const newConnection = 'new_conn';  // নতুন সংযোগ লগ
  static const treatmentPlant = 'wtp_log';  // পানি শোধন প্ল্যান্ট লগ

  static const all = [
    daily, weekly, monthly, quarterly,
    halfYearly, yearly, flood, newConnection, treatmentPlant
  ];
}

/// Status of a Log Entry
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
        return const Color(0xFFF9A825); // Elegant Amber
    }
  }
}

/// Designation-based Event Types
class EventTypes {
  static const general = 'general';
  static const pumpOperator = 'pump_operator';
  static const pipelineMechanic = 'pipeline_mechanic';
  static const sanitaryInspector = 'sanitary_inspector';
  static const billDistributor = 'bill_distributor';
  static const waterSuperintendent = 'water_superintendent';
  static const plantOperator = 'plant_operator';
}