import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

Future<void> sendOtpEmail(String recipientEmail, String otp) async {
  final smtpServer = gmail(
    'pwen0331@gmail.com',
    'rpyp iluv xkgm vifa',
  );

  final message = Message()
    ..from = Address('pwen0331@gmail.com', 'My Flutter App')
    ..recipients.add(recipientEmail)
    ..subject = 'Your OTP Code'
    ..text = 'Hello, your OTP is $otp. It expires in 5 minutes.';

  try {
    await send(message, smtpServer);
    print('OTP sent to $recipientEmail');
  } catch (e) {
    print('Error sending OTP: $e');
  }
}
