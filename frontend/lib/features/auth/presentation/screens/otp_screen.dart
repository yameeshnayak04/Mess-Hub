// This is the final version of the OTP screen with correct role-based navigation.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/core/api/dio_client.dart';
import 'package:mess_management_system/features/auth/presentation/providers/auth_provider.dart';
import 'package:mess_management_system/features/customer_dashboard/presentation/screens/my_memberships_screen.dart';
import 'package:mess_management_system/features/manager_dashboard/presentation/screens/manager_dashboard_screen.dart';
import 'package:mess_management_system/features/mess_onboarding/presentation/screens/create_mess_screen.dart';
import 'package:pinput/pinput.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;
  final bool isRegistration;

  const OtpScreen(
      {super.key, required this.phone, required this.isRegistration});

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

  Future<void> _verifyOtp() async {
    if (_formKey.currentState!.validate()) {
      final authNotifier = ref.read(authProvider.notifier);
      try {
        if (widget.isRegistration) {
          await authNotifier.verifyRegistrationOtp(
              widget.phone, _otpController.text);
        } else {
          await authNotifier.verifyLoginOtp(widget.phone, _otpController.text);
        }

        // After successful verification, get the user from the state.
        final user = ref.read(authProvider).user;

        if (mounted && user != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Welcome, ${user.name}!')),
          );

          // --- ROLE-BASED NAVIGATION LOGIC ---
          if (user.role == 'manager') {
            try {
              // After login, we make a quick check to see if the manager already has a mess.
              await DioClient.instance.dio.get('/managers/my-mess');

              // If the API call SUCCEEDS (status 200), it means a mess exists.
              // So, we navigate them to their main dashboard.
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (context) => const ManagerDashboardScreen()),
                  (route) => false,
                );
              }
            } on DioException catch (e) {
              // If the API call FAILS with a 404 Not Found, it means no mess exists for this manager.
              if (e.response?.statusCode == 404) {
                // So, we navigate them to the onboarding screen to create one.
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (context) => const CreateMessScreen()),
                    (route) => false,
                  );
                }
              } else {
                // Handle other potential network errors
                throw e;
              }
            }
          } else {
            // It's a 'customer'
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                  builder: (context) => const MyMembershipsScreen()),
              (route) => false,
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(e.toString()), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      decoration: BoxDecoration(
          color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
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
                  Pinput(
                    length: 6,
                    controller: _otpController,
                    defaultPinTheme: defaultPinTheme,
                    focusedPinTheme: defaultPinTheme.copyWith(
                        decoration: defaultPinTheme.decoration!.copyWith(
                            border: Border.all(
                                color: Theme.of(context).colorScheme.primary))),
                    autofocus: true,
                    validator: (value) => (value == null || value.length != 6)
                        ? 'Please enter a valid 6-digit OTP'
                        : null,
                  ),
                  const SizedBox(height: 40),
                  authState.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _verifyOtp,
                          child: const Text('Verify & Proceed')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
