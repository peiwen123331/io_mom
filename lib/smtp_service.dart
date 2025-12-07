import 'dart:io';
import 'package:io_mom/collaboration_request.dart';
import 'package:io_mom/confinement_center.dart';
import 'package:io_mom/database.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

import 'booking.dart';
import 'user.dart';

final dbService = DatabaseService();
Future<void> sendOtpEmail(String recipientEmail, String otp) async {
  final smtpServer = gmail(
    'pwen0331@gmail.com',
    'loia tlir gpbq xqaq',
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

  Future<void> sendBookingConfirmationEmail(Booking booking) async {
    final smtpServer = gmail(
      'pwen0331@gmail.com',
      'sdtj ynoe gopp vmjw',
    );
  final user = await dbService.getUserByUID(booking.userID);
  final package = await dbService.getPackageByPackageID(booking.PackageID);
  final checkOutDate = booking.checkInDate.add(Duration(days: package!.duration));
  final center = await dbService.getConfinementByCenterID(package.CenterID);

  final message = Message()
    ..from = Address('pwen0331@gmail.com', 'My Flutter App')
    ..recipients.add(user?.userEmail)
    ..subject = 'Booking Confirmation – ${center!.CenterName}'
    ..text = 'Dear ${user?.userName},'
        'Thank you for choosing ${center.CenterName}!\n\n'
        'We’re pleased to confirm your booking with the following details:\n\n'
        'Booking Details\n'
        'Booking ID: ${booking.BookingID}\n'
        'Customer Name: ${user?.userName}\n'
        'Check-in Date: ${booking.checkInDate}\n'
        'Check-out Date: $checkOutDate\n'
        'Room Type / Package: ${package.packageName}\n'
        'Total Amount: RM${booking.payAmount.toStringAsFixed(2)}\n'
        'Payment Status: Paid\n\n'
        'If you have any special requests or need to make changes to your booking,'
        'please don’t hesitate to contact us at admin@iomom.com'
        'We look forward to welcoming you and ensuring a comfortable and nurturing stay. 💖\n'
        'Warm regards,\n'
        'Io Mom App Team';


    final messageCC = Message()
      ..from = Address('pwen0331@gmail.com', 'My Flutter App')
      ..recipients.add(center.centerEmail)
      ..subject = 'New Booking Received – ${center!.CenterName}'
      ..text = 'Dear ${center.CenterName} Team,\n\n'
          'You have received a new booking from a customer. Below are the booking details:\n\n'
          '📌 **Booking Information**\n'
          'Booking ID: ${booking.BookingID}\n'
          'Customer Name: ${user?.userName}\n'
          'Customer Email: ${user?.userEmail}\n'
          'Check-in Date: ${booking.checkInDate}\n'
          'Check-out Date: $checkOutDate\n'
          'Selected Package: ${package.packageName}\n'
          'Total Amount Paid: RM${booking.payAmount.toStringAsFixed(2)}\n'
          'Payment Status: Paid\n\n'
          'Please ensure the room and services are well-prepared for the customer’s arrival.\n\n'
          'If you need to contact the customer, you may reach them at: ${user?.userEmail}\n\n'
          'Thank you and have a great day!\n'
          'Warm regards,\n'
          'Io Mom App Team';



    try {
    await send(message, smtpServer);
    await send(messageCC, smtpServer);
    print('Booking confirmation sent to ${user?.userEmail}');
  } catch (e) {
    print('Error sending Booking confirmation: $e');
  }
}


Future<void> sendCollaborationRequestEmail(CollaborationRequest colRequest, String businessRegCert, String ic, String bankStatement, String Logo) async {
  final smtpServer = gmail(
    'pwen0331@gmail.com',
    'hjkl iegk aqrj zdla',
  );

  final adminMessage = Message()
    ..from = Address('pwen0331@gmail.com', 'My Flutter App')
    ..recipients.add('peilisa0331@gmail.com')
    ..subject = 'New Collaboration Request – ${colRequest.centerName}'
    ..text = 'Dear Admin,\n'
        'A new collaboration request has been submitted and requires your attention. Here are the details:\n\n'
        'Request ID: ${colRequest.RequestID}\n'
        'Center Name: ${colRequest.centerEmail}\n'
        'Contact Person: ${colRequest.contactPersonName}\n'
        'Business Registration No: ${colRequest.businessRegNo}\n'
        'Center Email: ${colRequest.centerEmail}\n'
        'Request Date: ${colRequest.requestDate.toLocal().toString().split(' ')[0]}\n'  // formatted as YYYY-MM-DD
        'Bank Name: ${colRequest.bankName}\n'
        'Account Number: ${colRequest.accountNo}'
        'Account Name: ${colRequest.accountName}'
        'Status: ${colRequest.status}'
        'Approval Date: ${colRequest.approveDate ?? "Not yet approved"}'
        'Location: ${colRequest.location} \n\n'
        'Please review this request and take the necessary action.\n\n'
        'Thank you,\n'
        'Io Mom App Team'
        ..attachments.add(FileAttachment(File(businessRegCert))
        ..location = Location.inline // or Location.attachment
        ..cid = 'BusinessRegCert')
        ..attachments.add(FileAttachment(File(ic))
        ..location = Location.inline // or Location.attachment
        ..cid = 'IC Copy')
        ..attachments.add(FileAttachment(File(bankStatement))
        ..location = Location.inline // or Location.attachment
        ..cid = 'Bank Statement')
        ..attachments.add(FileAttachment(File(Logo))
        ..location = Location.inline // or Location.attachment
        ..cid = 'Logo'); // optional, used for inline references

      final requestorMessage = Message()
    ..from = Address('pwen0331@gmail.com', 'Io Mom App')
    ..recipients.add(colRequest.centerEmail)
    ..subject = 'Thank You for Your Collaboration Request'
    ..text = 'Dear ${colRequest.contactPersonName},\n\n'
        'Thank you for submitting a collaboration request with us. '
        'Your request (ID: ${colRequest.RequestID}) has been received and will be reviewed by our team shortly.\n\n'
        'We will notify you once your request has been approved.\n\n'
        'Thank you for your interest in collaborating with us!\n\n'
        'Best regards,\n'
        'Io Mom App Team';

  try {
    await send(adminMessage, smtpServer);
    await send(requestorMessage, smtpServer);
    print('Collaboration Request sent to ${colRequest.centerEmail}');
  } catch (e) {
    print('Error sending Collaboration Request: $e');
  }
}




Future<void> sendTemporaryPasswordEmail(ConfinementCenter center, String tempPassword, String from) async {
  final smtpServer = gmail(
    'pwen0331@gmail.com',
    'vasg jojo xwnw skdb',
  );
  final message;
  if(from == 'Approved'){
    message = Message()
    ..from = Address('pwen0331@gmail.com', 'My Flutter App')
    ..recipients.add(center.centerEmail)
    ..subject = 'Your Account Details and Temporary Password'
    ..text = 'Dear ${center.CenterName},'
        'Your account has been successfully created. Please find your account details below:\n\n'
        'Account           : ${center.centerEmail}\n'
        'Temporary Password: $tempPassword\n\n'
        'For security reasons, we recommend that you log in and change your temporary password immediately.\n'
        'Thank you for joining us!\n'
        'Best regards,\n'
        'Io Mom App Team\n';
  }else{
    message = Message()
      ..from = Address('pwen0331@gmail.com', 'My Flutter App')
      ..recipients.add(center.centerEmail)
      ..subject = 'Collaboration Request Status Update'
      ..text = 'Dear ${center.CenterName},\n'
          'Thank you for your interest in collaborating with ${center.CenterName} and'
          'for taking the time to submit your application. After careful review of your '
          'documents and business profile, we regret to inform you that we are unable '
          'to proceed with your collaboration request at this time. This decision was '
          'made after considering several evaluation criteria to ensure consistent service '
          'quality and compliance with our partnership standards. Please understand that '
          'this outcome does not reflect negatively on your business as a whole, and '
          'you are welcome to reapply in the future should circumstances change or once '
          'all partnership requirements are met. If you need further clarification or '
          'would like feedback regarding your application, feel free to reach out to us '
          'at admin@iomom.com. We sincerely appreciate your interest in partnering with '
          'us and wish you continued success.\n\n'
          'Thank you!\n\n'
          'Best regards,\n'
          'Io Mom App Team\n';
  }
  try {
    await send(message, smtpServer);
    print('Account and Temporary Password sent to ${center.centerEmail}');
  } catch (e) {
    print('Error sending Account and Temporary Password: $e');
  }
}

