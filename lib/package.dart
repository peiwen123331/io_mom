class Package{

  final String PackageID;
  final String packageName;
  final int duration;
  final String description;
  final double price;
  int availability;
  final String status;
  final String CenterID;


  Package({
    required this.PackageID,
    required this.packageName,
    required this.duration,
    required this.description,
    required this.price,
    required this.availability,
    required this.status,
    required this.CenterID,
  });

  factory Package.fromMap(Map<String, dynamic> data){
    return Package(
      PackageID: data['PackageID'],
      packageName: data['packageName'],
      duration: data['duration'],
      description: data['description'],
      price: data['price'] is num
          ? (data['price'] as num).toDouble()
          : double.tryParse(data['price'].toString()) ?? 0.0,
      availability: data['availability'] is num
          ? (data['availability'] as num).toInt()
          : int.tryParse(data['availability'].toString()) ?? 0,
      status: data['status'],
      CenterID: data['CenterID'],
    );
  }

  Map<String, dynamic> toMap(){
    return{
      'PackageID':PackageID,
      'packageName': packageName,
      'duration': duration,
      'description': description,
      'price':price,
      'availability': availability,
      'status':  status,
      'CenterID': CenterID,

    };
  }

  static Package empty() => Package(
    PackageID: "",
    packageName: "Unknown",
    duration: 0,
    description: "",
    price: 0,
    availability: 0,
    status: "Unavailable",
    CenterID: "",
  );



}