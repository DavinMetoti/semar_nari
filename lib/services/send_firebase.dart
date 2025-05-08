import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseNotificationService {
  final String serverKey = "AIzaSyA7YkiZ3Sj6lJO7BSDyI4FDgNUANQuKXS4";
  final String fcmUrl = "https://fcm.googleapis.com/fcm/send";

  // Fungsi untuk mengirim notifikasi
  Future<void> sendNotification({
    required String title,
    required String body,
    required String token,
  }) async {
    if (token.isEmpty) {
      print("Token perangkat tidak ditemukan.");
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(fcmUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "key=$serverKey",
        },
        body: jsonEncode({
          "to": token,
          "notification": {
            "title": title,
            "body": body,
          },
          "data": {
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
          },
        }),
      );

      if (response.statusCode == 200) {
        print("Notifikasi berhasil dikirim.");
      } else {
        print("Gagal mengirim notifikasi: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Error mengirim notifikasi: $e");
    }
  }

  // Fungsi untuk mendapatkan token perangkat
  Future<String?> getDeviceToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) {
        print("Token perangkat tidak ditemukan.");
      } else {
        print("Token perangkat: $token");
      }
      return token;
    } catch (e) {
      print("Error mendapatkan token perangkat: $e");
      return null;
    }
  }
}
