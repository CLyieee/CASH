import 'package:flutter/material.dart';
import 'package:g/utils/app_text.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../services/google_sign_in_service.dart';
import '../controllers/app_controller.dart';
import '../controllers/dashboard_controller.dart';
import 'scan_page.dart';
import 'transaction_logs_page.dart';
import 'settings_page.dart';
import 'landing_page.dart';
import 'dart:math' as math;

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
    return Scaffold(
      backgroundColor: const Color(0xFFE0E5EC),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome Back',
                        style: AppText.poppins(
                          color: const Color(0xFF64B5F6),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        widget.userName,
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
                    ],
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideX(begin: -0.3, end: 0),
                  GestureDetector(
                    onTap: () => _showLogoutDialog(context),
                    child: Container(
                      width: 50,
                      height: 50,
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
                      child: Center(
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.red.shade400,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.shade400.withOpacity(0.4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.logout_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 400.ms).scale(delay: 200.ms),
                ],
              ),
            ),

            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    // Balance Card
                    Container(
                      width: double.infinity,
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TOTAL BALANCE',
                            style: AppText.poppins(
                              color: const Color(0xFF64B5F6),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Obx(() {
                            final totalBalance =
                                dashController.totalCashIn.value +
                                    dashController.totalCashOut.value;
                            return Text(
                              currencyFormat.format(totalBalance),
                              style: AppText.poppins(
                                color: const Color(0xFF2C3E50),
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.white.withOpacity(0.8),
                                    offset: const Offset(-2, -2),
                                    blurRadius: 4,
                                  ),
                                  Shadow(
                                    color: Colors.black.withOpacity(0.15),
                                    offset: const Offset(2, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 100.ms, duration: 500.ms)
                        .slideY(begin: 0.3, end: 0),

                    const SizedBox(height: 20),

                    // Quick Actions
                    Row(
                      children: [
                        Expanded(
                          child: Obx(() => _buildQuickActionButton(
                                    'SEND/CASH IN',
                                    currencyFormat.format(
                                        dashController.totalCashIn.value),
                                    const Color(0xFF4CAF50),
                                  ))
                              .animate(delay: 200.ms)
                              .fadeIn(duration: 400.ms)
                              .scale(begin: const Offset(0.8, 0.8)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Obx(() => _buildQuickActionButton(
                                    'RECEIVE/CASH OUT',
                                    currencyFormat.format(
                                        dashController.totalCashOut.value),
                                    const Color(0xFF64B5F6),
                                  ))
                              .animate(delay: 300.ms)
                              .fadeIn(duration: 400.ms)
                              .scale(begin: const Offset(0.8, 0.8)),
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // Donut Chart Card - Centered
                    Center(
                            child: Container(
                      constraints: const BoxConstraints(maxWidth: 400),
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
                          Text(
                            'Fee Breakdown',
                            style: AppText.poppins(
                              color: const Color(0xFF2C3E50),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Obx(() => SizedBox(
                                height: 200,
                                width: 200,
                                child: Stack(
                                  children: [
                                    CustomPaint(
                                      size: const Size(200, 200),
                                      painter: DonutChartPainter(
                                        sourceBreakdown:
                                            dashController.sourceBreakdown,
                                      ),
                                    ),
                                    Center(
                                      child: Container(
                                        width: 110,
                                        height: 110,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE0E5EC),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.white.withOpacity(0.8),
                                              offset: const Offset(-4, -4),
                                              blurRadius: 8,
                                            ),
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.2),
                                              offset: const Offset(4, 4),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Total Fees',
                                                style: AppText.poppins(
                                                  color:
                                                      const Color(0xFF64B5F6),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Text(
                                                currencyFormat.format(
                                                    dashController
                                                        .totalFees.value),
                                                style: AppText.poppins(
                                                  color:
                                                      const Color(0xFF2C3E50),
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                          const SizedBox(height: 20),
                          Wrap(
                            spacing: 16,
                            runSpacing: 12,
                            alignment: WrapAlignment.center,
                            children: [
                              _buildLegend('GCASH', const Color(0xFF4CAF50)),
                              _buildLegend('Cash In', const Color(0xFF64B5F6)),
                              _buildLegend('Palawan', const Color(0xFFFF9800)),
                              _buildLegend('Pailia', const Color(0xFFF44336)),
                            ],
                          ),
                        ],
                      ),
                    ))
                        .animate(delay: 400.ms)
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: 0.3, end: 0),

                    const SizedBox(height: 25),

                    // Recent Transactions
                    Text(
                      'Recent Transactions',
                      style: AppText.poppins(
                        color: const Color(0xFF2C3E50),
                        fontSize: 16,
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
                    ).animate(delay: 500.ms).fadeIn(duration: 400.ms),

                    const SizedBox(height: 16),

                    Obx(() {
                      if (dashController.recentTransactions.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.receipt_long_rounded,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No transactions yet',
                                  style: AppText.poppins(
                                    color: Colors.grey.shade500,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Scan a receipt to get started',
                                  style: AppText.poppins(
                                    color: Colors.grey.shade400,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: dashController.recentTransactions
                            .take(5)
                            .map((transaction) {
                          final isPositive =
                              transaction.transactionType == 'Cash In';
                          final dateFormat = DateFormat('MMM dd, yyyy, h:mm a');
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildTransactionItem(
                              transaction.transactionType.toUpperCase(),
                              dateFormat.format(transaction.createdAt),
                              '${isPositive ? '+' : '-'}${currencyFormat.format(transaction.totalAmount)}',
                              isPositive,
                            ),
                          )
                              .animate(delay: 600.ms)
                              .fadeIn(duration: 400.ms)
                              .slideX(begin: -0.2, end: 0);
                        }).toList(),
                      );
                    }),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Floating Bottom Navigation
      bottomNavigationBar: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: const EdgeInsets.all(20),
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E5EC),
              borderRadius: BorderRadius.circular(35),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home_rounded, 'Home', 0),
                _buildNavItem(Icons.receipt_long_rounded, 'Logs', 1),
                const SizedBox(width: 60), // Space for center scan button
                _buildNavItem(Icons.settings_rounded, 'Settings', 2),
                const SizedBox(width: 8), // Balance spacing
              ],
            ),
          ),

          // Center Scan Button
          Positioned(
            left: 0,
            right: 0,
            bottom: 45,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  Get.to(
                    () => const ScanPage(),
                    transition: Transition.fadeIn,
                    duration: const Duration(milliseconds: 300),
                  );
                },
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF64B5F6), Color(0xFF42A5F5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF64B5F6).withOpacity(0.5),
                        offset: const Offset(0, 8),
                        blurRadius: 20,
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.8),
                        offset: const Offset(-4, -4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(String label, String amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E5EC),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            offset: const Offset(-4, -4),
            blurRadius: 10,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(4, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              label,
              style: AppText.poppins(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            amount,
            style: AppText.poppins(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
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
        Text(
          label,
          style: AppText.poppins(
            color: const Color(0xFF2C3E50),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(
    String title,
    String date,
    String amount,
    bool isPositive,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                  title,
                  style: AppText.poppins(
                    color: const Color(0xFF2C3E50),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: AppText.poppins(
                    color: const Color(0xFF64B5F6),
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isPositive
                  ? const Color(0xFF4CAF50).withOpacity(0.1)
                  : const Color(0xFFF44336).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              amount,
              style: AppText.poppins(
                color: isPositive
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFF44336),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 1) {
          // Navigate to Transaction Logs page
          Get.to(
            () => const TransactionLogsPage(),
            transition: Transition.rightToLeft,
            duration: const Duration(milliseconds: 300),
          );
        } else if (index == 2) {
          // Navigate to Settings page
          Get.to(
            () => const SettingsPage(),
            transition: Transition.rightToLeft,
            duration: const Duration(milliseconds: 300),
          );
        } else {
          setState(() {
            _selectedIndex = index;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: const Color(0xFFE0E5EC),
                borderRadius: BorderRadius.circular(20),
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
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF64B5F6)
                  : const Color(0xFF2C3E50).withOpacity(0.4),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppText.poppins(
                color: isSelected
                    ? const Color(0xFF64B5F6)
                    : const Color(0xFF2C3E50).withOpacity(0.4),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: const Color(0xFFE0E5EC),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: const Color(0xFFE0E5EC),
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
                  color: const Color(0xFF2C3E50),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to logout?',
                textAlign: TextAlign.center,
                style: AppText.poppins(
                  color: const Color(0xFF2C3E50).withOpacity(0.7),
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
                          color: const Color(0xFFE0E5EC),
                          borderRadius: BorderRadius.circular(12),
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
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: AppText.poppins(
                              color: const Color(0xFF2C3E50),
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

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = 25.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Color mapping for different sources
    final colorMap = {
      'GCash': const Color(0xFF4CAF50),
      'Cash In': const Color(0xFF64B5F6),
      'Palawan': const Color(0xFFFF9800),
      'Pailia': const Color(0xFFF44336),
    };

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

    double startAngle = -math.pi / 2;

    sourceBreakdown.forEach((source, percentage) {
      if (percentage > 0) {
        paint.color = colorMap[source] ?? Colors.grey;
        final sweepAngle = 2 * math.pi * percentage - 0.05;

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
          startAngle,
          sweepAngle,
          false,
          paint,
        );

        startAngle += sweepAngle + 0.05;
      }
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
