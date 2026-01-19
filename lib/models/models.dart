class User {
  final int? id;
  final String fullName;
  final String email;
  final String? password;
  final String role;

  User({this.id, required this.fullName, required this.email, required this.password, required this.role});

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['User_ID'],
      fullName: map['Full_Name'],
      email: map['Email'],
      password: map['Password'],
      role: map['Role'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'User_ID': id,
      'Full_Name': fullName,
      'Email': email,
      'Password': password,
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

  Supplier({this.id, required this.name,  this.phone, this.email, this.address});

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

class Category {
  final int? id;
  final String name;
  final String? description;

  Category({this.id, required this.name, this.description});

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['Category_ID'],
      name: map['Category_Name'],
      description: map['Description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'Category_ID': id,
      'Category_Name': name,
      'Description': description,
    };
  }
}

class Product {
  final int? id;
  final String name;
  final String? description;
  final double purchasePrice;
  final double salePrice;
  final int stockQuantity;
  final String? productCode;
  final String? expirationDate;
  final int lowStockThreshold;
  final int? categoryId;
  final int? supplierId;
  final String? dateAdded;

  Product({
    this.id,
    required this.name,
    this.description,
    required this.purchasePrice,
    required this.salePrice,
    required this.stockQuantity,
    this.productCode,
    this.expirationDate,
    this.lowStockThreshold = 5,
    this.categoryId,
    this.supplierId,
    this.dateAdded,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['Product_ID'],
      name: map['Product_Name'],
      description: map['Description'],
      purchasePrice: map['Purchase_Price'],
      salePrice: map['Sale_Price'],
      stockQuantity: map['Stock_Quantity'],
      productCode: map['Product_Code'],
      expirationDate: map['Expiration_Date'],
      lowStockThreshold: map['Low_Stock_Threshold'] ?? 5,
      categoryId: map['Category_ID'],
      supplierId: map['Supplier_ID'],
      dateAdded: map['Date_Added'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'Product_ID': id,
      'Product_Name': name,
      'Description': description,
      'Purchase_Price': purchasePrice,
      'Sale_Price': salePrice,
      'Stock_Quantity': stockQuantity,
      'Product_Code': productCode,
      'Expiration_Date': expirationDate,
      'Low_Stock_Threshold': lowStockThreshold,
      'Category_ID': categoryId,
      'Supplier_ID': supplierId,
      'Date_Added': dateAdded,
    };
  }
}

class Sale {
  final int? id;
  final int productId;
  final int quantitySold;
  final double unitPrice;
  final double totalPrice;
  final String saleDate;

  Sale({
    this.id,
    required this.productId,
    required this.quantitySold,
    required this.unitPrice,
    required this.totalPrice,
    required this.saleDate,
  });

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['Sale_ID'],
      productId: map['Product_ID'],
      quantitySold: map['Quantity_Sold'],
      unitPrice: map['Unit_Price'],
      totalPrice: map['Total_Price'],
      saleDate: map['Sale_Date'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'Sale_ID': id,
      'Product_ID': productId,
      'Quantity_Sold': quantitySold,
      'Unit_Price': unitPrice,
      'Total_Price': totalPrice,
      'Sale_Date': saleDate,
    };
  }
}

class Purchase {
  final int? id;
  final int productId;
  final int quantityPurchased;
  final double unitPrice;
  final double totalPrice;
  final String purchaseDate;

  Purchase({
    this.id,
    required this.productId,
    required this.quantityPurchased,
    required this.unitPrice,
    required this.totalPrice,
    required this.purchaseDate,
  });

  factory Purchase.fromMap(Map<String, dynamic> map) {
    return Purchase(
      id: map['Purchase_ID'],
      productId: map['Product_ID'],
      quantityPurchased: map['Quantity_Purchased'],
      unitPrice: map['Unit_Price'],
      totalPrice: map['Total_Price'],
      purchaseDate: map['Purchase_Date'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'Purchase_ID': id,
      'Product_ID': productId,
      'Quantity_Purchased': quantityPurchased,
      'Unit_Price': unitPrice,
      'Total_Price': totalPrice,
      'Purchase_Date': purchaseDate,
    };
  }
}

class Transactions {
  final int? id;
  final String type;
  final double amount;
  final String date;
  final String? description;

  Transactions({
    this.id,
    required this.type,
    required this.amount,
    required this.date,
    this.description,
  });

  factory Transactions.fromMap(Map<String, dynamic> map) {
    return Transactions(
      id: map['Transaction_ID'],
      type: map['Type'],
      amount: map['Amount'],
      date: map['Date'],
      description: map['Description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'Transaction_ID': id,
      'Type': type,
      'Amount': amount,
      'Date': date,
      'Description': description,
    };
  }
}