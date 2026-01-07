import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;

  // Create the singleton instance of DatabaseHelper
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize the database
  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'shop_inventory.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        // Create tables here
        db.execute('''
          CREATE TABLE User(
            User_ID INTEGER PRIMARY KEY AUTOINCREMENT,
            Full_Name TEXT,
            Email TEXT,
            Role TEXT
          )
        ''');
        db.execute('''
          CREATE TABLE Supplier(
            Supplier_ID INTEGER PRIMARY KEY AUTOINCREMENT,
            Supplier_Name TEXT,
            Phone TEXT,
            Email TEXT,
            Address TEXT
          )
        ''');
        db.execute('''
          CREATE TABLE Category(
            Category_ID INTEGER PRIMARY KEY AUTOINCREMENT,
            Category_Name TEXT,
            Description TEXT
          )
        ''');
        db.execute('''
          CREATE TABLE Product(
            Product_ID INTEGER PRIMARY KEY AUTOINCREMENT,
            Product_Name TEXT,
            Description TEXT,
            Purchase_Price REAL,
            Sale_Price REAL,
            Stock_Quantity INTEGER,
            Product_Code TEXT,
            Expiration_Date TEXT,
            Low_Stock_Threshold INTEGER,
            Category_ID INTEGER,
            Supplier_ID INTEGER
          )
        ''');
        db.execute('''
          CREATE TABLE Sale(
            Sale_ID INTEGER PRIMARY KEY AUTOINCREMENT,
            Product_ID INTEGER,
            Quantity_Sold INTEGER,
            Unit_Price REAL,
            Total_Price REAL,
            Sale_Date TEXT
          )
        ''');
        db.execute('''
          CREATE TABLE Purchase(
            Purchase_ID INTEGER PRIMARY KEY AUTOINCREMENT,
            Product_ID INTEGER,
            Quantity_Purchased INTEGER,
            Unit_Price REAL,
            Total_Price REAL,
            Purchase_Date TEXT
          )
        ''');
        db.execute('''
          CREATE TABLE Transaction(
            Transaction_ID INTEGER PRIMARY KEY AUTOINCREMENT,
            Type TEXT,
            Amount REAL,
            Date TEXT,
            Description TEXT
          )
        ''');
      },
    );
  }

  // General insert method
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data);
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
      where: 'Email = ? AND Role = ?', // Use email and password to fetch the user
      whereArgs: [email, password],
    );
    if (result.isNotEmpty) {
      return result.first;
    } else {
      return null; // No user found
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
          int updatedStock = updatedProduct['Stock_Quantity'] - quantitySold;

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
