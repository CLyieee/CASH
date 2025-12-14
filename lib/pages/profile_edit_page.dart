import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import '../controllers/app_controller.dart';
import '../utils/app_text.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final AppController controller = Get.find<AppController>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  bool _isLoading = false;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: controller.userName.value);
    _phoneController =
        TextEditingController(text: controller.phoneNumber.value);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      _showSnackbar('Error', 'Name cannot be empty', isError: true);
      return;
    }

    if (phone.isNotEmpty && !_isValidPhoneNumber(phone)) {
      _showSnackbar('Error', 'Invalid phone number format', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      controller.setUserName(name);
      if (phone.isNotEmpty) {
        controller.setPhoneNumber(phone);
      }

      await controller.saveUserData();

      if (mounted) {
        _showSnackbar('Success', 'Profile updated successfully!',
            isError: false);
        await Future.delayed(const Duration(milliseconds: 800));
        Get.back();
      }
    } catch (e) {
      if (mounted) {
        _showSnackbar('Erroamnr', 'Failed to update profile: $e',
            isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickAndUploadProfilePhoto() async {
    final uid = controller.currentUserId.value;
    if (uid.isEmpty) {
      _showSnackbar('Error', 'Please sign in first', isError: true);
      return;
    }

    setState(() => _isUploadingPhoto = true);

    try {
      print('📸 Starting image picker...');
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 400,
        maxHeight: 400,
      );

      if (picked == null) {
        print('❌ No image selected');
        setState(() => _isUploadingPhoto = false);
        return;
      }

      print('✅ Image selected: ${picked.name}');
      print('🔄 Reading image bytes...');
      final Uint8List bytes = await picked.readAsBytes();
      print('✅ Read ${bytes.length} bytes');

      print('🔄 Uploading to Firebase Storage...');
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'users/$uid/$fileName';
      print('📁 Upload path: $path');

      final storageRef = FirebaseStorage.instance.ref().child(path);
      print('📍 Storage reference: ${storageRef.fullPath}');

      print('⬆️ Starting putData...');
      final uploadTask = storageRef.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      print('⏳ Waiting for upload to complete...');
      final taskSnapshot = await uploadTask.whenComplete(() {
        print('✅ Upload whenComplete triggered');
      });

      print('✅ Upload complete, state: ${taskSnapshot.state}');
      print(
          '📊 Bytes transferred: ${taskSnapshot.bytesTransferred}/${taskSnapshot.totalBytes}');

      // Verify upload was successful
      if (taskSnapshot.state != TaskState.success) {
        throw Exception('Upload failed with state: ${taskSnapshot.state}');
      }

      // Wait a bit for Firebase to index the file
      print('⏱️ Waiting for file to be indexed...');
      await Future.delayed(const Duration(seconds: 2));

      print('🔄 Getting download URL...');
      print('📍 From ref: ${taskSnapshot.ref.fullPath}');

      // Try to get metadata first to confirm file exists
      try {
        final metadata = await taskSnapshot.ref.getMetadata();
        print('✅ File exists! Size: ${metadata.size} bytes');
      } catch (e) {
        print('❌ File metadata check failed: $e');
        throw Exception('File was uploaded but cannot be found: $e');
      }

      final url = await taskSnapshot.ref.getDownloadURL();
      print('✅ Download URL: $url');

      print('🔄 Saving to Firestore...');
      controller.setPhotoUrl(url);
      print('✅ Profile photo updated successfully');

      if (mounted) {
        _showSnackbar('Success', 'Profile photo updated', isError: false);
      }
    } catch (e, stackTrace) {
      print('❌ Upload error: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        _showErrorDialog(
            'Upload Failed', 'Error: $e\n\nStack trace:\n$stackTrace');
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: SelectableText(
            message,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              // Copy to clipboard would require clipboard package
              Navigator.pop(context);
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  bool _isValidPhoneNumber(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-()]'), '');
    return RegExp(r'^\+?63\d{10}$').hasMatch(cleaned) ||
        RegExp(r'^09\d{9}$').hasMatch(cleaned);
  }

  void _showSnackbar(String title, String message, {required bool isError}) {
    if (!mounted) return;
    final palette = _ProfilePalette(Theme.of(context));
    Get.snackbar(
      title,
      message,
      backgroundColor: isError ? palette.error : palette.success,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 16,
      duration: const Duration(seconds: 2),
      icon: Icon(
        isError
            ? Icons.error_outline_rounded
            : Icons.check_circle_outline_rounded,
        color: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _ProfilePalette(theme);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // M3 Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Material(
                      color: palette.surfaceContainer,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Get.back(),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: palette.onSurface,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Edit Profile',
                      style: AppText.poppins(
                        color: palette.onSurface,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Profile Avatar
                  _buildProfileAvatar(palette),
                  const SizedBox(height: 32),

                  // Name Field
                  _buildM3TextField(
                    controller: _nameController,
                    label: 'Full Name',
                    hint: 'Enter your full name',
                    icon: Icons.person_rounded,
                    palette: palette,
                  ),
                  const SizedBox(height: 20),

                  // Phone Field
                  _buildM3TextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    hint: '+63 912 345 6789',
                    icon: Icons.phone_rounded,
                    keyboardType: TextInputType.phone,
                    palette: palette,
                  ),
                  const SizedBox(height: 20),

                  // Change PIN
                  _buildChangePinTile(palette),
                  const SizedBox(height: 12),

                  // PIN Info
                  _buildInfoBanner(palette),
                  const SizedBox(height: 32),

                  // Action Buttons
                  _buildActionButtons(palette),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(_ProfilePalette palette) {
    return Center(
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              palette.primary,
              palette.primary.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: palette.primary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(
          Icons.person_rounded,
          color: Colors.white,
          size: 48,
        ),
      ),
    );
  }

  Widget _buildM3TextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required _ProfilePalette palette,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppText.poppins(
            color: palette.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: palette.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: AppText.poppins(
              color: palette.onSurface,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppText.poppins(
                color: palette.onSurfaceVariant.withOpacity(0.6),
                fontSize: 14,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.only(left: 4),
                child: Icon(icon, color: palette.primary, size: 22),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: palette.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChangePinTile(_ProfilePalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Security',
          style: AppText.poppins(
            color: palette.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: palette.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showChangePinDialog(palette),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: palette.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.lock_rounded,
                        color: palette.onPrimaryContainer,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Change PIN',
                            style: AppText.poppins(
                              color: palette.onSurface,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Update your 4-digit security PIN',
                            style: AppText.poppins(
                              color: palette.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: palette.outline,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBanner(_ProfilePalette palette) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: palette.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your PIN is used for secure transactions and app access',
              style: AppText.poppins(
                color: palette.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(_ProfilePalette palette) {
    return Column(
      children: [
        // Save Button
        SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton(
            onPressed: _isLoading ? null : _saveProfile,
            style: FilledButton.styleFrom(
              backgroundColor: palette.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: palette.primary.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    'Save Changes',
                    style: AppText.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        // Cancel Button
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Get.back(),
            style: OutlinedButton.styleFrom(
              foregroundColor: palette.onSurface,
              side: BorderSide(color: palette.outline),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Cancel',
              style: AppText.poppins(
                color: palette.onSurfaceVariant,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showChangePinDialog(_ProfilePalette palette) {
    String currentPin = '';
    String newPin = '';
    String confirmPin = '';
    int step = 1;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          String getTitle() {
            if (step == 1) return 'Enter Current PIN';
            if (step == 2) return 'Enter New PIN';
            return 'Confirm New PIN';
          }

          String getSubtitle() {
            if (step == 1) return 'Verify your current 4-digit PIN';
            if (step == 2) return 'Enter your new 4-digit PIN';
            return 'Re-enter your new PIN to confirm';
          }

          void onNumberPressed(String number) {
            setDialogState(() {
              if (step == 1) {
                if (currentPin.length < 4) {
                  currentPin += number;
                  if (currentPin.length == 4) {
                    if (currentPin == controller.pin.value) {
                      Future.delayed(const Duration(milliseconds: 300), () {
                        setDialogState(() => step = 2);
                      });
                    } else {
                      Future.delayed(const Duration(milliseconds: 300), () {
                        setDialogState(() => currentPin = '');
                        _showSnackbar('Error', 'Incorrect PIN', isError: true);
                      });
                    }
                  }
                }
              } else if (step == 2) {
                if (newPin.length < 4) {
                  newPin += number;
                  if (newPin.length == 4) {
                    Future.delayed(const Duration(milliseconds: 300), () {
                      setDialogState(() => step = 3);
                    });
                  }
                }
              } else if (step == 3) {
                if (confirmPin.length < 4) {
                  confirmPin += number;
                  if (confirmPin.length == 4) {
                    if (confirmPin == newPin) {
                      Future.delayed(const Duration(milliseconds: 300), () {
                        controller.setPin(newPin);
                        controller.saveUserData();
                        Navigator.of(dialogContext).pop();
                        _showSnackbar('Success', 'PIN changed successfully!',
                            isError: false);
                      });
                    } else {
                      Future.delayed(const Duration(milliseconds: 300), () {
                        setDialogState(() {
                          confirmPin = '';
                          newPin = '';
                          step = 2;
                        });
                        _showSnackbar('Error', 'PINs do not match',
                            isError: true);
                      });
                    }
                  }
                }
              }
            });
          }

          void onDeletePressed() {
            setDialogState(() {
              if (step == 1 && currentPin.isNotEmpty) {
                currentPin = currentPin.substring(0, currentPin.length - 1);
              } else if (step == 2 && newPin.isNotEmpty) {
                newPin = newPin.substring(0, newPin.length - 1);
              } else if (step == 3 && confirmPin.isNotEmpty) {
                confirmPin = confirmPin.substring(0, confirmPin.length - 1);
              }
            });
          }

          String getCurrentPin() {
            if (step == 1) return currentPin;
            if (step == 2) return newPin;
            return confirmPin;
          }

          return Dialog(
            backgroundColor: palette.surfaceContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: palette.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.lock_rounded,
                          color: palette.onPrimaryContainer,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          getTitle(),
                          style: AppText.poppins(
                            color: palette.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: palette.outline),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    getSubtitle(),
                    style: AppText.poppins(
                      color: palette.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // PIN Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      4,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index < getCurrentPin().length
                              ? palette.primary
                              : Colors.transparent,
                          border: Border.all(
                            color: index < getCurrentPin().length
                                ? palette.primary
                                : palette.outline,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Number Pad
                  Column(
                    children: [
                      for (int row = 0; row < 3; row++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              for (int col = 1; col <= 3; col++)
                                _buildM3NumberButton(
                                  '${row * 3 + col}',
                                  onNumberPressed,
                                  palette,
                                ),
                            ],
                          ),
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          const SizedBox(width: 60, height: 60),
                          _buildM3NumberButton('0', onNumberPressed, palette),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: onDeletePressed,
                              borderRadius: BorderRadius.circular(30),
                              child: Container(
                                width: 60,
                                height: 60,
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.backspace_outlined,
                                  color: palette.onSurfaceVariant,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Step Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: index + 1 == step ? 20 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: index + 1 == step
                              ? palette.primary
                              : palette.outline.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildM3NumberButton(
    String number,
    Function(String) onPressed,
    _ProfilePalette palette,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onPressed(number),
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 60,
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: palette.containerHigh,
          ),
          child: Text(
            number,
            style: AppText.poppins(
              color: palette.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// M3 Color Palette
class _ProfilePalette {
  _ProfilePalette(ThemeData theme)
      : isDark = theme.brightness == Brightness.dark,
        background = theme.brightness == Brightness.dark
            ? const Color(0xFF0D1117)
            : const Color(0xFFFCFCFF),
        surfaceContainer = theme.brightness == Brightness.dark
            ? const Color(0xFF1C2128)
            : const Color(0xFFF3F3F6),
        containerHigh = theme.brightness == Brightness.dark
            ? const Color(0xFF262C36)
            : const Color(0xFFEAEAED),
        onSurface = theme.colorScheme.onSurface,
        onSurfaceVariant = theme.brightness == Brightness.dark
            ? const Color(0xFF9CA3AF)
            : const Color(0xFF6B7280),
        primary = theme.brightness == Brightness.dark
            ? const Color(0xFF93C5FD)
            : const Color(0xFF2563EB),
        primaryContainer = theme.brightness == Brightness.dark
            ? const Color(0xFF1E3A5F)
            : const Color(0xFFDBEAFE),
        onPrimaryContainer = theme.brightness == Brightness.dark
            ? const Color(0xFFDBEAFE)
            : const Color(0xFF1E3A5F),
        outline = theme.brightness == Brightness.dark
            ? const Color(0xFF4B5563)
            : const Color(0xFFD1D5DB),
        error = theme.brightness == Brightness.dark
            ? const Color(0xFFFCA5A5)
            : const Color(0xFFDC2626),
        success = theme.brightness == Brightness.dark
            ? const Color(0xFF6EE7B7)
            : const Color(0xFF10B981);

  final bool isDark;
  final Color background;
  final Color surfaceContainer;
  final Color containerHigh;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color primary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color outline;
  final Color error;
  final Color success;
}
