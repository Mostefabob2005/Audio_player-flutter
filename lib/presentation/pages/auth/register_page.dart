// lib/presentation/pages/auth/register_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/app_router.dart';
import '../../../core/utils/result.dart';
import '../../../core/utils/validators.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/loading_overlay.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  // Controller dédié pour afficher la date
  final _dateCtrl = TextEditingController();
  DateTime? _dateOfBirth;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.primaryColor,
            surface: AppTheme.cardDark,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _dateOfBirth = picked;
        // Mettre à jour le controller pour afficher la date dans le champ
        _dateCtrl.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your date of birth'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final result = await context.read<AuthProvider>().signUp(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          firstName: _firstNameCtrl.text.trim(),
          lastName: _lastNameCtrl.text.trim(),
          dateOfBirth: _dateOfBirth!,
        );

    if (!mounted) return;
    result.fold(
      onSuccess: (_) => Navigator.pushReplacementNamed(context, AppRouter.home),
      onFailure: (msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppTheme.errorColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        context.watch<AuthProvider>().status == AuthStatus.loading;

    return LoadingOverlay(
      isLoading: isLoading,
      child: Scaffold(
        appBar: AppBar(title: const Text('Create Account')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // First & Last Name Row
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _firstNameCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(labelText: 'First Name'),
                          validator: (v) =>
                              Validators.requiredField(v, 'First name'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _lastNameCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(labelText: 'Last Name'),
                          validator: (v) =>
                              Validators.requiredField(v, 'Last name'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Date of Birth — avec TextEditingController pour afficher la date
                  TextFormField(
                    controller: _dateCtrl,
                    readOnly: true,
                    onTap: _pickDate,
                    decoration: const InputDecoration(
                      labelText: 'Date of Birth',
                      hintText: 'Select your date of birth',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    validator: (_) => Validators.dateOfBirth(_dateOfBirth),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: Validators.password,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _confirmPasswordCtrl,
                    obscureText: _obscureConfirm,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    validator: (v) =>
                        Validators.confirmPassword(v, _passwordCtrl.text),
                  ),
                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    child: const Text('Create Account'),
                  ),
                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Already have an account? Sign In'),
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
