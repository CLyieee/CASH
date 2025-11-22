import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/transaction_model.dart';

enum ReportPeriod { daily, weekly, monthly, yearly }

class ReportService {
  final currencyFormat =
      NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 2);
  final dateFormat = DateFormat('MMM dd, yyyy');
  final timeFormat = DateFormat('hh:mm a');

  /// Generate CSV report for transactions
  Future<String> generateCSVReport(
    List<TransactionModel> transactions,
    ReportPeriod period,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('GCash Transaction Report - ${_getPeriodLabel(period)}');
    buffer.writeln(
        'Generated: ${DateFormat('MMM dd, yyyy hh:mm a').format(DateTime.now())}');
    buffer.writeln(
        'Period: ${dateFormat.format(startDate)} to ${dateFormat.format(endDate)}');
    buffer.writeln('');

    // Summary
    final summary = _calculateSummary(transactions);
    buffer.writeln('Summary:');
    buffer.writeln('Total Transactions,${transactions.length}');
    buffer.writeln('Total Cash In,${currencyFormat.format(summary['cashIn'])}');
    buffer
        .writeln('Total Cash Out,${currencyFormat.format(summary['cashOut'])}');
    buffer.writeln('Total Fees,${currencyFormat.format(summary['fees'])}');
    buffer.writeln('Net Amount,${currencyFormat.format(summary['net'])}');
    buffer.writeln('');

    // Transaction details header
    buffer
        .writeln('Date,Time,Type,Recipient,Amount,Fee,Total,Reference,Source');

    // Transaction data
    for (final tx in transactions) {
      buffer.writeln([
        dateFormat.format(tx.createdAt),
        timeFormat.format(tx.createdAt),
        tx.transactionType,
        _escapeCsv(tx.recipientName),
        tx.amount.toStringAsFixed(2),
        tx.fee.toStringAsFixed(2),
        tx.totalAmount.toStringAsFixed(2),
        _escapeCsv(tx.refNumber),
        _escapeCsv(tx.source),
      ].join(','));
    }

    return buffer.toString();
  }

  /// Export report to file and share
  Future<void> exportReport(
    List<TransactionModel> transactions,
    ReportPeriod period,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Generate CSV content
      final csvContent =
          await generateCSVReport(transactions, period, startDate, endDate);

      // Get application documents directory (more reliable than temporary)
      Directory? directory;
      try {
        directory = await getApplicationDocumentsDirectory();
      } catch (e) {
        print('Error getting app directory: $e, trying external storage...');
        // Fallback to external storage directory on Android
        if (Platform.isAndroid) {
          directory = await getExternalStorageDirectory();
        }
        if (directory == null) {
          throw Exception('Could not access storage directory');
        }
      }

      final fileName =
          'transaction_report_${_getPeriodFileLabel(period)}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final file = File('${directory.path}/$fileName');

      // Write to file
      await file.writeAsString(csvContent);

      // Share file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Transaction Report - ${_getPeriodLabel(period)}',
        text:
            'Here is your ${_getPeriodLabel(period).toLowerCase()} transaction report',
      );
    } catch (e) {
      print('Error exporting report: $e');
      rethrow;
    }
  }

  /// Filter transactions by period
  List<TransactionModel> filterTransactionsByPeriod(
    List<TransactionModel> transactions,
    ReportPeriod period,
  ) {
    final now = DateTime.now();
    DateTime startDate;

    switch (period) {
      case ReportPeriod.daily:
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case ReportPeriod.weekly:
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case ReportPeriod.monthly:
        startDate = DateTime(now.year, now.month, 1);
        break;
      case ReportPeriod.yearly:
        startDate = DateTime(now.year, 1, 1);
        break;
    }

    return transactions
        .where((tx) =>
            tx.createdAt.isAfter(startDate) ||
            tx.createdAt.isAtSameMomentAs(startDate))
        .toList();
  }

  /// Get date range for period
  Map<String, DateTime> getDateRangeForPeriod(ReportPeriod period) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = now;

    switch (period) {
      case ReportPeriod.daily:
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case ReportPeriod.weekly:
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case ReportPeriod.monthly:
        startDate = DateTime(now.year, now.month, 1);
        break;
      case ReportPeriod.yearly:
        startDate = DateTime(now.year, 1, 1);
        break;
    }

    return {'start': startDate, 'end': endDate};
  }

  /// Calculate summary statistics
  Map<String, double> _calculateSummary(List<TransactionModel> transactions) {
    double cashIn = 0;
    double cashOut = 0;
    double fees = 0;

    for (final tx in transactions) {
      if (tx.transactionType == 'Cash In') {
        cashIn += tx.amount;
      } else {
        cashOut += tx.amount;
      }
      fees += tx.fee;
    }

    return {
      'cashIn': cashIn,
      'cashOut': cashOut,
      'fees': fees,
      'net': cashIn - cashOut,
    };
  }

  /// Escape CSV special characters
  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// Get human-readable period label
  String _getPeriodLabel(ReportPeriod period) {
    switch (period) {
      case ReportPeriod.daily:
        return 'Daily Report';
      case ReportPeriod.weekly:
        return 'Weekly Report';
      case ReportPeriod.monthly:
        return 'Monthly Report';
      case ReportPeriod.yearly:
        return 'Yearly Report';
    }
  }

  /// Get file-safe period label
  String _getPeriodFileLabel(ReportPeriod period) {
    switch (period) {
      case ReportPeriod.daily:
        return 'daily';
      case ReportPeriod.weekly:
        return 'weekly';
      case ReportPeriod.monthly:
        return 'monthly';
      case ReportPeriod.yearly:
        return 'yearly';
    }
  }
}
