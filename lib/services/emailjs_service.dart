import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

class EmailJsService {
  // Get these from EmailJS dashboard
  static const String serviceId = 'service_rarrurt';
  static const String templateId = 'template_jth6447';
  static const String publicKey = 'KIp8xvUGMY8vCSMTH';

  Future<bool> sendOtpEmail(String toEmail, String otp) async {
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
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': publicKey,
          'template_params': {
            'to_email': toEmail,
            'otp_code': otp,
            'app_name': 'GCash Receipt Tracker',
          }
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Email sent successfully');
        return true;
      } else {
        print('❌ EmailJS Error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ EmailJS Error: $e');
      return false;
    }
  }
}
