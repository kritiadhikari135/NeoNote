# Registration Flow Integration Guide

## Overview

This document explains how the registration flow is integrated between the login page, register page, and OTP verification page in the NeoNote web application.

## Files Involved

1. **login_page.dart**: The entry point for users to log in or navigate to the registration page.
2. **register_page.dart**: Where users enter their registration details (email, full name, password).
3. **otp_verification_page.dart**: Where users verify their email with an OTP code.

## Registration Flow

The registration flow follows these steps:

1. **Login Page**: User clicks "Sign Up" to navigate to the Register Page.
2. **Register Page**: User enters their email, full name, and password, then clicks "Register".
3. **OTP Check**: The app checks if the OTP endpoint exists:
   - If the endpoint exists, the user is navigated to the OTP Verification Page.
   - If the endpoint doesn't exist, the app falls back to direct registration.
4. **OTP Verification Page**: User enters the OTP received in their email and clicks "Verify & Complete Registration".
5. **Automatic Login**: After successful registration, the user is automatically logged in and redirected to the dashboard.

## Integration Details

### 1. Login Page to Register Page

In `login_page.dart`, the "Sign Up" button navigates to the Register Page:

```dart
TextButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegisterPage(),
      ),
    );
  },
  child: const Text('Sign Up'),
)
```

### 2. Register Page to OTP Verification Page

In `register_page.dart`, the "Register" button calls the `_navigateToOtpPage()` method:

```dart
ElevatedButton(
  onPressed: _isLoading ? null : _navigateToOtpPage,
  child: _isLoading
      ? CircularProgressIndicator()
      : Text('Register'),
)
```

The `_navigateToOtpPage()` method checks if the OTP endpoint exists and navigates accordingly:

```dart
void _navigateToOtpPage() async {
  // Check if the OTP endpoint exists
  final response = await http.post(
    Uri.parse('http://127.0.0.1:8000/api/accounts/send-otp/'),
    // ...
  );
  
  if (response.statusCode == 404) {
    // OTP endpoint doesn't exist, register directly
    _registerDirectly();
  } else {
    // OTP endpoint exists, navigate to OTP verification page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OtpVerificationPage(
          email: _emailController.text.trim(),
          fullName: _fullNameController.text.trim(),
          password: _passwordController.text,
        ),
      ),
    );
  }
}
```

### 3. OTP Verification Page to Dashboard

In `otp_verification_page.dart`, the "Verify & Complete Registration" button calls the `verifyOTP()` method:

```dart
ElevatedButton(
  onPressed: _isLoading ? null : verifyOTP,
  child: _isLoading
      ? CircularProgressIndicator()
      : Text('Verify & Complete Registration'),
)
```

The `verifyOTP()` method verifies the OTP, registers the user, and automatically logs them in:

```dart
Future<void> verifyOTP() async {
  // Verify OTP and register user
  final response = await http.post(
    Uri.parse('http://127.0.0.1:8000/api/accounts/register/'),
    // ...
  );
  
  if (response.statusCode == 201) {
    // Registration successful, automatically log in
    _loginAfterRegistration();
  }
}

Future<void> _loginAfterRegistration() async {
  // Log in the user and redirect to dashboard
  final response = await http.post(
    Uri.parse('http://127.0.0.1:8000/api/accounts/login/'),
    // ...
  );
  
  if (response.statusCode == 200) {
    // Save token and navigate to dashboard
    await LocalStorage.saveToken(data['access']);
    Navigator.pushReplacementNamed(context, '/dashboard');
  }
}
```

## Fallback Mechanism

If the OTP endpoint doesn't exist or returns a 404 error, the app falls back to direct registration without OTP verification. This ensures that the registration process works even if the OTP functionality is not implemented on the server.

## Error Handling

The implementation includes comprehensive error handling:

1. **HTML Response Detection**: The app detects if the server returns an HTML error page instead of a JSON response and shows a user-friendly error message.
2. **Network Error Handling**: The app handles network errors and shows appropriate error messages.
3. **JSON Parsing Errors**: The app handles JSON parsing errors and shows appropriate error messages.
4. **BuildContext Handling**: The app includes proper BuildContext handling with mounted checks to prevent Flutter errors.

## Testing

To test the registration flow:

1. Start from the Login Page and click "Sign Up"
2. Enter registration details and click "Register"
3. If the OTP endpoint exists, you'll be taken to the OTP Verification Page
4. Enter the OTP and click "Verify & Complete Registration"
5. You should be automatically logged in and redirected to the dashboard

If the OTP endpoint doesn't exist, you'll be registered directly and logged in automatically.

## Future Improvements

1. **Server-Side Implementation**
   - Implement the OTP verification endpoint in the Django backend
   - Add proper JSON error responses instead of HTML error pages
   - Implement better error handling on the server side

2. **Client-Side Improvements**
   - Replace debug print statements with proper logging
   - Add offline support for registration with later synchronization
   - Implement retry mechanisms for network failures
