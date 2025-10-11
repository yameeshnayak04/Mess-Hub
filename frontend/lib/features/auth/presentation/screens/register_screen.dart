// This file contains the UI for the user registration screen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/core/routing/app_router.dart';
import 'package:mess_management_system/features/auth/presentation/providers/auth_provider.dart';

// We use a ConsumerStatefulWidget to listen to Riverpod providers.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedRole = 'customer';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // The function to call when the "Send OTP" button is pressed.
  Future<void> _sendOtp() async {
    // First, validate the form.
    if (_formKey.currentState!.validate()) {
      // Get the AuthNotifier from the provider.
      final authNotifier = ref.read(authProvider.notifier);
      try {
        // Call the method on the notifier.
        await authNotifier.sendRegistrationOtp(
          _nameController.text.trim(),
          _phoneController.text.trim(),
          _selectedRole,
        );

        // If the API call is successful, navigate to the OTP screen.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('OTP sent successfully! Check your backend console.')),
          );
          Navigator.pushNamed(
            context,
            AppRouter.otpRoute,
            arguments: {
              'phone': _phoneController.text.trim(),
              'isRegistration': true,
            },
          );
        }
      } catch (e) {
        // If an error occurs, show it in a SnackBar.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the authProvider to get the current state (e.g., isLoading).
    final authState = ref.watch(authProvider);

    return Scaffold(
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
                  const Icon(Icons.food_bank_rounded,
                      size: 80, color: Colors.deepOrange),
                  const SizedBox(height: 20),
                  const Text('Welcome to Mess Hub',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text('Create your account to get started.',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                  const SizedBox(height: 40),

                  // Name field
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline)),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                            ? 'Please enter your name'
                            : null,
                  ),
                  const SizedBox(height: 20),

                  // Phone field
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                        labelText: '10-Digit Phone Number',
                        prefixIcon: Icon(Icons.phone_outlined),
                        prefixText: '+91 ',
                        counterText: ""),
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    validator: (value) => (value == null || value.length != 10)
                        ? 'Please enter a valid 10-digit phone number'
                        : null,
                  ),
                  const SizedBox(height: 20),

                  // Role selection
                  const Text('I am a:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  SegmentedButton<String>(
                    segments: const <ButtonSegment<String>>[
                      ButtonSegment<String>(
                          value: 'customer',
                          label: Text('Customer'),
                          icon: Icon(Icons.person_search)),
                      ButtonSegment<String>(
                          value: 'manager',
                          label: Text('Mess Owner'),
                          icon: Icon(Icons.storefront)),
                    ],
                    selected: <String>{_selectedRole},
                    onSelectionChanged: (Set<String> newSelection) =>
                        setState(() => _selectedRole = newSelection.first),
                  ),
                  const SizedBox(height: 40),

                  // Submit button
                  authState.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _sendOtp,
                          child: const Text('Send OTP'),
                        ),

                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account?',
                          style: TextStyle(color: Colors.grey.shade600)),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, AppRouter.loginRoute),
                        child: const Text('Login Now',
                            style: TextStyle(
                                color: Colors.deepOrange,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
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
