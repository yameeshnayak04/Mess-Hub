// This file contains the UI and logic for verifying the OTP.
// It is the final step in both registration and login flows.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/features/auth/presentation/providers/auth_provider.dart';
import 'package:mess_management_system/features/customer_dashboard/presentation/screens/my_memberships_screen.dart';
import 'package:mess_management_system/features/manager_dashboard/presentation/screens/manager_dashboard_screen.dart';
import 'package:pinput/pinput.dart';

class OtpScreen extends ConsumerStatefulWidget {
  // We receive the phone number and the flow type (registration or login) as arguments.
  final String phone;
  final bool isRegistration;

  const OtpScreen({
    super.key,
    required this.phone,
    required this.isRegistration,
  });

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  // This function is called when the "Verify & Proceed" button is pressed.
  Future<void> _verifyOtp() async {
    // First, check if the 6-digit OTP has been entered.
    if (_formKey.currentState!.validate()) {
      // Get the AuthNotifier from the provider to call its methods.
      final authNotifier = ref.read(authProvider.notifier);

      try {
        // Call the appropriate verification method based on the flow.
        if (widget.isRegistration) {
          await authNotifier.verifyRegistrationOtp(
              widget.phone, _otpController.text);
        } else {
          await authNotifier.verifyLoginOtp(widget.phone, _otpController.text);
        }

        // After a successful verification, the user object is now available in the authProvider's state.
        // We use ref.read() here because we are inside a function and don't need to listen for further changes.
        final user = ref.read(authProvider).user;

        // Ensure the widget is still mounted and the user object is not null before navigating.
        if (mounted && user != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Verification Successful! Welcome.')),
          );

          // --- ROLE-BASED NAVIGATION LOGIC ---
          // This is the critical step. We check the user's role and navigate to the correct dashboard.
          if (user.role == 'manager') {
            // If the user is a manager, navigate to the ManagerDashboardScreen.
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                  builder: (context) => const ManagerDashboardScreen()),
              (Route<dynamic> route) =>
                  false, // This removes all previous routes from the stack.
            );
          } else {
            // If the user is a customer, navigate to the MyMembershipsScreen.
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                  builder: (context) => const MyMembershipsScreen()),
              (Route<dynamic> route) =>
                  false, // Prevents user from pressing "back" to the login flow.
            );
          }
          // ------------------------------------
        }
      } catch (e) {
        // If the try block throws an error (e.g., invalid OTP), show it in a SnackBar.
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the authProvider to get the current loading state.
    final authState = ref.watch(authProvider);

    // Define the visual theme for the Pinput widget.
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.transparent),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Header ---
                  const Text('Enter Verification Code',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(
                      'A 6-digit code was sent to your\nbackend console for +91 ${widget.phone}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          height: 1.5)),
                  const SizedBox(height: 40),

                  // --- Pinput OTP Field ---
                  Pinput(
                    length: 6,
                    controller: _otpController,
                    defaultPinTheme: defaultPinTheme,
                    // Style for when the field is focused.
                    focusedPinTheme: defaultPinTheme.copyWith(
                      decoration: defaultPinTheme.decoration!.copyWith(
                        border: Border.all(
                            color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    autofocus: true,
                    validator: (value) {
                      return (value == null || value.length != 6)
                          ? 'Please enter a valid 6-digit OTP'
                          : null;
                    },
                  ),

                  const SizedBox(height: 40),

                  // --- Submit Button ---
                  // Show a loading indicator if the API call is in progress.
                  authState.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _verifyOtp,
                          child: const Text('Verify & Proceed'),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
