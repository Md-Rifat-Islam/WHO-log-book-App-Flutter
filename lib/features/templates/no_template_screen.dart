import 'package:flutter/material.dart';

class NoTemplateScreen extends StatelessWidget {
  final String logType;
  final String eventType;

  const NoTemplateScreen({
    super.key,
    required this.logType,
    required this.eventType,
  });

  // Project Theme Color
  static const Color tealWater = Color(0xFF0B6E69);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('ফর্ম পাওয়া যায়নি', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: tealWater,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Visual Indicator
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: tealWater.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.assignment_late_outlined,
                  size: 80,
                  color: tealWater,
                ),
              ),
              const SizedBox(height: 32),

              // Main Message
              const Text(
                'এই ক্যাটাগরির জন্য কোনো ফর্ম নির্ধারিত নেই',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3142),
                ),
              ),
              const SizedBox(height: 12),

              // Detail Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _detailRow('Log Type', logType.toUpperCase()),
                    const Divider(),
                    _detailRow('Event', eventType.toUpperCase()),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Action Instruction
              const Text(
                'নতুন ফর্ম সেটআপ করতে অথবা অ্যাক্সেস পেতে অনুগ্রহ করে আপনার অ্যাডমিন বা সুপারভাইজারের সাথে যোগাযোগ করুন।',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              // Back Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: tealWater),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'ফিরে যান',
                    style: TextStyle(color: tealWater, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}