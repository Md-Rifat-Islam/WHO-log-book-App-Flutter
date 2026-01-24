import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for TextInput
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../../core/constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _auth = AuthService();

  bool _loading = false;
  bool _obscurePass = true;
  String? _error;

  static const Color tealWater = Color(0xFF0B6E69);

  @override
  void initState() {
    super.initState();
    _loadSavedEmail(); // Load the email when screen opens
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // --- LOGIC: Load Email from Local Storage ---
  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('remembered_email');
    if (savedEmail != null && mounted) {
      setState(() {
        _emailCtrl.text = savedEmail;
      });
    }
  }

  // --- LOGIC: Save Email to Local Storage ---
  Future<void> _saveEmailLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('remembered_email', _emailCtrl.text.trim());
  }

  Future<void> _login() async {
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _error = "প্রবেশ করতে ইমেল এবং পাসওয়ার্ড দিন");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _auth.signInWithEmailPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );

      // On Success, save the email for next time
      await _saveEmailLocally();

      // Force the OS to ask to save credentials
      TextInput.finishAutofillContext();

    } catch (e) {
      setState(() => _error = "ইমেল বা পাসওয়ার্ড সঠিক নয়");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF7F8FA);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              // AutofillGroup allows the OS to group email and password together
              child: AutofillGroup(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // --- LOGO SECTION ---
                    Container(
                      height: 120, width: 120,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20, offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          AppAssets.logo,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.account_balance_rounded,
                            size: 50, color: tealWater,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'WHO Logbook',
                      style: TextStyle(
                        fontSize: 26, fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3142), letterSpacing: 0.5,
                      ),
                    ),
                    const Text(
                      'Sign in to continue',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 40),

                    // Email Field with Autofill
                    TextField(
                      controller: _emailCtrl,
                      autofillHints: const [AutofillHints.email],
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: _inputStyle('Email Address', Icons.email_outlined),
                    ),
                    const SizedBox(height: 16),

                    // Password Field with Autofill
                    TextField(
                      controller: _passCtrl,
                      obscureText: _obscurePass,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _login(),
                      decoration: _inputStyle('Password', Icons.lock_outline).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePass ? Icons.visibility_off : Icons.visibility,
                            color: tealWater.withOpacity(0.7),
                          ),
                          onPressed: () => setState(() => _obscurePass = !_obscurePass),
                        ),
                      ),
                    ),

                    if (_error != null) _buildErrorWidget(),

                    const SizedBox(height: 32),
                    _buildSignInButton(),
                  ],
                ),
              ),
            ),
          ),
          if (_loading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.4),
      width: double.infinity, height: double.infinity,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: ClipOval(
                child: Image.asset(AppAssets.logo, width: 60, height: 60, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
            const SizedBox(height: 15),
            const Text(
              'প্রবেশ করা হচ্ছে...',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignInButton() {
    return SizedBox(
      width: double.infinity, height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(colors: [tealWater, tealWater.withOpacity(0.85)]),
          boxShadow: [
            BoxShadow(
              color: tealWater.withOpacity(0.3),
              blurRadius: 12, offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _loading ? null : _login,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text(
            'SIGN IN',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
      prefixIcon: Icon(icon, color: tealWater),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: tealWater, width: 2),
      ),
    );
  }
}