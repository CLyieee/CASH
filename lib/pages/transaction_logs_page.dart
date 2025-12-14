import 'package:flutter/material.dart';
import 'package:g/utils/app_text.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:g/utils/responsive_helper.dart';
import '../controllers/app_controller.dart';
import '../services/transaction_service.dart';
import '../models/transaction_model.dart';

class _TransactionLogsPalette {
  _TransactionLogsPalette(ThemeData theme)
      : isDark = theme.brightness == Brightness.dark,
        // M3 Surface colors
        background = theme.brightness == Brightness.dark
            ? const Color(0xFF0D1117)
            : const Color(0xFFFCFCFF),
        surfaceContainer = theme.brightness == Brightness.dark
            ? const Color(0xFF1C2128)
            : const Color(0xFFF3F3F6),
        surfaceContainerHigh = theme.brightness == Brightness.dark
            ? const Color(0xFF262C36)
            : const Color(0xFFEAEAED),
        containerHigh = theme.brightness == Brightness.dark
            ? const Color(0xFF262C36)
            : const Color(0xFFEAEAED),
        cardSurface = theme.brightness == Brightness.dark
            ? const Color(0xFF1C2128)
            : Colors.white,
        cardBorder = theme.brightness == Brightness.dark
            ? Colors.white.withOpacity(0.06)
            : Colors.black.withOpacity(0.04),
        // M3 Text colors
        textPrimary = theme.colorScheme.onSurface,
        textSecondary = theme.brightness == Brightness.dark
            ? const Color(0xFF9CA3AF)
            : const Color(0xFF6B7280),
        textTertiary = theme.brightness == Brightness.dark
            ? const Color(0xFF6B7280)
            : const Color(0xFF9CA3AF),
        // M3 On-surface colors
        onSurface = theme.colorScheme.onSurface,
        onSurfaceVariant = theme.brightness == Brightness.dark
            ? const Color(0xFF9CA3AF)
            : const Color(0xFF6B7280),
        // M3 Outline colors
        outline = theme.brightness == Brightness.dark
            ? const Color(0xFF4B5563)
            : const Color(0xFFD1D5DB),
        outlineVariant = theme.brightness == Brightness.dark
            ? const Color(0xFF374151)
            : const Color(0xFFE5E7EB),
        // M3 Primary tonal palette
        primary = theme.brightness == Brightness.dark
            ? const Color(0xFF93C5FD)
            : const Color(0xFF2563EB),
        primaryContainer = theme.brightness == Brightness.dark
            ? const Color(0xFF1E3A5F)
            : const Color(0xFFDBEAFE),
        onPrimaryContainer = theme.brightness == Brightness.dark
            ? const Color(0xFFDBEAFE)
            : const Color(0xFF1E3A5F),
        // Legacy accent colors (for compatibility)
        accentBlue = theme.brightness == Brightness.dark
            ? const Color(0xFF93C5FD)
            : const Color(0xFF2563EB),
        accentGreen = theme.brightness == Brightness.dark
            ? const Color(0xFF86EFAC)
            : const Color(0xFF16A34A),
        accentRed = theme.brightness == Brightness.dark
            ? const Color(0xFFFCA5A5)
            : const Color(0xFFDC2626),
        // M3 Semantic colors
        success = theme.brightness == Brightness.dark
            ? const Color(0xFF86EFAC)
            : const Color(0xFF16A34A),
        successContainer = theme.brightness == Brightness.dark
            ? const Color(0xFF14532D)
            : const Color(0xFFDCFCE7),
        error = theme.brightness == Brightness.dark
            ? const Color(0xFFFCA5A5)
            : const Color(0xFFDC2626),
        onError = theme.brightness == Brightness.dark
            ? const Color(0xFF7F1D1D)
            : Colors.white,
        errorContainer = theme.brightness == Brightness.dark
            ? const Color(0xFF7F1D1D)
            : const Color(0xFFFEE2E2),
        warning = theme.brightness == Brightness.dark
            ? const Color(0xFFFBBF24)
            : const Color(0xFFD97706),
        warningContainer = theme.brightness == Brightness.dark
            ? const Color(0xFF78350F)
            : const Color(0xFFFEF3C7);

  final bool isDark;
  final Color background;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color containerHigh;
  final Color cardSurface;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color outline;
  final Color outlineVariant;
  final Color primary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color accentBlue;
  final Color accentGreen;
  final Color accentRed;
  final Color success;
  final Color successContainer;
  final Color error;
  final Color onError;
  final Color errorContainer;
  final Color warning;
  final Color warningContainer;
}

class TransactionLogsPage extends StatefulWidget {
  const TransactionLogsPage({super.key});

  @override
  State<TransactionLogsPage> createState() => _TransactionLogsPageState();
}

