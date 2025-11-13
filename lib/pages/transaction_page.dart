import 'package:flutter/material.dart';
import 'package:g/utils/app_text.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/app_controller.dart';

class TransactionFormPage extends StatefulWidget {
  const TransactionFormPage({super.key});

  @override
  State<TransactionFormPage> createState() => _TransactionFormPageState();
}

class _TransactionFormPageState extends State<TransactionFormPage> {
  final AppController controller = Get.find<AppController>();
  final TextEditingController refNoController = TextEditingController();
  final TextEditingController numberController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController dateController = TextEditingController();

  double calculatedFee = 0.0;

  @override
  void initState() {
    super.initState();
    // Set default date to today
    dateController.text = DateFormat('MMM dd, yyyy').format(DateTime.now());

    // Generate random reference number
    refNoController.text = _generateRefNo();

    // Listen to amount changes to calculate fee
    amountController.addListener(_calculateFee);
  }

  @override
  void dispose() {
    refNoController.dispose();
    numberController.dispose();
    nameController.dispose();
    amountController.dispose();
    dateController.dispose();
    super.dispose();
  }

  String _generateRefNo() {
    final now = DateTime.now();
    final random = DateTime.now().millisecondsSinceEpoch % 10000;
    return 'TXN${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}$random';
  }

