import 'package:flutter/material.dart';
import 'package:g/utils/app_text.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/app_controller.dart';
import '../controllers/theme_controller.dart';
import '../services/transaction_service.dart';
import '../models/transaction_model.dart';

class _TransactionLogsPalette {
  _TransactionLogsPalette(ThemeData theme)
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
        accentGreen = const Color(0xFF10B981),
        accentRed = const Color(0xFFEF4444);

  final bool isDark;
  final Color background;
  final Color cardSurface;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color accentBlue;
  final Color accentGreen;
  final Color accentRed;
}

class TransactionLogsPage extends StatefulWidget {
  const TransactionLogsPage({super.key});

  @override
  State<TransactionLogsPage> createState() => _TransactionLogsPageState();
}

class _TransactionLogsPageState extends State<TransactionLogsPage> {
  final TransactionService _transactionService = TransactionService();
  final AppController controller = Get.find<AppController>();
  final ThemeController _themeController = Get.find<ThemeController>();
  final currencyFormat =
      NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 2);
  final dateFormat = DateFormat('MMM dd, yyyy');
  final timeFormat = DateFormat('h:mm a');
  final TextEditingController _searchController = TextEditingController();

  String _selectedFilter = 'All';
  String _searchQuery = '';
  String _sortBy = 'Date (Newest)';
  List<TransactionModel> _allTransactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  List<TransactionModel> get filteredTransactions {
    var transactions = _allTransactions;

    // Apply filter
    if (_selectedFilter != 'All') {
      transactions = transactions
          .where((t) => t.transactionType == _selectedFilter)
          .toList();
    }

    // Apply search
    if (_searchQuery.isNotEmpty) {
      transactions = transactions.where((t) {
        final query = _searchQuery.toLowerCase();
        return t.recipientName.toLowerCase().contains(query) ||
            t.phoneNumber.contains(query) ||
            t.refNumber.toLowerCase().contains(query);
      }).toList();
    }

    // Apply sorting
    switch (_sortBy) {
      case 'Date (Newest)':
        transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Date (Oldest)':
        transactions.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'Amount (High-Low)':
        transactions.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'Amount (Low-High)':
        transactions.sort((a, b) => a.amount.compareTo(b.amount));
        break;
      case 'Name (A-Z)':
        transactions.sort((a, b) => a.recipientName
            .toLowerCase()
            .compareTo(b.recipientName.toLowerCase()));
        break;
      case 'Name (Z-A)':
        transactions.sort((a, b) => b.recipientName
            .toLowerCase()
            .compareTo(a.recipientName.toLowerCase()));
        break;
    }

    return transactions;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _TransactionLogsPalette(theme);

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
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Transaction History',
                              style: AppText.poppins(
                                color: palette.textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              '${filteredTransactions.length} transactions',
                              style: AppText.poppins(
                                color: palette.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: -0.2, end: 0),

                  const SizedBox(height: 16),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All', palette),
                        const SizedBox(width: 10),
                        _buildFilterChip('Cash In', palette),
                        const SizedBox(width: 10),
                        _buildFilterChip('Cash Out', palette),
                      ],
                    ),
                  )
                      .animate(delay: 100.ms)
                      .fadeIn(duration: 400.ms)
                      .slideX(begin: -0.1, end: 0),

                  const SizedBox(height: 16),

                  // Search and Sort Row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: palette.isDark
                                ? palette.cardSurface.withOpacity(0.6)
                                : palette.cardBorder.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: palette.cardBorder,
                            ),
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: AppText.poppins(
                              color: palette.textPrimary,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search by name, number, or ref...',
                              hintStyle: AppText.poppins(
                                color: palette.textSecondary,
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: palette.textSecondary,
                                size: 20,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.clear_rounded,
                                        color: palette.textSecondary,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showSortOptions(palette),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: palette.cardSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: palette.cardBorder,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.sort_rounded,
                                  color: palette.accentBlue,
                                  size: 20,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Sort',
                                  style: AppText.poppins(
                                    color: palette.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                      .animate(delay: 150.ms)
                      .fadeIn(duration: 400.ms)
                      .slideX(begin: 0.1, end: 0),
                ],
              ),
            ),

            // Transaction List
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(palette.accentBlue),
                      ),
                    )
                  : filteredTransactions.isEmpty
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
                                  Icons.receipt_long_rounded,
                                  color: Color(0xFF64B5F6),
                                  size: 50,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'No transactions found',
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
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                          itemCount: filteredTransactions.length,
                          itemBuilder: (context, index) {
                            return _buildTransactionCard(
                                    filteredTransactions[index], palette)
                                .animate(delay: (100 + index * 50).ms)
                                .fadeIn(duration: 400.ms)
                                .slideX(begin: 0.1, end: 0);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, _TransactionLogsPalette palette) {
    final isSelected = _selectedFilter == label;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedFilter = label;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? palette.accentBlue : palette.cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? palette.accentBlue : palette.cardBorder,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: AppText.poppins(
              color: isSelected ? Colors.white : palette.textPrimary,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(
    TransactionModel transaction,
    _TransactionLogsPalette palette,
  ) {
    final isCashIn = transaction.transactionType == 'Cash In';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showTransactionDetails(transaction, palette),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: palette.cardBorder,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (isCashIn ? palette.accentGreen : palette.accentRed)
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isCashIn
                      ? Icons.south_west_rounded
                      : Icons.north_east_rounded,
                  color: isCashIn ? palette.accentGreen : palette.accentRed,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          transaction.transactionType,
                          style: AppText.poppins(
                            color: palette.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${isCashIn ? '+' : '-'}${currencyFormat.format(transaction.amount)}',
                          style: AppText.poppins(
                            color: isCashIn
                                ? palette.accentGreen
                                : palette.accentRed,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            transaction.refNumber,
                            style: AppText.poppins(
                              color: palette.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: palette.accentGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Completed',
                            style: AppText.poppins(
                              color: palette.accentGreen,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${dateFormat.format(transaction.date)} • ${timeFormat.format(transaction.date)}',
                      style: AppText.poppins(
                        color: palette.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
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

  void _showTransactionDetails(
    TransactionModel transaction,
    _TransactionLogsPalette palette,
  ) {
    final isCashIn = transaction.transactionType == 'Cash In';

    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: palette.cardSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: (isCashIn ? palette.accentGreen : palette.accentRed)
                        .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isCashIn
                        ? Icons.south_west_rounded
                        : Icons.north_east_rounded,
                    color: isCashIn ? palette.accentGreen : palette.accentRed,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.transactionType,
                        style: AppText.poppins(
                          color: palette.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: palette.accentGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Completed',
                          style: AppText.poppins(
                            color: palette.accentGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            Divider(color: palette.cardBorder),

            const SizedBox(height: 16),

            // Amount
            _buildDetailRow(
                'Amount', currencyFormat.format(transaction.amount), palette),
            _buildDetailRow(
                'Fee', currencyFormat.format(transaction.fee), palette),
            _buildDetailRow('Total',
                currencyFormat.format(transaction.totalAmount), palette),
            _buildDetailRow('Ref Number', transaction.refNumber, palette),
            _buildDetailRow('Source', transaction.source, palette),
            _buildDetailRow(
                'Date',
                '${dateFormat.format(transaction.date)} • ${timeFormat.format(transaction.date)}',
                palette),

            const SizedBox(height: 24),

            // Delete Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.accentRed,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  Get.back();
                  _confirmDelete(transaction, palette);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.delete_outline,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Delete Transaction',
                      style: AppText.poppins(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      isDismissible: true,
      enableDrag: true,
    );
  }

  Widget _buildDetailRow(
      String label, String value, _TransactionLogsPalette palette) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppText.poppins(
              color: palette.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: AppText.poppins(
                color: palette.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      TransactionModel transaction, _TransactionLogsPalette palette) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: palette.cardSurface,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: palette.accentRed.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.delete_outline,
                  color: palette.accentRed,
                  size: 28,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Delete Transaction?',
                style: AppText.poppins(
                  color: palette.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This action cannot be undone. The transaction will be permanently removed.',
                style: AppText.poppins(
                  color: palette.textSecondary,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: palette.cardBorder),
                        ),
                      ),
                      onPressed: () => Get.back(),
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
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette.accentRed,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        Get.back();
                        await _deleteTransaction(transaction);
                      },
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

  Future<void> _deleteTransaction(TransactionModel transaction) async {
    try {
      await _transactionService.deleteTransaction(transaction.id);
      await _loadTransactions();
      Get.snackbar(
        'Success',
        'Transaction deleted successfully',
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete transaction',
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    }
  }

  void _showSortOptions(_TransactionLogsPalette palette) {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: palette.cardSurface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: palette.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(
                    Icons.sort_rounded,
                    color: palette.accentBlue,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Sort By',
                    style: AppText.poppins(
                      color: palette.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildSortOption(
                'Date (Newest)', Icons.access_time_rounded, palette),
            _buildSortOption('Date (Oldest)', Icons.history_rounded, palette),
            _buildSortOption(
                'Amount (High-Low)', Icons.trending_down_rounded, palette),
            _buildSortOption(
                'Amount (Low-High)', Icons.trending_up_rounded, palette),
            _buildSortOption(
                'Name (A-Z)', Icons.sort_by_alpha_rounded, palette),
            _buildSortOption('Name (Z-A)', Icons.sort_rounded, palette),
          ],
        ),
      ),
      isDismissible: true,
      enableDrag: true,
    );
  }

  Widget _buildSortOption(
      String label, IconData icon, _TransactionLogsPalette palette) {
    final isSelected = _sortBy == label;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _sortBy = label;
          });
          Get.back();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? palette.accentBlue.withOpacity(0.08)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? palette.accentBlue : palette.textSecondary,
                size: 22,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: AppText.poppins(
                    color:
                        isSelected ? palette.accentBlue : palette.textPrimary,
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_rounded,
                  color: palette.accentBlue,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
