import 'package:flutter/material.dart';
import 'package:g/utils/app_text.dart';
import 'package:g/utils/responsive_helper.dart';
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
import 'user_guide_page.dart';
import 'dart:math' as math;

/// Material 3 Dashboard Color Palette with dynamic theming
class _DashboardPalette {
  _DashboardPalette(ThemeData theme)
      : isDark = theme.brightness == Brightness.dark,
        // M3 Surface colors
        background = theme.colorScheme.surface,
        surfaceContainerLowest = theme.brightness == Brightness.dark
            ? const Color(0xFF0D1117)
            : const Color(0xFFFCFCFF),
        surfaceContainer = theme.brightness == Brightness.dark
            ? const Color(0xFF1C2128)
            : const Color(0xFFF3F3F6),
        surfaceContainerHigh = theme.brightness == Brightness.dark
            ? const Color(0xFF262C36)
            : const Color(0xFFEAEAED),
        cardSurface = theme.brightness == Brightness.dark
            ? const Color(0xFF1C2128)
            : Colors.white,
        cardBorder = theme.brightness == Brightness.dark
            ? Colors.white.withOpacity(0.06)
            : Colors.black.withOpacity(0.04),
        // M3 On-surface colors
        textPrimary = theme.colorScheme.onSurface,
        textSecondary = theme.brightness == Brightness.dark
            ? const Color(0xFF9CA3AF)
            : const Color(0xFF6B7280),
        textTertiary = theme.brightness == Brightness.dark
            ? const Color(0xFF6B7280)
            : const Color(0xFF9CA3AF),
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
        // M3 Secondary tonal palette
        secondary = theme.brightness == Brightness.dark
            ? const Color(0xFF86EFAC)
            : const Color(0xFF16A34A),
        secondaryContainer = theme.brightness == Brightness.dark
            ? const Color(0xFF14532D)
            : const Color(0xFFDCFCE7),
        onSecondaryContainer = theme.brightness == Brightness.dark
            ? const Color(0xFFDCFCE7)
            : const Color(0xFF14532D),
        // M3 Tertiary tonal palette
        tertiary = theme.brightness == Brightness.dark
            ? const Color(0xFFFBBF24)
            : const Color(0xFFD97706),
        tertiaryContainer = theme.brightness == Brightness.dark
            ? const Color(0xFF78350F)
            : const Color(0xFFFEF3C7),
        // M3 Error tonal palette
        error = theme.brightness == Brightness.dark
            ? const Color(0xFFFCA5A5)
            : const Color(0xFFDC2626),
        errorContainer = theme.brightness == Brightness.dark
            ? const Color(0xFF7F1D1D)
            : const Color(0xFFFEE2E2),
        // Legacy accent colors (mapped to M3)
        accentBlue = theme.brightness == Brightness.dark
            ? const Color(0xFF93C5FD)
            : const Color(0xFF2563EB),
        accentGreen = theme.brightness == Brightness.dark
            ? const Color(0xFF86EFAC)
            : const Color(0xFF16A34A),
        // Shadows & Elevation
        shadowLight = theme.brightness == Brightness.dark
            ? Colors.white.withOpacity(0.02)
            : Colors.white.withOpacity(0.9),
        shadowDark = theme.brightness == Brightness.dark
            ? Colors.black.withOpacity(0.5)
            : Colors.black.withOpacity(0.08),
        // Navigation
        navIconActive = theme.brightness == Brightness.dark
            ? const Color(0xFF93C5FD)
            : const Color(0xFF2563EB),
        navIconInactive = theme.brightness == Brightness.dark
            ? const Color(0xFF6B7280)
            : const Color(0xFF9CA3AF),
        navIndicator = theme.brightness == Brightness.dark
            ? const Color(0xFF1E3A5F)
            : const Color(0xFFDBEAFE);

