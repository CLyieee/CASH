import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/app_controller.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';
import '../utils/app_text.dart';

class CalendarViewPage extends StatefulWidget {
  const CalendarViewPage({super.key});

  @override
  State<CalendarViewPage> createState() => _CalendarViewPageState();
}

class _CalendarViewPageState extends State<CalendarViewPage> {
  final AppController controller = Get.find<AppController>();
  final TransactionService _transactionService = TransactionService();

  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();
  List<TransactionModel> _allTransactions = [];
  Map<String, List<TransactionModel>> _transactionsByDate = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);

    try {
      final transactions = await _transactionService.getUserTransactions(
        controller.currentUserId.value,
        limit: 500,
      );

      _allTransactions = transactions;
      _groupTransactionsByDate();
    } catch (e) {
      print('Error loading transactions: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _groupTransactionsByDate() {
    _transactionsByDate.clear();
    for (var transaction in _allTransactions) {
      final dateKey = DateFormat('yyyy-MM-dd').format(transaction.date);
      if (_transactionsByDate.containsKey(dateKey)) {
        _transactionsByDate[dateKey]!.add(transaction);
      } else {
        _transactionsByDate[dateKey] = [transaction];
      }
    }
  }

  List<TransactionModel> _getTransactionsForDate(DateTime date) {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    return _transactionsByDate[dateKey] ?? [];
  }

  bool _hasTransactionsOnDate(DateTime date) {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    return _transactionsByDate.containsKey(dateKey);
  }

  void _changeMonth(int monthDelta) {
    setState(() {
      _focusedMonth = DateTime(
        _focusedMonth.year,
        _focusedMonth.month + monthDelta,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF0D1117) : const Color(0xFFF6F8FA);
    final cardSurface = isDark ? const Color(0xFF1C2128) : Colors.white;
    final cardBorder = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.06);
    final textPrimary =
        isDark ? const Color(0xFFE6EDF3) : const Color(0xFF1F2937);
    final textSecondary =
        isDark ? const Color(0xFF8B949E) : const Color(0xFF6B7280);
    final accentBlue = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: cardSurface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: textPrimary, size: 20),
        ),
        title: Text(
          'Transaction Calendar',
          style: AppText.poppins(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: cardBorder),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: accentBlue),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Calendar
                  Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Column(
                      children: [
                        // Month Header
                        _buildMonthHeader(
                            textPrimary, textSecondary, accentBlue),

                        // Weekday Labels
                        _buildWeekdayLabels(textSecondary),

                        // Calendar Grid
                        _buildCalendarGrid(cardSurface, textPrimary,
                            textSecondary, accentBlue),
                      ],
                    ),
                  ),

                  // Selected Date Transactions
                  _buildTransactionsList(
                    cardSurface,
                    cardBorder,
                    textPrimary,
                    textSecondary,
                    accentBlue,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMonthHeader(
      Color textPrimary, Color textSecondary, Color accentBlue) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => _changeMonth(-1),
            icon: Icon(Icons.chevron_left, color: textPrimary),
          ),
          Column(
            children: [
              Text(
                DateFormat('MMMM yyyy').format(_focusedMonth),
                style: AppText.poppins(
                  color: textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_allTransactions.length} total transactions',
                style: AppText.poppins(
                  color: textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () => _changeMonth(1),
            icon: Icon(Icons.chevron_right, color: textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayLabels(Color textSecondary) {
    const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: weekdays.map((day) {
          return Expanded(
            child: Center(
              child: Text(
                day,
                style: AppText.poppins(
                  color: textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid(Color cardSurface, Color textPrimary,
      Color textSecondary, Color accentBlue) {
    final firstDayOfMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDayOfMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday
    final daysInMonth = lastDayOfMonth.day;

    final List<Widget> dayWidgets = [];

    // Add empty cells for days before the first day of month
    for (int i = 0; i < firstWeekday; i++) {
      dayWidgets.add(const SizedBox());
    }

    // Add day cells
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
      final isSelected = _selectedDate.year == date.year &&
          _selectedDate.month == date.month &&
          _selectedDate.day == date.day;
      final isToday = DateTime.now().year == date.year &&
          DateTime.now().month == date.month &&
          DateTime.now().day == date.day;
      final hasTransactions = _hasTransactionsOnDate(date);

      dayWidgets.add(
        _buildDayCell(
          day,
          date,
          isSelected,
          isToday,
          hasTransactions,
          textPrimary,
          textSecondary,
          accentBlue,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: dayWidgets,
      ),
    );
  }

  Widget _buildDayCell(
    int day,
    DateTime date,
    bool isSelected,
    bool isToday,
    bool hasTransactions,
    Color textPrimary,
    Color textSecondary,
    Color accentBlue,
  ) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedDate = date;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? accentBlue
              : isToday
                  ? accentBlue.withOpacity(0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isToday && !isSelected
              ? Border.all(color: accentBlue, width: 1.5)
              : null,
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                '$day',
                style: AppText.poppins(
                  color: isSelected ? Colors.white : textPrimary,
                  fontSize: 14,
                  fontWeight:
                      isToday || isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (hasTransactions && !isSelected)
              Positioned(
                bottom: 4,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: accentBlue,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList(
    Color cardSurface,
    Color cardBorder,
    Color textPrimary,
    Color textSecondary,
    Color accentBlue,
  ) {
    final transactions = _getTransactionsForDate(_selectedDate);
    final currencyFormat =
        NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 2);

    if (transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 64,
                color: textSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No transactions',
                style: AppText.poppins(
                  color: textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('MMM dd, yyyy').format(_selectedDate),
                style: AppText.poppins(
                  color: textSecondary.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate totals
    double totalCashIn = 0;
    double totalCashOut = 0;
    for (var tx in transactions) {
      if (tx.transactionType.toLowerCase().contains('in')) {
        totalCashIn += tx.amount;
      } else {
        totalCashOut += tx.totalAmount;
      }
    }

    return Column(
      children: [
        // Summary Card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate),
                style: AppText.poppins(
                  color: textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      'Cash In',
                      currencyFormat.format(totalCashIn),
                      const Color(0xFF10B981),
                      Icons.arrow_downward,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryItem(
                      'Cash Out',
                      currencyFormat.format(totalCashOut),
                      const Color(0xFFEF4444),
                      Icons.arrow_upward,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Transactions List
        ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return _buildTransactionCard(
              transaction,
              cardSurface,
              cardBorder,
              textPrimary,
              textSecondary,
              currencyFormat,
            );
          },
        ),
      ],
    );
  }

  Widget _buildSummaryItem(
      String label, String amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppText.poppins(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  amount,
                  style: AppText.poppins(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(
    TransactionModel transaction,
    Color cardSurface,
    Color cardBorder,
    Color textPrimary,
    Color textSecondary,
    NumberFormat currencyFormat,
  ) {
    final isCashIn = transaction.transactionType.toLowerCase().contains('in');
    final color = isCashIn ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCashIn ? Icons.arrow_downward : Icons.arrow_upward,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.recipientName,
                  style: AppText.poppins(
                    color: textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('hh:mm a').format(transaction.date),
                  style: AppText.poppins(
                    color: textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCashIn ? '+' : '-'}${currencyFormat.format(isCashIn ? transaction.amount : transaction.totalAmount)}',
                style: AppText.poppins(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (!isCashIn && transaction.fee > 0)
                Text(
                  'Fee: ${currencyFormat.format(transaction.fee)}',
                  style: AppText.poppins(
                    color: textSecondary,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
