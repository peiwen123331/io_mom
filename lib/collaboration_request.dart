import 'package:cloud_firestore/cloud_firestore.dart';

class CollaborationRequest{

  final String RequestID;
  final String centerName;
  final String contactPersonName;
  final String businessRegNo;
  final String centerEmail;
  final DateTime requestDate;
  final String bankName;
  final String accountNo;
  final String accountName;
  final String status;
  final String? approveDate;
  final String location;

  CollaborationRequest({
    required this.RequestID,
    required this.centerName,
    required this.contactPersonName,
    required this.businessRegNo,
    required this.centerEmail,
    required this.requestDate,
    required this.bankName,
    required this.accountNo,
    required this.accountName,
    required this.status,
    this.approveDate,
    required this.location
});

  factory CollaborationRequest.fromMap(Map<String, dynamic> data){
    return CollaborationRequest(
        RequestID: data['RequestID'],
        centerName: data['centerName'],
        contactPersonName: data['contactPersonName'],
        businessRegNo:data['businessRegNo'],
        centerEmail: data['centerEmail'],
        requestDate: data['requestDate'] is Timestamp
            ? (data['requestDate'] as Timestamp).toDate()
            : (data['requestDate'] is String
            ? DateTime.tryParse(data['requestDate']) ?? DateTime.now()
            : DateTime.now()
        ),
        bankName: data['bankName'],
        accountNo: data['accountNo'],
        accountName: data['accountName'],
        status: data['status'],
        approveDate: data['approveDate'],
        location: data['location'],
    );
  }

  Map<String, dynamic> toMap(){
    return{
      'RequestID': RequestID,
      'centerName': centerName,
      'contactPersonName': contactPersonName,
      'businessRegNo': businessRegNo,
      'centerEmail':centerEmail,
      'requestDate':requestDate.toIso8601String(),
      'bankName': bankName,
      'accountNo': accountNo,
      'accountName': accountName,
      'status': status,
      'approveDate': approveDate,
      'location': location,
    };
  }








}