  final bool isDark;
  final Color background;
  final Color surfaceContainerLowest;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color cardSurface;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color primary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color secondary;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color tertiary;
  final Color tertiaryContainer;
  final Color error;
  final Color errorContainer;
  final Color accentBlue;
  final Color accentGreen;
  final Color shadowLight;
  final Color shadowDark;
  final Color navIconActive;
  final Color navIconInactive;
  final Color navIndicator;
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
  bool _isBalanceVisible = true;

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
      backgroundColor: palette.surfaceContainerLowest,
      body: RefreshIndicator(
        onRefresh: () async {
          final userId = controller.currentUserId.value;
          if (userId.isNotEmpty) {
            await dashController.loadDashboardData(userId);
          }
        },
        color: palette.primary,
        backgroundColor: palette.surfaceContainer,
        child: SafeArea(
          child: Column(
            children: [
              // M3 Top App Bar Style - Responsive
              LayoutBuilder(
                builder: (context, appBarConstraints) {
                  final appBarScreenWidth = MediaQuery.of(context).size.width;
                  final isAppBarCompact = appBarScreenWidth < 360;
                  final isAppBarSmall = appBarScreenWidth < 400;

                  final avatarSize =
                      isAppBarCompact ? 40.0 : (isAppBarSmall ? 44.0 : 48.0);
                  final avatarFontSize =
                      isAppBarCompact ? 16.0 : (isAppBarSmall ? 18.0 : 20.0);
                  final welcomeFontSize =
                      isAppBarCompact ? 11.0 : (isAppBarSmall ? 12.0 : 13.0);
                  final nameFontSize =
                      isAppBarCompact ? 15.0 : (isAppBarSmall ? 16.0 : 18.0);
                  final horizontalPadding =
                      isAppBarCompact ? 12.0 : (isAppBarSmall ? 16.0 : 20.0);
                  final iconButtonSpacing = isAppBarCompact ? 2.0 : 4.0;

                  return Container(
                    padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        isAppBarCompact ? 12 : 16,
                        horizontalPadding,
                        isAppBarCompact ? 8 : 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // M3 Avatar with initial
                              Container(
                                width: avatarSize,
                                height: avatarSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: palette.primaryContainer,
                                ),
                                child: Center(
                                  child: Text(
                                    widget.userName.isNotEmpty
                                        ? widget.userName[0].toUpperCase()
                                        : 'U',
                                    style: AppText.poppins(
                                      color: palette.onPrimaryContainer,
                                      fontSize: avatarFontSize,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: isAppBarCompact ? 10 : 14),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Welcome back',
                                      style: AppText.poppins(
                                        color: palette.textSecondary,
                                        fontSize: welcomeFontSize,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: isAppBarCompact ? 1 : 2),
                                    Text(
                                      widget.userName,
                                      style: AppText.poppins(
                                        color: palette.textPrimary,
                                        fontSize: nameFontSize,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -0.3,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                              .animate()
                              .fadeIn(duration: 400.ms)
                              .slideX(begin: -0.2, end: 0),
                        ),
                        // M3 Icon Buttons Row
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildM3IconButton(
                              icon: Icons.calendar_month_outlined,
                              onTap: () => Get.to(
                                () => const CalendarViewPage(),
                                transition: Transition.cupertino,
                                duration: const Duration(milliseconds: 400),
                              ),
                              palette: palette,
                            ),
                            SizedBox(width: iconButtonSpacing),
                            _buildM3IconButton(
                              icon: Icons.help_outline_rounded,
                              onTap: () => Get.to(
                                () => const UserGuidePage(),
                                transition: Transition.cupertino,
                                duration: const Duration(milliseconds: 400),
                              ),
                              palette: palette,
                            ),
                            SizedBox(width: iconButtonSpacing),
                            _buildM3IconButton(
                              icon: Icons.logout_rounded,
                              onTap: () => _showLogoutDialog(context),
                              palette: palette,
                              isDestructive: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ).animate().fadeIn(duration: 300.ms),

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

                          // M3 Hero Balance Card
                          RepaintBoundary(
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: palette.isDark
                                      ? [
                                          const Color(0xFF1E3A5F),
                                          const Color(0xFF1E293B)
                                        ]
                                      : [
                                          const Color(0xFF2563EB),
                                          const Color(0xFF3B82F6)
                                        ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: palette.primary.withOpacity(0.25),
                                    offset: const Offset(0, 8),
                                    blurRadius: 24,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  // Subtle pattern overlay
                                  Positioned(
                                    right: -30,
                                    top: -30,
                                    child: Container(
                                      width: 140,
                                      height: 140,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withOpacity(0.06),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: -20,
                                    bottom: -40,
                                    child: Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withOpacity(0.04),
                                      ),
                                    ),
                                  ),
                                  // Content
                                  LayoutBuilder(
                                    builder: (context, heroConstraints) {
                                      final heroScreenWidth =
                                          MediaQuery.of(context).size.width;
                                      final isHeroCompact =
                                          heroScreenWidth < 360;
                                      final isHeroSmall = heroScreenWidth < 400;
                                      final heroPadding = isHeroCompact
                                          ? 16.0
                                          : (isHeroSmall ? 20.0 : 24.0);
                                      final balanceFontSize = isHeroCompact
                                          ? 28.0
                                          : (isHeroSmall ? 32.0 : 36.0);
                                      final labelFontSize =
                                          isHeroCompact ? 13.0 : 15.0;

                                      return Padding(
                                        padding: EdgeInsets.all(heroPadding),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Flexible(
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Container(
                                                        padding: EdgeInsets.all(
                                                            isHeroCompact
                                                                ? 6
                                                                : 8),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.white
                                                              .withOpacity(
                                                                  0.15),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                        ),
                                                        child: Icon(
                                                          Icons
                                                              .account_balance_wallet_rounded,
                                                          color: Colors.white,
                                                          size: isHeroCompact
                                                              ? 18
                                                              : 20,
                                                        ),
                                                      ),
                                                      SizedBox(
                                                          width: isHeroCompact
                                                              ? 8
                                                              : 12),
                                                      Text(
                                                        'Total Balance',
                                                        style: AppText.poppins(
                                                          color: Colors.white
                                                              .withOpacity(0.9),
                                                          fontSize:
                                                              labelFontSize,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    // Visibility toggle
                                                    Material(
                                                      color: Colors.transparent,
                                                      child: InkWell(
                                                        onTap: () {
                                                          setState(() {
                                                            _isBalanceVisible =
                                                                !_isBalanceVisible;
                                                          });
                                                        },
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                        child: Padding(
                                                          padding:
                                                              EdgeInsets.all(
                                                                  isHeroCompact
                                                                      ? 6
                                                                      : 8),
                                                          child: Icon(
                                                            _isBalanceVisible
                                                                ? Icons
                                                                    .visibility_rounded
                                                                : Icons
                                                                    .visibility_off_rounded,
                                                            color: Colors.white
                                                                .withOpacity(
                                                                    0.8),
                                                            size: isHeroCompact
                                                                ? 18
                                                                : 20,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                        width: isHeroCompact
                                                            ? 4
                                                            : 8),
                                                    // Live indicator pill
                                                    Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                        horizontal:
                                                            isHeroCompact
                                                                ? 8
                                                                : 12,
                                                        vertical: isHeroCompact
                                                            ? 4
                                                            : 6,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white
                                                            .withOpacity(0.2),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(50),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Container(
                                                            width: 6,
                                                            height: 6,
                                                            decoration:
                                                                const BoxDecoration(
                                                              shape: BoxShape
                                                                  .circle,
                                                              color: Color(
                                                                  0xFF4ADE80),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 6),
                                                          Text(
                                                            'Live',
                                                            style:
                                                                AppText.poppins(
                                                              color:
                                                                  Colors.white,
                                                              fontSize:
                                                                  isHeroCompact
                                                                      ? 10
                                                                      : 11,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            SizedBox(
                                                height:
                                                    isHeroCompact ? 14 : 20),
                                            Obx(() {
                                              final totalBalance =
                                                  dashController
                                                          .totalCashIn.value +
                                                      dashController
                                                          .totalCashOut.value;
                                              return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: Text(
                                                      _isBalanceVisible
                                                          ? currencyFormat
                                                              .format(
                                                                  totalBalance)
                                                          : '₱ ••••••',
                                                      style: AppText.poppins(
                                                        color: Colors.white,
                                                        fontSize:
                                                            balanceFontSize,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        height: 1.1,
                                                        letterSpacing: -0.5,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                      height: isHeroCompact
                                                          ? 12
                                                          : 16),
                                                  // Available funds row
                                                  Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal:
                                                                isHeroCompact
                                                                    ? 10
                                                                    : 14,
                                                            vertical:
                                                                isHeroCompact
                                                                    ? 8
                                                                    : 10),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white
                                                          .withOpacity(0.12),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              14),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons
                                                              .savings_outlined,
                                                          color: Colors.white
                                                              .withOpacity(0.9),
                                                          size: isHeroCompact
                                                              ? 16
                                                              : 18,
                                                        ),
                                                        SizedBox(
                                                            width: isHeroCompact
                                                                ? 8
                                                                : 10),
                                                        Flexible(
                                                          child: Text(
                                                            _isBalanceVisible
                                                                ? 'Available: ${currencyFormat.format(dashController.availableFunds.value)}'
                                                                : 'Available: ₱ ••••••',
                                                            style:
                                                                AppText.poppins(
                                                              color: Colors
                                                                  .white
                                                                  .withOpacity(
                                                                      0.95),
                                                              fontSize:
                                                                  isHeroCompact
                                                                      ? 11
                                                                      : 13,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              );
                                            }),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            )
                                .animate()
                                .fadeIn(delay: 100.ms, duration: 500.ms)
                                .slideY(begin: 0.2, end: 0),
                          ),

                          const SizedBox(height: 24),

                          // M3 Quick Stats Grid
                          Obx(() {
                            final stats = [
                              {
                                'label': 'Cash In',
                                'value': currencyFormat
                                    .format(dashController.totalCashIn.value),
                                'icon': Icons.south_west_rounded,
                                'color': const Color(0xFF16A34A),
                                'bgColor': palette.isDark
                                    ? const Color(0xFF14532D)
                                    : const Color(0xFFDCFCE7),
                              },
                              {
                                'label': 'Cash Out',
                                'value': currencyFormat
                                    .format(dashController.totalCashOut.value),
                                'icon': Icons.north_east_rounded,
                                'color': const Color(0xFFEA580C),
                                'bgColor': palette.isDark
                                    ? const Color(0xFF7C2D12)
                                    : const Color(0xFFFED7AA),
                              },
                              {
                                'label': 'Fees (Incl.)',
                                'value': currencyFormat
                                    .format(dashController.totalFees.value),
                                'icon': Icons.receipt_long_rounded,
                                'color': const Color(0xFF2563EB),
                                'bgColor': palette.isDark
                                    ? const Color(0xFF1E3A5F)
                                    : const Color(0xFFDBEAFE),
                              },
                              {
                                'label': 'Fees (Cash)',
                                'value': currencyFormat.format(
                                    dashController.totalSeparateFees.value),
                                'icon': Icons.payments_rounded,
                                'color': const Color(0xFF9333EA),
                                'bgColor': palette.isDark
                                    ? const Color(0xFF581C87)
                                    : const Color(0xFFF3E8FF),
                              },
                              {
                                'label': 'Transactions',
                                'value':
                                    '${dashController.totalTransactions.value}',
                                'icon': Icons.swap_horiz_rounded,
                                'color': const Color(0xFF0891B2),
                                'bgColor': palette.isDark
                                    ? const Color(0xFF164E63)
                                    : const Color(0xFFCFFAFE),
                              },
                            ];

                            // Responsive grid aspect ratio
                            final gridScreenWidth =
                                MediaQuery.of(context).size.width;
                            final gridAspectRatio = gridScreenWidth < 360
                                ? 1.2
                                : (gridScreenWidth < 400 ? 1.35 : 1.5);
                            final gridSpacing =
                                gridScreenWidth < 360 ? 8.0 : 12.0;

                            return GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: gridSpacing,
                              crossAxisSpacing: gridSpacing,
                              childAspectRatio: gridAspectRatio,
                              children: stats.map((stat) {
                                return _buildM3StatCard(
                                  stat['label'] as String,
                                  stat['value'] as String,
                                  stat['icon'] as IconData,
                                  stat['color'] as Color,
                                  stat['bgColor'] as Color,
                                  palette,
                                );
                              }).toList(),
                            )
                                .animate(delay: 200.ms)
                                .fadeIn(duration: 400.ms)
                                .slideY(begin: 0.15, end: 0);
                          }),

                          const SizedBox(height: 28),

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

                            return LayoutBuilder(
                              builder: (context, constraints) {
                                final screenWidth =
                                    MediaQuery.of(context).size.width;
                                final isCompact = screenWidth < 360;
                                final titleSize = isCompact ? 16.0 : 18.0;
                                final subtitleSize = isCompact ? 11.0 : 12.0;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Financial Insights',
                                      style: AppText.poppins(
                                        color: palette.textPrimary,
                                        fontSize: titleSize,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Based on your transaction data',
                                      style: AppText.poppins(
                                        color: palette.textSecondary,
                                        fontSize: subtitleSize,
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Insights Grid - Adaptive layout
                                    Column(
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildInsightCard(
                                                'Average Transaction',
                                                currencyFormat
                                                    .format(avgTransaction),
                                                Icons.analytics_outlined,
                                                const Color(0xFF9C27B0),
                                                palette,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: _buildInsightCard(
                                                'Top Recipient',
                                                topRecipient.key,
                                                Icons.person_outline,
                                                const Color(0xFF2196F3),
                                                palette,
                                                subtitle:
                                                    '${topRecipient.value} transactions',
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        // Full width for single card
                                        _buildInsightCard(
                                          'Largest Transaction',
                                          currencyFormat.format(largest.amount),
                                          Icons.trending_up,
                                          const Color(0xFFFF5722),
                                          palette,
                                          subtitle: largest.recipientName,
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            )
                                .animate(delay: 250.ms)
                                .fadeIn(duration: 400.ms)
                                .slideY(begin: 0.2, end: 0);
                          }),

                          const SizedBox(height: 25),

                          // Earnings Chart Card
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final screenWidth =
                                  MediaQuery.of(context).size.width;
                              final isCompact = screenWidth < 360;
                              final titleSize = isCompact ? 14.0 : 16.0;
                              final subtitleSize = isCompact ? 11.0 : 12.0;
                              final chartPadding = isCompact ? 16.0 : 20.0;

                              return Center(
                                child: Container(
                                  constraints:
                                      const BoxConstraints(maxWidth: 400),
                                  padding: EdgeInsets.all(chartPadding),
                                  decoration: BoxDecoration(
                                    color: palette.cardSurface,
                                    borderRadius: BorderRadius.circular(24),
                                    border:
                                        Border.all(color: palette.cardBorder),
                                    boxShadow: [
                                      BoxShadow(
                                        color: palette.shadowDark,
                                        offset: const Offset(2, 2),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                                    fontSize: titleSize,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Obx(() => Text(
                                                      dashController
                                                                  .selectedPeriod
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
                                                        color: palette
                                                            .textSecondary,
                                                        fontSize: subtitleSize,
                                                      ),
                                                    )),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Obx(() => Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 4),
                                                decoration: BoxDecoration(
                                                  color: palette.accentBlue
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
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
                              );
                            },
                          )
                              .animate(delay: 300.ms)
                              .fadeIn(duration: 500.ms)
                              .slideY(begin: 0.3, end: 0),

                          const SizedBox(height: 25),

                          // Fee Charts - Single Card with Horizontal Scrollable Content
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final screenWidth =
                                  MediaQuery.of(context).size.width;
                              final scrollController = ScrollController();
                              final currentPage = 0.obs;

                              scrollController.addListener(() {
                                final page = (scrollController.offset / 304)
                                    .round(); // 280 width + 24 margin
                                if (currentPage.value != page) {
                                  currentPage.value = page;
                                }
                              });

                              return Container(
                                width: screenWidth - 40,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 20),
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
                                    Text(
                                      'Fee Analysis',
                                      style: AppText.poppins(
                                        color: palette.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Swipe to view different breakdowns',
                                      style: AppText.poppins(
                                        color: palette.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      height: 320,
                                      child: ListView(
                                        controller: scrollController,
                                        scrollDirection: Axis.horizontal,
                                        children: [
                                          // Fee Payment Types Chart
                                          Obx(() {
                                            final includedFees =
                                                dashController.totalFees.value;
                                            final separateFees = dashController
                                                .totalSeparateFees.value;
                                            final totalAllFees =
                                                includedFees + separateFees;

                                            if (totalAllFees == 0) {
                                              return const SizedBox.shrink();
                                            }

                                            return Container(
                                              width: 280,
                                              margin: const EdgeInsets.only(
                                                  right: 24),
                                              child: Column(
                                                children: [
                                                  Text(
                                                    'Payment Types',
                                                    style: AppText.poppins(
                                                      color:
                                                          palette.textPrimary,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Included vs Separate',
                                                    style: AppText.poppins(
                                                      color:
                                                          palette.textSecondary,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  SizedBox(
                                                    height: 180,
                                                    width: 180,
                                                    child: Stack(
                                                      children: [
                                                        CustomPaint(
                                                          size: const Size(
                                                              180, 180),
                                                          painter:
                                                              _FeeComparisonChartPainter(
                                                            includedFees:
                                                                includedFees,
                                                            separateFees:
                                                                separateFees,
                                                            isDark:
                                                                palette.isDark,
                                                          ),
                                                        ),
                                                        Center(
                                                          child: Container(
                                                            width: 100,
                                                            height: 100,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: palette
                                                                  .cardSurface,
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                            child: Center(
                                                              child: Column(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .center,
                                                                children: [
                                                                  Text(
                                                                    'Total',
                                                                    style: AppText
                                                                        .poppins(
                                                                      color: palette
                                                                          .textSecondary,
                                                                      fontSize:
                                                                          10,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                      height:
                                                                          2),
                                                                  Text(
                                                                    currencyFormat
                                                                        .format(
                                                                            totalAllFees),
                                                                    style: AppText
                                                                        .poppins(
                                                                      color: palette
                                                                          .textPrimary,
                                                                      fontSize:
                                                                          14,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                                    textAlign:
                                                                        TextAlign
                                                                            .center,
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Wrap(
                                                    spacing: 12,
                                                    runSpacing: 8,
                                                    alignment:
                                                        WrapAlignment.center,
                                                    children: [
                                                      _buildLegend(
                                                        'Included',
                                                        const Color(0xFF64B5F6),
                                                        currencyFormat.format(
                                                            includedFees),
                                                      ),
                                                      _buildLegend(
                                                        'Separate',
                                                        const Color(0xFF9C27B0),
                                                        currencyFormat.format(
                                                            separateFees),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            );
                                          }),

                                          // Fees Breakdown Chart
                                          Container(
                                            width: 280,
                                            margin: const EdgeInsets.only(
                                                right: 24),
                                            child: Column(
                                              children: [
                                                Text(
                                                  'Fees by Source',
                                                  style: AppText.poppins(
                                                    color: palette.textPrimary,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Transaction sources',
                                                  style: AppText.poppins(
                                                    color:
                                                        palette.textSecondary,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                                Obx(() {
                                                  final breakdown =
                                                      Map<String, double>.from(
                                                          dashController
                                                              .feeBreakdown);
                                                  final total = breakdown.values
                                                      .fold(
                                                          0.0,
                                                          (sum, value) =>
                                                              sum + value);

                                                  return Column(
                                                    children: [
                                                      SizedBox(
                                                        height: 180,
                                                        width: 180,
                                                        child: Stack(
                                                          children: [
                                                            CustomPaint(
                                                              size: const Size(
                                                                  180, 180),
                                                              painter:
                                                                  DonutChartPainter(
                                                                sourceBreakdown:
                                                                    breakdown,
                                                              ),
                                                            ),
                                                            Center(
                                                              child: Container(
                                                                width: 100,
                                                                height: 100,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: palette
                                                                      .cardSurface,
                                                                  shape: BoxShape
                                                                      .circle,
                                                                ),
                                                                child: Center(
                                                                  child: Column(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .center,
                                                                    children: [
                                                                      Text(
                                                                        'Total',
                                                                        style: AppText
                                                                            .poppins(
                                                                          color:
                                                                              palette.textSecondary,
                                                                          fontSize:
                                                                              10,
                                                                          fontWeight:
                                                                              FontWeight.w500,
                                                                        ),
                                                                      ),
                                                                      const SizedBox(
                                                                          height:
                                                                              2),
                                                                      Text(
                                                                        currencyFormat
                                                                            .format(total),
                                                                        style: AppText
                                                                            .poppins(
                                                                          color:
                                                                              palette.textPrimary,
                                                                          fontSize:
                                                                              14,
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                        ),
                                                                        textAlign:
                                                                            TextAlign.center,
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                          height: 16),
                                                      if (dashController
                                                          .feeBreakdown.isEmpty)
                                                        Text(
                                                          'No fee data yet',
                                                          style:
                                                              AppText.poppins(
                                                            color: palette
                                                                .textSecondary,
                                                            fontSize: 11,
                                                          ),
                                                        )
                                                      else
                                                        Wrap(
                                                          spacing: 12,
                                                          runSpacing: 8,
                                                          alignment:
                                                              WrapAlignment
                                                                  .center,
                                                          children:
                                                              dashController
                                                                  .feeBreakdown
                                                                  .entries
                                                                  .toList()
                                                                  .asMap()
                                                                  .entries
                                                                  .map((entry) {
                                                            final index =
                                                                entry.key;
                                                            final source =
                                                                entry.value;
                                                            return _buildLegend(
                                                              source.key,
                                                              DonutChartPainter
                                                                  .getColorForSource(
                                                                      source
                                                                          .key,
                                                                      index),
                                                              currencyFormat
                                                                  .format(source
                                                                      .value),
                                                            );
                                                          }).toList(),
                                                        ),
                                                    ],
                                                  );
                                                }),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    // Dot Indicators
                                    Center(
                                      child: Obx(() => Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: List.generate(2, (index) {
                                              final isActive =
                                                  currentPage.value == index;
                                              return AnimatedContainer(
                                                duration: const Duration(
                                                    milliseconds: 300),
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 4),
                                                width: isActive ? 24 : 8,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  color: isActive
                                                      ? palette.accentBlue
                                                      : palette.textSecondary
                                                          .withOpacity(0.3),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                              );
                                            }),
                                          )),
                                    ),
                                  ],
                                ),
                              )
                                  .animate(delay: 350.ms)
                                  .fadeIn(duration: 500.ms)
                                  .slideY(begin: 0.3, end: 0);
                            },
                          ),

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

                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final screenWidth =
                                      MediaQuery.of(context).size.width;
                                  final isCompact = screenWidth < 360;
                                  final titleSize = isCompact ? 14.0 : 16.0;
                                  final subtitleSize = isCompact ? 11.0 : 12.0;
                                  final chartPadding = isCompact ? 16.0 : 20.0;

                                  return Container(
                                    width: screenWidth - 40,
                                    padding: EdgeInsets.all(chartPadding),
                                    decoration: BoxDecoration(
                                      color: palette.cardSurface,
                                      borderRadius: BorderRadius.circular(24),
                                      border:
                                          Border.all(color: palette.cardBorder),
                                      boxShadow: [
                                        BoxShadow(
                                          color: palette.shadowDark,
                                          offset: const Offset(2, 2),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Cash Flow Comparison',
                                          style: AppText.poppins(
                                            color: palette.textPrimary,
                                            fontSize: titleSize,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Income vs Expenses',
                                          style: AppText.poppins(
                                            color: palette.textSecondary,
                                            fontSize: subtitleSize,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        _buildComparisonBar(
                                            'Money Received',
                                            cashIn,
                                            maxValue,
                                            const Color(0xFF4CAF50),
                                            palette),
                                        const SizedBox(height: 16),
                                        _buildComparisonBar(
                                            'Money Sent',
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
                                                : Colors.black
                                                    .withOpacity(0.03),
                                            borderRadius:
                                                BorderRadius.circular(12),
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
                                                        ? const Color(
                                                            0xFF4CAF50)
                                                        : const Color(
                                                            0xFFEF4444),
                                                    size: 18,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    currencyFormat.format(
                                                        cashIn - cashOut),
                                                    style: AppText.poppins(
                                                      color: cashIn >= cashOut
                                                          ? const Color(
                                                              0xFF4CAF50)
                                                          : const Color(
                                                              0xFFEF4444),
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            )
                                .animate(delay: 500.ms)
                                .fadeIn(duration: 400.ms)
                                .slideY(begin: 0.2, end: 0);
                          }),

                          const SizedBox(height: 25),

                          // Recent Transactions Header
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final screenWidth =
                                  MediaQuery.of(context).size.width;
                              final isCompact = screenWidth < 360;
                              final titleSize = isCompact ? 16.0 : 18.0;
                              final subtitleSize = isCompact ? 11.0 : 12.0;
                              final buttonTextSize = isCompact ? 12.0 : 13.0;

                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Recent Activity',
                                          style: AppText.poppins(
                                            color: palette.textPrimary,
                                            fontSize: titleSize,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Transaction timeline',
                                          style: AppText.poppins(
                                            color: palette.textSecondary,
                                            fontSize: subtitleSize,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () {
                                      Get.to(
                                        () => const TransactionLogsPage(),
                                        transition: Transition.rightToLeft,
                                        duration:
                                            const Duration(milliseconds: 300),
                                      );
                                    },
                                    icon: Icon(
                                      Icons.arrow_forward,
                                      size: isCompact ? 14 : 16,
                                      color: palette.accentBlue,
                                    ),
                                    label: Text(
                                      'View All',
                                      style: AppText.poppins(
                                        color: palette.accentBlue,
                                        fontSize: buttonTextSize,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
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

      // M3 Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: palette.surfaceContainer,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildM3NavItem(Icons.home_rounded, Icons.home_outlined, 'Home',
                    0, palette),
                _buildM3NavItem(Icons.receipt_long_rounded,
                    Icons.receipt_long_outlined, 'History', 1, palette),
                _buildM3ScanButton(palette),
                _buildM3NavItem(Icons.smart_toy_rounded,
                    Icons.smart_toy_outlined, 'AI Chat', 3, palette),
                _buildM3NavItem(Icons.settings_rounded, Icons.settings_outlined,
                    'Settings', 2, palette),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // M3 Icon Button - Responsive
  Widget _buildM3IconButton({
    required IconData icon,
    required VoidCallback onTap,
    required _DashboardPalette palette,
    bool isDestructive = false,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 360;
    final isSmall = screenWidth < 400;

    final buttonSize = isCompact ? 36.0 : (isSmall ? 40.0 : 44.0);
    final iconSize = isCompact ? 18.0 : (isSmall ? 20.0 : 22.0);
    final borderRadius = isCompact ? 10.0 : 12.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            color: palette.surfaceContainer,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Icon(
            icon,
            color: isDestructive ? palette.error : palette.textSecondary,
            size: iconSize,
          ),
        ),
      ),
    );
  }

  // M3 Stat Card with tonal colors - Responsive
  Widget _buildM3StatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    Color bgColor,
    _DashboardPalette palette,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isCompact = screenWidth < 360 || constraints.maxWidth < 140;
        final isSmall = screenWidth < 400 || constraints.maxWidth < 160;

        final cardPadding = isCompact ? 10.0 : (isSmall ? 12.0 : 16.0);
        final iconPadding = isCompact ? 6.0 : (isSmall ? 8.0 : 10.0);
        final iconSize = isCompact ? 16.0 : (isSmall ? 18.0 : 20.0);
        final valueSize = isCompact ? 13.0 : (isSmall ? 14.0 : 16.0);
        final labelSize = isCompact ? 10.0 : (isSmall ? 11.0 : 12.0);

        return Container(
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            color: palette.surfaceContainer,
            borderRadius: BorderRadius.circular(isCompact ? 14 : 20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(iconPadding),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(isCompact ? 8 : 12),
                ),
                child: Icon(icon, color: color, size: iconSize),
              ),
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: AppText.poppins(
                    color: palette.textPrimary,
                    fontSize: valueSize,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              SizedBox(height: isCompact ? 1 : 2),
              Text(
                label,
                style: AppText.poppins(
                  color: palette.textSecondary,
                  fontSize: labelSize,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    _DashboardPalette palette,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 160;
        final iconSize = isCompact ? 16.0 : 18.0;
        final iconPadding = isCompact ? 6.0 : 8.0;
        final valueSize = isCompact ? 13.0 : 15.0;
        final labelSize = isCompact ? 10.0 : 11.0;
        final cardPadding = isCompact ? 10.0 : 12.0;

        return Container(
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            color: palette.surfaceContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(iconPadding),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: iconSize,
                ),
              ),
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: AppText.poppins(
                    color: palette.textPrimary,
                    fontSize: valueSize,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(height: isCompact ? 1 : 2),
              Text(
                label,
                style: AppText.poppins(
                  color: palette.textSecondary,
                  fontSize: labelSize,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isCompact = screenWidth < 360;
        final isSmall = screenWidth < 400;

        final cardPadding = isCompact ? 10.0 : (isSmall ? 12.0 : 16.0);
        final iconPadding = isCompact ? 8.0 : (isSmall ? 10.0 : 12.0);
        final iconSize = isCompact ? 18.0 : (isSmall ? 20.0 : 24.0);
        final labelSize = isCompact ? 10.0 : (isSmall ? 11.0 : 12.0);
        final valueSize = isCompact ? 13.0 : (isSmall ? 14.0 : 16.0);
        final subtitleSize = isCompact ? 9.0 : (isSmall ? 10.0 : 11.0);
        final spacing = isCompact ? 8.0 : (isSmall ? 10.0 : 14.0);

        return Container(
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            color: palette.surfaceContainer,
            borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(iconPadding),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(isCompact ? 8 : 12),
                ),
                child: Icon(icon, color: color, size: iconSize),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: AppText.poppins(
                        color: palette.textSecondary,
                        fontSize: labelSize,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isCompact ? 2 : 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: AppText.poppins(
                          color: palette.textPrimary,
                          fontSize: valueSize,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: isCompact ? 1 : 2),
                      Text(
                        subtitle,
                        style: AppText.poppins(
                          color: palette.textTertiary,
                          fontSize: subtitleSize,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
                            fontSize:
                                ResponsiveHelper.isExtraSmallScreen(context)
                                    ? 13
                                    : 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              amount,
                              style: AppText.poppins(
                                color: color,
                                fontSize:
                                    ResponsiveHelper.isExtraSmallScreen(context)
                                        ? 12
                                        : 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
                    fontSize: ResponsiveHelper.isExtraSmallScreen(context)
                        ? 8
                        : ResponsiveHelper.isSmallScreen(context)
                            ? 9
                            : 10,
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

  // M3 Navigation Item with pill indicator - Responsive
  Widget _buildM3NavItem(
    IconData filledIcon,
    IconData outlinedIcon,
    String label,
    int index,
    _DashboardPalette palette,
  ) {
    final isSelected = _selectedIndex == index;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 360;
    final isSmall = screenWidth < 400;

    // Responsive values
    final iconSize = isCompact ? 20.0 : (isSmall ? 22.0 : 24.0);
    final labelSize = isCompact ? 9.0 : (isSmall ? 10.0 : 11.0);
    final pillPaddingH = isCompact ? 12.0 : (isSmall ? 16.0 : 20.0);
    final pillPaddingV = isCompact ? 4.0 : 6.0;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (index == 1) {
              Get.to(() => const TransactionLogsPage(),
                  transition: Transition.cupertino,
                  duration: const Duration(milliseconds: 400));
            } else if (index == 2) {
              Get.to(() => const SettingsPage(),
                  transition: Transition.cupertino,
                  duration: const Duration(milliseconds: 400));
            } else if (index == 3) {
              Get.to(() => const AIChatPage(),
                  transition: Transition.cupertino,
                  duration: const Duration(milliseconds: 400));
            } else {
              setState(() => _selectedIndex = index);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: isCompact ? 4 : 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                      horizontal: pillPaddingH, vertical: pillPaddingV),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? palette.navIndicator : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isSelected ? filledIcon : outlinedIcon,
                    color: isSelected
                        ? palette.navIconActive
                        : palette.navIconInactive,
                    size: iconSize,
                  ),
                ),
                SizedBox(height: isCompact ? 2 : 4),
                Text(
                  label,
                  style: AppText.poppins(
                    color: isSelected
                        ? palette.navIconActive
                        : palette.navIconInactive,
                    fontSize: labelSize,
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

  // M3 Scan FAB Button - Responsive
  Widget _buildM3ScanButton(_DashboardPalette palette) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 360;
    final isSmall = screenWidth < 400;

    final buttonSize = isCompact ? 48.0 : (isSmall ? 52.0 : 56.0);
    final iconSize = isCompact ? 22.0 : (isSmall ? 25.0 : 28.0);

    return GestureDetector(
      onTap: () {
        Get.to(() => const ScanPage(),
            transition: Transition.zoom,
            duration: const Duration(milliseconds: 400));
      },
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: palette.primary,
          borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
          boxShadow: [
            BoxShadow(
              color: palette.primary.withOpacity(0.3),
              offset: const Offset(0, 4),
              blurRadius: 12,
            ),
          ],
        ),
        child: Icon(
          Icons.qr_code_scanner_rounded,
          color: palette.isDark ? Colors.black : Colors.white,
          size: iconSize,
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
          borderRadius: BorderRadius.circular(28),
        ),
        backgroundColor: palette.surfaceContainer,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: palette.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: palette.error,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Sign out',
                style: AppText.poppins(
                  color: palette.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to sign out?',
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
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Get.back(),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: palette.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
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
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          try {
                            Get.back();
                            Get.dialog(
                              Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      palette.primary),
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

                            Get.back();

                            Get.offAll(
                              () => const LandingPage(),
                              transition: Transition.fadeIn,
                              duration: const Duration(milliseconds: 400),
                            );

                            Get.snackbar(
                              'Signed out',
                              'You have been successfully signed out',
                              backgroundColor: palette.primary,
                              colorText: Colors.white,
                              snackPosition: SnackPosition.TOP,
                              margin: const EdgeInsets.all(20),
                              borderRadius: 16,
                              duration: const Duration(seconds: 2),
                            );
                          } catch (e) {
                            if (Get.isDialogOpen ?? false) {
                              Get.back();
                            }
                            Get.snackbar(
                              'Error',
                              'Failed to sign out: ${e.toString()}',
                              backgroundColor: palette.error,
                              colorText: Colors.white,
                              snackPosition: SnackPosition.TOP,
                              margin: const EdgeInsets.all(20),
                              borderRadius: 16,
                              duration: const Duration(seconds: 3),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: palette.error,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'Sign out',
                              style: AppText.poppins(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
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

// Fee Comparison Chart Painter (Included vs Separate)
class _FeeComparisonChartPainter extends CustomPainter {
  final double includedFees;
  final double separateFees;
  final bool isDark;

  _FeeComparisonChartPainter({
    required this.includedFees,
    required this.separateFees,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 25.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final total = includedFees + separateFees;

    // If no data, show default gray ring
    if (total == 0) {
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

    double startAngle = -math.pi / 2;

    // Draw Included Fees segment (Blue)
    if (includedFees > 0) {
      paint.color = const Color(0xFF64B5F6);
      final percentage = includedFees / total;
      final sweepAngle = 2 * math.pi * percentage - 0.02;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle + 0.02;
    }

    // Draw Separate Fees segment (Purple)
    if (separateFees > 0) {
      paint.color = const Color(0xFF9C27B0);
      final percentage = separateFees / total;
      final sweepAngle = 2 * math.pi * percentage - 0.02;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_FeeComparisonChartPainter oldDelegate) {
    return oldDelegate.includedFees != includedFees ||
        oldDelegate.separateFees != separateFees ||
        oldDelegate.isDark != isDark;
  }
}
