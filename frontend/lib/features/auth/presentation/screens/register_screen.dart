// lib/features/auth/presentation/screens/register_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/core/routing/app_router.dart';
import 'package:mess_management_system/features/auth/presentation/providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedRole = 'customer';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_formKey.currentState!.validate()) {
      // Validate PIN for customers
      if (_selectedRole == 'customer') {
        if (_pinController.text.trim().length != 4) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Customers must set a 4-digit kiosk PIN.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      final authNotifier = ref.read(authProvider.notifier);
      try {
        await authNotifier.sendRegistrationOtp(
          _nameController.text.trim(),
          _phoneController.text.trim(),
          _selectedRole,
          _selectedRole == 'customer' ? _pinController.text.trim() : null,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('OTP sent successfully! Check your backend console.'),
            ),
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
    final authState = ref.watch(authProvider);
    final isCustomer = _selectedRole == 'customer';

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
                      prefixIcon: Icon(Icons.person_outline),
                    ),
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
                      counterText: "",
                    ),
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                    segments: const [
                      ButtonSegment(
                        value: 'customer',
                        label: Text('Customer'),
                        icon: Icon(Icons.person_search),
                      ),
                      ButtonSegment(
                        value: 'manager',
                        label: Text('Mess Owner'),
                        icon: Icon(Icons.storefront),
                      ),
                    ],
                    selected: {_selectedRole},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() => _selectedRole = newSelection.first);
                    },
                  ),
                  const SizedBox(height: 20),

                  // Conditional PIN field (only for customers)
                  if (isCustomer) ...[
                    TextFormField(
                      controller: _pinController,
                      decoration: const InputDecoration(
                        labelText: '4-Digit Kiosk PIN *',
                        hintText: 'Used to mark attendance at mess',
                        prefixIcon: Icon(Icons.lock_outline),
                        counterText: "",
                        helperText:
                            'Keep this secret! You\'ll use it at every mess you join.',
                        helperMaxLines: 2,
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      obscureText: true,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) => (value == null || value.length != 4)
                          ? 'PIN must be exactly 4 digits'
                          : null,
                    ),
                    const SizedBox(height: 20),
                  ],

                  const SizedBox(height: 20),

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
