import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:partner_app/screens/auth/services_you_offer_screen.dart';
import 'package:partner_app/screens/auth/login_screen.dart';
import 'package:partner_app/providers/auth_provider.dart';
import 'package:partner_app/providers/provider_profile_provider.dart';

class DobInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.length < oldValue.text.length) {
      return newValue;
    }

    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();

    for (int i = 0; i < digitsOnly.length && i < 8; i++) {
      if (i == 2 || i == 4) {
        buffer.write('/');
      }
      buffer.write(digitsOnly[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class TellUsAboutYourselfScreen extends ConsumerStatefulWidget {
  const TellUsAboutYourselfScreen({super.key});

  @override
  ConsumerState<TellUsAboutYourselfScreen> createState() => _TellUsAboutYourselfScreenState();
}

class _TellUsAboutYourselfScreenState extends ConsumerState<TellUsAboutYourselfScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _emailController = TextEditingController();
  final _languageController = TextEditingController();
  
  String? _selectedGender;
  String _selectedExperience = '0-1 years';
  List<String> _selectedLanguages = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _populateFields();
    });
  }

  void _populateFields() {
    final user = ref.read(authProvider).user;
    if (user != null) {
      if (_nameController.text.isEmpty && user.name != null && user.name!.isNotEmpty) {
        _nameController.text = user.name!;
      }
      if (_emailController.text.isEmpty && user.email != null && user.email!.isNotEmpty) {
        _emailController.text = user.email!;
      }
      if (_selectedGender == null && user.gender != null && user.gender!.isNotEmpty) {
        final g = user.gender!.trim().toLowerCase();
        if (g == 'male') {
          _selectedGender = 'Male';
        } else if (g == 'female') {
          _selectedGender = 'Female';
        } else if (g == 'other') {
          _selectedGender = 'Other';
        }
      }
    }

    final profile = ref.read(providerProfileProvider).profileData;
    final userData = profile?['user_id'];
    if (userData is Map) {
      if (_nameController.text.isEmpty && userData['name'] != null && userData['name'].toString().isNotEmpty) {
        _nameController.text = userData['name'].toString();
      }
      if (_emailController.text.isEmpty && userData['email'] != null && userData['email'].toString().isNotEmpty) {
        _emailController.text = userData['email'].toString();
      }
      if (_selectedGender == null && userData['gender'] != null && userData['gender'].toString().isNotEmpty) {
        final g = userData['gender'].toString().trim().toLowerCase();
        if (g == 'male') {
          _selectedGender = 'Male';
        } else if (g == 'female') {
          _selectedGender = 'Female';
        } else if (g == 'other') {
          _selectedGender = 'Other';
        }
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _emailController.dispose();
    _languageController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('en', 'GB'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF16155D),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  void _addLanguage() {
    final lang = _languageController.text.trim();
    if (lang.isNotEmpty) {
      // Capitalize first letter for neat display
      final capitalized = lang[0].toUpperCase() + lang.substring(1);
      if (!_selectedLanguages.contains(capitalized)) {
        setState(() {
          _selectedLanguages.add(capitalized);
          _languageController.clear();
        });
      }
    }
  }

  Future<void> _handleGoBack() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(providerProfileProvider, (_, next) {
      if (next.status == ProfileStatus.loaded) {
        _populateFields();
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleGoBack();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: _handleGoBack,
          ),
        ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar (Step 1 of 4)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: List.generate(
                  4,
                  (index) => Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: index == 3 ? 0 : 6),
                      decoration: BoxDecoration(
                        color: index == 0 ? const Color(0xFF16155D) : const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tell Us About Yourself',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF16155D),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Full Name
                      _buildLabel('Full Name'),
                      TextFormField(
                        controller: _nameController,
                        decoration: _buildInputDecoration('Enter your name'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Gender
                      _buildLabel('Gender'),
                      Row(
                        children: [
                          Expanded(child: _buildGenderCard('Male', Icons.male)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildGenderCard('Female', Icons.female)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildGenderCard('Other', Icons.transgender)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Date of Birth
                      _buildLabel('Date of Birth'),
                      TextFormField(
                        controller: _dobController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          DobInputFormatter(),
                        ],
                        decoration: _buildInputDecoration('DD/MM/YYYY').copyWith(
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_month, color: Color(0xFF16155D)),
                            onPressed: () => _selectDate(context),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your date of birth';
                          }
                          if (value.length < 10) {
                            return 'Please enter a valid date (DD/MM/YYYY)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Email Address
                      _buildLabel('Email Address'),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _buildInputDecoration('name@example.com'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email address';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Experience Level
                      _buildLabel('Experience Level'),
                      Row(
                        children: [
                          Expanded(child: _buildExperienceCard('0-1 years')),
                          const SizedBox(width: 10),
                          Expanded(child: _buildExperienceCard('2-5 years')),
                          const SizedBox(width: 10),
                          Expanded(child: _buildExperienceCard('5+ years')),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Languages
                      _buildLabel('Languages'),
                      TextFormField(
                        controller: _languageController,
                        decoration: _buildInputDecoration('Type language (e.g. English, Tamil)').copyWith(
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.add_circle, color: Color(0xFF16155D), size: 28),
                            onPressed: _addLanguage,
                          ),
                        ),
                        onFieldSubmitted: (_) => _addLanguage(),
                      ),
                      if (_selectedLanguages.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F6FA),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _selectedLanguages.map((lang) => Chip(
                              label: Text(
                                lang,
                                style: const TextStyle(fontSize: 14, color: Colors.black87),
                              ),
                              deleteIcon: const Icon(Icons.close, size: 14, color: Colors.black54),
                              onDeleted: () {
                                setState(() {
                                  _selectedLanguages.remove(lang);
                                });
                              },
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide.none,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            )).toList(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
            
            // Bottom Action Button
            Padding(
              padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 20.0, top: 10.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: Consumer(
                  builder: (context, ref, child) {
                    final authState = ref.watch(authProvider);
                    final isLoading = authState.status == AuthStatus.loading;

                    return ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate()) {
                                if (_selectedGender == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please select your gender')),
                                  );
                                  return;
                                }

                                final name = _nameController.text.trim();
                                final email = _emailController.text.trim();
                                final gender = _selectedGender!.toLowerCase();

                                final success = await ref
                                    .read(authProvider.notifier)
                                    .registerUser(
                                      name: name,
                                      email: email,
                                      gender: gender,
                                    );

                                if (success && mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ServicesYouOfferScreen(),
                                    ),
                                  );
                                } else if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        ref.read(authProvider).errorMessage ?? 'Registration failed',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16155D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Continue',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.chevron_right, color: Colors.white, size: 18),
                              ],
                            ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black38, fontSize: 15),
      filled: true,
      fillColor: const Color(0xFFF5F6FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      errorStyle: const TextStyle(fontSize: 12, height: 0.8),
    );
  }

  Widget _buildGenderCard(String gender, IconData icon) {
    final isSelected = _selectedGender == gender;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = gender;
        });
      },
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF1FE) : const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF16155D) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? const Color(0xFF16155D) : Colors.black54,
            ),
            const SizedBox(width: 6),
            Text(
              gender,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF16155D) : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExperienceCard(String exp) {
    final isSelected = _selectedExperience == exp;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedExperience = exp;
        });
      },
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF1FE) : const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF16155D) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            exp,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? const Color(0xFF16155D) : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
