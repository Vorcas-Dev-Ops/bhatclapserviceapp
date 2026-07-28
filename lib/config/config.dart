import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  /// Razorpay Key ID loaded dynamically from the .env file.
  static String get razorpayKeyId {
    final key = dotenv.env['NEXT_PUBLIC_RAZORPAY_KEY_ID'];
    if (key != null && key.trim().isNotEmpty) {
      return key.trim();
    }
    return 'rzp_test_TCwlsGgFYgQdGL';
  }
}
