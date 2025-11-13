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

  // Text editing controllers for editable fields
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController amountController;
  late TextEditingController feeController;
  late TextEditingController refNumberController;

  // Available transaction type options
  final List<String> transactionTypeOptions = [
    'Cash In',
    'Cash Out',
    'Load',
    'Bank Transfer',
  ];

  // Available source options
  final List<String> sourceOptions = [
    'GCash',
    'Maya',
    'PayMaya',
    'Palawan Express',
    'MLhuillier',
    'Cebuana Lhuillier',
    'Western Union',
    'LBC',
    'Bank Transfer',
    'Load/E-Load',
    'Coins.ph',
    'GoTyme',
    'Seabank',
    'BPI',
    'BDO',
    'Metrobank',
    'UnionBank',
    'PNB',
    'Landbank',
    'RCBC',
    'Security Bank',
    'Chinabank',
    'Other',
  ];

  @override
  void initState() {
    super.initState();

    // Initialize text controllers with receipt data
    nameController = TextEditingController(text: widget.receipt.recipientName);
    phoneController = TextEditingController(text: widget.receipt.phoneNumber);
    amountController =
        TextEditingController(text: widget.receipt.amount.toString());
    feeController = TextEditingController(text: widget.receipt.fee.toString());
    refNumberController = TextEditingController(text: widget.receipt.refNumber);

    // Initialize with receipt source or default to 'GCash'
    selectedSource =
        widget.receipt.source.isNotEmpty ? widget.receipt.source : 'GCash';
    // Ensure selected source exists in options
    if (!sourceOptions.contains(selectedSource)) {
      selectedSource = 'Other';
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    amountController.dispose();
    feeController.dispose();
    refNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    final dateFormat = DateFormat('MMM dd, yyyy hh:mm a');

    return Scaffold(
      backgroundColor: const Color(0xFFE0E5EC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE0E5EC),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.8),
                  offset: const Offset(-4, -4),
                  blurRadius: 8,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  offset: const Offset(4, 4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF2C3E50),
            ),
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Receipt Preview',
          style: AppText.poppins(
            color: const Color(0xFF2C3E50),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Receipt Image
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        offset: const Offset(6, 6),
                        blurRadius: 12,
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.7),
                        offset: const Offset(-6, -6),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.file(
                      widget.imageFile,
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms).scale(delay: 100.ms),

                const SizedBox(height: 30),

                // Transaction Type Dropdown
                _buildTransactionTypeDropdown()
                    .animate()
                    .fadeIn(delay: 150.ms, duration: 400.ms)
                    .slideY(begin: 0.2, end: 0, delay: 150.ms),

                const SizedBox(height: 20),

                // Extracted Data (Editable)
                _buildDataCard(
                  title: 'Extracted Information (Editable)',
                  children: [
                    _buildEditableField(
                        'Recipient', nameController, Icons.person),
                    _buildDivider(),
                    _buildEditableField(
                        'Phone Number', phoneController, Icons.phone,
                        keyboardType: TextInputType.phone),
                    _buildDivider(),
                    _buildEditableField(
                        'Amount', amountController, Icons.attach_money,
                        keyboardType: TextInputType.number, prefix: '₱'),
                    _buildDivider(),
                    _buildEditableField(
                        'Fee', feeController, Icons.receipt_long,
                        keyboardType: TextInputType.number, prefix: '₱'),
                    _buildDivider(),
                    _buildInfoRow(
                      'Total',
                      currencyFormat.format(_calculateTotal()),
                      Icons.payments,
                      isHighlighted: true,
                    ),
                    _buildDivider(),
                    _buildEditableField(
                        'Ref Number', refNumberController, Icons.tag),
                    _buildDivider(),
                    _buildInfoRow(
                      'Date',
                      dateFormat.format(widget.receipt.date),
                      Icons.calendar_today,
                    ),
                    _buildDivider(),
                    _buildSourceDropdown(),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 400.ms)
                    .slideY(begin: 0.2, end: 0, delay: 200.ms),

                const SizedBox(height: 30),

                // Action Buttons
                if (isSaving)
                  const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF64B5F6)),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          label: 'Cancel',
                          icon: Icons.close_rounded,
                          color: Colors.red.shade400,
                          onTap: () {
                            Get.back(); // Go back to scan page
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildActionButton(
                          label: 'Save',
                          icon: Icons.check_circle_rounded,
                          color: const Color(0xFF4CAF50),
                          onTap: _saveTransaction,
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

  Future<void> _saveTransaction() async {
    try {
      setState(() => isSaving = true);

      // Parse edited values
      final amount =
          double.tryParse(amountController.text) ?? widget.receipt.amount;
      final fee = double.tryParse(feeController.text) ?? widget.receipt.fee;

      // Create transaction with edited values
      final transaction = TransactionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: controller.currentUserId.value,
        recipientName: nameController.text.trim().isNotEmpty
            ? nameController.text.trim()
            : widget.receipt.recipientName,
        phoneNumber: phoneController.text.trim().isNotEmpty
            ? phoneController.text.trim()
            : widget.receipt.phoneNumber,
        amount: amount,
        fee: fee,
        totalAmount: amount + fee,
        refNumber: refNumberController.text.trim().isNotEmpty
            ? refNumberController.text.trim()
            : widget.receipt.refNumber,
        date: widget.receipt.date,
        source: selectedSource, // Use the selected source from dropdown
        transactionType: selectedTransactionType,
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      await _transactionService.saveTransaction(transaction);

      setState(() => isSaving = false);

      // Go back to dashboard
      Get.back();
      Get.back(); // Close scan page too

      // Show success message
      Get.snackbar(
        'Success',
        'Transaction saved successfully!',
        backgroundColor: const Color(0xFF4CAF50),
        colorText: Colors.white,
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
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(20),
        borderRadius: 16,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Widget _buildTransactionTypeDropdown() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E5EC),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            offset: const Offset(-6, -6),
            blurRadius: 12,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(6, 6),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF64B5F6),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF64B5F6).withOpacity(0.4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(
              Icons.swap_horiz_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transaction Type',
                  style: AppText.poppins(
                    color: const Color(0xFF64B5F6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                DropdownButton<String>(
                  value: selectedTransactionType,
                  isExpanded: true,
                  underline: const SizedBox(),
                  icon: const Icon(
                    Icons.arrow_drop_down_rounded,
                    color: Color(0xFF2C3E50),
                  ),
                  style: AppText.poppins(
                    color: const Color(0xFF2C3E50),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  items: transactionTypeOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF64B5F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: Color(0xFF64B5F6),
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
                    color: const Color(0xFF64B5F6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                DropdownButton<String>(
                  value: selectedSource,
                  isExpanded: true,
                  underline: const SizedBox(),
                  icon: const Icon(
                    Icons.arrow_drop_down_rounded,
                    color: Color(0xFF2C3E50),
                  ),
                  style: AppText.poppins(
                    color: const Color(0xFF2C3E50),
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
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E5EC),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            offset: const Offset(-6, -6),
            blurRadius: 12,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(6, 6),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppText.poppins(
              color: const Color(0xFF2C3E50),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon, {
    bool isHighlighted = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isHighlighted
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFF64B5F6),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isHighlighted
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFF64B5F6))
                      .withOpacity(0.4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppText.poppins(
                    color: const Color(0xFF64B5F6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppText.poppins(
                    color: const Color(0xFF2C3E50),
                    fontSize: isHighlighted ? 18 : 15,
                    fontWeight:
                        isHighlighted ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            const Color(0xFF64B5F6).withOpacity(0.3),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.8)],
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              offset: const Offset(0, 4),
              blurRadius: 12,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppText.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    String? prefix,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF64B5F6),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF64B5F6).withOpacity(0.4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppText.poppins(
                    color: const Color(0xFF64B5F6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: AppText.poppins(
                    color: const Color(0xFF2C3E50),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF64B5F6),
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: const Color(0xFF64B5F6).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF64B5F6),
                        width: 2,
                      ),
                    ),
                    prefixText: prefix,
                    prefixStyle: AppText.poppins(
                      color: const Color(0xFF2C3E50),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {}); // Refresh total when amount/fee changes
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _calculateTotal() {
    final amount = double.tryParse(amountController.text) ?? 0.0;
    final fee = double.tryParse(feeController.text) ?? 0.0;
    return amount + fee;
  }
}
