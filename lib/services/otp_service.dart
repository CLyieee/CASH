import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

class OtpService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // EmailJS Configuration - Get these from https://dashboard.emailjs.com
  static const String _emailJsServiceId = 'service_rarrurt';
  static const String _emailJsTemplateId = 'template_jth6447';
  static const String _emailJsPublicKey = 'KIp8xvUGMY8vCSMTH';

  // Generate a 6-digit OTP
  String generateOTP() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  // Send OTP to user's email using Firebase Auth email link
  Future<bool> sendOTPToEmail(String userId, String email) async {
    try {
      // Generate OTP
      final otp = generateOTP();
      final expiryTime = DateTime.now().add(const Duration(minutes: 10));

      // Store OTP in Firestore
      await _firestore.collection('otp_codes').doc(userId).set({
        'otp': otp,
        'email': email,
        'expiryTime': expiryTime,
        'createdAt': DateTime.now(),
        'used': false,
      });

      // Send email via EmailJS
      final emailSent = await _sendEmailViaEmailJS(email, otp);

      if (emailSent) {
        print('✅ OTP email sent successfully to $email');
      } else {
        print('⚠️ Email sending failed, but OTP is stored in Firestore');
      }

      return true;
    } catch (e) {
      print('Error sending OTP: $e');
      return false;
    }
  }

  // Verify OTP
  Future<bool> verifyOTP(String userId, String otp) async {
    try {
      final doc = await _firestore.collection('otp_codes').doc(userId).get();

      if (!doc.exists) {
        return false;
      }

      final data = doc.data()!;
      final storedOtp = data['otp'] as String;
      final expiryTime = (data['expiryTime'] as Timestamp).toDate();
      final used = data['used'] as bool;

      // Check if OTP matches, not expired, and not already used
      if (storedOtp == otp && DateTime.now().isBefore(expiryTime) && !used) {
        // Mark OTP as used
        await _firestore.collection('otp_codes').doc(userId).update({
          'used': true,
          'usedAt': DateTime.now(),
        });
        return true;
      }

      return false;
    } catch (e) {
      print('Error verifying OTP: $e');
      return false;
    }
  }

  // Clean up expired OTPs
  Future<void> cleanupExpiredOTPs() async {
    try {
      final expiredOTPs = await _firestore
          .collection('otp_codes')
          .where('expiryTime', isLessThan: DateTime.now())
          .get();

      for (var doc in expiredOTPs.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error cleaning up OTPs: $e');
    }
  }

  // Get OTP for debugging/testing (remove in production)
  Future<String?> getOTPForUser(String userId) async {
    try {
      final doc = await _firestore.collection('otp_codes').doc(userId).get();
      if (doc.exists) {
        return doc.data()?['otp'] as String?;
      }
      return null;
    } catch (e) {
      print('Error getting OTP: $e');
      return null;
    }
  }

  // Send OTP email via EmailJS
  Future<bool> _sendEmailViaEmailJS(String email, String otp) async {
    try {
      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Origin': 'https://app.emailjs.com',
        },
        body: json.encode({
          'service_id': _emailJsServiceId,
          'template_id': _emailJsTemplateId,
          'user_id': _emailJsPublicKey,
          'template_params': {
            'to_name': 'User',
            'to_email': email,
            'reply_to': email,
            'otp_code': otp,
            'app_name': 'GCash Receipt Tracker',
            'expiry_minutes': '10',
          },
          'accessToken': _emailJsPublicKey,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ EmailJS: Email sent successfully');
        return true;
      } else {
        print('❌ EmailJS Error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ EmailJS Exception: $e');
      return false;
    }
  }
}
