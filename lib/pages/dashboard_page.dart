import 'package:flutter/material.dart';
import 'package:g/utils/app_text.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import '../services/google_sign_in_service.dart';
import '../controllers/app_controller.dart';
import '../controllers/dashboard_controller.dart';
import 'scan_page.dart';
import 'transaction_logs_page.dart';
import 'settings_page.dart';
import 'landing_page.dart';
import 'ai_chat_page.dart';
import 'calendar_view_page.dart';
import 'dart:math' as math;

class _DashboardPalette {
  _DashboardPalette(ThemeData theme)
      : isDark = theme.brightness == Brightness.dark,
        background = theme.scaffoldBackgroundColor,
        cardSurface = theme.brightness == Brightness.dark
            ? const Color(0xFF1A2332)
            : Colors.white,
        cardBorder = theme.brightness == Brightness.dark
            ? Colors.white.withOpacity(0.08)
            : Colors.black.withOpacity(0.06),
        textPrimary = theme.colorScheme.onSurface,
        textSecondary = theme.brightness == Brightness.dark
            ? const Color(0xFF8A99B3)
            : const Color(0xFF5A6B84),
        accentBlue = theme.brightness == Brightness.dark
            ? const Color(0xFF5BA3E8)
            : const Color(0xFF64B5F6),
        accentGreen = theme.brightness == Brightness.dark
            ? const Color(0xFF4DB87F)
            : const Color(0xFF4CAF50),
        shadowLight = theme.brightness == Brightness.dark
            ? Colors.white.withOpacity(0.05)
            : Colors.white.withOpacity(0.8),
        shadowDark = theme.brightness == Brightness.dark
            ? Colors.black.withOpacity(0.4)
            : Colors.black.withOpacity(0.2),
        navIconActive = theme.brightness == Brightness.dark
            ? const Color(0xFF5BA3E8)
            : const Color(0xFF64B5F6),
        navIconInactive = theme.brightness == Brightness.dark
            ? Colors.white38
            : const Color(0xFF2C3E50).withOpacity(0.4);

  final bool isDark;
  final Color background;
  final Color cardSurface;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color accentBlue;
  final Color accentGreen;
  final Color shadowLight;
  final Color shadowDark;
  final Color navIconActive;
  final Color navIconInactive;
}

class DashboardPage extends StatefulWidget {
  final String userName;

