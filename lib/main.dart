import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';        // ← ADD IF MISSING
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';
import 'auth_service.dart';
import 'cart_service.dart';
import 'product_service.dart';
import 'order_service.dart';                                   // ← also make sure this is here
import 'package:flutter/foundation.dart' show kIsWeb;

// ============================================================
// TROLLEYMATE BRAND CONSTANTS
// ============================================================
class TMColors {
  static const primary = Color(0xFFF7C948);      // Primary Yellow
  static const accent = Color(0xFFFFD54F);       // Accent Yellow
  static const black = Color(0xFF000000);
  static const white = Color(0xFFFFFFFF);
  static const grey = Color(0xFF666666);
  static const lightGrey = Color(0xFFF8F9FC);
}

const String kBrandName = 'TrolleyMate';
const String kTagline = 'Scan. Shop. Skip the queue.';

// ============================================================
// TROLLEYMATE LOGO — Icon Only (Yellow rounded square)
// ============================================================
class TrolleyMateLogo extends StatelessWidget {
  final double size;
  const TrolleyMateLogo({super.key, this.size = 100});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [TMColors.primary, TMColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.25),
        boxShadow: [
          BoxShadow(
            color: TMColors.primary.withAlpha(100),
            blurRadius: size * 0.15,
            offset: Offset(0, size * 0.05),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: size * 0.08,
            child: Icon(Icons.wifi,
                color: Colors.black.withAlpha(220), size: size * 0.26),
          ),
          Positioned(
            bottom: size * 0.12,
            left: size * 0.12,
            child:
                Icon(Icons.shopping_cart, color: Colors.black, size: size * 0.48),
          ),
          Positioned(
            bottom: size * 0.14,
            right: size * 0.14,
            child: Transform.rotate(
              angle: 0.2,
              child: Container(
                width: size * 0.26,
                height: size * 0.38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border:
                      Border.all(color: Colors.black, width: size * 0.025),
                  borderRadius: BorderRadius.circular(size * 0.04),
                ),
                child: Center(
                  child: Icon(Icons.qr_code_2,
                      color: Colors.black, size: size * 0.18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TROLLEYMATE LOGO — Horizontal (icon + name + tagline)
// ============================================================
class TrolleyMateLogoHorizontal extends StatelessWidget {
  final double size;
  final bool showTagline;
  final bool light;
  const TrolleyMateLogoHorizontal({
    super.key,
    this.size = 60,
    this.showTagline = true,
    this.light = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = light ? Colors.white : Colors.black;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TrolleyMateLogo(size: size),
        SizedBox(width: size * 0.22),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(
                  fontSize: size * 0.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
                children: [
                  TextSpan(text: 'Trolley', style: TextStyle(color: textColor)),
                  const TextSpan(
                      text: 'Mate', style: TextStyle(color: TMColors.primary)),
                ],
              ),
            ),
            if (showTagline)
              Text(
                kTagline,
                style: GoogleFonts.poppins(
                  fontSize: size * 0.2,
                  color: light ? Colors.white70 : TMColors.grey,
                  letterSpacing: 0.2,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('🟢 STEP 1: Framework ready');

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 8));
    print('🟢 STEP 2: Firebase initialized OK');
  } catch (e) {
    print('🔴 STEP 2 FAILED: $e');
  }

  print('🟢 STEP 3: Calling runApp now');
  runApp(const MyApp());
  print('🟢 STEP 4: runApp finished');
}
// ============================================================
// MY APP
// ============================================================
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrolleyMate',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: TMColors.primary,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: TMColors.primary,
          primary: TMColors.primary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: false,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: TMColors.primary,
          unselectedItemColor: TMColors.grey,
          elevation: 8,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: TMColors.primary,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        useMaterial3: true,
      ),
      home: kIsWeb ? const BillingBoothScreen() : const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}
// ============================================================
// TROLLEY ENTRY SCREEN (after login)
// ============================================================
class TrolleyEntryScreen extends StatefulWidget {
  const TrolleyEntryScreen({super.key});

  @override
  State<TrolleyEntryScreen> createState() => _TrolleyEntryScreenState();
}

class _TrolleyEntryScreenState extends State<TrolleyEntryScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  String _error = '';

  Future<void> _confirm() async {
    final code = _codeController.text.trim();
    if (code.length != 4) {
      setState(() => _error = 'Enter a valid 4-digit trolley number');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    await CartService.instance.setTrolleyCode(code);
    await CartService.instance.refreshIdentity();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CustomerMainScreen()),
      );
    }
  }

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const TrolleyMateLogo(size: 100),
                const SizedBox(height: 24),
                Text(
                  'Enter Trolley Number',
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Type the 4-digit number printed\non your trolley',
                  style:
                      GoogleFonts.poppins(fontSize: 14, color: TMColors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 16,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '0000',
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.grey.shade300,
                      letterSpacing: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                if (_error.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(_error, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _confirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TMColors.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.black),
                          )
                        : Text(
                            'Start Shopping',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// AUTH WRAPPER (Firebase Auth)
// ============================================================
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _auth = AuthService();
  bool _isLoading = true;
  bool _isLoggedIn = false;
  String _userRole = 'customer';
  bool _hasTrolley = false;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  void _checkLogin() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _isLoading = false;
        });
      }
      return;
    }

    final profile = await _auth.getUserProfile();
    final prefs = await SharedPreferences.getInstance();
    final trolley = prefs.getString('trolleyCode');

