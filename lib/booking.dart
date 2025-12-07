import 'package:cloud_firestore/cloud_firestore.dart';

class Booking{

  final String BookingID;
  final DateTime bookingDate;
  final DateTime checkInDate;
  final double payAmount;
  final String paymentStatus;
  final String userID;
  final String PackageID;
  String checkOutStatus;


  Booking({
    required this.BookingID,
    required this.bookingDate,
    required this.checkInDate,
    required this.payAmount,
    required this.paymentStatus,
    required this.userID,
    required this.PackageID,
    required this.checkOutStatus,
  });

  factory Booking.fromMap(Map<String, dynamic> data){
    return Booking(
      BookingID: data['BookingID'],
      bookingDate: data['bookingDate'] is Timestamp
          ? (data['bookingDate'] as Timestamp).toDate()
          : (data['bookingDate'] is String
          ? DateTime.tryParse(data['bookingDate']) ?? DateTime.now()
          : DateTime.now()),
      checkInDate: data['checkInDate'] is Timestamp
          ? (data['checkInDate'] as Timestamp).toDate()
          : (data['checkInDate'] is String
          ? DateTime.tryParse(data['checkInDate']) ?? DateTime.now()
          : DateTime.now()),
      payAmount: (data['payAmount'] is String)
          ? double.tryParse(data['payAmount']) ?? 0.0
          : (data['payAmount'] is num
          ? (data['payAmount'] as num).toDouble()
          : 0.0),
      paymentStatus: data['paymentStatus'],
      userID: data['userID'],
      PackageID: data['PackageID'],
      checkOutStatus: data['checkOutStatus'],
    );
  }

  Map<String, dynamic> toMap(){
    return{
      'BookingID':BookingID,
      'bookingDate': bookingDate.toIso8601String(),
      'checkInDate': checkInDate.toIso8601String(),
      'payAmount': payAmount,
      'paymentStatus':paymentStatus,
      'userID': userID,
      'PackageID':  PackageID,
      'checkOutStatus': checkOutStatus,
    };
  }





}