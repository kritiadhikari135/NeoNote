import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:project/register_page.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:project/services/local_storage.dart';
import 'package:project/services/api_service.dart';
import 'package:project/models/page.dart';
import 'package:provider/provider.dart';
import 'package:project/providers/pages_provider.dart';



class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();



  Future<void> _loginUser() async {
  setState(() {
    _isLoading = true;
  });

  final response = await http.post(
    Uri.parse('http://127.0.0.1:8000/api/accounts/login/'),
    headers: {
      'Content-Type': 'application/json',
    },
    body: json.encode({
      'email': _emailController.text,
      'password': _passwordController.text,
    }),
  );

  setState(() {
    _isLoading = false;
  });

  if (response.statusCode == 200) {
    final data = json.decode(response.body);

    // Save token and then retrieve it to check if it's correctly stored
    await LocalStorage.saveToken(data['access']);
    String? storedToken = await LocalStorage.getToken();
    print("✅ Token retrieved after login: $storedToken");





    if (storedToken != null) {
      print("✅ Token successfully retrieved after saving!");

      // Initialize the PagesProvider by fetching pages
      try {
        final pagesProvider = Provider.of<PagesProvider>(context, listen: false);
        await pagesProvider.fetchPages();
        print("✅ Pages fetched successfully after login");
      } catch (e) {
        print("⚠️ Error fetching pages after login: $e");
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login successful')),
      );

      // Redirect to dashboard
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      print("⚠️ Token retrieval failed after saving.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Token not saved correctly')),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Login failed: ${response.body}')),
    );
  }

}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9EBEE), // Light gray background
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Title
              const Text(
                'NeoNote',
                style: TextStyle(
                  fontSize: 32, // Large and bold header
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1877F2), // Facebook blue
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your Notes Simplified!',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF555555), // Subtle gray text
                ),
              ),
              const SizedBox(height: 30),

              // Login Form Container
              Container(
                constraints: const BoxConstraints.tightForFinite(width: 600),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: "Email",
                          labelStyle: const TextStyle(color: Color(0xFF555555)),
                          hintText: 'Enter your email',
                          prefixIcon:
                              const Icon(Icons.email, color: Color(0xFF1877F2)),
                          filled: true,
                          fillColor: const Color(0xFFF7F7F7),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: "Password",
                          labelStyle: const TextStyle(color: Color(0xFF555555)),
                          hintText: 'Enter your password',
                          prefixIcon:
                              const Icon(Icons.lock, color: Color(0xFF1877F2)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: const Color(0xFF555555),
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF7F7F7),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          // if (value.length < 8) {
                          //   return 'Password must be at least 8 characters';
                          // }
                          // if (!RegExp(r'[!@#\$&*~]').hasMatch(value)) {
                          //   return 'Password must include a special character (!@#\$&*~)';
                          // }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      ElevatedButton(
                        onPressed: _isLoading ? null : _loginUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF1877F2), // Facebook blue
                          minimumSize:
                              const Size(double.infinity, 50), // Full width
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              )
                            : const Text(
                                'Log In',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Sign Up
              const Text(
                "Don't have an account?",
                style: TextStyle(color: Color(0xFF555555), fontSize: 14),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RegisterPage(),
                    ),
                  ); // Navigate to SignUp
                },
                child: const Text(
                  'Sign Up',
                  style: TextStyle(
                    color: Color(0xFF1877F2),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