  void _calculateFee() {
    if (amountController.text.isNotEmpty) {
      try {
        final amount = double.parse(amountController.text);
        setState(() {
          calculatedFee = controller.getFeeForAmount(amount);
        });
      } catch (e) {
        setState(() {
          calculatedFee = 0.0;
        });
      }
    } else {
      setState(() {
        calculatedFee = 0.0;
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF64B5F6),
              onPrimary: Colors.white,
              surface: Color(0xFFE0E5EC),
              onSurface: Color(0xFF2C3E50),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        dateController.text = DateFormat('MMM dd, yyyy').format(picked);
      });
    }
  }

  void _submitTransaction() {
    if (refNoController.text.isEmpty ||
        numberController.text.isEmpty ||
        nameController.text.isEmpty ||
        amountController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill all fields',
        backgroundColor: Colors.redAccent.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(20),
        borderRadius: 16,
      );
      return;
    }

    Get.snackbar(
      'Transaction Successful',
      'Reference: ${refNoController.text}',
      backgroundColor: const Color(0xFF4CAF50).withOpacity(0.9),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(20),
      borderRadius: 16,
      duration: const Duration(seconds: 3),
    );

    // Clear form
    numberController.clear();
    nameController.clear();
    amountController.clear();
    setState(() {
      calculatedFee = 0.0;
      refNoController.text = _generateRefNo();
      dateController.text = DateFormat('MMM dd, yyyy').format(DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0E5EC),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  IconButton(
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'New Transaction',
                      style: AppText.poppins(
                        color: const Color(0xFF2C3E50),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.white.withOpacity(0.8),
                            offset: const Offset(-2, -2),
                            blurRadius: 4,
                          ),
                          Shadow(
                            color: Colors.black.withOpacity(0.2),
                            offset: const Offset(2, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.3, end: 0),
            ),

            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    // Reference Number (Read-only)
                    _buildNeuInput(
                      label: 'Reference Number',
                      controller: refNoController,
                      icon: Icons.tag_rounded,
                      readOnly: true,
                    )
                        .animate(delay: 100.ms)
                        .fadeIn(duration: 400.ms)
                        .slideX(begin: -0.2, end: 0),

                    const SizedBox(height: 20),

                    // Phone Number
                    _buildNeuInput(
                      label: 'Phone Number',
                      controller: numberController,
                      icon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                      hintText: '09XX XXX XXXX',
                    )
                        .animate(delay: 200.ms)
                        .fadeIn(duration: 400.ms)
                        .slideX(begin: -0.2, end: 0),

                    const SizedBox(height: 20),

                    // Recipient Name
                    _buildNeuInput(
                      label: 'Recipient Name',
                      controller: nameController,
                      icon: Icons.person_outline_rounded,
                      hintText: 'Enter full name',
                    )
                        .animate(delay: 300.ms)
                        .fadeIn(duration: 400.ms)
                        .slideX(begin: -0.2, end: 0),

                    const SizedBox(height: 20),

                    // Amount
                    _buildNeuInput(
                      label: 'Amount',
                      controller: amountController,
                      icon: Icons.attach_money_rounded,
                      keyboardType: TextInputType.number,
                      hintText: '0.00',
                    )
                        .animate(delay: 400.ms)
                        .fadeIn(duration: 400.ms)
                        .slideX(begin: -0.2, end: 0),

                    const SizedBox(height: 20),

                    // Date
                    GestureDetector(
                      onTap: _selectDate,
                      child: AbsorbPointer(
                        child: _buildNeuInput(
                          label: 'Date',
                          controller: dateController,
                          icon: Icons.calendar_today_rounded,
                          readOnly: true,
                        ),
                      ),
                    )
                        .animate(delay: 500.ms)
                        .fadeIn(duration: 400.ms)
                        .slideX(begin: -0.2, end: 0),

                    const SizedBox(height: 30),

                    // Fee Display Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E5EC),
                        borderRadius: BorderRadius.circular(24),
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
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Transaction Fee',
                                style: AppText.poppins(
                                  color: const Color(0xFF2C3E50),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF64B5F6),
                                      Color(0xFF42A5F5)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF64B5F6)
                                          .withOpacity(0.4),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  '₱${calculatedFee.toStringAsFixed(2)}',
                                  style: AppText.poppins(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (amountController.text.isNotEmpty &&
                              calculatedFee > 0) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0E5EC),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    offset: const Offset(4, 4),
                                    blurRadius: 8,
                                  ),
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.7),
                                    offset: const Offset(-4, -4),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  _buildFeeRow(
                                    'Amount',
                                    '₱${double.tryParse(amountController.text)?.toStringAsFixed(2) ?? '0.00'}',
                                  ),
                                  const SizedBox(height: 8),
                                  _buildFeeRow(
                                    'Fee',
                                    '₱${calculatedFee.toStringAsFixed(2)}',
                                  ),
                                  const Divider(height: 20),
                                  _buildFeeRow(
                                    'Total',
                                    '₱${((double.tryParse(amountController.text) ?? 0) + calculatedFee).toStringAsFixed(2)}',
                                    isTotal: true,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                        .animate(delay: 600.ms)
                        .fadeIn(duration: 500.ms)
                        .scale(begin: const Offset(0.9, 0.9)),

                    const SizedBox(height: 30),

                    // Submit Button
                    GestureDetector(
                      onTap: _submitTransaction,
                      child: Container(
                        height: 68,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF64B5F6), Color(0xFF42A5F5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF64B5F6).withOpacity(0.4),
                              offset: const Offset(0, 8),
                              blurRadius: 24,
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: _submitTransaction,
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.check_circle_outline_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Submit Transaction',
                                    style: AppText.poppins(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                        .animate(delay: 700.ms)
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: 0.3, end: 0),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNeuInput({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    String? hintText,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppText.poppins(
            color: const Color(0xFF64B5F6),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFE0E5EC),
            borderRadius: BorderRadius.circular(16),
            boxShadow: readOnly
                ? [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.7),
                      offset: const Offset(-4, -4),
                      blurRadius: 8,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      offset: const Offset(4, 4),
                      blurRadius: 8,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      offset: const Offset(4, 4),
                      blurRadius: 8,
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.7),
                      offset: const Offset(-4, -4),
                      blurRadius: 8,
                    ),
                  ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            style: AppText.poppins(
              color:
                  readOnly ? const Color(0xFF64B5F6) : const Color(0xFF2C3E50),
              fontSize: 16,
              fontWeight: readOnly ? FontWeight.w600 : FontWeight.w500,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                color: const Color(0xFF64B5F6),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
              hintText: hintText,
              hintStyle: AppText.poppins(
                color: const Color(0xFF2C3E50).withOpacity(0.4),
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeeRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppText.poppins(
            color: isTotal ? const Color(0xFF2C3E50) : const Color(0xFF64B5F6),
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: AppText.poppins(
            color: const Color(0xFF2C3E50),
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
