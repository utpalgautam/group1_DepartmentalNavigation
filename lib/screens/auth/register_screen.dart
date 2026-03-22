import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _branchCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();

  UserType _selectedType = UserType.student;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  static const _userTypes = [
    UserType.student,
    UserType.faculty,
    UserType.staff,
  ];

  static const _typeLabels = {
    UserType.student: 'Student',
    UserType.faculty: 'Faculty',
    UserType.staff: 'Staff',
  };

  static const _branches = [
    'Computer Science & Engineering',
    'Electronics & Communication',
    'Electrical Engineering',
    'Mechanical Engineering',
    'Civil Engineering',
    'Chemical Engineering',
    'Production Engineering',
    'Architecture',
    'Other',
  ];

  static const _years = ['1st Year', '2nd Year', '3rd Year', '4th Year', 'PG'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _branchCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  bool get _showBranch =>
      _selectedType == UserType.student || _selectedType == UserType.faculty;
  bool get _showYear => _selectedType == UserType.student;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<app_auth.AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    auth.clearError();

    final ok = await auth.register(
      name: _nameCtrl.text,
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
      userType: _selectedType,
      branch: _showBranch ? _branchCtrl.text : null,
      year: _showYear ? _yearCtrl.text : null,
    );

    if (!mounted) return;

    if (ok) {
      messenger.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text(
                'Registration Successful! Welcome aboard 🎉',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      // Pop all routes back to root — AuthWrapper will show home since user is now logged in
      navigator.popUntil((route) => route.isFirst);
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Registration failed'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<app_auth.AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Back Button (Top Left)
                Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Header Texts
                const Text(
                  'Create Account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    'Join the campus navigator community.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF888888),
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // ── User type selector ───────────────────────────
                const Text(
                  'I am a...',
                  style: TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                _UserTypeSelector(
                  selected: _selectedType,
                  types: _userTypes,
                  labels: _typeLabels,
                  onChanged: (t) => setState(() => _selectedType = t),
                ),
                const SizedBox(height: 24),

                // Full Name
                CustomTextField(
                  label: 'Full Name',
                  hintText: 'John Doe',
                  controller: _nameCtrl,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),

                // Email
                CustomTextField(
                  label: 'Email Address',
                  hintText: 'user@example.com',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password
                CustomTextField(
                  label: 'Password',
                  hintText: '********',
                  controller: _passwordCtrl,
                  isPassword: true,
                  isVisible: !_obscurePassword,
                  onVisibilityToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 6) return 'Minimum 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm Password
                CustomTextField(
                  label: 'Confirm Password',
                  hintText: '********',
                  controller: _confirmCtrl,
                  isPassword: true,
                  isVisible: !_obscureConfirm,
                  onVisibilityToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  validator: (v) {
                    if (v != _passwordCtrl.text) return 'Passwords do not match';
                    return null;
                  },
                ),

                // ── Optional: Branch ──────────────────────────────
                if (_showBranch) ...[
                  const SizedBox(height: 16),
                  _buildDropdown(
                    label: 'Branch / Department',
                    hintText: 'Select your branch',
                    items: _branches,
                    controller: _branchCtrl,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Branch is required' : null,
                  ),
                ],

                // ── Optional: Year ────────────────────────────────
                if (_showYear) ...[
                  const SizedBox(height: 16),
                  _buildDropdown(
                    label: 'Year of Study',
                    hintText: 'Select your year',
                    items: _years,
                    controller: _yearCtrl,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Year is required' : null,
                  ),
                ],

                const SizedBox(height: 32),

                // Submit
                PrimaryButton(
                  label: 'Sign Up',
                  isLoading: auth.isLoading,
                  onTap: _submit,
                ),
                const SizedBox(height: 32),

                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(color: Color(0xFF555555), fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String hintText,
    required List<String> items,
    required TextEditingController controller,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF888888),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: controller.text.isEmpty ? null : controller.text,
          validator: validator,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Color(0xFFB0B0B0),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.black12, width: 1),
            ),
          ),
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF888888)),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) {
            if (v != null) controller.text = v;
          },
          isExpanded: true,
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ],
    );
  }
}

// ── User type pill selector ────────────────────────────────────────────────────
class _UserTypeSelector extends StatelessWidget {
  final UserType selected;
  final List<UserType> types;
  final Map<UserType, String> labels;
  final ValueChanged<UserType> onChanged;

  const _UserTypeSelector({
    required this.selected,
    required this.types,
    required this.labels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: types.map((t) {
        final isSelected = t == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(t),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              alignment: Alignment.center,
              child: Text(
                labels[t] ?? '',
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF555555),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

