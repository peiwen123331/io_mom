
class ConfinementCenter{

  final String CenterID;
  final String CenterName;
  final String ContactPersonName;
  final String? centerContact;
  final String centerEmail;
  final String location;
  final String? description;
  final String? centerImgPath;
  final String accountNo;
  final String accountName;
  final String bankName;

  ConfinementCenter({
   required this.CenterID,
   required this.CenterName,
   required this.ContactPersonName,
    this.centerContact,
   required this.centerEmail,
   required this.location,
    this.description,
     this.centerImgPath,
    required this.accountNo,
    required this.accountName,
    required this.bankName,
});

  factory ConfinementCenter.fromMap(Map<String, dynamic> data){
    return ConfinementCenter(
      CenterID: data['CenterID'],
      CenterName: data['CenterName'],
      ContactPersonName: data['ContactPersonName'],
      centerContact: data['centerContact'],
      centerEmail: data['centerEmail'],
      location: data['location'],
      description: data['description'],
      centerImgPath: data['centerImgPath'],
      accountNo: data['accountNo'],
      accountName: data['accountName'],
      bankName: data['bankName'],
    );
  }

  Map<String, dynamic> toMap(){
    return{
      'CenterID':CenterID,
      'CenterName': CenterName,
      'ContactPersonName':ContactPersonName,
      'centerContact': centerContact,
      'centerEmail':  centerEmail,
      'location': location,
      'description': description,
      'centerImgPath': centerImgPath,
      'accountNo':accountNo,
      'accountName': accountName,
      'bankName': bankName,
    };
  }

  static ConfinementCenter empty() =>ConfinementCenter(
      CenterID: '',
      CenterName: '',
      ContactPersonName: '',
      centerContact: '',
      centerEmail: '',
      location: '',
      description: '',
      centerImgPath: '',
      accountNo: '',
      accountName: '',
      bankName: '',
    );





}