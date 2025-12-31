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

class Supplier {
  final int? id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;

  Supplier({this.id, required this.name, this.phone, this.email, this.address});

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['Supplier_ID'],
      name: map['Supplier_Name'],
      phone: map['Phone'],
      email: map['Email'],
      address: map['Address'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'Supplier_ID': id,
      'Supplier_Name': name,
      'Phone': phone,
      'Email': email,
      'Address': address,
    };
  }
}