import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/app_controller.dart';
import '../services/transaction_service.dart';
import '../services/report_service.dart';
import '../utils/app_text.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final AppController _appController = Get.find<AppController>();
  final TransactionService _transactionService = TransactionService();
  final ReportService _reportService = ReportService();
  final currencyFormat =
      NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 2);

  bool _isGenerating = false;

  Future<void> _generateReport(ReportPeriod period) async {
    setState(() => _isGenerating = true);

    try {
      // Get all transactions
      final userId = _appController.currentUserId.value;
      final allTransactions =
          await _transactionService.getUserTransactions(userId, limit: 10000);

      // Filter by period
      final filteredTransactions =
          _reportService.filterTransactionsByPeriod(allTransactions, period);

      if (filteredTransactions.isEmpty) {
        Get.snackbar(
          'No Data',
          'No transactions found for this period',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      // Get date range
      final dateRange = _reportService.getDateRangeForPeriod(period);

      // Export report
      await _reportService.exportReport(
        filteredTransactions,
        period,
        dateRange['start']!,
        dateRange['end']!,
      );

      Get.snackbar(
        'Success',
        'Report generated successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to generate report: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: cardSurface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: textPrimary, size: 20),
        ),
        title: Text(
          'Export Reports',
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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accentBlue, accentBlue.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: accentBlue.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.file_download,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Generate CSV Reports',
                              style: AppText.poppins(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Export your transaction data',
                              style: AppText.poppins(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  'Select Report Period',
                  style: AppText.poppins(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose the time period for your report',
                  style: AppText.poppins(
                    color: textSecondary,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 20),

                // Report Cards
                _buildReportCard(
                  'Daily Report',
                  'Today\'s transactions',
                  Icons.today,
                  const Color(0xFF4CAF50),
                  () => _generateReport(ReportPeriod.daily),
                  cardSurface,
                  cardBorder,
                  textPrimary,
                  textSecondary,
                ),

                const SizedBox(height: 12),

                _buildReportCard(
                  'Weekly Report',
                  'This week\'s transactions',
                  Icons.calendar_view_week,
                  const Color(0xFF2196F3),
                  () => _generateReport(ReportPeriod.weekly),
                  cardSurface,
                  cardBorder,
                  textPrimary,
                  textSecondary,
                ),

                const SizedBox(height: 12),

                _buildReportCard(
                  'Monthly Report',
                  'This month\'s transactions',
                  Icons.calendar_month,
                  const Color(0xFF9C27B0),
                  () => _generateReport(ReportPeriod.monthly),
                  cardSurface,
                  cardBorder,
                  textPrimary,
                  textSecondary,
                ),

                const SizedBox(height: 12),

                _buildReportCard(
                  'Yearly Report',
                  'This year\'s transactions',
                  Icons.calendar_today,
                  const Color(0xFFFF9800),
                  () => _generateReport(ReportPeriod.yearly),
                  cardSurface,
                  cardBorder,
                  textPrimary,
                  textSecondary,
                ),

                const SizedBox(height: 24),

                // Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: accentBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: accentBlue.withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: accentBlue, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'About Reports',
                              style: AppText.poppins(
                                color: accentBlue,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Reports are generated in CSV format and include all transaction details, summaries, and statistics. You can open them in Excel, Google Sheets, or any spreadsheet application.',
                              style: AppText.poppins(
                                color: textSecondary,
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Loading Overlay
          if (_isGenerating)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cardSurface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: accentBlue),
                      const SizedBox(height: 16),
                      Text(
                        'Generating Report...',
                        style: AppText.poppins(
                          color: textPrimary,
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
      ),
    );
  }

  Widget _buildReportCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
    Color cardSurface,
    Color cardBorder,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isGenerating ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
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
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppText.poppins(
                        color: textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppText.poppins(
                        color: textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: textSecondary, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
