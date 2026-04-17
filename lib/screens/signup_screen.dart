class SignUpScreen extends StatefulWidget { ... }

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  DateTime? _selectedBirthDate;

  bool _isLoading = false;

  int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBirthDate == null) {
      // show error
      return;
    }
    if (_calculateAge(_selectedBirthDate!) < 13) {
      // show error: user must be at least 13
      return;
    }

    setState(() => _isLoading = true);
    try {
      await context.read<AuthService>().signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            birthDate: _selectedBirthDate!,
          );
      // Navigate to home (auth state will handle)
    } catch (e) {
      // Show error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Build method with form fields and date picker
}