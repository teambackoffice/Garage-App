import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'bottom_nav.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final sid = prefs.getString('sid');
    if (sid != null && sid.isNotEmpty) {
      // User already logged in, navigate to home screen
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BottomNavBarScreen()),
      );
    }
  }

  Future<void> _login() async {
    const String apiUrl =
        'https://garage.tbo365.cloud/api/method/garage.garage.auth.user_login';

    if (!await _hasNetwork()) {
      _showError("No internet connection. Please check your network.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'usr': _usernameController.text.trim(),
          'pwd': _passwordController.text.trim(),
        }),
      );

      final Map<String, dynamic> data = json.decode(response.body);
      print("Login API Response: ${response.body}");

      if (response.statusCode == 200 && data.containsKey('message')) {
        final messageData = data['message'];

        if (messageData is Map<String, dynamic> &&
            messageData['message'] == "Authentication success") {
          final String username = messageData['username'];
          final String? token = messageData['sid'];

          if (token != null) {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString('username', username);
            await prefs.setString('sid', token);  // Save session ID

            print("✅ Saved sid: $token");

            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const BottomNavBarScreen()),
            );
          } else {
            _showError("Session token not found.");
          }
        } else {
          String errorMessage = "Login failed. Please check your credentials.";
          if (messageData is Map<String, dynamic> && messageData['message'] != null) {
            errorMessage = messageData['message'];
          }
          _showError(errorMessage);
        }
      } else {
        _showError("Invalid response from server.");
      }
    } catch (e) {
      print("Login Error: $e");
      _showError("Something went wrong. Please try again.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _hasNetwork() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      body: Padding(
        padding: EdgeInsets.all(w * 0.06),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(height: h * 0.25),
                Text(
                  'GARAGE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                    foreground: Paint()
                      ..shader = const LinearGradient(
                        colors: [Colors.blue, Colors.purple],
                      ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                  ),
                ),
                SizedBox(height: h * 0.08),
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    filled: true,
                    fillColor: Colors.deepPurple.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.deepPurple),
                    ),
                  ),
                  validator: (value) => value!.isEmpty ? 'Enter username' : null,
                ),
                SizedBox(height: h * 0.03),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    filled: true,
                    fillColor: Colors.deepPurple.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.deepPurple),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.deepPurple,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) =>
                  value!.length < 6 ? 'Min 6 characters' : null,
                ),
                SizedBox(height: h * 0.04),
                Container(
                  width: w * 0.5,
                  height: h * 0.06,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.blue, Colors.purple],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isLoading
                        ? null
                        : () {
                      if (_formKey.currentState!.validate()) _login();
                    },
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                      "Login",
                      style: TextStyle(color: Colors.white),
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
