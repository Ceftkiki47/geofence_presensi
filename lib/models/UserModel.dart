class userModel {
  final String uid;
  final String nama;
  final String email;
  final bool insideZone;


  userModel ({
    required this.uid,
    required this.nama,
    required this.email,
    required this.insideZone,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nama': nama,
      'email': email,
      'insideZone': insideZone,
      'createAt': DateTime.now(),
    };  
  }
}