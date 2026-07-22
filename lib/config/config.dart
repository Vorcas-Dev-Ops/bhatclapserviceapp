import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  /// Razorpay Key ID loaded dynamically from the .env file.
  static String get razorpayKeyId => dotenv.env['NEXT_PUBLIC_RAZORPAY_KEY_ID'] ?? '';
}
