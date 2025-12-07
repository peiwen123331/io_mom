import 'package:cloud_firestore/cloud_firestore.dart';

class Transactions{

  final String TransactionID;
  final DateTime transactionDate;
  final double amount;
  final String status;
  final String BookingID;

  Transactions({
    required this.TransactionID,
    required this.transactionDate,
    required this.amount,
    required this.status,
    required this.BookingID,
});

  factory Transactions.fromMap(Map<String, dynamic> data){
    return Transactions(
        TransactionID: data['TransactionID'],
        transactionDate: data['transactionDate'] is Timestamp
            ? (data['transactionDate'] as Timestamp).toDate()
            : (data['transactionDate'] is String
            ? DateTime.tryParse(data['transactionDate']) ?? DateTime.now()
            : DateTime.now()),
        amount: data['amount'] is num
            ? (data['amount'] as num).toDouble()
            : double.tryParse(data['amount'].toString()) ?? 0.0,
        status: data['status'],
        BookingID: data['BookingID']
    );
  }

  Map<String, dynamic> toMap(){
    return {
      'TransactionID':TransactionID,
      'transactionDate': transactionDate.toIso8601String(),
      'amount': amount,
      'status':status,
      'BookingID':BookingID,
    };
  }






}