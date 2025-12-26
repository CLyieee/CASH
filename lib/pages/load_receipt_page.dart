import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../models/receipt_model.dart';
import '../services/transaction_service.dart';
import '../utils/app_text.dart';
import '../widgets/cash_loading_animation.dart';

class LoadReceiptPage extends StatefulWidget {
  final ReceiptModel? initialReceipt;

  const LoadReceiptPage({super.key, this.initialReceipt});

  @override
  State<LoadReceiptPage> createState() => _LoadReceiptPageState();
}

class _LoadReceiptPageState extends State<LoadReceiptPage> {
  final _formKey = GlobalKey<FormState>();
  final _transactionService = TransactionService();

  // Controllers
  final _providerNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _amountController = TextEditingController();
  final _feeController = TextEditingController();
  final _referenceNumberController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill data if initial receipt is provided
    if (widget.initialReceipt != null) {
      _prefillFromReceipt(widget.initialReceipt!);
    }
  }

  void _prefillFromReceipt(ReceiptModel receipt) {
    _providerNameController.text = receipt.recipientName;
    _phoneNumberController.text = receipt.phoneNumber;
    if (receipt.amount > 0) {
      _amountController.text = receipt.amount.toStringAsFixed(2);
    }
    if (receipt.fee > 0) {
      _feeController.text = receipt.fee.toStringAsFixed(2);
    }
    _referenceNumberController.text =
        receipt.refNumber.replaceAll(RegExp(r'\s'), '');
    _selectedDate = receipt.date;
  }

  @override
  void dispose() {
    _providerNameController.dispose();
    _phoneNumberController.dispose();
    _amountController.dispose();
    _feeController.dispose();
    _referenceNumberController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              surface: Theme.of(context).colorScheme.surface,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Theme.of(context).colorScheme.primary,
                onPrimary: Colors.white,
                surface: Theme.of(context).colorScheme.surface,
                onSurface: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            child: child!,
          );
        },
      );

      if (time != null) {
        setState(() {
          _selectedDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _saveLoadTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final amount = double.parse(_amountController.text);
      final fee =
          double.parse(_feeController.text.isEmpty ? '0' : _feeController.text);
      final total = amount + fee;

      final transaction = TransactionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: _transactionService.getCurrentUserId(),
        recipientName: _providerNameController.text.trim(),
        phoneNumber: _phoneNumberController.text.trim(),
        amount: amount,
        fee: 0, // Fee is separate for load
        totalAmount: total,
        refNumber: _referenceNumberController.text.trim(),
        date: _selectedDate,
        source: 'Load',
        transactionType: 'Load',
        createdAt: DateTime.now(),
        separateFee: fee,
      );

      await _transactionService.addTransaction(transaction);

      if (mounted) {
        Get.back();
        Get.snackbar(
          'Success',
          'Load transaction saved successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          icon: const Icon(Icons.check_circle, color: Colors.white),
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to save load transaction: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          icon: const Icon(Icons.error, color: Colors.white),
          duration: const Duration(seconds: 3),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Get.back(),
        ),
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: 26,
                height: 26,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'Load Receipt',
                overflow: TextOverflow.ellipsis,
                style: AppText.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
      body: _isSaving
          ? const Center(
              child: CashLoadingAnimation(
                message: 'Saving transaction...',
                size: 90,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primary,
                            colorScheme.primary.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.phone_android,
                            size: 48,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Mobile Load',
                            style: AppText.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter load transaction details',
                            style: AppText.poppins(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Provider Name Field
                    Text(
                      'Provider Name',
                      style: AppText.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _providerNameController,
                      decoration: InputDecoration(
                        hintText: 'e.g., Smart, Globe, TNT',
                        hintStyle: AppText.poppins(
                          color: colorScheme.onSurface.withOpacity(0.4),
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(
                          Icons.business,
                          color: colorScheme.primary,
                        ),
                      ),
                      style: AppText.poppins(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Provider name is required';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Phone Number Field
                    Text(
                      'Phone Number',
                      style: AppText.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneNumberController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ],
                      decoration: InputDecoration(
                        hintText: '09XXXXXXXXX',
                        hintStyle: AppText.poppins(
                          color: colorScheme.onSurface.withOpacity(0.4),
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(
                          Icons.phone,
                          color: colorScheme.primary,
                        ),
                      ),
                      style: AppText.poppins(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Phone number is required';
                        }
                        if (value.length != 11) {
                          return 'Phone number must be 11 digits';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Amount Field
                    Text(
                      'Load Amount',
                      style: AppText.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: AppText.poppins(
                          color: colorScheme.onSurface.withOpacity(0.4),
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            '₱',
                            style: AppText.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      style: AppText.poppins(
                        color: colorScheme.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Amount is required';
                        }
                        final amount = double.tryParse(value);
                        if (amount == null || amount <= 0) {
                          return 'Enter a valid amount';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Convenience Charge Field
                    Text(
                      'Convenience Charge',
                      style: AppText.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _feeController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: AppText.poppins(
                          color: colorScheme.onSurface.withOpacity(0.4),
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            '₱',
                            style: AppText.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      style: AppText.poppins(
                        color: colorScheme.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Reference Number Field
                    Text(
                      'Reference Number',
                      style: AppText.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _referenceNumberController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(9),
                      ],
                      decoration: InputDecoration(
                        hintText: '9-digit reference number',
                        hintStyle: AppText.poppins(
                          color: colorScheme.onSurface.withOpacity(0.4),
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(
                          Icons.tag,
                          color: colorScheme.primary,
                        ),
                      ),
                      style: AppText.poppins(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                        letterSpacing: 1.2,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Reference number is required';
                        }
                        if (value.length != 9) {
                          return 'Reference number must be exactly 9 digits';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Date Field
                    Text(
                      'Transaction Date',
                      style: AppText.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _selectDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              DateFormat('MMM dd, yyyy  h:mm a')
                                  .format(_selectedDate),
                              style: AppText.poppins(
                                color: colorScheme.onSurface,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Total Display
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.primary.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Amount',
                            style: AppText.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            _calculateTotal(),
                            style: AppText.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Save Button
                    FilledButton(
                      onPressed: _saveLoadTransaction,
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        'Save Transaction',
                        style: AppText.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Cancel Button
                    OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: colorScheme.outline),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: AppText.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String _calculateTotal() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final fee = double.tryParse(_feeController.text) ?? 0;
    final total = amount + fee;
    return '₱${NumberFormat('#,##0.00').format(total)}';
  }
}
