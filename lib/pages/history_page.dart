import 'package:flutter/material.dart';
import 'package:g/utils/app_text.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/app_controller.dart';
import '../services/transaction_service.dart';
import '../models/transaction_model.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final TextEditingController searchController = TextEditingController();
  final TransactionService _transactionService = TransactionService();
  final AppController controller = Get.find<AppController>();
  final currencyFormat =
      NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 2);

  String searchQuery = '';
  List<TransactionModel> _allTransactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    if (controller.currentUserId.value.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final transactions = await _transactionService.getUserTransactions(
        controller.currentUserId.value,
      );
      setState(() {
        _allTransactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading transactions: $e');
      setState(() => _isLoading = false);
    }
  }

  // Group transactions by month
  Map<String, List<TransactionModel>> get groupedTransactions {
    Map<String, List<TransactionModel>> grouped = {};

    for (var transaction in _allTransactions) {
      // Filter by search query
      if (searchQuery.isNotEmpty) {
        final matchesSearch = transaction.recipientName
                .toLowerCase()
                .contains(searchQuery.toLowerCase()) ||
            transaction.transactionType
                .toLowerCase()
                .contains(searchQuery.toLowerCase()) ||
            transaction.phoneNumber
                .toLowerCase()
                .contains(searchQuery.toLowerCase());

        if (!matchesSearch) continue;
      }

      final monthYear = DateFormat('MMMM yyyy').format(transaction.createdAt);

      if (!grouped.containsKey(monthYear)) {
        grouped[monthYear] = [];
      }
      grouped[monthYear]!.add(transaction);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0E5EC),
      body: SafeArea(
        child: Column(
          children: [
            // Header with neumorphic style
            Padding(
              padding: const EdgeInsets.all(20),
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
                      'History',
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

            // Search bar with neumorphic style
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E5EC),
                  borderRadius: BorderRadius.circular(25),
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
                child: Row(
                  children: [
                    const SizedBox(width: 20),
                    const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF64B5F6),
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                          });
                        },
                        style: AppText.poppins(
                          color: const Color(0xFF2C3E50),
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search Reference',
                          hintStyle: AppText.poppins(
                            color: const Color(0xFF2C3E50).withOpacity(0.4),
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                  ],
                ),
              )
                  .animate(delay: 100.ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: -0.2, end: 0),
            ),

            const SizedBox(height: 20),

            // History List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF64B5F6)),
                      ),
                    )
                  : groupedTransactions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0E5EC),
                                  shape: BoxShape.circle,
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
                                child: const Icon(
                                  Icons.history_rounded,
                                  size: 50,
                                  color: Color(0xFF64B5F6),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'No history found',
                                style: AppText.poppins(
                                  color:
                                      const Color(0xFF2C3E50).withOpacity(0.6),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: groupedTransactions.keys.length,
                          itemBuilder: (context, index) {
                            String month =
                                groupedTransactions.keys.elementAt(index);
                            List<TransactionModel> transactions =
                                groupedTransactions[month]!;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Month Header
                                Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 16, top: 8),
                                  child: Text(
                                    month,
                                    style: AppText.poppins(
                                      color: const Color(0xFF2C3E50),
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          color: Colors.white.withOpacity(0.8),
                                          offset: const Offset(-1, -1),
                                          blurRadius: 2,
                                        ),
                                        Shadow(
                                          color: Colors.black.withOpacity(0.2),
                                          offset: const Offset(1, 1),
                                          blurRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                    .animate(delay: (100 + index * 50).ms)
                                    .fadeIn(duration: 400.ms)
                                    .slideX(begin: -0.2, end: 0),

                                // Transaction Cards
                                ...transactions.asMap().entries.map((entry) {
                                  int transIndex = entry.key;
                                  TransactionModel transaction = entry.value;

                                  return _buildHistoryCard(transaction)
                                      .animate(
                                          delay: (150 +
                                                  index * 50 +
                                                  transIndex * 50)
                                              .ms)
                                      .fadeIn(duration: 400.ms)
                                      .slideX(begin: -0.2, end: 0);
                                }).toList(),

                                const SizedBox(height: 16),
                              ],
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(TransactionModel transaction) {
    final isCashIn = transaction.transactionType == 'Cash In';
    final dateFormat = DateFormat('MMM dd, yyyy');

    return GestureDetector(
      onTap: () => _showTransactionDetails(transaction),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFE0E5EC),
          borderRadius: BorderRadius.circular(16),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.recipientName,
                    style: AppText.poppins(
                      color: const Color(0xFF2C3E50),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${transaction.transactionType} - ${dateFormat.format(transaction.createdAt)}',
                    style: AppText.poppins(
                      color: const Color(0xFF64B5F6),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: (isCashIn
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFF44336))
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${isCashIn ? '+' : '-'}${currencyFormat.format(transaction.totalAmount)}',
                style: AppText.poppins(
                  color: isCashIn
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFF44336),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactionDetails(TransactionModel transaction) {
    final dateFormat = DateFormat('MMM dd, yyyy hh:mm a');
    final currencyFormat = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFE0E5EC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF64B5F6).withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'Transaction Details',
              style: AppText.poppins(
                color: const Color(0xFF2C3E50),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Details
            _buildDetailRow(
                'Recipient', transaction.recipientName, Icons.person),
            _buildDetailRow('Phone', transaction.phoneNumber, Icons.phone),
            _buildDetailRow('Amount', currencyFormat.format(transaction.amount),
                Icons.attach_money),
            _buildDetailRow('Fee', currencyFormat.format(transaction.fee),
                Icons.receipt_long),
            _buildDetailRow('Total',
                currencyFormat.format(transaction.totalAmount), Icons.payments),
            _buildDetailRow('Ref Number', transaction.refNumber, Icons.tag),
            _buildDetailRow(
                'Source', transaction.source, Icons.account_balance_wallet),
            _buildDetailRow(
                'Type', transaction.transactionType, Icons.swap_horiz),
            _buildDetailRow('Date', dateFormat.format(transaction.date),
                Icons.calendar_today),

            const SizedBox(height: 24),

            // Close Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF64B5F6),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Get.back(),
                child: Text(
                  'Close',
                  style: AppText.poppins(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF64B5F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF64B5F6), size: 20),
          ),
          const SizedBox(width: 12),
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
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppText.poppins(
                    color: const Color(0xFF2C3E50),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
