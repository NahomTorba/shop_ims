class User {
  final int? id;
  final String fullName;
  final String email;
  final String role;

  User({this.id, required this.fullName, required this.email, required this.role});

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['User_ID'],
      fullName: map['Full_Name'],
      email: map['Email'],
      role: map['Role'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'User_ID': id,
      'Full_Name': fullName,
      'Email': email,
      'Role': role,
    };
  }
}