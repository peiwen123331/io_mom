class RTHealthData{

  final double PulseRate;
  final double bodyTemp;
  final double SpO2;




  RTHealthData({
    required this.PulseRate,
    required this.bodyTemp,
    required this.SpO2,
  });


  factory RTHealthData.fromMap(Map<String,dynamic> data){
    return RTHealthData(
      PulseRate: (data['HeartRate']?['bpm'] ?? 0).toDouble(),
      SpO2: (data['SpO2']?['percent'] ?? 0).toDouble(),
      bodyTemp: (data['Temperature']?['Celsius'] ?? 0).toDouble(),

    );
  }

}