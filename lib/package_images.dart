class PackageImages{

  final String PackageID;
  final String packageImgPath;

  PackageImages({
    required this.PackageID,
    required this.packageImgPath,
});

  factory PackageImages.fromMap(Map<String, dynamic> data){
    return PackageImages(
      PackageID: data['PackageID'],
      packageImgPath: data['packageImgPath'],
    );
  }

  Map<String, dynamic> toMap(){
   return{
     'PackageID': PackageID,
     'packageImgPath': packageImgPath,
   };
  }


}