import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/database_service.dart';
import '../theme/app_colors.dart';

class ProfileTab extends StatefulWidget {
  final ValueChanged<UserProfile>? onProfileUpdated;

  const ProfileTab({super.key, this.onProfileUpdated});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _formKey = GlobalKey<FormState>();

  // Patient controllers
  final _patientNameController = TextEditingController();
  final _patientAgeController = TextEditingController();
  final _patientLocationController = TextEditingController();
  final _patientPhoneController = TextEditingController();
  String _patientGender = 'Male';

  // Caretaker controllers
  final _caretakerEmailController = TextEditingController();
  final _caretakerNameController = TextEditingController();
  final _caretakerPhoneController = TextEditingController();
  String _caretakerGender = 'Female';

  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await DatabaseService.instance.getProfile();
    if (!mounted) return;

    setState(() {
      _patientNameController.text = profile.patientName;
      _patientAgeController.text = profile.patientAge;
      _patientLocationController.text = profile.patientLocation;
      _patientPhoneController.text = profile.patientPhone;
      _patientGender = _genderOptions.contains(profile.patientGender)
          ? profile.patientGender
          : 'Male';

      _caretakerEmailController.text = profile.caretakerEmail;
      _caretakerNameController.text = profile.caretakerName;
      _caretakerPhoneController.text = profile.caretakerPhone;
      _caretakerGender = _genderOptions.contains(profile.caretakerGender)
          ? profile.caretakerGender
          : 'Female';

      _isLoading = false;
    });

    widget.onProfileUpdated?.call(profile);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final updatedProfile = UserProfile(
      id: 1,
      patientName: _patientNameController.text.trim(),
      patientAge: _patientAgeController.text.trim(),
      patientLocation: _patientLocationController.text.trim(),
      patientGender: _patientGender,
      patientPhone: _patientPhoneController.text.trim(),
      caretakerEmail: _caretakerEmailController.text.trim(),
      caretakerName: _caretakerNameController.text.trim(),
      caretakerPhone: _caretakerPhoneController.text.trim(),
      caretakerGender: _caretakerGender,
    );

    await DatabaseService.instance.saveProfile(updatedProfile);

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    widget.onProfileUpdated?.call(updatedProfile);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Profile saved successfully!'),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    _patientAgeController.dispose();
    _patientLocationController.dispose();
    _patientPhoneController.dispose();
    _caretakerEmailController.dispose();
    _caretakerNameController.dispose();
    _caretakerPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryBlue),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPatientSection(),
            const SizedBox(height: 18),
            _buildCaretakerSection(),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveProfile,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(
                  _isSaving ? 'Saving Profile...' : 'Save Profile',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientSection() {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: AppColors.primaryBlue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  '1. Patient Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textNavy,
                  ),
                ),
              ],
            ),
            const Divider(color: AppColors.borderLight, height: 24),
            _buildTextField(
              controller: _patientNameController,
              label: 'Patient Name',
              hint: 'e.g. Rahul',
              icon: Icons.badge_outlined,
              validator: (val) =>
                  (val == null || val.trim().isEmpty) ? 'Please enter patient name' : null,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildTextField(
                    controller: _patientAgeController,
                    label: 'Age',
                    hint: 'e.g. 24',
                    icon: Icons.calendar_today_outlined,
                    keyboardType: TextInputType.number,
                    validator: (val) =>
                        (val == null || val.trim().isEmpty) ? 'Enter age' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: _buildGenderDropdown(
                    value: _patientGender,
                    label: 'Gender',
                    onChanged: (val) {
                      if (val != null) setState(() => _patientGender = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _patientLocationController,
              label: 'Location',
              hint: 'e.g. #24, Room 1, Manipal',
              icon: Icons.location_on_outlined,
              validator: (val) =>
                  (val == null || val.trim().isEmpty) ? 'Please enter location' : null,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _patientPhoneController,
              label: 'Phone Number',
              hint: 'e.g. 9876543210',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (val) =>
                  (val == null || val.trim().isEmpty) ? 'Please enter phone number' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaretakerSection() {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.health_and_safety_outlined,
                    color: AppColors.primaryBlue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  '2. Caretaker Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textNavy,
                  ),
                ),
              ],
            ),
            const Divider(color: AppColors.borderLight, height: 24),
            _buildTextField(
              controller: _caretakerEmailController,
              label: 'Caretaker Email',
              hint: 'e.g. caretaker@gmail.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter caretaker email';
                }
                if (!val.contains('@') || !val.contains('.')) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _caretakerNameController,
              label: 'Caretaker Name',
              hint: 'e.g. Dr. Anita Sharma',
              icon: Icons.person_outline,
              validator: (val) =>
                  (val == null || val.trim().isEmpty) ? 'Please enter caretaker name' : null,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: _buildTextField(
                    controller: _caretakerPhoneController,
                    label: 'Phone Number',
                    hint: 'e.g. 9123456780',
                    icon: Icons.phone_android_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (val) =>
                        (val == null || val.trim().isEmpty) ? 'Enter phone number' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: _buildGenderDropdown(
                    value: _caretakerGender,
                    label: 'Gender',
                    onChanged: (val) {
                      if (val != null) setState(() => _caretakerGender = val);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        fontSize: 15,
        color: AppColors.textNavy,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.inactive, fontSize: 13),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.primaryBlue, size: 20),
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildGenderDropdown({
    required String value,
    required String label,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: _genderOptions
          .map((g) => DropdownMenuItem(
                value: g,
                child: Text(
                  g,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textNavy,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
        ),
      ),
    );
  }
}
