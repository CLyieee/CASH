import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../controllers/gemini_controller.dart';
import '../controllers/theme_controller.dart';
import '../utils/app_text.dart';

class _AIChatPalette {
  _AIChatPalette(ThemeData theme)
      : isDark = theme.brightness == Brightness.dark,
        background = theme.brightness == Brightness.dark
            ? const Color(0xFF0F1419)
            : const Color(0xFFF8F9FA),
        cardSurface = theme.brightness == Brightness.dark
            ? const Color(0xFF1C2128)
            : Colors.white,
        cardBorder = theme.brightness == Brightness.dark
            ? Colors.white.withOpacity(0.08)
            : Colors.black.withOpacity(0.06),
        textPrimary = theme.brightness == Brightness.dark
            ? const Color(0xFFE6EDF3)
            : const Color(0xFF1F2937),
        textSecondary = theme.brightness == Brightness.dark
            ? const Color(0xFF8B949E)
            : const Color(0xFF6B7280),
        accentBlue = theme.colorScheme.primary,
        userBubble = theme.colorScheme.primary,
        aiBubble = theme.brightness == Brightness.dark
            ? const Color(0xFF1C2128)
            : Colors.white;

  final bool isDark;
  final Color background;
  final Color cardSurface;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color accentBlue;
  final Color userBubble;
  final Color aiBubble;
}

class AIChatPage extends StatefulWidget {
  const AIChatPage({super.key});

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> {
  final GeminiController geminiController = Get.put(GeminiController());
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
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

  void _sendMessage() {
    final message = messageController.text.trim();
    if (message.isEmpty) return;

    geminiController.sendChatMessage(message);
    messageController.clear();

    // Scroll to bottom after a short delay
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _AIChatPalette(theme);

    return Scaffold(
        backgroundColor: palette.background,
        body: SafeArea(
          child: Column(
            children: [
              // Modern Header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                decoration: BoxDecoration(
                  color: palette.cardSurface,
                  border: Border(
                    bottom: BorderSide(
                      color: palette.cardBorder,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
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
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: palette.accentBlue.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.smart_toy_rounded,
                                  color: palette.accentBlue,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'AI Assistant',
                                style: AppText.poppins(
                                  color: palette.textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Powered by Gemini AI',
                            style: AppText.poppins(
                              color: palette.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          geminiController.clearChat();
                        },
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
                            Icons.delete_outline_rounded,
                            color: palette.textPrimary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Chat messages
              Expanded(
                child: Obx(() {
                  final messages = geminiController.chatHistory;

                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: palette.accentBlue.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 64,
                              color: palette.accentBlue,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Start a conversation',
                            style: AppText.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: palette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              'Ask me anything about your finances or transaction history',
                              style: AppText.poppins(
                                fontSize: 14,
                                color: palette.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
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
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                child: SafeArea(
                  child: Row(
                    children: [
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
                              hintText: 'Type your message...',
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
                      const SizedBox(width: 12),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _sendMessage,
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            padding: const EdgeInsets.all(12),
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
                ),
              ),
            ],
          ),
        ));
  }

  Widget _buildMessageBubble(ChatMessage message, _AIChatPalette palette) {
    final timeFormat = DateFormat('hh:mm a');

    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
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
                    size: 14,
                    color: palette.accentBlue,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'AI Assistant',
                    style: AppText.poppins(
                      color: palette.accentBlue,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            if (!message.isUser) const SizedBox(height: 8),
            Text(
              message.text,
              style: AppText.poppins(
                color: message.isUser ? Colors.white : palette.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 6),
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
      ),
    );
  }
}
