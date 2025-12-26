import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
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
          snackPosition: SnackPosition.TOP,
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
          colorText: Theme.of(context).colorScheme.onErrorContainer,
          margin: const EdgeInsets.all(20),
          borderRadius: 16,
        );
        return;
      }

      // Get date range
      final dateRange = _reportService.getDateRangeForPeriod(period);

      // Export report - let user choose location
      final savedPath = await _reportService.exportReport(
        filteredTransactions,
        period,
        dateRange['start']!,
        dateRange['end']!,
      );

      if (savedPath != null) {
        // Successfully saved
        final fileName =
            kIsWeb ? savedPath : savedPath.split(Platform.pathSeparator).last;

        String message;
        if (kIsWeb) {
          message = 'Report downloaded: $fileName';
        } else {
          try {
            final isMobile = Platform.isAndroid || Platform.isIOS;
            message = isMobile
                ? 'Report generated: $fileName\nShare dialog opened'
                : 'Report saved: $fileName';
          } catch (e) {
            message = 'Report saved: $fileName';
          }
        }

        Get.snackbar(
          'Success',
          message,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          colorText: Theme.of(context).colorScheme.onPrimaryContainer,
          margin: const EdgeInsets.all(20),
          borderRadius: 16,
          duration: const Duration(seconds: 4),
        );
      } else {
        // User cancelled
        Get.snackbar(
          'Cancelled',
          'Export cancelled by user',
          snackPosition: SnackPosition.TOP,
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerHighest,
          colorText: Theme.of(context).colorScheme.onSurface,
          margin: const EdgeInsets.all(20),
          borderRadius: 16,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to generate report: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
        colorText: Theme.of(context).colorScheme.onErrorContainer,
        margin: const EdgeInsets.all(20),
        borderRadius: 16,
        duration: const Duration(seconds: 4),
      );
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colorScheme.onSurface,
            size: 20,
          ),
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
                'Export Reports',
                overflow: TextOverflow.ellipsis,
                style: AppText.poppins(
                  color: colorScheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
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
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary,
                        colorScheme.primary.withOpacity(0.8)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
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
                        child: const Icon(
                          Icons.file_download_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
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
                    color: colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose the time period for your report',
                  style: AppText.poppins(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 20),

                // Report Cards
                _buildReportCard(
                  colorScheme,
                  'Daily Report',
                  'Today\'s transactions',
                  Icons.today_rounded,
                  const Color(0xFF4CAF50),
                  () => _generateReport(ReportPeriod.daily),
                ),

                const SizedBox(height: 12),

                _buildReportCard(
                  colorScheme,
                  'Weekly Report',
                  'This week\'s transactions',
                  Icons.calendar_view_week_rounded,
                  const Color(0xFF2196F3),
                  () => _generateReport(ReportPeriod.weekly),
                ),

                const SizedBox(height: 12),

                _buildReportCard(
                  colorScheme,
                  'Monthly Report',
                  'This month\'s transactions',
                  Icons.calendar_month_rounded,
                  const Color(0xFF9C27B0),
                  () => _generateReport(ReportPeriod.monthly),
                ),

                const SizedBox(height: 12),

                _buildReportCard(
                  colorScheme,
                  'Yearly Report',
                  'This year\'s transactions',
                  Icons.calendar_today_rounded,
                  const Color(0xFFFF9800),
                  () => _generateReport(ReportPeriod.yearly),
                ),

                const SizedBox(height: 24),

                // Info Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: colorScheme.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: colorScheme.onPrimaryContainer,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'About Reports',
                              style: AppText.poppins(
                                color: colorScheme.onPrimaryContainer,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Reports are generated in CSV format and include all transaction details, summaries, and statistics. You can open them in Excel, Google Sheets, or any spreadsheet application.',
                              style: AppText.poppins(
                                color: colorScheme.onPrimaryContainer,
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
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: colorScheme.primary),
                      const SizedBox(height: 16),
                      Text(
                        'Generating Report...',
                        style: AppText.poppins(
                          color: colorScheme.onSurface,
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
    ColorScheme colorScheme,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isGenerating ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppText.poppins(
                        color: colorScheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppText.poppins(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: colorScheme.onSurfaceVariant,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
