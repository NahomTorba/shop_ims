import 'dart:async';
import 'package:shop_ims/models/models.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;
  DatabaseHelper._internal();

  // Create the singleton instance of DatabaseHelper
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize the database
  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'shop_inventory.db');

    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        return db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    // User table
    batch.execute('''
      CREATE TABLE User (
        User_ID INTEGER PRIMARY KEY AUTOINCREMENT,
        Full_Name TEXT NOT NULL,
        Email TEXT NOT NULL UNIQUE,
        Password TEXT NOT NULL,
        Role TEXT NOT NULL
      )
    ''');

    // Supplier table
    batch.execute('''
      CREATE TABLE Supplier (
        Supplier_ID INTEGER PRIMARY KEY AUTOINCREMENT,
        Supplier_Name TEXT NOT NULL,
        Phone TEXT,
        Email TEXT,
        Address TEXT
      )
    ''');

    // Category table
    batch.execute('''
      CREATE TABLE Category (
        Category_ID INTEGER PRIMARY KEY AUTOINCREMENT,
        Category_Name TEXT NOT NULL UNIQUE,
        Description TEXT
      )
    ''');

    // Product table
    batch.execute('''
      CREATE TABLE Product (
        Product_ID INTEGER PRIMARY KEY AUTOINCREMENT,
        Product_Name TEXT NOT NULL,
        Description TEXT,
        Purchase_Price REAL NOT NULL,
        Sale_Price REAL NOT NULL,
        Stock_Quantity INTEGER NOT NULL,
        Product_Code TEXT UNIQUE,
        Expiration_Date TEXT,
        Low_Stock_Threshold INTEGER DEFAULT 5,
        Category_ID INTEGER,
        Supplier_ID INTEGER,
        FOREIGN KEY (Category_ID) REFERENCES Category(Category_ID) ON DELETE SET NULL,
        FOREIGN KEY (Supplier_ID) REFERENCES Supplier(Supplier_ID) ON DELETE SET NULL
      )
    ''');

    // Sale table
    batch.execute('''
      CREATE TABLE Sale (
        Sale_ID INTEGER PRIMARY KEY AUTOINCREMENT,
        Product_ID INTEGER NOT NULL,
        Quantity_Sold INTEGER NOT NULL,
        Unit_Price REAL NOT NULL,
        Total_Price REAL NOT NULL,
        Sale_Date TEXT NOT NULL,
        FOREIGN KEY (Product_ID) REFERENCES Product(Product_ID) ON DELETE CASCADE
      )
    ''');

    // Purchase table
    batch.execute('''
      CREATE TABLE Purchase (
        Purchase_ID INTEGER PRIMARY KEY AUTOINCREMENT,
        Product_ID INTEGER NOT NULL,
        Quantity_Purchased INTEGER NOT NULL,
        Unit_Price REAL NOT NULL,
        Total_Price REAL NOT NULL,
        Purchase_Date TEXT NOT NULL,
        FOREIGN KEY (Product_ID) REFERENCES Product(Product_ID) ON DELETE CASCADE
      )
    ''');

    // Transactions table
    batch.execute('''
      CREATE TABLE Transactions (
        Transaction_ID INTEGER PRIMARY KEY AUTOINCREMENT,
        Type TEXT NOT NULL,
        Amount REAL NOT NULL,
        Date TEXT NOT NULL,
        Description TEXT
      )
    ''');

    await batch.commit(noResult: true);
  }

  // General insert method
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace,);
  }

  // General update method
  Future<int> update(String table, Map<String, dynamic> data, String idColumn) async {
    final db = await database;
    return await db.update(
      table,
      data,
      where: '$idColumn = ?', // Customize for each model by passing column name dynamically
      whereArgs: [data[idColumn]], // Customize for each model
    );
  }

  // General delete method
  Future<int> delete(String table, int id, String idColumn) async {
    final db = await database;
    return await db.delete(
      table,
      where: '$idColumn = ?',
      whereArgs: [id],
    );
  }

  // General get method
  Future<List<Map<String, dynamic>>> getAll(String table) async {
    final db = await database;
    return await db.query(table);
  }

  // Get a user by email and password (for login functionality)
  Future<Map<String, dynamic>?> getUser(String email, String password) async {
    final db = await database;
    var result = await db.query(
      'User',
      where: 'Email = ? AND Password = ?', // Use email and password to fetch the user
      whereArgs: [email, password],
    );
    if (result.isNotEmpty) {
      return User.fromMap(result.first).toMap();
    } else {
      return null; // show try again message or No user found
    }
  }

  // Process sale (update inventory and record transaction)
  Future<void> processSale(Map<String, dynamic> transaction, List<Map<String, dynamic>> items) async {
    final db = await database;
    await db.transaction((txn) async {
      // Insert the transaction
      await txn.insert('Transaction', transaction);

      // Update stock for each item sold
      for (var item in items) {
        int productId = item['Product_ID'];
        int quantitySold = item['Quantity_Sold'];

        // Update the product stock quantity
        var product = await txn.query(
          'Product',
          where: 'Product_ID = ?',
          whereArgs: [productId],
        );

        if (product.isNotEmpty) {
          var updatedProduct = product.first;
          int updatedStock = (updatedProduct['Stock_Quantity'] as int) - quantitySold;

          // Update the product stock in the database
          await txn.update(
            'Product',
            {'Stock_Quantity': updatedStock},
            where: 'Product_ID = ?',
            whereArgs: [productId],
          );
        }

        // Insert the sale record
        await txn.insert('Sale', item);
      }
    });
  }
}