  const DashboardPage({super.key, required this.userName});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  final DashboardController dashController = Get.put(DashboardController());
  final AppController controller = Get.find<AppController>();
  final currencyFormat =
      NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    // Load dashboard data when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = controller.currentUserId.value;
      if (userId.isNotEmpty) {
        dashController.loadDashboardData(userId);
        dashController.streamDashboardData(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _DashboardPalette(theme);

    return Scaffold(
      backgroundColor: palette.background,
      body: RefreshIndicator(
        onRefresh: () async {
          final userId = controller.currentUserId.value;
          if (userId.isNotEmpty) {
            await dashController.loadDashboardData(userId);
          }
        },
        color: palette.accentBlue,
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [palette.accentBlue, palette.accentGreen],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              widget.userName.isNotEmpty
                                  ? widget.userName[0].toUpperCase()
                                  : 'U',
                              style: AppText.poppins(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome Back',
                              style: AppText.poppins(
                                color: palette.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.userName,
                              style: AppText.poppins(
                                color: palette.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideX(begin: -0.3, end: 0),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Get.to(
                            () => const CalendarViewPage(),
                            transition: Transition.cupertino,
                            duration: const Duration(milliseconds: 400),
                          ),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: palette.cardSurface,
                              shape: BoxShape.circle,
                              border: Border.all(color: palette.cardBorder),
                              boxShadow: [
                                BoxShadow(
                                  color: palette.shadowDark,
                                  offset: const Offset(2, 2),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.calendar_month_rounded,
                              color: palette.accentBlue,
                              size: 20,
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .scale(delay: 150.ms),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => _showLogoutDialog(context),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: palette.cardSurface,
                              shape: BoxShape.circle,
                              border: Border.all(color: palette.cardBorder),
                              boxShadow: [
                                BoxShadow(
                                  color: palette.shadowDark,
                                  offset: const Offset(2, 2),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.logout_rounded,
                              color: Colors.red.shade400,
                              size: 20,
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .scale(delay: 200.ms),
                      ],
                    ),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),

                          // Hero Balance Card with Glass Effect
                          RepaintBoundary(
                            child: Container(
                              width: double.infinity,
                              height: 180,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: palette.isDark
                                      ? [
                                          const Color(0xFF2D4263),
                                          const Color(0xFF1A2B3F)
                                        ]
                                      : [
                                          const Color(0xFF64B5F6),
                                          const Color(0xFF42A5F5)
                                        ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: palette.isDark
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.transparent,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: palette.accentBlue.withOpacity(0.3),
                                    offset: const Offset(0, 12),
                                    blurRadius: 24,
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  // Animated background pattern
                                  Positioned(
                                    right: -20,
                                    top: -20,
                                    child: Container(
                                      width: 150,
                                      height: 150,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withOpacity(0.05),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 40,
                                    bottom: -30,
                                    child: Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withOpacity(0.05),
                                      ),
                                    ),
                                  ),
                                  // Content
                                  Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Total Balance',
                                              style: AppText.poppins(
                                                color: Colors.white
                                                    .withOpacity(0.85),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withOpacity(0.15),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.trending_up,
                                                    color: Colors.white,
                                                    size: 14,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Live',
                                                    style: AppText.poppins(
                                                      color: Colors.white,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        Obx(() {
                                          final totalBalance = dashController
                                                  .totalCashIn.value +
                                              dashController.totalCashOut.value;
                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                currencyFormat
                                                    .format(totalBalance),
                                                style: AppText.poppins(
                                                  color: Colors.white,
                                                  fontSize: 42,
                                                  fontWeight: FontWeight.bold,
                                                  height: 1.1,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons
                                                        .account_balance_wallet,
                                                    color: Colors.white
                                                        .withOpacity(0.7),
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    'Available Funds',
                                                    style: AppText.poppins(
                                                      color: Colors.white
                                                          .withOpacity(0.7),
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                                .animate()
                                .fadeIn(delay: 100.ms, duration: 500.ms)
                                .slideY(begin: 0.3, end: 0)
                                .shimmer(
                                    delay: 1000.ms,
                                    duration: 1800.ms,
                                    color: Colors.white.withOpacity(0.1)),
                          ),

                          const SizedBox(height: 20),

                          // Quick Stats Grid (2x2)
                          Obx(() {
                            final stats = [
                              {
                                'label': 'Cash In',
                                'value': currencyFormat
                                    .format(dashController.totalCashIn.value),
                                'icon': Icons.arrow_downward,
                                'color': const Color(0xFF4CAF50),
                              },
                              {
                                'label': 'Cash Out',
                                'value': currencyFormat
                                    .format(dashController.totalCashOut.value),
                                'icon': Icons.arrow_upward,
                                'color': const Color(0xFFFF9800),
                              },
                              {
                                'label': 'Total Fees',
                                'value': currencyFormat
                                    .format(dashController.totalFees.value),
                                'icon': Icons.account_balance_wallet,
                                'color': const Color(0xFF64B5F6),
                              },
                              {
                                'label': 'Transactions',
                                'value':
                                    '${dashController.totalTransactions.value}',
                                'icon': Icons.receipt_long,
                                'color': const Color(0xFF8B7CFF),
                              },
                            ];

                            return GridView.count(
                              crossAxisCount: stats.length == 1 ? 1 : 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: stats.length == 1 ? 2.5 : 1.4,
                              children: stats.map((stat) {
                                return _buildStatCard(
                                  stat['label'] as String,
                                  stat['value'] as String,
                                  stat['icon'] as IconData,
                                  stat['color'] as Color,
                                  palette,
                                );
                              }).toList(),
                            )
                                .animate(delay: 200.ms)
                                .fadeIn(duration: 400.ms)
                                .slideY(begin: 0.2, end: 0);
                          }),

                          const SizedBox(height: 25),

                          // Analytics Insights Section
                          Obx(() {
                            final transactions =
                                dashController.recentTransactions;
                            if (transactions.isEmpty)
                              return const SizedBox.shrink();

                            // Calculate analytics
                            final avgTransaction = transactions.isNotEmpty
                                ? transactions.fold<double>(
                                        0, (sum, t) => sum + t.amount) /
                                    transactions.length
                                : 0.0;

                            final largest = transactions
                                .reduce((a, b) => a.amount > b.amount ? a : b);
                            final smallest = transactions
                                .reduce((a, b) => a.amount < b.amount ? a : b);

                            // Top recipient
                            final recipientCounts = <String, int>{};
                            final recipientTotals = <String, double>{};
                            for (final tx in transactions) {
                              recipientCounts[tx.recipientName] =
                                  (recipientCounts[tx.recipientName] ?? 0) + 1;
                              recipientTotals[tx.recipientName] =
                                  (recipientTotals[tx.recipientName] ?? 0) +
                                      tx.amount;
                            }
                            final topRecipient = recipientCounts.entries
                                .reduce((a, b) => a.value > b.value ? a : b);

                            // Calculate savings rate
                            final totalIn = dashController.totalCashIn.value;
                            final totalOut = dashController.totalCashOut.value;
                            final savingsRate = totalIn > 0
                                ? ((totalIn - totalOut) / totalIn * 100)
                                : 0.0;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Financial Insights',
                                  style: AppText.poppins(
                                    color: palette.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Based on your transaction data',
                                  style: AppText.poppins(
                                    color: palette.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Insights Grid
                                GridView.count(
                                  crossAxisCount: 2,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 1.5,
                                  children: [
                                    _buildInsightCard(
                                      'Avg Transaction',
                                      currencyFormat.format(avgTransaction),
                                      Icons.analytics_outlined,
                                      const Color(0xFF9C27B0),
                                      palette,
                                    ),
                                    _buildInsightCard(
                                      'Savings Rate',
                                      '${savingsRate.toStringAsFixed(1)}%',
                                      Icons.savings_outlined,
                                      const Color(0xFF4CAF50),
                                      palette,
                                    ),
                                    _buildInsightCard(
                                      'Top Recipient',
                                      topRecipient.key,
                                      Icons.person_outline,
                                      const Color(0xFF2196F3),
                                      palette,
                                      subtitle: '${topRecipient.value} txs',
                                    ),
                                    _buildInsightCard(
                                      'Largest Tx',
                                      currencyFormat.format(largest.amount),
                                      Icons.trending_up,
                                      const Color(0xFFFF5722),
                                      palette,
                                      subtitle: largest.recipientName,
                                    ),
                                  ],
                                ),
                              ],
                            )
                                .animate(delay: 250.ms)
                                .fadeIn(duration: 400.ms)
                                .slideY(begin: 0.2, end: 0);
                          }),

                          const SizedBox(height: 25),

                          // Earnings Chart Card
                          Center(
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 400),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: palette.cardSurface,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: palette.cardBorder),
                                boxShadow: [
                                  BoxShadow(
                                    color: palette.shadowDark,
                                    offset: const Offset(2, 2),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Earnings Overview',
                                              style: AppText.poppins(
                                                color: palette.textPrimary,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Obx(() => Text(
                                                  dashController.selectedPeriod
                                                              .value ==
                                                          'Daily'
                                                      ? 'Last 7 days'
                                                      : dashController
                                                                  .selectedPeriod
                                                                  .value ==
                                                              'Weekly'
                                                          ? 'Last 4 weeks'
                                                          : 'Last 6 months',
                                                  style: AppText.poppins(
                                                    color:
                                                        palette.textSecondary,
                                                    fontSize: 12,
                                                  ),
                                                )),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Obx(() => Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 4),
                                            decoration: BoxDecoration(
                                              color: palette.accentBlue
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                _buildPeriodTab(
                                                    'Daily', palette),
                                                _buildPeriodTab(
                                                    'Weekly', palette),
                                                _buildPeriodTab(
                                                    'Monthly', palette),
                                              ],
                                            ),
                                          )),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  Obx(() => SizedBox(
                                        height: 200,
                                        child: _buildLineChart(palette),
                                      )),
                                ],
                              ),
                            ),
                          )
                              .animate(delay: 300.ms)
                              .fadeIn(duration: 500.ms)
                              .slideY(begin: 0.3, end: 0),

                          const SizedBox(height: 25),

                          // Donut Chart Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: palette.cardSurface,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: palette.cardBorder),
                              boxShadow: [
                                BoxShadow(
                                  color: palette.shadowDark,
                                  offset: const Offset(2, 2),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Transaction Sources',
                                  style: AppText.poppins(
                                    color: palette.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Amount breakdown by source',
                                  style: AppText.poppins(
                                    color: palette.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Obx(() {
                                  final breakdown = Map<String, double>.from(
                                      dashController.sourceBreakdown);
                                  final total = breakdown.values
                                      .fold(0.0, (sum, value) => sum + value);

                                  return SizedBox(
                                    height: 200,
                                    width: 200,
                                    child: Stack(
                                      children: [
                                        CustomPaint(
                                          size: const Size(200, 200),
                                          painter: DonutChartPainter(
                                            sourceBreakdown: breakdown,
                                          ),
                                        ),
                                        Center(
                                          child: Container(
                                            width: 110,
                                            height: 110,
                                            decoration: BoxDecoration(
                                              color: palette.cardSurface,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    'Total',
                                                    style: AppText.poppins(
                                                      color:
                                                          palette.textSecondary,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    currencyFormat
                                                        .format(total),
                                                    style: AppText.poppins(
                                                      color:
                                                          palette.textPrimary,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                const SizedBox(height: 20),
                                Obx(() {
                                  if (dashController.sourceBreakdown.isEmpty) {
                                    return Text(
                                      'No transaction data yet',
                                      style: AppText.poppins(
                                        color: palette.textSecondary,
                                        fontSize: 12,
                                      ),
                                    );
                                  }

                                  final sources = dashController
                                      .sourceBreakdown.entries
                                      .toList();
                                  sources.sort(
                                      (a, b) => b.value.compareTo(a.value));

                                  return Wrap(
                                    spacing: 16,
                                    runSpacing: 12,
                                    alignment: WrapAlignment.center,
                                    children:
                                        sources.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final source = entry.value;
                                      return _buildLegend(
                                        source.key,
                                        DonutChartPainter.getColorForSource(
                                            source.key, index),
                                        currencyFormat.format(source.value),
                                      );
                                    }).toList(),
                                  );
                                }),
                              ],
                            ),
                          )
                              .animate(delay: 400.ms)
                              .fadeIn(duration: 500.ms)
                              .slideY(begin: 0.3, end: 0),

                          const SizedBox(height: 25),

                          // Cash Flow Comparison Chart
                          Obx(() {
                            final transactions =
                                dashController.recentTransactions;
                            if (transactions.isEmpty)
                              return const SizedBox.shrink();

                            final cashIn = transactions
                                .where((t) => t.transactionType == 'Cash In')
                                .fold<double>(0, (sum, t) => sum + t.amount);
                            final cashOut = transactions
                                .where((t) => t.transactionType == 'Cash Out')
                                .fold<double>(0, (sum, t) => sum + t.amount);
                            final maxValue =
                                cashIn > cashOut ? cashIn : cashOut;

                            return Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: palette.cardSurface,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: palette.cardBorder),
                                boxShadow: [
                                  BoxShadow(
                                    color: palette.shadowDark,
                                    offset: const Offset(2, 2),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Cash Flow Comparison',
                                    style: AppText.poppins(
                                      color: palette.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Income vs Expenses',
                                    style: AppText.poppins(
                                      color: palette.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  _buildComparisonBar(
                                      'Cash In',
                                      cashIn,
                                      maxValue,
                                      const Color(0xFF4CAF50),
                                      palette),
                                  const SizedBox(height: 16),
                                  _buildComparisonBar(
                                      'Cash Out',
                                      cashOut,
                                      maxValue,
                                      const Color(0xFFFF9800),
                                      palette),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: palette.isDark
                                          ? Colors.white.withOpacity(0.05)
                                          : Colors.black.withOpacity(0.03),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Net Flow',
                                          style: AppText.poppins(
                                            color: palette.textPrimary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Icon(
                                              cashIn >= cashOut
                                                  ? Icons.trending_up
                                                  : Icons.trending_down,
                                              color: cashIn >= cashOut
                                                  ? const Color(0xFF4CAF50)
                                                  : const Color(0xFFEF4444),
                                              size: 18,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              currencyFormat
                                                  .format(cashIn - cashOut),
                                              style: AppText.poppins(
                                                color: cashIn >= cashOut
                                                    ? const Color(0xFF4CAF50)
                                                    : const Color(0xFFEF4444),
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                                .animate(delay: 500.ms)
                                .fadeIn(duration: 400.ms)
                                .slideY(begin: 0.2, end: 0);
                          }),

                          const SizedBox(height: 25),

                          // Recent Transactions Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Recent Activity',
                                    style: AppText.poppins(
                                      color: palette.textPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Transaction timeline',
                                    style: AppText.poppins(
                                      color: palette.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  Get.to(
                                    () => const TransactionLogsPage(),
                                    transition: Transition.rightToLeft,
                                    duration: const Duration(milliseconds: 300),
                                  );
                                },
                                icon: Icon(
                                  Icons.arrow_forward,
                                  size: 16,
                                  color: palette.accentBlue,
                                ),
                                label: Text(
                                  'View All',
                                  style: AppText.poppins(
                                    color: palette.accentBlue,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ).animate(delay: 500.ms).fadeIn(duration: 400.ms),

                          const SizedBox(height: 20),

                          Obx(() {
                            if (dashController.recentTransactions.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: palette.cardSurface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: palette.cardBorder),
                                ),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: palette.accentBlue
                                              .withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.receipt_long_rounded,
                                          size: 40,
                                          color: palette.accentBlue,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No transactions yet',
                                        style: AppText.poppins(
                                          color: palette.textPrimary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Scan a receipt to get started',
                                        style: AppText.poppins(
                                          color: palette.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            final transactions = dashController
                                .recentTransactions
                                .take(5)
                                .toList();
                            return Column(
                              children:
                                  List.generate(transactions.length, (index) {
                                final transaction = transactions[index];
                                final isPositive =
                                    transaction.transactionType == 'Cash In';
                                final dateFormat = DateFormat('MMM dd, h:mm a');
                                final isLast = index == transactions.length - 1;

                                return _buildTimelineItem(
                                  transaction.transactionType,
                                  dateFormat.format(transaction.createdAt),
                                  '${isPositive ? '+' : '-'}${currencyFormat.format(transaction.totalAmount)}',
                                  isPositive,
                                  isLast,
                                  palette,
                                )
                                    .animate(delay: (600 + (index * 100)).ms)
                                    .fadeIn(duration: 400.ms)
                                    .slideX(begin: -0.2, end: 0);
                              }),
                            );
                          }),

                          const SizedBox(height: 120),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      // Modern Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: palette.cardSurface,
          border: Border(
            top: BorderSide(
              color: palette.cardBorder,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: palette.isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.08),
              offset: const Offset(0, -2),
              blurRadius: 12,
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 65,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home_rounded, 'Home', 0, palette),
                _buildNavItem(
                    Icons.receipt_long_rounded, 'History', 1, palette),
                _buildScanButton(palette),
                _buildNavItem(Icons.smart_toy_rounded, 'AI Chat', 3, palette),
                _buildNavItem(Icons.settings_rounded, 'Settings', 2, palette),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    _DashboardPalette palette,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.cardBorder),
        boxShadow: [
          BoxShadow(
            color: palette.shadowDark,
            offset: const Offset(2, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: AppText.poppins(
              color: palette.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppText.poppins(
              color: palette.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(
    String label,
    String value,
    IconData icon,
    Color color,
    _DashboardPalette palette, {
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.cardBorder),
        boxShadow: [
          BoxShadow(
            color: palette.shadowDark,
            offset: const Offset(1, 1),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const Spacer(),
          Text(
            label,
            style: AppText.poppins(
              color: palette.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppText.poppins(
              color: palette.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 1),
            Text(
              subtitle,
              style: AppText.poppins(
                color: palette.textSecondary,
                fontSize: 9,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildComparisonBar(
    String label,
    double value,
    double maxValue,
    Color color,
    _DashboardPalette palette,
  ) {
    final percentage = maxValue > 0 ? (value / maxValue) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppText.poppins(
                color: palette.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              currencyFormat.format(value),
              style: AppText.poppins(
                color: palette.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 10,
            width: double.infinity,
            decoration: BoxDecoration(
              color: palette.isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(String label, Color color, [String? amount]) {
    final theme = Theme.of(context);
    final palette = _DashboardPalette(theme);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppText.poppins(
                color: palette.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (amount != null)
              Text(
                amount,
                style: AppText.poppins(
                  color: palette.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPeriodTab(String period, _DashboardPalette palette) {
    final isSelected = dashController.selectedPeriod.value == period;
    return GestureDetector(
      onTap: () => dashController.setPeriod(period),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? palette.accentBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          period,
          style: AppText.poppins(
            color: isSelected ? Colors.white : palette.textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildLineChart(_DashboardPalette palette) {
    final data = dashController.getChartData();

    if (data.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: AppText.poppins(
            color: palette.textSecondary,
            fontSize: 12,
          ),
        ),
      );
    }

    final maxValue = data.values.isEmpty
        ? 100.0
        : data.values.reduce((a, b) => a > b ? a : b);
    final entries = data.entries.toList();

    return CustomPaint(
      size: Size.infinite,
      painter: LineChartPainter(
        data: entries,
        maxValue: maxValue > 0 ? maxValue : 100,
        lineColor: palette.accentBlue,
        dotColor: palette.accentGreen,
        textColor: palette.textSecondary,
        gridColor: palette.cardBorder,
      ),
    );
  }

  Widget _buildTimelineItem(
    String title,
    String date,
    String amount,
    bool isPositive,
    bool isLast,
    _DashboardPalette palette,
  ) {
    final color =
        isPositive ? const Color(0xFF4CAF50) : const Color(0xFFFF9800);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: Icon(
                  isPositive ? Icons.arrow_downward : Icons.arrow_upward,
                  color: color,
                  size: 20,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(0.5),
                          color.withOpacity(0.1),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Transaction details
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: palette.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: palette.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: palette.shadowDark,
                    offset: const Offset(2, 2),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: AppText.poppins(
                            color: palette.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          amount,
                          style: AppText.poppins(
                            color: color,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: palette.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        date,
                        style: AppText.poppins(
                          color: palette.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    int index,
    _DashboardPalette palette,
  ) {
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (index == 1) {
              // Navigate to Transaction Logs page
              Get.to(
                () => const TransactionLogsPage(),
                transition: Transition.cupertino,
                duration: const Duration(milliseconds: 400),
              );
            } else if (index == 2) {
              // Navigate to Settings page
              Get.to(
                () => const SettingsPage(),
                transition: Transition.cupertino,
                duration: const Duration(milliseconds: 400),
              );
            } else if (index == 3) {
              // Navigate to AI Chat page
              Get.to(
                () => const AIChatPage(),
                transition: Transition.cupertino,
                duration: const Duration(milliseconds: 400),
              );
            } else {
              setState(() {
                _selectedIndex = index;
              });
            }
          },
          borderRadius: BorderRadius.circular(16),
          splashColor: palette.accentBlue.withOpacity(0.1),
          highlightColor: palette.accentBlue.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(6),
                  decoration: isSelected
                      ? BoxDecoration(
                          color: palette.accentBlue.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        )
                      : null,
                  child: Icon(
                    icon,
                    color: isSelected
                        ? palette.accentBlue
                        : palette.navIconInactive,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: AppText.poppins(
                    color: isSelected
                        ? palette.accentBlue
                        : palette.navIconInactive,
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScanButton(_DashboardPalette palette) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          Get.to(
            () => const ScanPage(),
            transition: Transition.zoom,
            duration: const Duration(milliseconds: 400),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      palette.accentBlue,
                      palette.accentBlue.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: palette.accentBlue.withOpacity(0.4),
                      offset: const Offset(0, 2),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Scan',
                style: AppText.poppins(
                  color: palette.accentBlue,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _DashboardPalette(theme);

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: palette.cardSurface,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: palette.cardSurface,
            border: Border.all(color: palette.cardBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade400,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.shade400.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Logout',
                style: AppText.poppins(
                  color: palette.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to logout?',
                textAlign: TextAlign.center,
                style: AppText.poppins(
                  color: palette.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: palette.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: palette.cardBorder),
                        ),
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: AppText.poppins(
                              color: palette.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        try {
                          // Close dialog
                          Get.back();

                          // Show loading
                          Get.dialog(
                            const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF64B5F6)),
                              ),
                            ),
                            barrierDismissible: false,
                          );

                          // Sign out
                          final googleSignInService = GoogleSignInService();
                          await googleSignInService.signOut();

                          // Clear app controller data
                          final controller = Get.find<AppController>();
                          controller.userName.value = '';
                          controller.phoneNumber.value = '';
                          controller.pin.value = '';
                          controller.currentUserId.value = '';

                          // Close loading
                          Get.back();

                          // Navigate to landing page
                          Get.offAll(
                            () => const LandingPage(),
                            transition: Transition.fadeIn,
                            duration: const Duration(milliseconds: 400),
                          );

                          // Show success message
                          Get.snackbar(
                            'Logged Out',
                            'You have been successfully logged out',
                            backgroundColor: const Color(0xFF64B5F6),
                            colorText: Colors.white,
                            snackPosition: SnackPosition.TOP,
                            margin: const EdgeInsets.all(20),
                            borderRadius: 16,
                            duration: const Duration(seconds: 2),
                          );
                        } catch (e) {
                          // Close loading if still open
                          if (Get.isDialogOpen ?? false) {
                            Get.back();
                          }

                          // Show error
                          Get.snackbar(
                            'Error',
                            'Failed to logout: ${e.toString()}',
                            backgroundColor: Colors.red.shade400,
                            colorText: Colors.white,
                            snackPosition: SnackPosition.TOP,
                            margin: const EdgeInsets.all(20),
                            borderRadius: 16,
                            duration: const Duration(seconds: 3),
                          );
                        }
                      },
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [Colors.red.shade400, Colors.red.shade600],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.shade400.withOpacity(0.4),
                              offset: const Offset(0, 4),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Logout',
                            style: AppText.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
}

class DonutChartPainter extends CustomPainter {
  final Map<String, double> sourceBreakdown;

  DonutChartPainter({required this.sourceBreakdown});

  // Color mapping for different sources
  static const colorMap = {
    'GCash': Color(0xFF4CAF50),
    'Maya': Color(0xFF00C853),
    'Palawan': Color(0xFFFF9800),
    'MLhuillier': Color(0xFFF44336),
    'Cebuana': Color(0xFF9C27B0),
    'LBC': Color(0xFF2196F3),
    'RD Pawnshop': Color(0xFFFF5722),
    'Cash In': Color(0xFF64B5F6),
  };

  static Color getColorForSource(String source, int index) {
    if (colorMap.containsKey(source)) {
      return colorMap[source]!;
    }
    // Generate color based on index for unknown sources
    final colors = [
      const Color(0xFF4CAF50),
      const Color(0xFFFF9800),
      const Color(0xFF2196F3),
      const Color(0xFFF44336),
      const Color(0xFF9C27B0),
      const Color(0xFFFF5722),
      const Color(0xFF00BCD4),
      const Color(0xFFCDDC39),
    ];
    return colors[index % colors.length];
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 25.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // If no data, show default gray ring
    if (sourceBreakdown.isEmpty ||
        sourceBreakdown.values.every((v) => v == 0)) {
      paint.color = Colors.grey.shade300;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        -math.pi / 2,
        2 * math.pi,
        false,
        paint,
      );
      return;
    }

    // Calculate total for percentage calculation
    final total = sourceBreakdown.values.fold(0.0, (sum, value) => sum + value);

    double startAngle = -math.pi / 2;
    int index = 0;

    sourceBreakdown.forEach((source, amount) {
      if (amount > 0) {
        paint.color = getColorForSource(source, index);
        final percentage = amount / total;
        final sweepAngle = 2 * math.pi * percentage - 0.02;

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
          startAngle,
          sweepAngle,
          false,
          paint,
        );

        startAngle += sweepAngle + 0.02;
        index++;
      }
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class LineChartPainter extends CustomPainter {
  final List<MapEntry<String, double>> data;
  final double maxValue;
  final Color lineColor;
  final Color dotColor;
  final Color textColor;
  final Color gridColor;

  LineChartPainter({
    required this.data,
    required this.maxValue,
    required this.lineColor,
    required this.dotColor,
    required this.textColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    const padding = 40.0;
    const bottomPadding = 30.0;
    final chartWidth = size.width - padding * 2;
    final chartHeight = size.height - padding - bottomPadding;

    // Draw grid lines
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    for (int i = 0; i <= 4; i++) {
      final y = padding + (chartHeight * i / 4);
      canvas.drawLine(
        Offset(padding, y),
        Offset(size.width - padding, y),
        gridPaint,
      );
    }

    // Draw line and dots
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    final dotBorderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < data.length; i++) {
      final x = padding + (chartWidth * i / (data.length - 1));
      final normalizedValue = data[i].value / maxValue;
      final y = padding + chartHeight - (chartHeight * normalizedValue);

      points.add(Offset(x, y));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Draw gradient below line
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withOpacity(0.3),
          lineColor.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, padding, size.width, chartHeight));

    final fillPath = Path.from(path);
    fillPath.lineTo(points.last.dx, padding + chartHeight);
    fillPath.lineTo(points.first.dx, padding + chartHeight);
    fillPath.close();
    canvas.drawPath(fillPath, gradientPaint);

    // Draw line
    canvas.drawPath(path, linePaint);

    // Draw dots
    for (final point in points) {
      canvas.drawCircle(point, 5, dotPaint);
      canvas.drawCircle(point, 5, dotBorderPaint);
    }

    // Draw labels
    for (int i = 0; i < data.length; i++) {
      final x = padding + (chartWidth * i / (data.length - 1));

      final textPainter = TextPainter(
        text: TextSpan(
          text: data[i].key,
          style: TextStyle(
            color: textColor,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - 20),
      );
    }

    // Draw value labels on Y axis
    final currencyFormat = NumberFormat.currency(symbol: '₱', decimalDigits: 0);
    for (int i = 0; i <= 4; i++) {
      final value = maxValue * (4 - i) / 4;
      final y = padding + (chartHeight * i / 4);

      final textPainter = TextPainter(
        text: TextSpan(
          text: value > 0 ? currencyFormat.format(value) : '₱0',
          style: TextStyle(
            color: textColor,
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(5, y - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