class _TransactionLogsPageState extends State<TransactionLogsPage> {
  final TransactionService _transactionService = TransactionService();
  final AppController controller = Get.find<AppController>();
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
      // Special handling for Load - filter by source
      if (_selectedFilter == 'Load') {
        transactions = transactions.where((t) => t.source == 'Load').toList();
      } else {
        transactions = transactions
            .where((t) => t.transactionType == _selectedFilter)
            .toList();
      }
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 360;
    final isSmall = screenWidth < 400;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          children: [
            // M3 Header with surfaceContainer background
            Container(
              padding: EdgeInsets.fromLTRB(
                isCompact ? 12 : (isSmall ? 16 : 20),
                isCompact ? 12 : 16,
                isCompact ? 12 : (isSmall ? 16 : 20),
                isCompact ? 12 : 16,
              ),
              decoration: BoxDecoration(
                color: palette.surfaceContainer,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // M3 Back button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Get.back(),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: EdgeInsets.all(isCompact ? 8 : 10),
                            decoration: BoxDecoration(
                              color: palette.cardSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: palette.cardBorder),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: palette.textPrimary,
                              size: isCompact ? 18 : 20,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: isCompact ? 12 : 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Transaction History',
                              style: AppText.poppins(
                                color: palette.textPrimary,
                                fontSize: isCompact ? 18 : (isSmall ? 20 : 22),
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              '${filteredTransactions.length} transactions',
                              style: AppText.poppins(
                                color: palette.textSecondary,
                                fontSize: isCompact ? 11 : (isSmall ? 12 : 13),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // M3 Sort button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showSortOptions(palette),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: EdgeInsets.all(isCompact ? 8 : 10),
                            decoration: BoxDecoration(
                              color: palette.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.sort_rounded,
                              color: palette.onPrimaryContainer,
                              size: isCompact ? 18 : 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: -0.2, end: 0),

                  SizedBox(height: isCompact ? 12 : 16),

                  // M3 Search Field
                  Container(
                    height: isCompact ? 44 : 48,
                    decoration: BoxDecoration(
                      color: palette.cardSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: palette.cardBorder),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: AppText.poppins(
                        color: palette.textPrimary,
                        fontSize: isCompact ? 13 : 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search transactions...',
                        hintStyle: AppText.poppins(
                          color: palette.textTertiary,
                          fontSize: isCompact ? 13 : 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: palette.textSecondary,
                          size: isCompact ? 18 : 20,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear_rounded,
                                  color: palette.textSecondary,
                                  size: isCompact ? 18 : 20,
                                ),
                                onPressed: () => _searchController.clear(),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 12 : 16,
                          vertical: isCompact ? 10 : 12,
                        ),
                      ),
                    ),
                  )
                      .animate(delay: 100.ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.1, end: 0),

                  SizedBox(height: isCompact ? 12 : 16),

                  // M3 Filter Chips with pill style
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildM3FilterChip('All', Icons.list_rounded, palette),
                        SizedBox(width: isCompact ? 6 : 8),
                        _buildM3FilterChip(
                            'Cash In', Icons.south_west_rounded, palette),
                        SizedBox(width: isCompact ? 6 : 8),
                        _buildM3FilterChip(
                            'Cash Out', Icons.north_east_rounded, palette),
                        SizedBox(width: isCompact ? 6 : 8),
                        _buildM3FilterChip(
                            'Load', Icons.phone_android_rounded, palette),
                        SizedBox(width: isCompact ? 6 : 8),
                        _buildM3FilterChip('Bank Transfer',
                            Icons.account_balance_rounded, palette),
                      ],
                    ),
                  )
                      .animate(delay: 150.ms)
                      .fadeIn(duration: 400.ms)
                      .slideX(begin: -0.1, end: 0),
                ],
              ),
            ),

            // Transaction List
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(palette.primary),
                      ),
                    )
                  : filteredTransactions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: ResponsiveHelper.iconSize(context,
                                    base: 100),
                                height: ResponsiveHelper.iconSize(context,
                                    base: 100),
                                decoration: BoxDecoration(
                                  color: palette.surfaceContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.receipt_long_rounded,
                                  color: palette.primary,
                                  size: ResponsiveHelper.iconSize(context,
                                      base: 50),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'No transactions found',
                                style: AppText.poppins(
                                  color: palette.onSurfaceVariant,
                                  fontSize: ResponsiveHelper.fontSize(context,
                                      mobile: 16),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Transactions will appear here',
                                style: AppText.poppins(
                                  color: palette.outline,
                                  fontSize: ResponsiveHelper.fontSize(context,
                                      mobile: 13),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.fromLTRB(
                            ResponsiveHelper.horizontalPadding(context),
                            ResponsiveHelper.verticalPadding(context) * 0.83,
                            ResponsiveHelper.horizontalPadding(context),
                            ResponsiveHelper.verticalPadding(context) * 0.83,
                          ),
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
              fontSize: ResponsiveHelper.fontSize(context, mobile: 13),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildM3FilterChip(
      String label, IconData icon, _TransactionLogsPalette palette) {
    final isSelected = _selectedFilter == label;
    final isCompact = MediaQuery.of(context).size.width < 360;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedFilter = label;
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 12 : 16,
            vertical: isCompact ? 8 : 10,
          ),
          decoration: BoxDecoration(
            color: isSelected ? palette.primaryContainer : palette.cardSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? palette.primary : palette.outline,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: isCompact ? 14 : 16,
                color: isSelected
                    ? palette.onPrimaryContainer
                    : palette.onSurfaceVariant,
              ),
              SizedBox(width: isCompact ? 4 : 6),
              Text(
                label,
                style: AppText.poppins(
                  color: isSelected
                      ? palette.onPrimaryContainer
                      : palette.onSurface,
                  fontSize: ResponsiveHelper.fontSize(context, mobile: 12),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
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
          padding: ResponsiveHelper.cardPadding(context),
          decoration: BoxDecoration(
            color: palette.containerHigh,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: ResponsiveHelper.iconSize(context, base: 48),
                height: ResponsiveHelper.iconSize(context, base: 48),
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
                  size: ResponsiveHelper.iconSize(context, base: 24),
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
                              fontSize: ResponsiveHelper.fontSize(context,
                                  mobile: 12),
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: palette.accentGreen.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Completed',
                            style: AppText.poppins(
                              color: palette.accentGreen,
                              fontSize: ResponsiveHelper.fontSize(context,
                                  mobile: 10),
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
                        fontSize:
                            ResponsiveHelper.fontSize(context, mobile: 11),
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
      LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 380;
          return Container(
            decoration: BoxDecoration(
              color: palette.surfaceContainer,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.all(isNarrow ? 16 : 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: ResponsiveHelper.iconSize(context, base: 56),
                      height: ResponsiveHelper.iconSize(context, base: 56),
                      decoration: BoxDecoration(
                        color:
                            (isCashIn ? palette.accentGreen : palette.accentRed)
                                .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        isCashIn
                            ? Icons.south_west_rounded
                            : Icons.north_east_rounded,
                        color:
                            isCashIn ? palette.accentGreen : palette.accentRed,
                        size: ResponsiveHelper.iconSize(context, base: 28),
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
                              color: palette.onSurface,
                              fontSize: ResponsiveHelper.fontSize(context,
                                  mobile: 18),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: palette.accentGreen.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Completed',
                              style: AppText.poppins(
                                color: palette.accentGreen,
                                fontSize: ResponsiveHelper.fontSize(context,
                                    mobile: 11),
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

                Divider(color: palette.outlineVariant),

                const SizedBox(height: 16),

                // Amount
                _buildDetailRow('Amount',
                    currencyFormat.format(transaction.amount), palette),
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

                // M3 Delete Button - Tonal Error Style
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.error.withOpacity(0.12),
                      foregroundColor: palette.error,
                      padding: EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: isNarrow ? 8 : 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Get.back();
                      _confirmDelete(transaction, palette);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          size: isNarrow ? 18 : 20,
                        ),
                        SizedBox(width: isNarrow ? 6 : 8),
                        Flexible(
                          child: Text(
                            'Delete Transaction',
                            style: AppText.poppins(
                              fontSize: isNarrow ? 13 : 14,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
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
              color: palette.onSurfaceVariant,
              fontSize: ResponsiveHelper.fontSize(context, mobile: 13),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style: AppText.poppins(
                color: palette.onSurface,
                fontSize: ResponsiveHelper.fontSize(context, mobile: 13),
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
          borderRadius: BorderRadius.circular(28),
        ),
        backgroundColor: palette.surfaceContainer,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: ResponsiveHelper.iconSize(context, base: 56),
                height: ResponsiveHelper.iconSize(context, base: 56),
                decoration: BoxDecoration(
                  color: palette.error.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: palette.error,
                  size: ResponsiveHelper.iconSize(context, base: 28),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Delete Transaction?',
                style: AppText.poppins(
                  color: palette.onSurface,
                  fontSize: ResponsiveHelper.fontSize(context, mobile: 18),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This action cannot be undone. The transaction will be permanently removed.',
                style: AppText.poppins(
                  color: palette.onSurfaceVariant,
                  fontSize: ResponsiveHelper.fontSize(context, mobile: 13),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        foregroundColor: palette.onSurface,
                        side: BorderSide(color: palette.outline),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => Get.back(),
                      child: Text(
                        'Cancel',
                        style: AppText.poppins(
                          fontSize:
                              ResponsiveHelper.fontSize(context, mobile: 14),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.error,
                        foregroundColor: palette.onError,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () async {
                        Get.back();
                        await _deleteTransaction(transaction);
                      },
                      child: Text(
                        'Delete',
                        style: AppText.poppins(
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
          color: palette.surfaceContainer,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: palette.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.horizontalPadding(context),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: palette.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.sort_rounded,
                      color: palette.onPrimaryContainer,
                      size: ResponsiveHelper.iconSize(context, base: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Sort By',
                    style: AppText.poppins(
                      color: palette.onSurface,
                      fontSize: ResponsiveHelper.fontSize(context, mobile: 18),
                      fontWeight: FontWeight.w600,
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: isSelected ? palette.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? palette.onPrimaryContainer
                    : palette.onSurfaceVariant,
                size: ResponsiveHelper.iconSize(context, base: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: AppText.poppins(
                    color: isSelected
                        ? palette.onPrimaryContainer
                        : palette.onSurface,
                    fontSize: ResponsiveHelper.fontSize(context, mobile: 15),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: palette.primary,
                  size: ResponsiveHelper.iconSize(context, base: 22),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
