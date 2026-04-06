import 'dart:io';
import 'package:flutter/material.dart';
import 'package:econosmart/theme/app_colors.dart';
import 'package:econosmart/auth_service.dart';
import 'package:econosmart/welcome_screen.dart';
import 'package:image_picker/image_picker.dart';

class AccountDetailsPage extends StatefulWidget {
  const AccountDetailsPage({super.key});

  @override
  State<AccountDetailsPage> createState() => _AccountDetailsPageState();
}

class _AccountDetailsPageState extends State<AccountDetailsPage> {
  final _authService = AuthService();
  Map<String, dynamic>? _userData;
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  File? _profileImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked != null) {
      setState(() => _profileImage = File(picked.path));
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final data = await _authService.getUserData();
    setState(() {
      _userData = data;
      _usernameController.text = _userData?['username'] as String? ?? '';
    });
  }

  Future<void> _saveChanges() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    if (username.isEmpty && password.isEmpty && _profileImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a username or new password.')),
      );
      return;
    }

    setState(() => _loading = true);
    String? error;
    if (username.isNotEmpty) {
      error = await _authService.updateUsername(username);
    }
    if (password.isNotEmpty && error == null) {
      error = await _authService.updatePassword(password);
    }
    
    // If a new image was picked, upload it to the database/storage
    if (_profileImage != null && error == null) {
      // Note: Assuming updateProfileImage exists in your AuthService
      // If not, you'll need to implement this method to save the image to Firebase/DB
      error = await _authService.updateProfileImage(_profileImage!);
    }

    setState(() => _loading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
      );
      return;
    }

    await _loadUser();
    _passwordController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account updated successfully.')),
    );
  }

  Future<void> _logout() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final email = _userData?['email'] as String? ?? 'Not available';
    final username = _userData?['username'] as String? ?? 'User';
    final profileUrl = _userData?['profileImageUrl'] as String?;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryTeal),
        title: const Text(
          'Account Details',
          style: TextStyle(color: AppColors.textDark),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryTeal.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 62,
                            height: 62,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(18),
                              image: _profileImage != null
                                  ? DecorationImage(
                                      image: FileImage(_profileImage!),
                                      fit: BoxFit.cover)
                                  : (profileUrl != null
                                      ? DecorationImage(
                                          image: NetworkImage(profileUrl),
                                          fit: BoxFit.cover)
                                      : null),
                            ),
                            child: _profileImage == null && profileUrl == null
                                ? const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 30,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                username,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                email,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        _InfoPill(
                            label: 'Verified',
                            icon: Icons.verified,
                            color: Colors.white),
                        const SizedBox(width: 12),
                        _InfoPill(
                            label: 'Secure',
                            icon: Icons.shield,
                            color: Colors.white),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Welcome back! Keep your account secure, and update your credentials anytime.',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 13, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Update Account',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Change your username or set a new password to keep your profile secure.',
                style: TextStyle(
                    color: AppColors.textGrey, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.inputBg,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: AppColors.inputBg),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Username',
                        style: TextStyle(color: AppColors.textGrey)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _usernameController,
                      style: const TextStyle(color: AppColors.textDark),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        hintText: 'Enter username',
                        hintStyle: const TextStyle(color: AppColors.textGrey),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 18),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text('Email',
                        style: TextStyle(color: AppColors.textGrey)),
                    const SizedBox(height: 10),
                    TextFormField(
                      initialValue: email,
                      enabled: false,
                      style: const TextStyle(color: AppColors.textDark),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 18),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text('New Password',
                        style: TextStyle(color: AppColors.textGrey)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: const TextStyle(color: AppColors.textDark),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        hintText: 'Enter new password',
                        hintStyle: const TextStyle(color: AppColors.textGrey),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 18),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: const [
                        Icon(Icons.info_outline,
                            color: AppColors.textGrey, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Use at least 8 characters with a mix of letters and numbers.',
                            style: TextStyle(
                                color: AppColors.textGrey, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: _loading ? null : _saveChanges,
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Save Changes',
                        style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 14),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryTeal,
                  side: const BorderSide(color: AppColors.primaryTeal),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: _logout,
                child: const Text('Logout',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _InfoPill({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