    if (mounted) {
      setState(() {
        _isLoggedIn = true;
        _userRole = profile?['role'] ?? 'customer';
        _hasTrolley = trolley != null && trolley.length == 4;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_isLoggedIn) {
      return const LoginScreen();
    }
    if (_userRole == 'admin') {
      return const AdminMainScreen();
    }
    if (!_hasTrolley) {
      return const TrolleyEntryScreen();
    }
    return const CustomerMainScreen();
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;
  String _error = '';

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    final u = _userController.text.trim();
    final p = _passController.text.trim();

    if (u.isEmpty || p.isEmpty) {
      if (mounted) {
        setState(() {
          _error = 'Fill all fields';
          _isLoading = false;
        });
      }
      return;
    }

    // Admin hardcoded
    if (u == 'admin' && p == 'admin123') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userRole', 'admin');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminMainScreen()),
        );
      }
      return;
    }

    // Firebase login
    final error = await _auth.login(username: u, password: p);

    if (mounted) {
      if (error == null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userRole', 'customer');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
        );
      } else {
        setState(() {
          _error = error;
          _isLoading = false;
        });
      }
    }
  }

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const TrolleyMateLogo(size: 110),
                const SizedBox(height: 20),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.poppins(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                    children: const [
                      TextSpan(
                          text: 'Trolley', style: TextStyle(color: Colors.black)),
                      TextSpan(
                          text: 'Mate',
                          style: TextStyle(color: TMColors.primary)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  kTagline,
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: TMColors.grey, letterSpacing: 0.3),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _userController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16)),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passController,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16)),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SignupScreen()));
                      },
                      child: const Text('Create Account',
                          style: TextStyle(
                              color: TMColors.primary,
                              fontWeight: FontWeight.w600)),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const ForgotPasswordScreen()));
                      },
                      child: const Text('Forgot Password?',
                          style: TextStyle(color: TMColors.primary)),
                    ),
                  ],
                ),
                if (_error.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(_error,
                                style: const TextStyle(color: Colors.red))),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TMColors.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.black, strokeWidth: 2))
                        : Text('Log In',
                            style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SIGNUP SCREEN (Firebase Auth)
// ============================================================
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final AuthService _auth = AuthService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;
  String _error = '';
  String _selectedQuestion = '';
  final List<String> _securityQuestions = [
    'What is your favorite color?',
    'What is your pet\'s name?',
    'What is your mother\'s maiden name?',
    'What city were you born in?',
    'What is your favorite food?',
  ];

  @override
  void initState() {
    super.initState();
    _selectedQuestion = _securityQuestions.first;
  }

  Future<void> _signup() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();
    final answer = _answerController.text.trim();

    if (name.isEmpty || username.isEmpty || password.isEmpty ||
        confirm.isEmpty || answer.isEmpty) {
      setState(() {
        _error = 'Fill all fields';
        _isLoading = false;
      });
      return;
    }
    if (password != confirm) {
      setState(() {
        _error = 'Passwords do not match';
        _isLoading = false;
      });
      return;
    }
    if (password.length < 6) {
      setState(() {
        _error = 'Password must be at least 6 characters';
        _isLoading = false;
      });
      return;
    }
    if (username.length < 4) {
      setState(() {
        _error = 'Username must be at least 4 characters';
        _isLoading = false;
      });
      return;
    }

    final error = await _auth.signUp(
      fullName: name,
      username: username,
      password: password,
      securityQuestion: _selectedQuestion,
      securityAnswer: answer,
    );

    if (mounted) {
      if (error == null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userName', name);
        await prefs.setString('username', username);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created! Please login.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        setState(() {
          _error = error;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Account',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username (min 4 chars)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  prefixIcon: const Icon(Icons.account_circle_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Password (min 6 chars)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmController,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedQuestion,
                decoration: const InputDecoration(
                  labelText: 'Security Question',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                ),
                items: _securityQuestions
                    .map((q) => DropdownMenuItem(value: q, child: Text(q)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedQuestion = val);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _answerController,
                decoration: InputDecoration(
                  labelText: 'Answer',
                  hintText: 'Enter your answer (case sensitive)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  prefixIcon: const Icon(Icons.security),
                ),
              ),
              if (_error.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error, style: const TextStyle(color: Colors.red))),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF7C948),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.black))
                      : const Text('Create Account',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// FORGOT PASSWORD SCREEN (Firebase)
// ============================================================
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final AuthService _auth = AuthService();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();
  bool _isLoading = false;
  String _status = '';
  int _step = 0;
  String _storedQuestion = '';
  String _storedAnswer = '';
  String _username = '';

  Future<void> _checkUsername() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      setState(() => _status = 'Please enter your username');
      return;
    }

    setState(() {
      _isLoading = true;
      _status = '';
    });

    final data = await _auth.getSecurityQuestion(username);

    if (!mounted) return;

    if (data == null) {
      setState(() {
        _isLoading = false;
        _status = 'User not found';
      });
      return;
    }

    setState(() {
      _step = 1;
      _isLoading = false;
      _storedQuestion = data['question'] ?? '';
      _storedAnswer = data['answer'] ?? '';
      _username = username;
      _status = 'Please answer the security question';
    });
  }

  Future<void> _verifyAnswer() async {
    final answer = _answerController.text.trim();
    if (answer.isEmpty) {
      setState(() => _status = 'Please enter your answer');
      return;
    }
    if (answer.toLowerCase() != _storedAnswer.toLowerCase()) {
      setState(() => _status = 'Incorrect answer. Try again.');
      return;
    }

    // Success: notify admin (saved to SharedPreferences for admin to see)
    final prefs = await SharedPreferences.getInstance();
    final requests = prefs.getStringList('password_reset_requests') ?? [];
    requests.add('$_username|${DateTime.now().toString()}|verified');
    await prefs.setStringList('password_reset_requests', requests);

    if (!mounted) return;
    setState(() {
      _step = 2;
      _status = 'Answer correct! Request sent to admin for password reset.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Forgot Password',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_reset, size: 80, color: Color(0xFFF7C948)),
            const SizedBox(height: 20),
            Text(
              _step == 0
                  ? 'Enter your username'
                  : _step == 1
                      ? 'Answer Security Question'
                      : 'Request Sent to Admin',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            if (_step == 0) ...[
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _checkUsername,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF7C948),
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text('Next'),
              ),
            ] else if (_step == 1) ...[
              Text('Question: $_storedQuestion',
                  style: GoogleFonts.poppins(fontSize: 16)),
              const SizedBox(height: 16),
              TextField(
                controller: _answerController,
                decoration: InputDecoration(
                  labelText: 'Your Answer',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  prefixIcon: const Icon(Icons.security),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _verifyAnswer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF7C948),
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Verify'),
              ),
            ] else if (_step == 2) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 60),
                    const SizedBox(height: 12),
                    Text(
                      'Your password reset request has been sent to the admin.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please contact the admin to get your new password.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF7C948),
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Back to Login'),
              ),
            ],
            const SizedBox(height: 16),
            if (_step < 2)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Login'),
              ),
            if (_status.isNotEmpty && _step < 2)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _status,
                  style: TextStyle(
                    color: _status.contains('correct') || _status.contains('sent')
                        ? Colors.green
                        : Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CustomerMainScreen extends StatefulWidget {
  const CustomerMainScreen({super.key});

  @override
  State<CustomerMainScreen> createState() => _CustomerMainScreenState();
}

class _CustomerMainScreenState extends State<CustomerMainScreen> {
  int _selectedIndex = 0;
  final List<Widget> _screens = const [
    CustomerHomeScreen(),
    ControlScreen(),
    CartScreen(),
    CustomerProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), activeIcon: Icon(Icons.shopping_cart), label: 'Trolley'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_basket_outlined), activeIcon: Icon(Icons.shopping_basket), label: 'Cart'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  Map<String, List<Map<String, dynamic>>> _categories = {};
  final List<String> _selectedCategories = [];
  String _searchQuery = '';
  Map<String, Map<String, dynamic>> _cart = {};
  StreamSubscription? _cartSub;

  final CartService _cartService = CartService.instance;

    StreamSubscription? _prodSub;
  final ProductService _productService = ProductService.instance;

  @override
  void initState() {
    super.initState();
    _initCart();
    _prodSub = _productService.productsStream().listen((list) {
      if (!mounted) return;
      final Map<String, List<Map<String, dynamic>>> newCats = {};
      for (final p in list) {
        final cat = p['category'] as String? ?? 'Other';
        newCats.putIfAbsent(cat, () => []);
        newCats[cat]!.add({
          'name': p['name'],
          'price': p['price'],
          'emoji': p['emoji'],
          'unit': 'pcs',
          'barcode': p['barcode'],
        });
      }
      setState(() => _categories = newCats);
    });
  }

  Future<void> _initCart() async {
    await _cartService.init();
    await _cartService.refreshIdentity();
    _cartSub = _cartService.itemsStream.listen((items) {
      if (mounted) setState(() => _cart = items);
    });
    if (mounted) setState(() => _cart = _cartService.items);
  }

  @override
  void dispose() {
    _cartSub?.cancel();
    _prodSub?.cancel();
    super.dispose();
  }

  Future<void> _addToCart(Map<String, dynamic> product) async {
    await _cartService.addItem(
      product['name'],
      product['price'] as int,
      product['emoji'] as String,
    );
    _showSnackbar('${product['name']} added', Colors.green);
  }

  Future<void> _removeFromCart(String productName) async {
    await _cartService.removeItem(productName);
    _showSnackbar('$productName removed', Colors.orange);
  }

  void _showSnackbar(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        duration: const Duration(milliseconds: 500),
        behavior: SnackBarBehavior.floating,
      ),
      
    );
  }
    Map<String, dynamic>? _findByBarcode(String code) {
    final normalized = code.trim();
    if (normalized.isEmpty) return null;

    debugPrint('🔍 Looking for barcode: "$normalized"');
    debugPrint('   Total products: ${_allProducts.length}');

    for (final p in _allProducts) {
      final stored = (p['barcode'] ?? '').toString().trim();
      if (stored.isEmpty) continue;
      debugPrint('   compare "$stored" (${p['name']})');
      if (stored == normalized) {
        debugPrint('   ✅ MATCH!');
        return p;
      }
    }
    debugPrint('   ❌ No match found');
    return null;
  }

    Future<void> _scanAndAdd() async {
    // ✅ Reload products first so newly added ones are found

    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ScanScreen()),
    );
    if (code == null || code.isEmpty) return;

    final product = _findByBarcode(code);
    if (product == null) {
      _showSnackbar('❌ No product for barcode: $code', Colors.red);
      return;
    }

    await _addToCart(product);
    _showSnackbar('✅ Scanned: ${product['name']}', Colors.green);
  }
  List<Map<String, dynamic>> get _allProducts =>
      _categories.values.expand((list) => list).toList();

  List<Map<String, dynamic>> get _filteredProducts {
    return _allProducts.where((product) {
      final nameMatch =
          product['name'].toLowerCase().contains(_searchQuery.toLowerCase());
      final categoryMatch = _selectedCategories.isEmpty ||
          _categories.entries.any((entry) =>
              entry.value.contains(product) &&
              _selectedCategories.contains(entry.key));
      return nameMatch && categoryMatch;
    }).toList();
  }
  

  List<String> get _categoryNames => _categories.keys.toList();

  int getTotalItems() => _cart.values.fold(0, (s, e) => s + (e['qty'] as int));
  double getTotalPrice() => _cart.values
      .fold(0.0, (s, e) => s + (e['price'] as int) * (e['qty'] as int));

  void _toggleCategory(String category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        _selectedCategories.add(category);
      }
    });
  }

  void _showCartBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheet) {
          final items = _cartService.items;
          return Container(
            padding: const EdgeInsets.all(20),
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                    child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Text('Your Cart',
                    style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black)),
                const SizedBox(height: 16),
                Expanded(
                  child: items.isEmpty
                      ? Center(
                          child: Text('Cart is empty',
                              style: GoogleFonts.poppins(
                                  fontSize: 16, color: Colors.grey)))
                      : ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (ctx, index) {
                            final key = items.keys.elementAt(index);
                            final item = items[key]!;
                            return ListTile(
                              leading: Text(item['emoji'] ?? '🛒',
                                  style: const TextStyle(fontSize: 28)),
                              title: Text(key,
                                  style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500)),
                              subtitle: Text(
                                  '₹${item['price']} x ${item['qty']}'),
                              trailing: Text(
                                  '₹${(item['price'] as int) * (item['qty'] as int)}',
                                  style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            );
                          },
                        ),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total: ₹${_cartService.totalPrice.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                                        ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);

                        // ✅ Save order to Firebase BEFORE clearing cart
                        if (_cartService.items.isNotEmpty) {
                          await OrderService.instance.saveOrder(
                            username: _cartService.username,
                            trolleyCode: _cartService.trolleyCode,
                            items: _cartService.itemList,
                            total: _cartService.totalPrice,
                            status: 'completed',
                          );
                        }

                        await _cartService.markPaid();
                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const OrderConfirmationScreen()),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF7C948),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Checkout'),
                    ),
                  ],
                ),
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredProducts;
    final totalItems = getTotalItems();
    final totalPrice = getTotalPrice();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
            appBar: AppBar(
        title: Row(
          children: [
            const TrolleyMateLogoHorizontal(size: 36, showTagline: false),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF7C948).withAlpha(40),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.confirmation_number_outlined,
                      size: 14, color: Colors.black),
                  const SizedBox(width: 4),
                  Text('Trolley ${_cartService.trolleyCode}',
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.black)),
                ],
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Colors.black),
            tooltip: 'Scan barcode',
            onPressed: _scanAndAdd,
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_basket_outlined,
                    color: Colors.black),
                onPressed: () => _showCartBottomSheet(context),
              ),
              if (totalItems > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: Color(0xFFF7C948), shape: BoxShape.circle),
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text('$totalItems',
                        style: const TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categoryNames.length,
              itemBuilder: (context, index) {
                final category = _categoryNames[index];
                final isSelected = _selectedCategories.contains(category);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _toggleCategory(category),
                    child: Chip(
                      label: Text(category),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      backgroundColor:
                          isSelected ? const Color(0xFFF7C948) : Colors.white,
                      side: BorderSide(
                          color: isSelected
                              ? const Color(0xFFF7C948)
                              : Colors.grey.shade300),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('No products found',
                        style: TextStyle(color: Colors.grey)))
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final product = filtered[index];
                      final productName = product['name']!;
                      final qty =
                          _cart[productName]?['qty'] as int? ?? 0;
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.grey.shade100,
                                blurRadius: 8,
                                offset: const Offset(0, 4))
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(40),
                              ),
                              child: Text(product['emoji'],
                                  style: const TextStyle(fontSize: 40)),
                            ),
                            const SizedBox(height: 8),
                            Text(productName,
                                style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            Text('₹${product['price']}/${product['unit']}',
                                style: GoogleFonts.poppins(
                                    fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 8),
                            Container(
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (qty > 0)
                                    GestureDetector(
                                      onTap: () =>
                                          _removeFromCart(productName),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                            color: Color(0xFFF7C948),
                                            shape: BoxShape.circle),
                                        child: const Icon(Icons.remove,
                                            size: 16, color: Colors.black),
                                      ),
                                    ),
                                  if (qty > 0) ...[
                                    const SizedBox(width: 8),
                                    Text('$qty',
                                        style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () => _addToCart(product),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                          color: Color(0xFFF7C948),
                                          shape: BoxShape.circle),
                                      child: const Icon(Icons.add,
                                          size: 16, color: Colors.black),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: totalItems > 0
          ? FloatingActionButton.extended(
              onPressed: () => _showCartBottomSheet(context),
              backgroundColor: const Color(0xFFF7C948),
              foregroundColor: Colors.black,
              icon: const Icon(Icons.shopping_basket),
              label:
                  Text('₹${totalPrice.toStringAsFixed(0)}  •  $totalItems items'),
              elevation: 8,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController _scanner = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _handled = false;

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan Barcode'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scanner,
            errorBuilder: (context, error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.no_photography,
                          color: Colors.white, size: 60),
                      const SizedBox(height: 16),
                      Text(
                        'Camera error:\n${error.errorCode}',
                        style: const TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tip: On web, allow camera permission.\nUse localhost or HTTPS.',
                        style: TextStyle(
                            color: Colors.white38, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
            onDetect: (capture) {
              if (_handled) return;
              if (capture.barcodes.isEmpty) return;
              final raw = capture.barcodes.first.rawValue;
              if (raw == null || raw.isEmpty) return;
              _handled = true;
              if (mounted) Navigator.pop(context, raw);
            },
          ),
          Center(
            child: Container(
              width: 250,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(
                    color: const Color(0xFFF7C948), width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Align barcode within the frame',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  RawDatagramSocket? _socket;
  String _status = 'Disconnected';
  final String _ipAddress = '192.168.4.1';
  final int _port = 1234;
  bool _isConnected = false;
  String _lastCommand = 'None';
  double _speed = 0.5;
  String _trolleyId = 'T-001';

  @override
  void initState() {
    super.initState();
    _connect();
    _loadTrolleyId();
  }

  Future<void> _loadTrolleyId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _trolleyId = prefs.getString('trolleyId') ?? 'T-001';
    });
  }

  void _connect() async {
    if (mounted) {
      setState(() => _status = 'Connecting...');
    }
    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      if (mounted) {
        setState(() {
          _isConnected = true;
          _status = '✅ Connected to ESP32';
        });
      }
      _sendCommand('S');
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnected = false;
          _status = '❌ Error: ${e.toString()}';
        });
      }
    }
  }

  void _sendCommand(String cmd) {
    if (_socket == null || !_isConnected) {
      if (mounted) {
        setState(() => _status = '⚠️ Not connected');
      }
      return;
    }
    try {
      final List<int> data = cmd.codeUnits;
      int bytesSent = _socket!.send(data, InternetAddress(_ipAddress), _port);
      if (mounted) {
        setState(() {
          _lastCommand = cmd;
          _status = '📨 $cmd (${bytesSent}B)';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _status = '❌ Send error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trolley Control', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isConnected ? Colors.green.shade100 : Colors.red.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: _isConnected ? Colors.green : Colors.red, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(
                  _isConnected ? 'ONLINE' : 'OFFLINE',
                  style: TextStyle(
                    color: _isConnected ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Icon(Icons.shopping_cart, color: Color(0xFFF7C948)),
                        const SizedBox(height: 4),
                        Text('Trolley ID', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                        Text(_trolleyId, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      children: [
                        Icon(_isConnected ? Icons.wifi : Icons.wifi_off, color: const Color(0xFFF7C948)),
                        const SizedBox(height: 4),
                        Text('Status', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                        Text(
                          _isConnected ? 'Connected' : 'Disconnected',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _isConnected ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const Icon(Icons.battery_std, color: Color(0xFFF7C948)),
                        const SizedBox(height: 4),
                        Text('Battery', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                        Text('85%', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(_status, style: TextStyle(fontSize: 16, color: _isConnected ? Colors.green : Colors.red)),
                    const SizedBox(height: 4),
                    Text('Last: $_lastCommand', style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.speed, color: Color(0xFFF7C948)),
                const SizedBox(width: 8),
                Expanded(
                  child: Slider(
                    value: _speed,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    activeColor: const Color(0xFFF7C948),
                    onChanged: (val) => setState(() => _speed = val),
                  ),
                ),
                Text('${(_speed * 100).toInt()}%', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildButton('⬆', 'F', Colors.green),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildButton('⬅', 'L', Colors.orange),
                const SizedBox(width: 40),
                _buildButton('⬇', 'B', Colors.red),
                const SizedBox(width: 40),
                _buildButton('➡', 'R', Colors.blue),
              ],
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _connect,
              icon: const Icon(Icons.wifi, size: 24),
              label: const Text('Connect to ESP32'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF7C948),
                foregroundColor: Colors.black,
                minimumSize: const Size(250, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _sendCommand('S'),
              icon: const Icon(Icons.stop, size: 24, color: Colors.white),
              label: const Text('Emergency Stop'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(String label, String cmd, Color color) {
    return GestureDetector(
      onTapDown: (_) => _sendCommand(cmd),
      onTapUp: (_) => _sendCommand('S'),
      child: Container(
        margin: const EdgeInsets.all(8),
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: color.withAlpha(80), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(fontSize: 32, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                      color: TMColors.primary, shape: BoxShape.circle),
                  child:
                      const Icon(Icons.check, color: Colors.white, size: 80),
                ),
                const SizedBox(height: 24),
                Text(
                  'Checkout Successful! 🎉',
                  style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please proceed to the billing booth\nfor payment.',
                  style:
                      GoogleFonts.poppins(fontSize: 16, color: TMColors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Order ID: #ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(8, 12)}',
                  style: GoogleFonts.poppins(
                      fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await CartService.instance.clear();
                      if (context.mounted) {
                        Navigator.popUntil(
                            context, (route) => route.isFirst);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TMColors.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text('Continue Shopping',
                        style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService.instance;
  StreamSubscription? _sub;
  Map<String, Map<String, dynamic>> _items = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _cartService.init();
    _sub = _cartService.itemsStream.listen((items) {
      if (mounted) setState(() => _items = items);
    });
    if (mounted) setState(() => _items = _cartService.items);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _removeItem(String name) async {
    await _cartService.removeItem(name);
  }

  Future<void> _clearCart() async {
    await _cartService.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('My Cart',
              style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                    color: Colors.grey.shade100, shape: BoxShape.circle),
                child: const Icon(Icons.shopping_basket_outlined,
                    size: 60, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Text('Your cart is empty',
                  style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: Colors.black)),
              const SizedBox(height: 8),
              Text('Add items from the Home tab',
                  style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
      );
    }

    final total = _cartService.totalPrice;
    final totalQty = _cartService.totalItems;

    return Scaffold(
      appBar: AppBar(
        title: Text('My Cart ($totalQty items)',
            style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Clear Cart'),
                  content: const Text('Remove all items from cart?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel')),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _clearCart();
                      },
                      style:
                          TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final key = _items.keys.elementAt(index);
                final item = _items[key]!;
                final qty = item['qty'] as int;
                final price = item['price'] as int;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.grey.shade100,
                          blurRadius: 4,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(item['emoji'] ?? '🛒',
                          style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(key,
                                style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black)),
                            Text('₹${qty * price} ($qty × ₹$price)',
                                style: GoogleFonts.poppins(
                                    fontSize: 14, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => _removeItem(key),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                  color: Color(0xFFF7C948),
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.remove,
                                  size: 16, color: Colors.black),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('$qty',
                              style: GoogleFonts.poppins(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () async {
                              await _cartService.addItem(
                                  key, price, item['emoji'] as String);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                  color: Color(0xFFF7C948),
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.add,
                                  size: 16, color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 8,
                    offset: const Offset(0, -4))
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total: ₹${total.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black)),
                    Text('$totalQty items',
                        style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
                                ElevatedButton(
                  onPressed: () async {
                    // ✅ Save order to Firebase BEFORE clearing
                    if (_cartService.items.isNotEmpty) {
                      await OrderService.instance.saveOrder(
                        username: _cartService.username,
                        trolleyCode: _cartService.trolleyCode,
                        items: _cartService.itemList,
                        total: _cartService.totalPrice,
                        status: 'completed',
                      );
                    }

                    await _cartService.markPaid();
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const OrderConfirmationScreen()),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF7C948),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Checkout',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}


class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  final AuthService _auth = AuthService();
  String _userName = 'Customer';
  String _username = '';
  String _email = '';
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = _auth.currentUser;
    final profile = await _auth.getUserProfile();
    if (mounted) {
      setState(() {
        _userName = profile?['name'] ?? user?.displayName ?? 'Customer';
        _username = profile?['username'] ?? '';
        _email = user?.email ?? '';
      });
    }
  }

  Future<void> _editName() async {
    _nameController.text = _userName;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Name',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(
              hintText: 'Enter your name', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (_nameController.text.trim().isNotEmpty) {
                Navigator.pop(ctx, _nameController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF7C948)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await _auth.updateName(result);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', result);
      if (mounted) setState(() => _userName = result);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // Clear cart on logout
    await CartService.instance.clear();
    await CartService.instance.clearTrolleyCode();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await _auth.logout();

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile',
            style: GoogleFonts.poppins(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFFF7C948), Color(0xFFFFD54F)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.person, color: Colors.black, size: 40),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_userName,
                          style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black)),
                      Text('@$_username',
                          style: GoogleFonts.poppins(
                              fontSize: 14, color: Colors.black87)),
                      if (_email.isNotEmpty)
                        Text(_email,
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: Colors.black54)),
                    ],
                  ),
                ),
                IconButton(
                    icon: const Icon(Icons.edit, color: Colors.black),
                    onPressed: _editName),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Column(
                children: [
                  _buildMenuItem(Icons.history, 'Order History', () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const OrderHistoryScreen()));
                  }),
                  _buildDivider(),
                  _buildMenuItem(Icons.payment, 'Payment Methods', () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PaymentMethodsScreen()));
                  }),
                  _buildDivider(),
                  _buildMenuItem(Icons.contact_mail, 'Contact Us', () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ContactUsScreen()));
                  }),
                  _buildDivider(),
                  _buildMenuItem(Icons.logout, 'Logout', _logout,
                      isLogout: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap,
      {bool isLogout = false}) {
    return ListTile(
      leading: Icon(icon,
          color: isLogout ? Colors.red : const Color(0xFFF7C948)),
      title: Text(title,
          style: GoogleFonts.poppins(
              color: isLogout ? Colors.red : Colors.black, fontSize: 16)),
      trailing: Icon(Icons.arrow_forward_ios,
          size: 16, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }

  Widget _buildDivider() => Divider(
      color: Colors.grey.shade200,
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16);
}

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendMessage() async {
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();
    if (subject.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill all fields'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final messages = prefs.getStringList('contact_messages') ?? [];
    final username = prefs.getString('username') ?? 'anonymous';
    messages.add('$username|$subject|$message|${DateTime.now().toString()}');
    await prefs.setStringList('contact_messages', messages);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message sent to admin!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Contact Us', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.contact_mail, size: 80, color: Color(0xFFF7C948)),
            const SizedBox(height: 20),
            TextField(
              controller: _subjectController,
              decoration: InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _sendMessage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF7C948),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                    : const Text('Send Message', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  StreamSubscription? _sub;
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _sub = OrderService.instance.myOrdersStream().listen((list) {
      if (mounted) {
        setState(() {
          _orders = list;
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  String _formatDate(dynamic ts) {
    if (ts is Timestamp) {
      final d = ts.toDate();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${d.day} ${months[d.month - 1]} ${d.year}  •  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    return 'Just now';
  }

  Future<void> _reorder(Map<String, dynamic> order) async {
    final items = order['items'] as List<Map<String, dynamic>>;
    for (final item in items) {
      final qty = item['qty'] as int? ?? 1;
      for (int i = 0; i < qty; i++) {
        await CartService.instance.addItem(
          item['name'] as String,
          item['price'] as int,
          item['emoji'] as String? ?? '🛒',
        );
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${items.length} items added to cart'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    final items = order['items'] as List<Map<String, dynamic>>;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Order Details',
                style: GoogleFonts.poppins(
                    fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('#${order['id'].toString().substring(0, 8).toUpperCase()}',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.grey)),
            Text(_formatDate(order['createdAt']),
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 6),
            Text('Trolley ${order['trolleyCode']}',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.grey)),
            const Divider(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (ctx, i) {
                  final it = items[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Text(it['emoji'] ?? '🛒',
                        style: const TextStyle(fontSize: 26)),
                    title: Text(it['name'] ?? '',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500)),
                    subtitle: Text('₹${it['price']} × ${it['qty']}'),
                    trailing: Text(
                        '₹${(it['price'] as int) * (it['qty'] as int)}',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold)),
                  );
                },
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total',
                    style: GoogleFonts.poppins(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                Text('₹${(order['total'] as double).toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: TMColors.primary)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _reorder(order);
                },
                icon: const Icon(Icons.refresh),
                label: Text('Reorder',
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TMColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order History',
            style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle),
                        child: const Icon(Icons.receipt_long,
                            size: 60, color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      Text('No orders yet',
                          style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Text('Your completed orders will appear here',
                          style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    final isCompleted =
                        order['status'] == 'completed';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(14),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? Colors.green.shade50
                                : Colors.orange.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isCompleted
                                ? Icons.check_circle
                                : Icons.access_time,
                            color: isCompleted
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                        title: Text(
                            '#${order['id'].toString().substring(0, 8).toUpperCase()}',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(_formatDate(order['createdAt']),
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                            const SizedBox(height: 2),
                            Text(
                                '${order['itemCount']} items  •  ${order['status']}',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600)),
                          ],
                        ),
                        trailing: Text(
                            '₹${(order['total'] as double).toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        onTap: () => _showOrderDetails(order),
                      ),
                    );
                  },
                ),
    );
  }
}

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  List<Map<String, dynamic>> _cards = [];
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardNameController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  void _loadCards() async {
    final prefs = await SharedPreferences.getInstance();
    final cardsJson = prefs.getStringList('cards') ?? [];
    if (mounted) {
      setState(() {
        _cards = cardsJson.map((e) => Map<String, dynamic>.from({'card': e})).toList();
      });
    }
  }

  void _saveCards() async {
    final prefs = await SharedPreferences.getInstance();
    final cardsList = _cards.map((e) => e['card'] as String).toList();
    await prefs.setStringList('cards', cardsList);
  }

  void _addCard() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Card', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _cardNumberController,
              decoration: const InputDecoration(hintText: 'Card Number', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cardNameController,
              decoration: const InputDecoration(hintText: 'Name on Card', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _expiryController,
              decoration: const InputDecoration(hintText: 'MM/YY', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (_cardNumberController.text.isNotEmpty) {
                setState(() {
                  _cards.add({
                    'card': '**** ${_cardNumberController.text.substring(_cardNumberController.text.length - 4)}'
                  });
                });
                _saveCards();
                _cardNumberController.clear();
                _cardNameController.clear();
                _expiryController.clear();
                if (mounted) Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF7C948)),
            child: const Text('Add Card'),
          ),
        ],
      ),
    );
  }

  void _removeCard(int index) {
    setState(() {
      _cards.removeAt(index);
    });
    _saveCards();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment Methods', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: _addCard,
          ),
        ],
      ),
      body: _cards.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.credit_card, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No cards added',
                    style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text('Tap the + icon to add a card', style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _cards.length,
              itemBuilder: (context, index) {
                final card = _cards[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.credit_card, color: Color(0xFFF7C948)),
                      const SizedBox(width: 16),
                      Expanded(child: Text(card['card'] ?? '', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500))),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _removeCard(index),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// ============================================================
// ADMIN SCREENS
// ============================================================

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _selectedIndex = 0;
  final List<Widget> _screens = const [
    AdminDashboardScreen(),
    AdminUsersScreen(),
    AdminProductsScreen(),
    AdminMessagesScreen(),
    AdminProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), activeIcon: Icon(Icons.inventory_2), label: 'Products'),
          BottomNavigationBarItem(icon: Icon(Icons.message_outlined), activeIcon: Icon(Icons.message), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _userCount = 0;
  int _resetRequests = 0;
  int _productCount = 0;
  int _messageCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final users = prefs.getStringList('users') ?? [];
    final requests = prefs.getStringList('password_reset_requests') ?? [];
    final products = prefs.getStringList('products') ?? [];
    final messages = prefs.getStringList('contact_messages') ?? [];
    if (mounted) {
      setState(() {
        _userCount = users.length;
        _resetRequests = requests.length;
        _productCount = products.length;
        _messageCount = messages.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStatCard('Users', _userCount.toString(), Icons.people, Colors.blue),
                _buildStatCard('Products', _productCount.toString(), Icons.inventory_2, Colors.green),
                _buildStatCard('Reset Requests', _resetRequests.toString(), Icons.lock_reset, Colors.orange),
                _buildStatCard('Messages', _messageCount.toString(), Icons.message, Colors.purple),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recent Activity', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                    const SizedBox(height: 16),
                    if (_resetRequests > 0)
                      ListTile(
                        leading: const Icon(Icons.notifications, color: Color(0xFFF7C948)),
                        title: const Text('New password reset requests'),
                        subtitle: Text('$_resetRequests pending'),
                      )
                    else if (_messageCount > 0)
                      ListTile(
                        leading: const Icon(Icons.message, color: Color(0xFFF7C948)),
                        title: const Text('New contact messages'),
                        subtitle: Text('$_messageCount unread'),
                      )
                    else
                      const ListTile(
                        leading: Icon(Icons.check_circle, color: Colors.green),
                        title: Text('All clear!'),
                        subtitle: Text('No pending actions'),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<Map<String, String>> _users = [];
  List<Map<String, String>> _resetRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getStringList('users') ?? [];
    final requestsJson = prefs.getStringList('password_reset_requests') ?? [];

    List<Map<String, String>> users = [];
    for (var data in usersJson) {
      final parts = data.split('|');
      if (parts.length >= 3) {
        users.add({
          'username': parts[0],
          'password': parts[1],
          'role': parts[2],
          'question': parts.length > 3 ? parts[3] : '',
          'answer': parts.length > 4 ? parts[4] : '',
        });
      }
    }

    List<Map<String, String>> requests = [];
    for (var data in requestsJson) {
      final parts = data.split('|');
      if (parts.length >= 2) {
        requests.add({
          'username': parts[0],
          'time': parts[1],
        });
      }
    }

    if (mounted) {
      setState(() {
        _users = users;
        _resetRequests = requests;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteUser(String username) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete "$username"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      List<String> usersJson = prefs.getStringList('users') ?? [];
      usersJson.removeWhere((e) => e.startsWith('$username|'));
      await prefs.setStringList('users', usersJson);
      final requestsJson = prefs.getStringList('password_reset_requests') ?? [];
      requestsJson.removeWhere((e) => e.startsWith('$username|'));
      await prefs.setStringList('password_reset_requests', requestsJson);
      _loadData();
      if (!mounted) return;  
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User "$username" deleted'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _viewUserDetails(Map<String, String> user) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('User Details', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Username: ${user['username']}'),
            Text('Role: ${user['role']}'),
            Text('Security Question: ${user['question'] ?? 'N/A'}'),
            Text('Answer: ${user['answer'] ?? 'N/A'}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Users', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              labelColor: Colors.black,
              indicatorColor: const Color(0xFFF7C948),
              tabs: [
                Tab(text: 'Users (${_users.length})'),
                Tab(
                  text: 'Reset Requests (${_resetRequests.length})',
                  icon: _resetRequests.isNotEmpty ? const Icon(Icons.notifications, color: Colors.red) : null,
                ),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      final isAdmin = user['role'] == 'admin';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 4, offset: const Offset(0, 2))],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isAdmin ? Colors.orange.shade100 : Colors.blue.shade100,
                              child: Icon(
                                isAdmin ? Icons.admin_panel_settings : Icons.person,
                                color: isAdmin ? Colors.orange : Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user['username'] ?? '', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black)),
                                  Text(user['role'] ?? 'customer', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                ],
                              ),
                            ),
                            if (!isAdmin) ...[
                              IconButton(
                                icon: const Icon(Icons.info_outline, color: Colors.grey),
                                onPressed: () => _viewUserDetails(user),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _deleteUser(user['username']!),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                  _resetRequests.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, size: 60, color: Colors.green),
                              SizedBox(height: 16),
                              Text('No pending reset requests'),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _resetRequests.length,
                          itemBuilder: (context, index) {
                            final request = _resetRequests[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFF7C948), width: 1),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.person, color: Color(0xFFF7C948)),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(request['username'] ?? '', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black)),
                                        Text('Requested at: ${request['time']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.check_circle, color: Colors.green),
                                    onPressed: () => _changePassword(request['username']!),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changePassword(String username) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Change Password for $username', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'New password', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.pop(ctx, controller.text);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF7C948)),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getStringList('users') ?? [];
      final updatedUsers = usersJson.map((data) {
        final parts = data.split('|');
        if (parts.length >= 3 && parts[0] == username) {
          return '$username|$result|${parts[2]}';
        }
        return data;
      }).toList();
      await prefs.setStringList('users', updatedUsers);

      final requestsJson = prefs.getStringList('password_reset_requests') ?? [];
      final updatedRequests = requestsJson.where((e) => !e.startsWith('$username|')).toList();
      await prefs.setStringList('password_reset_requests', updatedRequests);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully!'), backgroundColor: Colors.green),
        );
      }
      _loadData();
    }
  }
}

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final ProductService _service = ProductService.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _emojiController = TextEditingController();

  List<Map<String, dynamic>> _products = [];
  List<String> _categories = [];
  String _selectedCategory = '';
  StreamSubscription? _prodSub;
  StreamSubscription? _catSub;

  @override
  void initState() {
    super.initState();
    _prodSub = _service.productsStream().listen((list) {
      if (mounted) setState(() => _products = list);
    });
    _catSub = _service.categoriesStream().listen((list) {
      if (mounted) {
        setState(() {
          _categories = list;
          if (_categories.isNotEmpty &&
              !_categories.contains(_selectedCategory)) {
            _selectedCategory = _categories.first;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _prodSub?.cancel();
    _catSub?.cancel();
    super.dispose();
  }

  void _addCategory() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Category',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: _categoryController,
          decoration: const InputDecoration(
              hintText: 'Category Name', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (_categoryController.text.trim().isNotEmpty) {
                await _service.addCategory(_categoryController.text.trim());
                _categoryController.clear();
                if (mounted) Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF7C948)),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _deleteCategory(String category) async {
    if (_categories.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Cannot delete the last category'),
            backgroundColor: Colors.red),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Delete "$category" and all its products?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _service.deleteCategory(category);
    }
  }

  void _addProduct() {
    if (_selectedCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No category selected'), backgroundColor: Colors.red),
      );
      return;
    }
    final barcodeController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text('Add Product',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                      hintText: 'Product Name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                      hintText: 'Price (₹)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emojiController,
                  decoration: const InputDecoration(
                      hintText: 'Emoji (e.g., 🍎)',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: barcodeController,
                  decoration: InputDecoration(
                    hintText: 'Barcode',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.qr_code),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.qr_code_scanner,
                          color: Color(0xFFF7C948)),
                      onPressed: () async {
                        final code = await Navigator.push<String>(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ScanScreen()),
                        );
                        if (code != null && code.isNotEmpty) {
                          barcodeController.text = code;
                          setDialog(() {});
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '💡 Scan or type the real product barcode.',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final name = _nameController.text.trim();
                final priceTxt = _priceController.text.trim();
                final emoji = _emojiController.text.trim();
                if (name.isEmpty || priceTxt.isEmpty || emoji.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                        content: Text('Fill Name, Price, Emoji'),
                        backgroundColor: Colors.red),
                  );
                  return;
                }
                final price = int.tryParse(priceTxt) ?? 0;
                await _service.addProduct(
                  name: name,
                  price: price,
                  category: _selectedCategory,
                  emoji: emoji,
                  barcode: barcodeController.text.trim(),
                );
                _nameController.clear();
                _priceController.clear();
                _emojiController.clear();
                if (mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF7C948)),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _editBarcode(Map<String, dynamic> product) {
    final controller =
        TextEditingController(text: product['barcode'] ?? '');
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text('Edit Barcode',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(product['name'] ?? '',
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Enter barcode',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.qr_code),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner,
                        color: Color(0xFFF7C948)),
                    onPressed: () async {
                      final code = await Navigator.push<String>(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ScanScreen()),
                      );
                      if (code != null && code.isNotEmpty) {
                        controller.text = code;
                        setDialog(() {});
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                await _service.updateBarcode(
                    product['id'], controller.text.trim());
                if (mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF7C948)),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteProduct(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Remove "${product['name']}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await _service.deleteProduct(product['id']);
              if (mounted) Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _products
        .where((p) => p['category'] == _selectedCategory)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Products',
            style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: _addCategory,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('Category: ',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedCategory.isEmpty
                        ? null
                        : _selectedCategory,
                    isExpanded: true,
                    items: _categories
                        .map((cat) =>
                            DropdownMenuItem(value: cat, child: Text(cat)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedCategory = val);
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deleteCategory(_selectedCategory),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.green),
                  onPressed: _addCategory,
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('No products in this category',
                        style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final product = filtered[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.grey.shade100,
                                blurRadius: 4,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: Row(
                          children: [
                            Text(product['emoji'] ?? '🛒',
                                style: const TextStyle(fontSize: 32)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(product['name'] ?? '',
                                      style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black)),
                                  Text(
                                      '₹${product['price']} • ${product['category']}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600)),
                                  Text(
                                    (product['barcode'] ?? '').isEmpty
                                        ? '🚫 No barcode'
                                        : '🏷️ ${product['barcode']}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color:
                                          (product['barcode'] ?? '').isEmpty
                                              ? Colors.orange
                                              : Colors.green,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.qr_code_2,
                                  color: Colors.blue),
                              onPressed: () => _editBarcode(product),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              onPressed: () => _deleteProduct(product),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _addProduct,
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF7C948),
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class AdminMessagesScreen extends StatefulWidget {
  const AdminMessagesScreen({super.key});

  @override
  State<AdminMessagesScreen> createState() => _AdminMessagesScreenState();
}

class _AdminMessagesScreenState extends State<AdminMessagesScreen> {
  List<Map<String, String>> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  void _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = prefs.getStringList('contact_messages') ?? [];
    final List<Map<String, String>> msgs = [];
    for (var item in messagesJson) {
      final parts = item.split('|');
      if (parts.length >= 4) {
        msgs.add({
          'user': parts[0],
          'subject': parts[1],
          'message': parts[2],
          'time': parts[3],
        });
      }
    }
    setState(() {
      _messages = msgs;
      _isLoading = false;
    });
  }

  Future<void> _deleteMessage(int index) async {
    setState(() {
      _messages.removeAt(index);
    });
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = _messages.map((m) => '${m['user']}|${m['subject']}|${m['message']}|${m['time']}').toList();
    await prefs.setStringList('contact_messages', messagesJson);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Contact Messages', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _messages.isEmpty
          ? const Center(child: Text('No messages from customers'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: CircleAvatar(child: Text(msg['user']![0].toUpperCase())),
                    title: Text(msg['subject'] ?? '', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                    subtitle: Text('From: ${msg['user']}  •  ${msg['time']}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _deleteMessage(index),
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text('Message from ${msg['user']}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Subject: ${msg['subject']}'),
                              const SizedBox(height: 8),
                              Text('Message: ${msg['message']}'),
                              const SizedBox(height: 8),
                              Text('Time: ${msg['time']}'),
                            ],
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  Future<void> _changePassword() async {
    final newPass = _newPassController.text.trim();
    final confirm = _confirmPassController.text.trim();
    if (newPass.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill all fields'), backgroundColor: Colors.red),
      );
      return;
    }
    if (newPass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match'), backgroundColor: Colors.red),
      );
      return;
    }
    if (newPass.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 4 characters'), backgroundColor: Colors.red),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    List<String> usersJson = prefs.getStringList('users') ?? [];
    for (int i = 0; i < usersJson.length; i++) {
      final parts = usersJson[i].split('|');
      if (parts.length >= 3 && parts[0] == 'admin') {
        parts[1] = newPass;
        usersJson[i] = parts.join('|');
        break;
      }
    }
    await prefs.setStringList('users', usersJson);
    if (!mounted) return;  
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Admin password updated!'), backgroundColor: Colors.green),
    );
    _newPassController.clear();
    _confirmPassController.clear();
    Navigator.pop(context);
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthWrapper()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Profile', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Colors.orange, Colors.orangeAccent]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.admin_panel_settings, color: Colors.orange, size: 40),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Administrator', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('admin@trolleymate.com', style: TextStyle(fontSize: 14, color: Colors.white70)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('Change Password', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _newPassController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'New Password', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirmPassController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Confirm Password', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _changePassword,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF7C948), foregroundColor: Colors.black),
                      child: const Text('Update Password'),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ============================================================
// BILLING BOOTH SCREEN (Flutter Web – Laptop)
// ============================================================


// ------------------------------------------------------------
// Simple in-memory service (replace with Firebase later)
// ------------------------------------------------------------


// ------------------------------------------------------------
// Billing Booth Screen
// ------------------------------------------------------------
class BillingBoothScreen extends StatefulWidget {
  const BillingBoothScreen({super.key});

  @override
  State<BillingBoothScreen> createState() => _BillingBoothScreenState();
}

class _BillingBoothScreenState extends State<BillingBoothScreen> {
  final TextEditingController _codeController = TextEditingController();
  Map<String, dynamic>? _cart;
  String? _trolleyCode;
  bool _isLoading = false;
  String _status = '';

  // ---------------- Flow: Fetch Cart ----------------
    Future<void> _fetchCart() async {
    final code = _codeController.text.trim();
    if (code.length != 4) {
      setState(() => _status = 'Enter a valid 4-digit trolley code');
      return;
    }

    setState(() {
      _isLoading = true;
      _status = '';
    });

    try {
      final db = FirebaseDatabase.instanceFor(
  app: Firebase.app(),
  databaseURL: 'https://trolley-mate-3c373-default-rtdb.asia-southeast1.firebasedatabase.app',
);
final snapshot = await db.ref('liveCarts/$code').get();
      if (!mounted) return;

      if (!snapshot.exists || snapshot.value == null) {
        setState(() {
          _isLoading = false;
          _status = 'No active cart found for trolley $code';
        });
        return;
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        _isLoading = false;
        _trolleyCode = code;
        _cart = data;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _status = 'Error: $e';
      });
    }
  }

  // ---------------- Flow: Cancel Item ----------------
    Future<void> _cancelItem(String itemName) async {
    if (_trolleyCode == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Product'),
        content: Text(
          'Remove "$itemName" from the cart?\n\n'
          '(In the real system, the customer would place it in the cancellation box for weight verification.)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF7C948),
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final db = FirebaseDatabase.instanceFor(
  app: Firebase.app(),
  databaseURL: 'https://trolley-mate-3c373-default-rtdb.asia-southeast1.firebasedatabase.app',
);
final ref = db.ref('liveCarts/$_trolleyCode');
      final snap = await ref.get();
      if (!snap.exists) return;

      final data = Map<String, dynamic>.from(snap.value as Map);
      final items = List<Map<String, dynamic>>.from(
          (data['items'] as List).map((e) => Map<String, dynamic>.from(e)));
      items.removeWhere((e) => e['name'] == itemName);

      if (items.isEmpty) {
        await ref.remove();
      } else {
        final total = items.fold<double>(
            0, (s, e) => s + (e['price'] as int) * (e['qty'] as int));
        await ref.update({
          'items': items,
          'total': total,
        });
      }

      await _fetchCart();
      if (!mounted) return;
      setState(() => _status = '$itemName cancelled successfully');
    }
  }
  // ---------------- Flow: Payment ----------------
  Future<void> _processPayment() async {
    if (_cart == null) return;

    final total = _cartTotal();

    // Generate UPI URL (replace merchant with your own)
    final upiUrl =
        'upi://pay?pa=merchant@bank&pn=TrolleyMate&am=${total.toStringAsFixed(2)}&cu=INR';

    // Show QR dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Pay ₹${total.toStringAsFixed(2)}',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: upiUrl,
              size: 220,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 16),
            Text(
              'Scan with any UPI app',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF7C948),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () async {
  final db = FirebaseDatabase.instanceFor(
  app: Firebase.app(),
  databaseURL: 'https://trolley-mate-3c373-default-rtdb.asia-southeast1.firebasedatabase.app',
);
await db.ref('liveCarts/$_trolleyCode').update({'status': 'paid'});
  if (mounted) Navigator.pop(ctx);
  _showSuccess();
},
                  child: const Text('Simulate Payment Success'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Success Screen ----------------
  void _showSuccess() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _BoothSuccessScreen()),
    );
  }

  // ---------------- Helpers ----------------
  double _cartTotal() {
    if (_cart == null) return 0;
    final items = _cart!['items'] as List;
    return items.fold(
      0.0,
      (sum, item) => sum + (item['price'] as int) * (item['qty'] as int),
    );
  }

  void _reset() {
    setState(() {
      _cart = null;
      _trolleyCode = null;
      _codeController.clear();
      _status = '';
    });
  }

  // ---------------- Build ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: _cart == null ? _buildEntryView() : _buildCartView(),
            ),
          ),
        ),
      ),
    );
  }

  // -------- Entry View (Enter Trolley Code) --------
    Widget _buildEntryView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const TrolleyMateLogo(size: 100),
        const SizedBox(height: 20),
        RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                letterSpacing: -1),
            children: const [
              TextSpan(
                  text: 'Trolley', style: TextStyle(color: Colors.black)),
              TextSpan(
                  text: 'Mate', style: TextStyle(color: TMColors.primary)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Billing Booth',
          style: GoogleFonts.poppins(
            fontSize: 18,
            color: TMColors.grey,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 48),
        Container(
          width: 420,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Enter Trolley Code',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Type the 4-digit number from the trolley',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: TMColors.grey),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 12,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '0000',
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.grey.shade300,
                    letterSpacing: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _fetchCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TMColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Fetch Cart',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              if (_status.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  _status,
                  style: GoogleFonts.poppins(
                    color: Colors.red.shade400,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // -------- Cart View (Show Items + Actions) --------
  Widget _buildCartView() {
    final items = _cart!['items'] as List;
    final total = _cartTotal();
    final username = _cart!['user'] ?? 'guest';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // -------- LEFT: Cart List --------
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                                Row(
                  children: [
                    const TrolleyMateLogoHorizontal(size: 40, showTagline: false),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _reset,
                      icon: const Icon(Icons.refresh),
                      label: const Text('New Trolley'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7C948),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.confirmation_number_outlined,
                              size: 14, color: Colors.black),
                          const SizedBox(width: 4),
                          Text('Trolley $_trolleyCode',
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Customer: @$username',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),
                Expanded(
                  child: items.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.remove_shopping_cart,
                                size: 60,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'All items cancelled',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (ctx, i) {
                            final item = items[i];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              leading: Text(
                                item['emoji'] ?? '🛒',
                                style: const TextStyle(fontSize: 32),
                              ),
                              title: Text(
                                item['name'],
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                '₹${item['price']} × ${item['qty']}',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '₹${(item['price'] as int) * (item['qty'] as int)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.cancel_outlined,
                                      color: Colors.red,
                                    ),
                                    tooltip: 'Cancel item',
                                    onPressed: () =>
                                        _cancelItem(item['name']),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 24),

        // -------- RIGHT: Payment Panel --------
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF7C948), Color(0xFFFFD54F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Billing Summary',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 24),
                _summaryRow('Items', '${items.length}'),
                _summaryRow(
                  'Total Quantity',
                  '${items.fold(0, (s, e) => s + (e['qty'] as int))}',
                ),
                const Divider(height: 32, color: Colors.black26),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Grand Total',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      '₹${total.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: items.isEmpty ? null : _processPayment,
                    icon: const Icon(Icons.qr_code_2, size: 28),
                    label: Text(
                      'Pay Now',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'After payment, the exit gate unlocks automatically.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// BOOTH SUCCESS SCREEN
// ============================================================
class _BoothSuccessScreen extends StatelessWidget {
  const _BoothSuccessScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const TrolleyMateLogo(size: 100),
            const SizedBox(height: 24),
            TrolleyMateLogoHorizontal(size: 50, showTagline: false),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: TMColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: TMColors.primary.withAlpha(120),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 90,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Thank You! 🎉',
              style: GoogleFonts.poppins(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Payment Successful — Visit Again',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: TMColors.grey,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_open, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Exit Gate Unlocked',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Billing Booth'),
              style: ElevatedButton.styleFrom(
                backgroundColor: TMColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}