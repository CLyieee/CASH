import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../models/receipt_model.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';
import '../controllers/app_controller.dart';
import '../utils/app_text.dart';

class ReceiptPreviewPage extends StatefulWidget {
  final ReceiptModel receipt;
  final File imageFile;

  const ReceiptPreviewPage({
    super.key,
    required this.receipt,
    required this.imageFile,
  });

  @override
  State<ReceiptPreviewPage> createState() => _ReceiptPreviewPageState();
}

class _ReceiptPreviewPageState extends State<ReceiptPreviewPage> {
  final TransactionService _transactionService = TransactionService();
  final AppController controller = Get.find<AppController>();
  String selectedTransactionType = 'Cash In';
  late String selectedSource;
  bool isSaving = false;

  // Available transaction type options
  final List<String> transactionTypeOptions = [
    'Cash In',
    'Cash Out',
    'Load',
    'Bank Transfer',
  ];

  // Available source options - Only GCash supported
  final List<String> sourceOptions = [
    'GCash',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize with receipt source or default to 'GCash'
    selectedSource =
        widget.receipt.source.isNotEmpty ? widget.receipt.source : 'GCash';

    // Auto-detect load transactions and set type to 'Load'
    if (selectedSource == 'Load' || _isLoadTransaction()) {
      selectedTransactionType = 'Load';
      selectedSource = 'Load';
    } else {
      // Ensure selected source exists in options
      if (!sourceOptions.contains(selectedSource)) {
        selectedSource = 'GCash';
      }
    }
  }

  // Check if this is a load transaction based on receipt data
  bool _isLoadTransaction() {
    final refNumber = widget.receipt.refNumber;
    final recipientName = widget.receipt.recipientName.toLowerCase();

    // Check if reference number is exactly 9 digits
    final nineDigitPattern = RegExp(r'^\d{9}$');
    final hasNineDigits =
        nineDigitPattern.hasMatch(refNumber.replaceAll(RegExp(r'\s'), ''));

    // Check for load keywords
    final loadKeywords = [
      'load',
      'autoload',
      'easysurf',
      'surf',
      'unli',
      'giga',
      'allnet',
      'smart',
      'globe',
      'tnt'
    ];
    final hasLoadKeyword =
        loadKeywords.any((keyword) => recipientName.contains(keyword));

    return hasNineDigits || (selectedSource == 'Load') || hasLoadKeyword;
  }

