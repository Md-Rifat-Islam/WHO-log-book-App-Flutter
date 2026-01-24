import 'package:flutter/material.dart';

class AppLoader extends StatelessWidget {
  final String? message;
  const AppLoader({super.key, this.message});

  static const Color tealWater = Color(0xFF0B6E69);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // --- LOGO CONTAINER ---
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/app_logo.png',
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.water_drop_rounded,
                  color: tealWater,
                  size: 40,
                ),
              ),
            ),
          ),
          const SizedBox(height: 25),
          // --- PROGRESS INDICATOR ---
          const CircularProgressIndicator(
            color: tealWater,
            strokeWidth: 3,
          ),
          if (message != null) ...[
            const SizedBox(height: 15),
            Text(
              message!,
              style: TextStyle(
                color: tealWater.withOpacity(0.8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}