import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../controllers/gemini_controller.dart';
import '../utils/app_text.dart';
import 'package:g/utils/responsive_helper.dart';

class _AIChatPalette {
  _AIChatPalette(ThemeData theme)
      : isDark = theme.brightness == Brightness.dark,
        // M3 surface + containers
        background = theme.brightness == Brightness.dark
            ? const Color(0xFF0D1117)
            : const Color(0xFFFCFCFF),
        surfaceContainer = theme.brightness == Brightness.dark
            ? const Color(0xFF1C2128)
            : const Color(0xFFF3F3F6),
        containerHigh = theme.brightness == Brightness.dark
            ? const Color(0xFF262C36)
            : const Color(0xFFEAEAED),
        cardSurface = theme.brightness == Brightness.dark
            ? const Color(0xFF1C2128)
            : const Color(0xFFFDFDFE),
        cardBorder = theme.brightness == Brightness.dark
            ? const Color(0xFF2D323B)
            : const Color(0xFFE6E8EC),
        // M3 text colors
        textPrimary = theme.colorScheme.onSurface,
        textSecondary = theme.brightness == Brightness.dark
            ? const Color(0xFF9CA3AF)
            : const Color(0xFF6B7280),
        // M3 primary palette
        accentBlue = theme.brightness == Brightness.dark
            ? const Color(0xFF93C5FD)
            : const Color(0xFF2563EB),
        primaryContainer = theme.brightness == Brightness.dark
            ? const Color(0xFF1E3A5F)
            : const Color(0xFFDBEAFE),
        onPrimaryContainer = theme.brightness == Brightness.dark
            ? const Color(0xFFDBEAFE)
            : const Color(0xFF1E3A5F),
        // M3 outline
        outline = theme.brightness == Brightness.dark
            ? const Color(0xFF4B5563)
            : const Color(0xFFD1D5DB),
        outlineVariant = theme.brightness == Brightness.dark
            ? const Color(0xFF374151)
            : const Color(0xFFE5E7EB),
        // Bubbles
        userBubble = theme.brightness == Brightness.dark
            ? const Color(0xFF2563EB)
            : const Color(0xFF2563EB),
        aiBubble = theme.brightness == Brightness.dark
            ? const Color(0xFF1C2128)
            : const Color(0xFFF8FAFC);

  final bool isDark;
  final Color background;
  final Color surfaceContainer;
  final Color containerHigh;
  final Color cardSurface;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color accentBlue;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color outline;
  final Color outlineVariant;
  final Color userBubble;
  final Color aiBubble;
}

class AIChatPage extends StatefulWidget {
  const AIChatPage({super.key});

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> {
  late final GeminiController geminiController;
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;

  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // Use Get.find to reuse existing controller, or create permanent one if doesn't exist
    if (Get.isRegistered<GeminiController>()) {
      geminiController = Get.find<GeminiController>();
    } else {
      geminiController = Get.put(GeminiController(), permanent: true);
    }
  }

