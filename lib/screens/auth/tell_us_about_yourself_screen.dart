import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:partner_app/screens/auth/services_you_offer_screen.dart';
import 'package:partner_app/providers/auth_provider.dart';

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
  
  String? _selectedGender;
  String _selectedExperience = '0-1 years';
  List<String> _selectedLanguages = ['English', 'Hindi', 'Kannada'];

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
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
        _dobController.text = "${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  void _addLanguage() {
    final List<String> availableLanguages = [
      'Tamil', 'Telugu', 'Bengali', 'Marathi', 'Gujarati', 'Punjabi', 'Malayalam'
    ];
    final unselected = availableLanguages.where((l) => !_selectedLanguages.contains(l)).toList();
    if (unselected.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Language'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: unselected.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(unselected[index]),
                onTap: () {
                  setState(() {
                    _selectedLanguages.add(unselected[index]);
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
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
                        readOnly: true,
                        onTap: () => _selectDate(context),
                        decoration: _buildInputDecoration('mm/dd/yyyy').copyWith(
                          suffixIcon: const Icon(Icons.calendar_month, color: Color(0xFF16155D)),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select your date of birth';
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
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            ..._selectedLanguages.map((lang) => Chip(
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
                            )),
                            GestureDetector(
                              onTap: _addLanguage,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                child: Text(
                                  'Add more...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
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
