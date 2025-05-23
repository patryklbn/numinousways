import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../utils/validators.dart';
import '../../services/retreat_service.dart';
import '../../services/login_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  String? _selectedGender;
  DateTime? _selectedDate;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isDeleting = false;
  bool _needsReauthentication = false;
  bool _isAuthorized = false;
  bool _isCheckingAuth = true;
  bool _isLoadingProfile = true;

  // Firebase URL for the default avatar
  final String defaultAvatarUrl = 'https://firebasestorage.googleapis.com/v0/b/numinousway.firebasestorage.app/o/profile_images%2Fdefault_avatar.png?alt=media&token=d6afd74a-433c-4713-b8fc-73ffaa18d49c';

  @override
  void initState() {
    super.initState();

    // Initialize the controllers here to avoid LateInitializationError
    _nameController = TextEditingController();
    _locationController = TextEditingController();

    // Security check verify the user is editing their own profile
    _verifyAuthorization();
  }

  // Check if the user is authorized to edit this profile
  Future<void> _verifyAuthorization() async {
    setState(() {
      _isCheckingAuth = true;
    });

    try {
      final loginProvider = Provider.of<LoginProvider>(context, listen: false);
      final profileViewModel = Provider.of<ProfileViewModel>(context, listen: false);

      // Get the current authenticated user ID
      final currentAuthUserId = loginProvider.userId;
      print('EditProfileScreen - Auth User ID: $currentAuthUserId');

      if (currentAuthUserId == null) {
        print('SECURITY VIOLATION: No authenticated user found');
        _exitUnauthorized('You must be logged in to edit a profile');
        return;
      }

      //  load the profile for the current logged in user
      await profileViewModel.forceRefreshProfile(currentAuthUserId);


      await Future.delayed(const Duration(milliseconds: 300));

      // check if we have a profile
      final profileUserId = profileViewModel.userProfile?.id;

      print('EditProfileScreen - Profile User ID: $profileUserId');
      print('EditProfileScreen - Profile Status: ${profileViewModel.getProfileStatus()}');

      if (profileUserId == null) {
        print('SECURITY VIOLATION: No profile ID found after fetching');
        _exitUnauthorized('Unable to determine profile ownership');
        return;
      }

      if (currentAuthUserId != profileUserId) {
        print('SECURITY VIOLATION: Attempted to edit another user\'s profile');
        print('Auth User: $currentAuthUserId');
        print('Profile User: $profileUserId');
        _exitUnauthorized('You can only edit your own profile');
        return;
      }

      // User is authorized - proceed with loading the profile data
      print('Authorization successful - user is editing their own profile');
      setState(() {
        _isAuthorized = true;
        _isCheckingAuth = false;
      });

      // Now load the profile data
      _loadProfileData();

    } catch (e) {
      print('Error during authorization check: $e');
      _exitUnauthorized('An error occurred while verifying your identity');
    }
  }

  // Handle unauthorized access
  void _exitUnauthorized(String message) {
    setState(() {
      _isAuthorized = false;
      _isCheckingAuth = false;
    });

    // Exit the edit screen after showing a message
    Future.microtask(() {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );

      // Return to previous screen
      Navigator.of(context).pop();
    });
  }

  // Load profile data after authorization is confirmed
  void _loadProfileData() {
    setState(() {
      _isLoadingProfile = true;
    });

    final profileViewModel = Provider.of<ProfileViewModel>(context, listen: false);
    final userProfile = profileViewModel.userProfile;

    print('Loading profile data:');
    print('  UserProfile: ${userProfile != null ? 'exists' : 'null'}');
    if (userProfile != null) {
      print('  ID: ${userProfile.id}');
      print('  Name: ${userProfile.name}');
    }

    // Set values to controllers after they've been initialized
    _nameController.text = userProfile?.name ?? '';
    _locationController.text = userProfile?.location ?? '';
    _selectedGender = userProfile?.gender;
    if (userProfile?.age != null) {
      _selectedDate = DateTime.tryParse(userProfile!.age!);
    }

    setState(() {
      _isLoadingProfile = false;
    });
  }

  @override
  void dispose() {
    // dispose of controllers
    _nameController.dispose();
    _locationController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate ?? DateTime(2000),
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF6A0DAD),
                onPrimary: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          );
        }
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    // Verify user is still authenticated
    final loginProvider = Provider.of<LoginProvider>(context, listen: false);
    final profileViewModel = Provider.of<ProfileViewModel>(context, listen: false);

    if (loginProvider.userId == null || loginProvider.userId != profileViewModel.userProfile?.id) {
      _exitUnauthorized('Your session has expired. Please log in again.');
      return;
    }

    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });

      await profileViewModel.uploadProfileImage(_selectedImage!, loginProvider.userId!);
    }
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt, color: Color(0xFF6A0DAD)),
            title: const Text('Take a Photo'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library, color: Color(0xFF6A0DAD)),
            title: const Text('Choose from Gallery'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
          ),
        ],
      ),
    );
  }

  // Show reauthentication dialog with better error handling
  Future<bool> _showReauthenticationDialog() async {
    _passwordController.clear();
    bool isAuthenticating = false;
    String? errorMessage;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text(
                  'Confirm Your Password',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'For your security, please confirm your password before deleting your account.',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          errorText: errorMessage,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Color(0xFF6A0DAD)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        obscureText: true,
                      ),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    onPressed: isAuthenticating
                        ? null
                        : () {
                      Navigator.of(dialogContext).pop(false);
                    },
                  ),
                  TextButton(
                    child: isAuthenticating
                        ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.red[700]!),
                      ),
                    )
                        : Text(
                      'Confirm',
                      style: TextStyle(color: Colors.red[700]),
                    ),
                    onPressed: isAuthenticating
                        ? null
                        : () async {
                      setState(() {
                        isAuthenticating = true;
                        errorMessage = null;
                      });

                      final loginProvider = Provider.of<LoginProvider>(context, listen: false);
                      final success = await loginProvider.reauthenticateUser(_passwordController.text);

                      if (success) {
                        Navigator.of(dialogContext).pop(true);
                      } else {
                        setState(() {
                          isAuthenticating = false;
                          errorMessage = loginProvider.errorMessage ?? 'Incorrect password. Please try again.';
                        });
                      }
                    },
                  ),
                ],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              );
            }
        );
      },
    );

    return result ?? false;
  }

  // Show delete account confirmation dialog
  Future<void> _showDeleteAccountDialog() async {
    // Verify user is still authenticated
    final loginProvider = Provider.of<LoginProvider>(context, listen: false);
    final profileViewModel = Provider.of<ProfileViewModel>(context, listen: false);

    if (loginProvider.userId == null || loginProvider.userId != profileViewModel.userProfile?.id) {
      _exitUnauthorized('Your session has expired. Please log in again.');
      return;
    }

    //  user is authenticated recently before proceeding
    final reauthed = await _showReauthenticationDialog();
    if (!reauthed) return;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Delete Account',
            style: TextStyle(
              color: Colors.red[700],
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text(
                  'Are you sure you want to delete your account?',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This action cannot be undone. All your personal data, travel details, retreat information, and photos will be permanently deleted.',
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Text(
                    'For your security, you will be signed out immediately after your account is deleted.',
                    style: TextStyle(
                      color: Colors.red[800],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[700]),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: _isDeleting
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                ),
              )
                  : const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: _isDeleting
                  ? null
                  : () async {
                await _deleteAccount();
              },
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }

  // Handle account deletion
  Future<void> _deleteAccount() async {
    setState(() {
      _isDeleting = true;
    });

    try {
      final profileViewModel = Provider.of<ProfileViewModel>(context, listen: false);
      final loginProvider = Provider.of<LoginProvider>(context, listen: false);
      final retreatService = RetreatService();

      if (profileViewModel.userProfile?.id != null) {
        final userId = profileViewModel.userProfile!.id!;

        // Final security check before deletion
        if (loginProvider.userId != userId) {
          throw Exception('Security verification failed. User IDs do not match.');
        }

        try {
          // Delete user data from all retreats
          await retreatService.deleteUserData(userId);

          // Delete the user account
          final success = await profileViewModel.deleteUserAccount(userId);

          if (success) {
            // Close the dialog
            Navigator.of(context).pop();

            // Navigate to onboarding/login screen and clear navigation stack
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/onboarding',
                  (Route<dynamic> route) => false,
            );

            // Show confirmation snackbar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Your account has been deleted'),
                backgroundColor: Colors.red[700],
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          } else {
            // Handle errors
            throw Exception(profileViewModel.deleteError ?? 'Failed to delete account');
          }
        } catch (e) {
          rethrow;
        }
      }
    } catch (e) {
      print('Error deleting account: $e');

      // Close the dialog
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete account: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      setState(() {
        _isDeleting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileViewModel = Provider.of<ProfileViewModel>(context);

    // Security check loading state
    if (_isCheckingAuth) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Edit Profile'),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6A0DAD), Color(0xFF3700B3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6A0DAD)),
              ),
              SizedBox(height: 16),
              Text(
                'Verifying account...',
                style: TextStyle(
                  color: Color(0xFF6A0DAD),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Not authorized

    if (!_isAuthorized) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Access Denied'),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade700, Colors.red.shade900],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text(
                'Unauthorized Access',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You do not have permission to edit this profile.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red[700],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Return to previous screen'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Edit Profile'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A0DAD), Color(0xFF3700B3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: profileViewModel.isLoading || profileViewModel.isDeletingAccount || _isLoadingProfile
          ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6A0DAD)),
              ),
              const SizedBox(height: 16),
              Text(
                profileViewModel.isDeletingAccount
                    ? 'Deleting account...'
                    : 'Loading profile...',
                style: const TextStyle(
                  color: Color(0xFF6A0DAD),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ))
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Profile image section
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 65,
                      backgroundColor: const Color(0xFFA785D3),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white,
                        child: ClipOval(
                          child: (_selectedImage != null)
                              ? Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                            width: 120,
                            height: 120,
                          )
                              : Image.network(
                            profileViewModel.profileImageUrl ?? defaultAvatarUrl,
                            fit: BoxFit.cover,
                            width: 120,
                            height: 120,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.network(
                                defaultAvatarUrl,
                                fit: BoxFit.cover,
                                width: 120,
                                height: 120,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _showImageSourceOptions,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6A0DAD), Color(0xFF3700B3)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Form fields
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: const TextStyle(color: Color(0xFF333333)),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF6A0DAD)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return Validators.validateName(value);
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedGender,
                items: ['Male', 'Female', 'Other']
                    .map((label) => DropdownMenuItem(
                  value: label,
                  child: Text(label),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Gender',
                  labelStyle: const TextStyle(color: Color(0xFF333333)),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF6A0DAD)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                readOnly: true,
                onTap: () => _selectDate(context),
                controller: TextEditingController(
                    text: _selectedDate != null ? "${_selectedDate!.toLocal()}".split(' ')[0] : ''),
                decoration: InputDecoration(
                  labelText: 'Birthdate',
                  labelStyle: const TextStyle(color: Color(0xFF333333)),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF6A0DAD)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: const Icon(Icons.calendar_today, color: Color(0xFF6A0DAD)),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Location',
                  labelStyle: const TextStyle(color: Color(0xFF333333)),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF6A0DAD)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: Validators.validateLocation,
              ),
              const SizedBox(height: 20),

              // Save button
              ElevatedButton(
                onPressed: () async {
                  // Reverify authentication before saving changes
                  final loginProvider = Provider.of<LoginProvider>(context, listen: false);
                  final profileViewModel = Provider.of<ProfileViewModel>(context, listen: false);

                  if (loginProvider.userId == null ||
                      loginProvider.userId != profileViewModel.userProfile?.id) {
                    _exitUnauthorized('Session expired. Please log in again.');
                    return;
                  }

                  if (_formKey.currentState!.validate()) {
                    await profileViewModel.updateUserProfile(
                      _nameController.text.trim(),
                      profileViewModel.userProfile?.bio ?? '',
                      _locationController.text.trim(),
                      gender: _selectedGender,
                      age: _selectedDate != null ? _selectedDate!.toIso8601String() : null,
                    );

                    await profileViewModel.fetchUserProfile(profileViewModel.userProfile!.id!);
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
                child: Ink(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF6A0DAD), Color(0xFF3700B3)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save_outlined, size: 20, color: Colors.white),
                        SizedBox(width: 12),
                        Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Delete account section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delete Account',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Permanently delete your account and all associated data. This action cannot be undone.',
                      style: TextStyle(
                        color: Colors.red[700],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _showDeleteAccountDialog,
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.red[100],
                        foregroundColor: Colors.red[800],
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.red[300]!),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.delete_forever, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Delete My Account',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}