  bool get isLoadTransaction => selectedTransactionType == 'Load';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currencyFormat = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    final dateFormat = DateFormat('MMM dd, yyyy hh:mm a');
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0D1117) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: colorScheme.onSurface,
              size: 18,
            ),
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Receipt Preview',
          style: AppText.poppins(
            color: colorScheme.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Receipt Image - Material 3 Card Style
                GestureDetector(
                  onTap: () => _showFullScreenImage(context),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1C2128) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.receipt_long_rounded,
                                  color: colorScheme.onPrimaryContainer,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Receipt Image',
                                style: AppText.poppins(
                                  color: colorScheme.onSurface,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Image
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(24),
                                bottomRight: Radius.circular(24),
                              ),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxHeight: 300,
                                ),
                                child: Image.file(
                                  widget.imageFile,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  frameBuilder: (context, child, frame,
                                      wasSynchronouslyLoaded) {
                                    if (wasSynchronouslyLoaded) {
                                      return child;
                                    }
                                    return AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      child: frame != null
                                          ? child
                                          : Container(
                                              height: 300,
                                              color: colorScheme
                                                  .surfaceContainerHighest,
                                              child: Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  color: colorScheme.primary,
                                                ),
                                              ),
                                            ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 300,
                                      color:
                                          colorScheme.surfaceContainerHighest,
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.broken_image_rounded,
                                              size: 48,
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              'Unable to load image',
                                              style: AppText.poppins(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            // Tap to expand indicator
                            Positioned(
                              bottom: 16,
                              right: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          colorScheme.primary.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.fullscreen_rounded,
                                      color: colorScheme.onPrimary,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'View Full',
                                      style: AppText.poppins(
                                        color: colorScheme.onPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms).scale(delay: 100.ms),

                const SizedBox(height: 30),

                // Transaction Type Dropdown
                _buildTransactionTypeDropdown(colorScheme)
                    .animate()
                    .fadeIn(delay: 150.ms, duration: 400.ms)
                    .slideY(begin: 0.2, end: 0, delay: 150.ms),

                const SizedBox(height: 20),

                // Extracted Data (Read-only)
                _buildDataCard(
                  colorScheme: colorScheme,
                  title: 'Extracted Information',
                  children: isLoadTransaction
                      ? _buildLoadFields(
                          colorScheme, currencyFormat, dateFormat)
                      : widget.receipt.transactionType == 'bank_transfer'
                          ? _buildBankTransferFields(
                              colorScheme, currencyFormat, dateFormat)
                          : _buildMoneyTransferFields(
                              colorScheme, currencyFormat, dateFormat),
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 400.ms)
                    .slideY(begin: 0.2, end: 0, delay: 200.ms),

                const SizedBox(height: 30),

                // Action Buttons
                if (isSaving)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1C2128) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          CircularProgressIndicator(
                            color: colorScheme.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Saving transaction...',
                            style: AppText.poppins(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Get.back(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.error,
                            side:
                                BorderSide(color: colorScheme.error, width: 2),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.close_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Cancel',
                                style: AppText.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: _showFeeHandlingDialog,
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_rounded, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                'Save Transaction',
                                style: AppText.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 400.ms)
                      .slideY(begin: 0.3, end: 0, delay: 400.ms),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFeeHandlingDialog() {
    final colorScheme = Theme.of(context).colorScheme;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: colorScheme.surface,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.help_outline_rounded,
                  color: colorScheme.onPrimaryContainer,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                'Fee Handling',
                style: AppText.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Message
              Text(
                'Is the fee already included in the amount or paid in cash?',
                style: AppText.poppins(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Included button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Get.back();
                    _saveTransaction(feeIncluded: true);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Fee Included in Amount',
                    style: AppText.poppins(
                      color: colorScheme.onPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Cash button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Get.back();
                    _saveTransaction(feeIncluded: false);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    side: BorderSide(color: colorScheme.primary, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Fee is Cash',
                    style: AppText.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  Future<void> _saveTransaction({required bool feeIncluded}) async {
    try {
      setState(() => isSaving = true);

      // Use receipt values directly (non-editable)
      final amount = widget.receipt.amount;
      final fee = feeIncluded ? widget.receipt.fee : 0.0;
      final separateFee = !feeIncluded ? widget.receipt.fee : 0.0;
      final refNumber = widget.receipt.refNumber;

      // Check for duplicate reference number
      if (refNumber.isNotEmpty) {
        final isDuplicate =
            await _transactionService.isReferenceNumberDuplicate(
          controller.currentUserId.value,
          refNumber,
        );

        if (isDuplicate) {
          setState(() => isSaving = false);

          final colorScheme = Theme.of(context).colorScheme;
          // Show dialog for duplicate reference number
          Get.dialog(
            Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: colorScheme.surface,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Warning Icon
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.warning_rounded,
                        color: colorScheme.onErrorContainer,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    Text(
                      'Duplicate Reference Number',
                      style: AppText.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // Message
                    Text(
                      'A transaction with reference number "$refNumber" already exists in your records.',
                      style: AppText.poppins(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    Text(
                      'Please rescan with a unique reference number.',
                      style: AppText.poppins(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Get.back(),
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.error,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Go Back',
                          style: AppText.poppins(
                            color: colorScheme.onError,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            barrierDismissible: true,
          );
          return;
        }
      }

      // Create transaction with receipt values
      final transaction = TransactionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: controller.currentUserId.value,
        recipientName: widget.receipt.recipientName,
        phoneNumber: widget.receipt.phoneNumber,
        amount: amount,
        fee: fee,
        totalAmount: amount,
        refNumber: refNumber,
        date: DateTime.now(),
        source: isLoadTransaction ? 'Load' : selectedSource,
        transactionType: selectedTransactionType == 'Load'
            ? 'Cash Out'
            : selectedTransactionType,
        createdAt: DateTime.now(),
        separateFee: separateFee,
      );

      // Save to Firestore
      await _transactionService.saveTransaction(transaction);

      setState(() => isSaving = false);

      // Go back to dashboard
      Get.back();
      Get.back();

      // Show success message
      Get.snackbar(
        'Success',
        'Transaction saved successfully!',
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        colorText: Theme.of(context).colorScheme.onPrimaryContainer,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(20),
        borderRadius: 16,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      setState(() => isSaving = false);

      Get.snackbar(
        'Error',
        'Failed to save transaction: ${e.toString()}',
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
        colorText: Theme.of(context).colorScheme.onErrorContainer,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(20),
        borderRadius: 16,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Widget _buildTransactionTypeDropdown(ColorScheme colorScheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2128) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.category_rounded,
                  color: colorScheme.onPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Transaction Type',
                style: AppText.poppins(
                  color: colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outlineVariant,
                width: 1,
              ),
            ),
            child: DropdownButton<String>(
              value: selectedTransactionType,
              isExpanded: true,
              underline: const SizedBox(),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: colorScheme.primary,
                size: 24,
              ),
              style: AppText.poppins(
                color: colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              dropdownColor: isDark ? const Color(0xFF1C2128) : Colors.white,
              items: transactionTypeOptions.map((String value) {
                IconData icon;
                Color iconColor;

                switch (value) {
                  case 'Cash In':
                    icon = Icons.arrow_downward_rounded;
                    iconColor = const Color(0xFF10B981);
                    break;
                  case 'Cash Out':
                    icon = Icons.arrow_upward_rounded;
                    iconColor = const Color(0xFFEF4444);
                    break;
                  case 'Load':
                    icon = Icons.phone_android_rounded;
                    iconColor = const Color(0xFF3B82F6);
                    break;
                  case 'Bank Transfer':
                    icon = Icons.account_balance_rounded;
                    iconColor = const Color(0xFF8B5CF6);
                    break;
                  default:
                    icon = Icons.swap_horiz_rounded;
                    iconColor = colorScheme.primary;
                }

                return DropdownMenuItem<String>(
                  value: value,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          icon,
                          size: 16,
                          color: iconColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(value),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    selectedTransactionType = newValue;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceDropdown(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.account_balance_wallet,
              color: colorScheme.onPrimaryContainer,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Source',
                  style: AppText.poppins(
                    color: colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                DropdownButton<String>(
                  value: selectedSource,
                  isExpanded: true,
                  underline: const SizedBox(),
                  icon: Icon(
                    Icons.arrow_drop_down_rounded,
                    color: colorScheme.onSurface,
                  ),
                  style: AppText.poppins(
                    color: colorScheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  items: sourceOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedSource = newValue;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataCard({
    required ColorScheme colorScheme,
    required String title,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2128) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.receipt_rounded,
                  color: colorScheme.onSecondaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppText.poppins(
                  color: colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  // Build fields for load transaction (non-editable)
  List<Widget> _buildLoadFields(ColorScheme colorScheme,
      NumberFormat currencyFormat, DateFormat dateFormat) {
    return [
      // Provider Name (from recipient name)
      _buildInfoRow(colorScheme, 'Provider', widget.receipt.recipientName,
          Icons.business),
      _buildDivider(colorScheme),
      // Phone Number
      _buildInfoRow(colorScheme, 'Phone Number', widget.receipt.phoneNumber,
          Icons.phone_android),
      _buildDivider(colorScheme),
      // Load Amount
      _buildInfoRow(colorScheme, 'Load Amount',
          currencyFormat.format(widget.receipt.amount), Icons.attach_money),
      _buildDivider(colorScheme),
      // Convenience Fee
      _buildInfoRow(colorScheme, 'Convenience Fee',
          currencyFormat.format(widget.receipt.fee), Icons.receipt_long),
      _buildDivider(colorScheme),
      // Total Amount
      _buildInfoRow(
        colorScheme,
        'Total',
        currencyFormat.format(widget.receipt.amount + widget.receipt.fee),
        Icons.payments,
        isHighlighted: true,
      ),
      _buildDivider(colorScheme),
      // Reference Number (9 digits)
      _buildInfoRow(
          colorScheme, 'Reference Number', widget.receipt.refNumber, Icons.tag),
      _buildDivider(colorScheme),
      // Date
      _buildInfoRow(
        colorScheme,
        'Date',
        dateFormat.format(widget.receipt.date),
        Icons.calendar_today,
      ),
    ];
  }

  // Build fields for bank transfer (non-editable)
  List<Widget> _buildBankTransferFields(ColorScheme colorScheme,
      NumberFormat currencyFormat, DateFormat dateFormat) {
    return [
      _buildInfoRow(colorScheme, 'Bank', widget.receipt.phoneNumber,
          Icons.account_balance),
      _buildDivider(colorScheme),
      if (widget.receipt.accountNumber != null &&
          widget.receipt.accountNumber!.isNotEmpty) ...[
        _buildInfoRow(colorScheme, 'Account Number',
            widget.receipt.accountNumber!, Icons.account_box),
        _buildDivider(colorScheme),
      ],
      _buildInfoRow(colorScheme, 'Account Name', widget.receipt.recipientName,
          Icons.person_outline),
      _buildDivider(colorScheme),
      if (widget.receipt.receiptEmail != null &&
          widget.receipt.receiptEmail!.isNotEmpty) ...[
        _buildInfoRow(colorScheme, 'Receipt sent to',
            widget.receipt.receiptEmail!, Icons.email_outlined),
        _buildDivider(colorScheme),
      ],
      _buildInfoRow(colorScheme, 'Transfer Amount',
          currencyFormat.format(widget.receipt.amount), Icons.attach_money),
      _buildDivider(colorScheme),
      _buildInfoRow(colorScheme, 'Bank Fee',
          currencyFormat.format(widget.receipt.fee), Icons.receipt_long),
      _buildDivider(colorScheme),
      _buildInfoRow(
        colorScheme,
        'Total',
        currencyFormat.format(widget.receipt.amount + widget.receipt.fee),
        Icons.payments,
        isHighlighted: true,
      ),
      _buildDivider(colorScheme),
      _buildInfoRow(
          colorScheme, 'Ref No.', widget.receipt.refNumber, Icons.tag),
      _buildDivider(colorScheme),
      _buildInfoRow(
        colorScheme,
        'Transfer Date',
        dateFormat.format(widget.receipt.date),
        Icons.calendar_today,
      ),
      _buildDivider(colorScheme),
      _buildSourceDropdown(colorScheme),
    ];
  }

  // Build fields for money transfer (non-editable)
  List<Widget> _buildMoneyTransferFields(ColorScheme colorScheme,
      NumberFormat currencyFormat, DateFormat dateFormat) {
    return [
      _buildInfoRow(
          colorScheme, 'Recipient', widget.receipt.recipientName, Icons.person),
      _buildDivider(colorScheme),
      _buildInfoRow(
          colorScheme, 'Phone Number', widget.receipt.phoneNumber, Icons.phone),
      _buildDivider(colorScheme),
      _buildInfoRow(colorScheme, 'Amount',
          currencyFormat.format(widget.receipt.amount), Icons.attach_money),
      _buildDivider(colorScheme),
      _buildInfoRow(colorScheme, 'Fee',
          currencyFormat.format(widget.receipt.fee), Icons.receipt_long),
      _buildDivider(colorScheme),
      _buildInfoRow(
        colorScheme,
        'Total',
        currencyFormat.format(widget.receipt.amount + widget.receipt.fee),
        Icons.payments,
        isHighlighted: true,
      ),
      _buildDivider(colorScheme),
      _buildInfoRow(
          colorScheme, 'Ref Number', widget.receipt.refNumber, Icons.tag),
      _buildDivider(colorScheme),
      _buildInfoRow(
        colorScheme,
        'Date',
        dateFormat.format(widget.receipt.date),
        Icons.calendar_today,
      ),
      _buildDivider(colorScheme),
      _buildSourceDropdown(colorScheme),
    ];
  }

  Widget _buildInfoRow(
    ColorScheme colorScheme,
    String label,
    String value,
    IconData icon, {
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlighted
            ? colorScheme.primaryContainer.withOpacity(0.3)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: isHighlighted
                  ? LinearGradient(
                      colors: [
                        colorScheme.primary,
                        colorScheme.primary.withOpacity(0.7),
                      ],
                    )
                  : null,
              color:
                  isHighlighted ? null : colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color:
                  isHighlighted ? colorScheme.onPrimary : colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppText.poppins(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppText.poppins(
                    color: colorScheme.onSurface,
                    fontSize: isHighlighted ? 18 : 15,
                    fontWeight:
                        isHighlighted ? FontWeight.w700 : FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(ColorScheme colorScheme) {
    return const SizedBox(height: 8);
  }

  void _showFullScreenImage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Full screen image with pinch to zoom
              Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.file(
                    widget.imageFile,
                    fit: BoxFit.contain,
                    frameBuilder:
                        (context, child, frame, wasSynchronouslyLoaded) {
                      if (wasSynchronouslyLoaded) {
                        return child;
                      }
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: frame != null
                            ? child
                            : Container(
                                color: Colors.black,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[900],
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.broken_image_rounded,
                                size: 64,
                                color: Colors.white54,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Unable to load image',
                                style: AppText.poppins(
                                  color: Colors.white54,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Error: $error',
                                style: AppText.poppins(
                                  color: Colors.white38,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Close button
              Positioned(
                top: 16,
                right: 16,
                child: SafeArea(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
              // Instructions
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Pinch to zoom • Drag to pan',
                        style: AppText.poppins(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        fullscreenDialog: true,
      ),
    );
  }
}
