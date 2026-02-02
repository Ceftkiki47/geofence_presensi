class AttendanceModel {
  final int? id;
  final int? userId;
  final String kategori;
  final String status;
  final DateTime tanggal;
  final String? alasan;
  final String? photoUrl;

  AttendanceModel({
    this.id,
    required this.userId,
    required this.kategori,
    required this.status,
    required this.tanggal,
    required this.alasan,
    required this.photoUrl,
  });

  ///FROM JSON
  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'],
      userId: json['userId'],
      kategori: json['kategori'],
      status: json['status'],
      tanggal: json['tanggal'],
      alasan: json['alasan'],
      photoUrl: json['photoUrl'],
    );
  }
}
