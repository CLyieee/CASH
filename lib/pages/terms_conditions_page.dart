import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/app_text.dart';

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = theme.scaffoldBackgroundColor;
    final textPrimary = theme.colorScheme.onSurface;
    final textMuted =
        isDark ? const Color(0xFF7A88A8) : const Color(0xFF5A6B84);
    final cardSurface = isDark ? const Color(0xFF111A2E) : Colors.white;
    final cardBorder = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.05);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: textPrimary,
              size: 18,
            ),
          ),
        ),
        title: Text(
          'Terms & Conditions',
          style: AppText.poppins(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardSurface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Last Updated: December 3, 2025',
                style: AppText.poppins(
                  color: textMuted,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: '1. Acceptance of Terms',
                content:
                    'By accessing and using G Cash Application ("the App"), you agree to be bound by these Terms and Conditions. If you do not agree with any part of these terms, you must not use the App.',
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
              _buildSection(
                title: '2. Service Description',
                content:
                    'G Cash is a financial management application that allows you to track cash transactions, manage transfers, monitor balances, and generate financial reports. The App provides tools for personal finance management and record-keeping.',
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
              _buildSection(
                title: '3. User Responsibilities',
                content:
                    'You are responsible for:\n\n• Maintaining the confidentiality of your account credentials and PIN\n• All activities that occur under your account\n• Ensuring all information you provide is accurate and up-to-date\n• Using the App in compliance with all applicable laws and regulations\n• Not sharing your biometric authentication or login credentials with others',
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
              _buildSection(
                title: '4. Data Privacy & Security',
                content:
                    'We take your privacy seriously. Your financial data is stored securely and is not shared with third parties without your consent. We implement industry-standard security measures including:\n\n• Encrypted data transmission\n• Secure cloud storage via Firebase\n• Optional biometric authentication\n• Local device security measures\n\nYou retain ownership of all your financial data and can request deletion at any time.',
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
              _buildSection(
                title: '5. Transaction Fees',
                content:
                    'Transaction fees may apply based on the fee structure you configure in your settings. These fees are customizable and are for your personal record-keeping purposes only. The App does not process actual financial transactions or collect any fees from users.',
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
              _buildSection(
                title: '6. Service Availability',
                content:
                    'While we strive to provide continuous access to the App, we do not guarantee that the service will be uninterrupted or error-free. We reserve the right to modify, suspend, or discontinue any part of the service with or without notice.',
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
              _buildSection(
                title: '7. Limitation of Liability',
                content:
                    'The App is provided "as is" without warranties of any kind. We shall not be liable for any direct, indirect, incidental, or consequential damages resulting from:\n\n• Use or inability to use the App\n• Data loss or corruption\n• Errors or inaccuracies in financial records\n• Unauthorized access to your data\n• Any other matter relating to the App',
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
              _buildSection(
                title: '8. Intellectual Property',
                content:
                    'All content, features, and functionality of the App, including but not limited to text, graphics, logos, and software, are the exclusive property of G Cash Application and are protected by copyright and intellectual property laws.',
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
              _buildSection(
                title: '9. User Conduct',
                content:
                    'You agree not to:\n\n• Use the App for any unlawful purpose\n• Attempt to gain unauthorized access to the App or related systems\n• Interfere with or disrupt the App\'s functionality\n• Reverse engineer or attempt to extract source code\n• Use the App to transmit viruses or malicious code\n• Impersonate others or provide false information',
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
              _buildSection(
                title: '10. Termination',
                content:
                    'We reserve the right to terminate or suspend your access to the App immediately, without prior notice, for any breach of these Terms and Conditions. Upon termination, your right to use the App will cease immediately.',
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
              _buildSection(
                title: '11. Changes to Terms',
                content:
                    'We reserve the right to modify these Terms and Conditions at any time. Changes will be effective immediately upon posting. Your continued use of the App after changes constitutes acceptance of the modified terms.',
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
              _buildSection(
                title: '12. Governing Law',
                content:
                    'These Terms and Conditions shall be governed by and construed in accordance with applicable laws. Any disputes arising from these terms shall be subject to the exclusive jurisdiction of the appropriate courts.',
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
              _buildSection(
                title: '13. Contact Information',
                content:
                    'If you have any questions about these Terms and Conditions, please contact us through the support section in the App settings.',
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      color: theme.colorScheme.primary,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your Trust Matters',
                      style: AppText.poppins(
                        color: textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We are committed to protecting your financial data and providing a secure, reliable service for managing your cash transactions.',
                      style: AppText.poppins(
                        color: textMuted,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required Color textPrimary,
    required Color textMuted,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppText.poppins(
              color: textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: AppText.poppins(
              color: textMuted,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
