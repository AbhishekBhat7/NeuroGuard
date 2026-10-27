import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user_profile.dart';

class AlertResult {
  final bool success;
  final String disease;
  final String message;
  final int? statusCode;

  const AlertResult({
    required this.success,
    required this.disease,
    required this.message,
    this.statusCode,
  });
}

class AlertService {
  static const String apiUrl =
      'https://wellwisetesting-h2a7erara0b5bqbn.centralindia-01.azurewebsites.net/api/neuroguard/send';

  static String getDiseaseForButton(int buttonId) {
    if (buttonId == 1) {
      return 'Epilepsy Signal';
    } else {
      return 'Seizure signal';
    }
  }

  static Future<AlertResult> sendAbnormalityAlert({
    required UserProfile profile,
    required int buttonId,
  }) async {
    final disease = getDiseaseForButton(buttonId);

    final payload = {
      'caretakerEmail': profile.caretakerEmail.trim(),
      'patientName': profile.patientName.trim(),
      'location': profile.patientLocation.trim(),
      'disease': disease,
    };

    debugPrint('Sending Alert to $apiUrl with payload: $payload');

    try {
      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('Alert response (${response.statusCode}): ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return AlertResult(
          success: true,
          disease: disease,
          statusCode: response.statusCode,
          message: 'Alert sent successfully to ${profile.caretakerEmail}!',
        );
      } else {
        return AlertResult(
          success: false,
          disease: disease,
          statusCode: response.statusCode,
          message: 'Server responded with error ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error sending alert: $e');
      return AlertResult(
        success: false,
        disease: disease,
        message: 'Failed to send alert: ${e.toString()}',
      );
    }
  }
}

