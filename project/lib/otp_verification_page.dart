import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OtpVerificationPage extends StatefulWidget {
  final String email;
  final String fullName;
  final String password;

  const OtpVerificationPage({
    Key? key,
    required this.email,
    required this.fullName,
    required this.password,
  }) : super(key: key);

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isSendingOtp = false;

  @override
  void initState() {
    super.initState();
    sendOTP();
  }

  void sendOTP() async {
    setState(() {
      _isSendingOtp = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/accounts/send-otp/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': widget.email,
        }),
      );

      if (!mounted) return;

      setState(() {
        _isSendingOtp = false;
      });

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("OTP sent to ${widget.email}. Check your email.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to send OTP: ${response.body}")),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSendingOtp = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error sending OTP: $e")),
      );
    }
  }

  void verifyOTP() {
    setState(() {
      _isLoading = true;
    });

    // Now we'll verify the OTP by attempting to register with the OTP
    _registerUserWithOtp();
  }

  Future<void> _registerUserWithOtp() async {
    try {
      // Print debug information
      print('Attempting to register with:');
      print('Email: ${widget.email}');
      print('Full Name: ${widget.fullName}');
      print('OTP: ${_otpController.text.trim()}');

      final requestBody = {
        'email': widget.email,
        'full_name': widget.fullName,
        'password': widget.password,
        'otp': _otpController.text.trim(),
      };

      print('Request body: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/accounts/register/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User registered successfully')),
        );
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: ${response.body}')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during registration: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Verify OTP")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Enter OTP sent to ${widget.email}"),
            TextField(
              controller: _otpController,
              decoration: InputDecoration(labelText: "OTP"),
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: verifyOTP,
                    child: Text("Verify OTP and Register"),
                  ),
          ],
        ),
      ),
    );
  }
}