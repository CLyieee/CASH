import 'package:http/http.dart' as http;
import 'dart:convert';

class EmailJsService {
  // Get these from EmailJS dashboard
  static const String serviceId = 'YOUR_SERVICE_ID';
  static const String templateId = 'YOUR_TEMPLATE_ID';
  static const String publicKey = 'YOUR_PUBLIC_KEY';

  Future<bool> sendOtpEmail(String toEmail, String otp) async {
    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
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

    return response.statusCode == 200;
  }
}
