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
  final String? productCode;
  final String? expirationDate;
  final int lowStockThreshold;
  final int? categoryId;
  final int? supplierId;
  final String? dateAdded;
  
  // Transient field for UI display, populated via JOINs
  final int? currentStock;

  Product({
    this.id,
    required this.name,
    this.description,
    required this.purchasePrice,
    required this.salePrice,
    this.productCode,
    this.expirationDate,
    this.lowStockThreshold = 5,
    this.categoryId,
    this.supplierId,
    this.dateAdded,
    this.currentStock,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['Product_ID'],
      name: map['Product_Name'],
      description: map['Description'],
      purchasePrice: map['Purchase_Price'],
      salePrice: map['Sale_Price'],
      productCode: map['Product_Code'],
      expirationDate: map['Expiration_Date'],
      lowStockThreshold: map['Low_Stock_Threshold'] ?? 5,
      categoryId: map['Category_ID'],
      supplierId: map['Supplier_ID'],
      dateAdded: map['Date_Added'],
      currentStock: map['Quantity'], // Populated from Stock table join
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'Product_ID': id,
      'Product_Name': name,
      'Description': description,
      'Purchase_Price': purchasePrice,
      'Sale_Price': salePrice,
      'Product_Code': productCode,
      'Expiration_Date': expirationDate,
      'Low_Stock_Threshold': lowStockThreshold,
      'Category_ID': categoryId,
      'Supplier_ID': supplierId,
      'Date_Added': dateAdded,
      // currentStock is NOT preserved in Product table
    };
  }
}

class Stock {
  final int productId;
  final int quantity;
  final String? lastUpdated;

  Stock({
    required this.productId,
    required this.quantity,
    this.lastUpdated,
  });

  factory Stock.fromMap(Map<String, dynamic> map) {
    return Stock(
      productId: map['Product_ID'],
      quantity: map['Quantity'],
      lastUpdated: map['Last_Updated'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'Product_ID': productId,
      'Quantity': quantity,
      'Last_Updated': lastUpdated,
    };
  }
}

class InventoryMovement {
  final int? movementId;
  final int productId;
  final int userId;
  final String movementType;
  final int quantity;
  final double? unitPrice;
  final String movementDate;
  final String? reason;

  InventoryMovement({
    this.movementId,
    required this.productId,
    required this.userId,
    required this.movementType,
    required this.quantity,
    this.unitPrice,
    required this.movementDate,
    this.reason,
  });

  factory InventoryMovement.fromMap(Map<String, dynamic> map) {
    return InventoryMovement(
      movementId: map['Movement_ID'],
      productId: map['Product_ID'],
      userId: map['User_ID'],
      movementType: map['Movement_Type'],
      quantity: map['Quantity'],
      unitPrice: map['Unit_Price'],
      movementDate: map['Movement_Date'],
      reason: map['Reason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'Movement_ID': movementId,
      'Product_ID': productId,
      'User_ID': userId,
      'Movement_Type': movementType,
      'Quantity': quantity,
      'Unit_Price': unitPrice,
      'Movement_Date': movementDate,
      'Reason': reason,
    };
  }
}