  @override
  void dispose() {
    // Keep controller alive so conversation persists
    // Only dispose of page-specific resources
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void _showChatHistorySheet(BuildContext context, _AIChatPalette palette) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: palette.cardSurface,
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(
                  ResponsiveHelper.borderRadius(context, base: 24))),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: ResponsiveHelper.cardPadding(context),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: palette.cardBorder),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.history_rounded,
                    color: palette.accentBlue,
                    size: ResponsiveHelper.iconSize(context),
                  ),
                  SizedBox(
                      width: ResponsiveHelper.spacing(context, mobile: 12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chat History',
                          style: AppText.poppins(
                            color: palette.textPrimary,
                            fontSize:
                                ResponsiveHelper.fontSize(context, mobile: 20),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'View and manage saved conversations',
                          style: AppText.poppins(
                            color: palette.textSecondary,
                            fontSize:
                                ResponsiveHelper.fontSize(context, mobile: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Auto-save info banner
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: palette.accentBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: palette.accentBlue.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: palette.accentBlue,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Chats auto-save when you start a new conversation',
                      style: AppText.poppins(
                        color: palette.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Saved chats list
            Expanded(
              child: Obx(() {
                final savedChats = geminiController.savedChatSessions;
                if (savedChats.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 64,
                          color: palette.textSecondary.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No saved chats yet',
                          style: AppText.poppins(
                            color: palette.textSecondary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Save your conversations to access them later',
                          style: AppText.poppins(
                            color: palette.textSecondary,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(
                      ResponsiveHelper.horizontalPadding(context)),
                  itemCount: savedChats.length,
                  itemBuilder: (context, index) {
                    final chat = savedChats[index];
                    final dateFormat = DateFormat('MMM dd, yyyy • h:mm a');
                    return Container(
                      margin: EdgeInsets.only(
                          bottom:
                              ResponsiveHelper.spacing(context, mobile: 12)),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            _showChatSessionDetail(chat, palette);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: palette.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: palette.cardBorder),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: palette.accentBlue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.chat_rounded,
                                    color: palette.accentBlue,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        chat.title,
                                        style: AppText.poppins(
                                          color: palette.textPrimary,
                                          fontSize: ResponsiveHelper.fontSize(
                                              context,
                                              mobile: 14),
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(
                                          height: ResponsiveHelper.spacing(
                                              context,
                                              mobile: 4)),
                                      Text(
                                        '${chat.messageCount} messages • ${dateFormat.format(chat.savedAt)}',
                                        style: AppText.poppins(
                                          color: palette.textSecondary,
                                          fontSize: ResponsiveHelper.fontSize(
                                              context,
                                              mobile: 11),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    _confirmDeleteChat(
                                        context, chat.id, palette);
                                  },
                                  icon: Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.red.shade400,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _saveCurrentChat(_AIChatPalette palette) {
    final TextEditingController titleController = TextEditingController();

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: palette.cardSurface,
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Save Chat',
                style: AppText.poppins(
                  color: palette.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Enter chat title',
                  hintStyle: AppText.poppins(
                    color: palette.textSecondary,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: palette.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: palette.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: palette.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: palette.accentBlue),
                  ),
                ),
                style: AppText.poppins(
                  color: palette.textPrimary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: palette.background,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: palette.cardBorder),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: AppText.poppins(
                          color: palette.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        final title = titleController.text.trim();
                        if (title.isEmpty) {
                          Get.snackbar(
                            'Error',
                            'Please enter a title',
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                            snackPosition: SnackPosition.TOP,
                          );
                          return;
                        }
                        geminiController.saveChatSession(title);
                        Get.back();
                        Get.snackbar(
                          'Saved',
                          'Chat saved successfully',
                          backgroundColor: palette.accentBlue,
                          colorText: Colors.white,
                          snackPosition: SnackPosition.TOP,
                          margin: const EdgeInsets.all(16),
                          borderRadius: 12,
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: palette.accentBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Save',
                        style: AppText.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteChat(
      BuildContext context, String chatId, _AIChatPalette palette) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: palette.cardSurface,
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_rounded,
                color: Colors.red.shade400,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Delete Chat?',
                style: AppText.poppins(
                  color: palette.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This action cannot be undone',
                style: AppText.poppins(
                  color: palette.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: palette.background,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: palette.cardBorder),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: AppText.poppins(
                          color: palette.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        geminiController.deleteChatSession(chatId);
                        Get.back();
                        Navigator.pop(context);
                        Get.snackbar(
                          'Deleted',
                          'Chat deleted successfully',
                          backgroundColor: Colors.red.shade400,
                          colorText: Colors.white,
                          snackPosition: SnackPosition.TOP,
                          margin: const EdgeInsets.all(16),
                          borderRadius: 12,
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.red.shade400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Delete',
                        style: AppText.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (image != null) {
        // Show loading indicator while validating
        Get.dialog(
          const Center(
            child: CircularProgressIndicator(),
          ),
          barrierDismissible: false,
        );

        // Validate if the image looks like a receipt
        final isReceipt = await _validateReceiptImage(File(image.path));

        Get.back(); // Close loading dialog

        if (isReceipt) {
          setState(() {
            _selectedImage = File(image.path);
          });
        } else {
          Get.snackbar(
            'Invalid Image',
            'Please upload a receipt image. The selected image doesn\'t appear to be a receipt.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFFEF4444),
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick image: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
    }
  }

  Future<bool> _validateReceiptImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();

      // Use Gemini AI to validate if this is a receipt
      final validation = await geminiController.validateReceiptImage(bytes);

      return validation;
    } catch (e) {
      print('Error validating receipt: $e');
      // If validation fails, allow the image (fail open)
      return true;
    }
  }

  void _clearImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  void _sendMessage() async {
    print('🔵 [UI] _sendMessage called');

    // Prevent double sending
    if (_isSending) {
      print('⚠️ [UI] Already sending, returning');
      return;
    }

    final message = messageController.text.trim();
    if (message.isEmpty && _selectedImage == null) {
      print('⚠️ [UI] Empty message and no image, returning');
      return;
    }

    print('🔵 [UI] Message to send: "$message"');
    print(
        '🔵 [UI] Current chat history length: ${geminiController.chatHistory.length}');

    // Set sending flag immediately
    setState(() {
      _isSending = true;
    });
    print('🔵 [UI] Set _isSending to true');

    final previousMessageCount = geminiController.chatHistory.length;
    final imageToSend = _selectedImage;

    // Clear UI immediately
    messageController.clear();
    setState(() {
      _selectedImage = null;
    });

    // Scroll to bottom after a short delay
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);

    try {
      // Send message and wait for completion
      print('🔵 [UI] Calling sendChatMessageWithImage...');
      await geminiController.sendChatMessageWithImage(
        message.isEmpty
            ? 'Scan this receipt and save the transaction'
            : message,
        imageToSend,
      );
      print('🔵 [UI] sendChatMessageWithImage completed');
      print(
          '🔵 [UI] New chat history length: ${geminiController.chatHistory.length}');
    } finally {
      // Reset sending flag
      setState(() {
        _isSending = false;
      });
      print('🔵 [UI] Set _isSending to false');
    }

    // Scroll to bottom again after response
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _AIChatPalette(theme);
    final isExtraSmall = ResponsiveHelper.isExtraSmallScreen(context);
    final headerHorizontalPadding = isExtraSmall ? 12.0 : 16.0;

    return Scaffold(
        backgroundColor: palette.background,
        body: SafeArea(
          child: Column(
            children: [
              // Modern Header
              Container(
                padding: EdgeInsets.fromLTRB(
                  headerHorizontalPadding,
                  16,
                  headerHorizontalPadding,
                  isExtraSmall ? 14 : 20,
                ),
                decoration: BoxDecoration(
                  color: palette.surfaceContainer,
                  border: Border(
                    bottom: BorderSide(
                      color: palette.outlineVariant,
                      width: 1,
                    ),
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Get.back(),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: EdgeInsets.all(isExtraSmall ? 10 : 12),
                              decoration: BoxDecoration(
                                color: palette.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: palette.outlineVariant,
                                ),
                              ),
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: palette.textPrimary,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: isExtraSmall ? 12 : 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color:
                                          palette.accentBlue.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.smart_toy_rounded,
                                      color: palette.accentBlue,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'AI Assistant',
                                      style: AppText.poppins(
                                        color: palette.textPrimary,
                                        fontSize: ResponsiveHelper
                                                .isExtraSmallScreen(context)
                                            ? 16
                                            : ResponsiveHelper.isSmallScreen(
                                                    context)
                                                ? 18
                                                : ResponsiveHelper.fontSize(
                                                    context,
                                                    mobile: 20),
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.5,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(width: isExtraSmall ? 4 : 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color:
                                          palette.accentBlue.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color:
                                            palette.accentBlue.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      'BETA',
                                      style: AppText.poppins(
                                        color: palette.accentBlue,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Welcome! Ask me anything about your cash flow.',
                                style: AppText.poppins(
                                  color: palette.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: isExtraSmall ? 1 : 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: isExtraSmall ? 10 : 12),
                        Flexible(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.end,
                            children: [
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    _showChatHistorySheet(context, palette);
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding:
                                        EdgeInsets.all(isExtraSmall ? 10 : 12),
                                    decoration: BoxDecoration(
                                      color: palette.background,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: palette.outlineVariant,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.history_rounded,
                                      color: palette.textPrimary,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    geminiController.startNewConversation();
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding:
                                        EdgeInsets.all(isExtraSmall ? 10 : 12),
                                    decoration: BoxDecoration(
                                      color: palette.accentBlue,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.add_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Chat messages
              Expanded(
                child: Obx(() {
                  final messages = geminiController.chatHistory;

                  if (messages.isEmpty) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: palette.primaryContainer,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: palette.accentBlue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.smart_toy_rounded,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Hi, I\'m your Cash AI',
                                        style: AppText.poppins(
                                          color: palette.onPrimaryContainer,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Welcome back! Ask me to summarize your activity, scan a receipt, or find a transaction.',
                                        style: AppText.poppins(
                                          color: palette.onPrimaryContainer
                                              .withOpacity(0.85),
                                          fontSize: 13,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          _buildSuggestions(palette),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return _buildMessageBubble(message, palette);
                    },
                  );
                }),
              ),

              // Status indicators wrapper with scroll for overflow protection
              SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Loading indicator
                    Obx(() {
                      if (geminiController.isLoading.value) {
                        return Container(
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: palette.cardSurface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: palette.cardBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    palette.accentBlue,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'AI is thinking...',
                                style: AppText.poppins(
                                  color: palette.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),

                    // Error message
                    Obx(() {
                      if (geminiController.error.value.isNotEmpty) {
                        return Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFEF4444).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: Color(0xFFEF4444),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  geminiController.error.value,
                                  style: AppText.poppins(
                                    color: const Color(0xFFEF4444),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),

                    // Pending action confirmation
                    Obx(() {
                      final pending = geminiController.pendingAction.value;
                      if (pending == null) return const SizedBox.shrink();

                      return Container(
                        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: palette.cardSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: palette.cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pending Action',
                              style: AppText.poppins(
                                color: palette.accentBlue,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              pending.description,
                              style: AppText.poppins(
                                color: palette.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      await geminiController
                                          .confirmPendingAction();
                                      _scrollToBottom();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: palette.accentBlue,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text(
                                      'Confirm',
                                      style: AppText.poppins(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      geminiController.cancelPendingAction();
                                      _scrollToBottom();
                                    },
                                    style: OutlinedButton.styleFrom(
                                      side:
                                          BorderSide(color: palette.cardBorder),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      backgroundColor: palette.isDark
                                          ? Colors.transparent
                                          : palette.cardSurface,
                                    ),
                                    child: Text(
                                      'Cancel',
                                      style: AppText.poppins(
                                        color: palette.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

              // Input field
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: palette.cardSurface,
                  border: Border(
                    top: BorderSide(
                      color: palette.cardBorder,
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image preview
                    if (_selectedImage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: palette.isDark
                              ? palette.background
                              : palette.cardBorder.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: palette.cardBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _selectedImage!,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Receipt Image',
                                    style: AppText.poppins(
                                      color: palette.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Ready to scan',
                                    style: AppText.poppins(
                                      color: palette.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _clearImage,
                              icon: Icon(
                                Icons.close_rounded,
                                color: palette.textSecondary,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Input row
                    Row(
                      children: [
                        // Image picker button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: palette.cardSurface,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                ),
                                builder: (context) => Container(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: palette.cardBorder,
                                          borderRadius:
                                              BorderRadius.circular(2),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        'Upload Receipt',
                                        style: AppText.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: palette.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      ListTile(
                                        leading: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: palette.accentBlue
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            Icons.camera_alt_rounded,
                                            color: palette.accentBlue,
                                          ),
                                        ),
                                        title: Text(
                                          'Camera',
                                          style: AppText.poppins(
                                            color: palette.textPrimary,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        subtitle: Text(
                                          'Take a photo of the receipt',
                                          style: AppText.poppins(
                                            color: palette.textSecondary,
                                            fontSize: 13,
                                          ),
                                        ),
                                        onTap: () {
                                          Navigator.pop(context);
                                          _pickImage(ImageSource.camera);
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      ListTile(
                                        leading: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: palette.accentBlue
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            Icons.photo_library_rounded,
                                            color: palette.accentBlue,
                                          ),
                                        ),
                                        title: Text(
                                          'Gallery',
                                          style: AppText.poppins(
                                            color: palette.textPrimary,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        subtitle: Text(
                                          'Choose from your photos',
                                          style: AppText.poppins(
                                            color: palette.textSecondary,
                                            fontSize: 13,
                                          ),
                                        ),
                                        onTap: () {
                                          Navigator.pop(context);
                                          _pickImage(ImageSource.gallery);
                                        },
                                      ),
                                      const SizedBox(height: 10),
                                    ],
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: EdgeInsets.all(isExtraSmall ? 10 : 12),
                              decoration: BoxDecoration(
                                color: palette.isDark
                                    ? palette.background
                                    : palette.cardBorder.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: palette.cardBorder,
                                ),
                              ),
                              child: Icon(
                                Icons.add_photo_alternate_rounded,
                                color: palette.accentBlue,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: isExtraSmall ? 10 : 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: palette.isDark
                                  ? palette.background
                                  : palette.cardBorder.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: palette.cardBorder,
                              ),
                            ),
                            child: TextField(
                              controller: messageController,
                              style: AppText.poppins(
                                color: palette.textPrimary,
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                hintText: _selectedImage != null
                                    ? 'Add instructions (optional)...'
                                    : 'Type your message...',
                                hintStyle: AppText.poppins(
                                  color: palette.textSecondary,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                              maxLines: null,
                              textCapitalization: TextCapitalization.sentences,
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                        ),
                        SizedBox(width: isExtraSmall ? 8 : 10),
                        // Send button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _sendMessage,
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              padding: EdgeInsets.all(isExtraSmall ? 10 : 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    palette.accentBlue,
                                    palette.accentBlue.withOpacity(0.8),
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: palette.accentBlue.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }

  Widget _buildMessageBubble(ChatMessage message, _AIChatPalette palette) {
    final timeFormat = DateFormat('hh:mm a');
    final messageIndex = geminiController.chatHistory.indexOf(message);

    return Align(
        alignment:
            message.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onLongPress: () {
            _showDeleteMessageDialog(messageIndex, palette);
          },
          child: Container(
            margin: EdgeInsets.only(
                bottom: ResponsiveHelper.spacing(context, mobile: 12)),
            padding:
                EdgeInsets.all(ResponsiveHelper.spacing(context, mobile: 14)),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width *
                  (ResponsiveHelper.isSmallScreen(context) ? 0.85 : 0.75),
            ),
            decoration: BoxDecoration(
              color: message.isUser ? palette.userBubble : palette.aiBubble,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: message.isUser
                    ? const Radius.circular(18)
                    : const Radius.circular(4),
                bottomRight: message.isUser
                    ? const Radius.circular(4)
                    : const Radius.circular(18),
              ),
              border: Border.all(
                color: message.isUser ? Colors.transparent : palette.cardBorder,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: palette.isDark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!message.isUser)
                  Row(
                    children: [
                      Icon(
                        Icons.smart_toy_rounded,
                        size: ResponsiveHelper.fontSize(context, mobile: 14),
                        color: palette.accentBlue,
                      ),
                      SizedBox(
                          width: ResponsiveHelper.spacing(context, mobile: 6)),
                      Text(
                        'AI Assistant',
                        style: AppText.poppins(
                          color: palette.accentBlue,
                          fontSize:
                              ResponsiveHelper.fontSize(context, mobile: 11),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                if (!message.isUser)
                  SizedBox(
                      height: ResponsiveHelper.spacing(context, mobile: 8)),
                Text(
                  message.text,
                  style: AppText.poppins(
                    color: message.isUser ? Colors.white : palette.textPrimary,
                    fontSize: ResponsiveHelper.fontSize(context, mobile: 14),
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.spacing(context, mobile: 6)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeFormat.format(message.timestamp),
                      style: AppText.poppins(
                        color: message.isUser
                            ? Colors.white.withOpacity(0.7)
                            : palette.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ));
  }

  void _showDeleteMessageDialog(int index, _AIChatPalette palette) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: palette.cardSurface,
        title: Text(
          'Delete Message',
          style: AppText.poppins(
            color: palette.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this message?',
          style: AppText.poppins(
            color: palette.textSecondary,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppText.poppins(
                color: palette.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              geminiController.deleteMessage(index);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: Text(
              'Delete',
              style: AppText.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions(_AIChatPalette palette) {
    final suggestions = [
      {'icon': Icons.auto_graph_rounded, 'text': 'What\'s my balance?'},
      {'icon': Icons.receipt_long_rounded, 'text': 'Scan this receipt'},
      {'icon': Icons.history_rounded, 'text': 'Show my last 5 transactions'},
      {
        'icon': Icons.tips_and_updates_rounded,
        'text': 'Set fee for 1-500 to 15'
      },
    ];

    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: ResponsiveHelper.horizontalPadding(context)),
      child: Wrap(
        spacing: ResponsiveHelper.spacing(context, mobile: 8),
        runSpacing: ResponsiveHelper.spacing(context, mobile: 8),
        alignment: WrapAlignment.center,
        children: suggestions.map((suggestion) {
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                messageController.text = suggestion['text'] as String;
              },
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: palette.surfaceContainer,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: palette.outlineVariant),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      suggestion['icon'] as IconData,
                      size: 16,
                      color: palette.accentBlue,
                    ),
                    SizedBox(
                        width: ResponsiveHelper.spacing(context, mobile: 6)),
                    Flexible(
                      child: Text(
                        suggestion['text'] as String,
                        style: AppText.poppins(
                          fontSize:
                              ResponsiveHelper.fontSize(context, mobile: 13),
                          color: palette.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showChatSessionDetail(ChatSession session, _AIChatPalette palette) {
    final dateFormat = DateFormat('MMMM dd, yyyy \'at\' h:mm a');

    Get.to(
      () => Builder(
        builder: (context) => Scaffold(
          backgroundColor: palette.background,
          body: SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.fromLTRB(
                    ResponsiveHelper.horizontalPadding(context),
                    ResponsiveHelper.verticalPadding(context),
                    ResponsiveHelper.horizontalPadding(context),
                    ResponsiveHelper.spacing(context, mobile: 20),
                  ),
                  decoration: BoxDecoration(
                    color: palette.cardSurface,
                    border: Border(
                      bottom: BorderSide(
                        color: palette.cardBorder,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Get.back(),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: palette.cardSurface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: palette.cardBorder,
                                  ),
                                ),
                                child: Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: palette.textPrimary,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                              width: ResponsiveHelper.spacing(context,
                                  mobile: 16)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  session.title,
                                  style: AppText.poppins(
                                    color: palette.textPrimary,
                                    fontSize: ResponsiveHelper.fontSize(context,
                                        mobile: 18),
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(
                                    height: ResponsiveHelper.spacing(context,
                                        mobile: 2)),
                                Text(
                                  'Saved on ${dateFormat.format(session.savedAt)}',
                                  style: AppText.poppins(
                                    color: palette.textSecondary,
                                    fontSize: ResponsiveHelper.fontSize(context,
                                        mobile: 12),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_vert_rounded,
                              color: palette.textPrimary,
                            ),
                            color: palette.cardSurface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: palette.cardBorder),
                            ),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'load',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.restore_rounded,
                                      size: 18,
                                      color: palette.accentBlue,
                                    ),
                                    SizedBox(
                                        width: ResponsiveHelper.spacing(context,
                                            mobile: 12)),
                                    Text(
                                      'Load to Current Chat',
                                      style: AppText.poppins(
                                        color: palette.textPrimary,
                                        fontSize: ResponsiveHelper.fontSize(
                                            context,
                                            mobile: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline_rounded,
                                      size: 18,
                                      color: Colors.red.shade400,
                                    ),
                                    SizedBox(
                                        width: ResponsiveHelper.spacing(context,
                                            mobile: 12)),
                                    Text(
                                      'Delete',
                                      style: AppText.poppins(
                                        color: Colors.red.shade400,
                                        fontSize: ResponsiveHelper.fontSize(
                                            context,
                                            mobile: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'load') {
                                geminiController.loadChatSession(session.id);
                                Get.back();
                                Get.snackbar(
                                  'Chat Loaded',
                                  'Conversation restored to current chat',
                                  backgroundColor: palette.accentBlue,
                                  colorText: Colors.white,
                                  snackPosition: SnackPosition.TOP,
                                  margin: const EdgeInsets.all(16),
                                  borderRadius: 12,
                                );
                              } else if (value == 'delete') {
                                _confirmDeleteChatFromDetail(
                                    context, session.id, palette);
                              }
                            },
                          ),
                        ],
                      ),
                      SizedBox(
                          height:
                              ResponsiveHelper.spacing(context, mobile: 12)),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal:
                                ResponsiveHelper.spacing(context, mobile: 12),
                            vertical:
                                ResponsiveHelper.spacing(context, mobile: 8)),
                        decoration: BoxDecoration(
                          color: palette.background,
                          borderRadius: BorderRadius.circular(
                              ResponsiveHelper.borderRadius(context, base: 8)),
                          border: Border.all(color: palette.cardBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.message_rounded,
                              size:
                                  ResponsiveHelper.iconSize(context, base: 16),
                              color: palette.textSecondary,
                            ),
                            SizedBox(
                                width: ResponsiveHelper.spacing(context,
                                    mobile: 8)),
                            Text(
                              '${session.messageCount} messages',
                              style: AppText.poppins(
                                color: palette.textSecondary,
                                fontSize: ResponsiveHelper.fontSize(context,
                                    mobile: 13),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Messages
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.all(
                        ResponsiveHelper.horizontalPadding(context)),
                    itemCount: session.messages.length,
                    itemBuilder: (context, index) {
                      final message = session.messages[index];
                      return _buildMessageBubbleReadOnly(
                          message, palette, context);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 300),
    );
  }

  Widget _buildMessageBubbleReadOnly(
      ChatMessage message, _AIChatPalette palette, BuildContext context) {
    final isUser = message.isUser;
    final timeFormat = DateFormat('h:mm a');

    return Padding(
      padding: EdgeInsets.only(
          bottom: ResponsiveHelper.spacing(context, mobile: 16)),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: ResponsiveHelper.iconSize(context, base: 32),
              height: ResponsiveHelper.iconSize(context, base: 32),
              decoration: BoxDecoration(
                color: palette.accentBlue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(
                    ResponsiveHelper.borderRadius(context, base: 8)),
              ),
              child: Icon(
                Icons.smart_toy_rounded,
                color: palette.accentBlue,
                size: ResponsiveHelper.iconSize(context, base: 18),
              ),
            ),
            SizedBox(width: ResponsiveHelper.spacing(context, mobile: 12)),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(
                      ResponsiveHelper.spacing(context, mobile: 16)),
                  decoration: BoxDecoration(
                    color: isUser ? palette.userBubble : palette.aiBubble,
                    borderRadius: BorderRadius.circular(16).copyWith(
                      topLeft: isUser ? const Radius.circular(16) : Radius.zero,
                      topRight:
                          isUser ? Radius.zero : const Radius.circular(16),
                    ),
                    border: isUser
                        ? null
                        : Border.all(color: palette.cardBorder, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: palette.isDark
                            ? Colors.black.withOpacity(0.2)
                            : Colors.black.withOpacity(0.05),
                        offset: const Offset(0, 2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: AppText.poppins(
                      color: isUser ? Colors.white : palette.textPrimary,
                      fontSize: ResponsiveHelper.fontSize(context, mobile: 14),
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                    ),
                  ),
                ),
                SizedBox(height: ResponsiveHelper.spacing(context, mobile: 6)),
                Text(
                  timeFormat.format(message.timestamp),
                  style: AppText.poppins(
                    color: palette.textSecondary,
                    fontSize: ResponsiveHelper.fontSize(context, mobile: 11),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            SizedBox(width: ResponsiveHelper.spacing(context, mobile: 12)),
            Container(
              width: ResponsiveHelper.iconSize(context, base: 32),
              height: ResponsiveHelper.iconSize(context, base: 32),
              decoration: BoxDecoration(
                color: palette.userBubble,
                borderRadius: BorderRadius.circular(
                    ResponsiveHelper.borderRadius(context, base: 8)),
              ),
              child: Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: ResponsiveHelper.iconSize(context, base: 18),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmDeleteChatFromDetail(
      BuildContext context, String chatId, _AIChatPalette palette) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
                ResponsiveHelper.borderRadius(context, base: 20))),
        backgroundColor: palette.cardSurface,
        child: Container(
          padding: ResponsiveHelper.cardPadding(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_rounded,
                color: Colors.red.shade400,
                size: ResponsiveHelper.iconSize(context, base: 48),
              ),
              SizedBox(height: ResponsiveHelper.spacing(context, mobile: 16)),
              Text(
                'Delete Chat?',
                style: AppText.poppins(
                  color: palette.textPrimary,
                  fontSize: ResponsiveHelper.fontSize(context, mobile: 20),
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: ResponsiveHelper.spacing(context, mobile: 8)),
              Text(
                'This action cannot be undone',
                style: AppText.poppins(
                  color: palette.textSecondary,
                  fontSize: ResponsiveHelper.fontSize(context, mobile: 14),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: ResponsiveHelper.spacing(context, mobile: 20)),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: palette.background,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: palette.cardBorder),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: AppText.poppins(
                          color: palette.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        geminiController.deleteChatSession(chatId);
                        Get.back(); // Close dialog
                        Get.back(); // Close detail view
                        Get.snackbar(
                          'Deleted',
                          'Chat deleted successfully',
                          backgroundColor: Colors.red.shade400,
                          colorText: Colors.white,
                          snackPosition: SnackPosition.TOP,
                          margin: const EdgeInsets.all(16),
                          borderRadius: 12,
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.red.shade400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Delete',
                        style: AppText.poppins(
                          color: Colors.white,
                          fontSize:
                              ResponsiveHelper.fontSize(context, mobile: 14),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
