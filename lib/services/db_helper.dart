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
      version: 6,
      onConfigure: (db) async {
        return db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Version 2: Add Date_Added column to Product table
      await db.execute('ALTER TABLE Product ADD COLUMN Date_Added TEXT');
    }
    if (oldVersion < 6) {
      // Version 6: Add Triggers and Views
      await _createTriggersAndViews(db);
    }
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
        Product_Code TEXT UNIQUE,
        Expiration_Date TEXT,
        Low_Stock_Threshold INTEGER DEFAULT 5,
        Category_ID INTEGER,
        Supplier_ID INTEGER,
        Date_Added TEXT,
        FOREIGN KEY (Category_ID) REFERENCES Category(Category_ID) ON DELETE SET NULL,
        FOREIGN KEY (Supplier_ID) REFERENCES Supplier(Supplier_ID) ON DELETE SET NULL
      )
    ''');

    // Stock table (correct FK)
    batch.execute('''
      CREATE TABLE Stock (
        Product_ID INTEGER PRIMARY KEY,
        Quantity INTEGER NOT NULL DEFAULT 0,
        Last_Updated TEXT,
        FOREIGN KEY (Product_ID) REFERENCES Product(Product_ID) ON DELETE CASCADE
      )
    ''');

    // Inventory movement table
    batch.execute('''
      CREATE TABLE Inventory_Movement (
        Movement_ID INTEGER PRIMARY KEY AUTOINCREMENT,
        Product_ID INTEGER NOT NULL,
        User_ID INTEGER NOT NULL,
        Movement_Type TEXT NOT NULL,
        Quantity INTEGER NOT NULL,
        Unit_Price REAL,
        Movement_Date TEXT NOT NULL,
        Reason TEXT,
        FOREIGN KEY (Product_ID) REFERENCES Product(Product_ID) ON DELETE CASCADE,
        FOREIGN KEY (User_ID) REFERENCES User(User_ID)
      )
    ''');

    await batch.commit(noResult: true);
    
    // Create Triggers and Views
    await _createTriggersAndViews(db);
  }

  static Future<void> _createTriggersAndViews(Database db) async {
    // 1. Trigger: After Product Insert - Initialize Stock
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS after_product_insert
      AFTER INSERT ON Product
      FOR EACH ROW
      BEGIN
        INSERT INTO Stock (Product_ID, Quantity, Last_Updated)
        VALUES (NEW.Product_ID, 0, datetime('now'));
      END;
    ''');

    // 2. Trigger: Before Inventory Movement Insert - Validation
    // Check if stock record exists
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS validate_stock_exists_before_movement
      BEFORE INSERT ON Inventory_Movement
      FOR EACH ROW
      BEGIN
        SELECT RAISE(ABORT, 'Stock record does not exist for this product.')
        WHERE NOT EXISTS (SELECT 1 FROM Stock WHERE Product_ID = NEW.Product_ID);
      END;
    ''');

    // Check for insufficient stock on OUT
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS validate_stock_quantity_before_out
      BEFORE INSERT ON Inventory_Movement
      FOR EACH ROW
      WHEN NEW.Movement_Type = 'OUT'
      BEGIN
        SELECT RAISE(ABORT, 'Insufficient stock: cannot remove more items than available.')
        FROM Stock
        WHERE Product_ID = NEW.Product_ID AND Quantity < NEW.Quantity;
      END;
    ''');

    // 3. Triggers: After Inventory Movement Insert - Update Stock
    // SQLite triggers don't support IF/ELSEIF, so we use WHEN clauses
    
    // Handle IN
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS update_stock_after_in
      AFTER INSERT ON Inventory_Movement
      FOR EACH ROW
      WHEN NEW.Movement_Type = 'IN'
      BEGIN
        UPDATE Stock
        SET Quantity = Quantity + NEW.Quantity,
            Last_Updated = datetime('now')
        WHERE Product_ID = NEW.Product_ID;
      END;
    ''');

    // Handle OUT
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS update_stock_after_out
      AFTER INSERT ON Inventory_Movement
      FOR EACH ROW
      WHEN NEW.Movement_Type = 'OUT'
      BEGIN
        UPDATE Stock
        SET Quantity = Quantity - NEW.Quantity,
            Last_Updated = datetime('now')
        WHERE Product_ID = NEW.Product_ID;
      END;
    ''');

    // Handle ADJUSTMENT
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS update_stock_after_adjustment
      AFTER INSERT ON Inventory_Movement
      FOR EACH ROW
      WHEN NEW.Movement_Type = 'ADJUSTMENT'
      BEGIN
        UPDATE Stock
        SET Quantity = NEW.Quantity,
            Last_Updated = datetime('now')
        WHERE Product_ID = NEW.Product_ID;
      END;
    ''');

    // 4. View: Inventory Status
    await db.execute('''
      CREATE VIEW IF NOT EXISTS v_inventory_status AS
      SELECT
        p.Product_ID,
        p.Product_Name,
        c.Category_Name,
        s.Quantity,
        p.Low_Stock_Threshold
      FROM Product p
      JOIN Stock s ON p.Product_ID = s.Product_ID
      LEFT JOIN Category c ON p.Category_ID = c.Category_ID
    ''');

    // 5. View: Low Stock Products
    await db.execute('''
      CREATE VIEW IF NOT EXISTS v_low_stock_products AS
      SELECT
        p.Product_ID,
        p.Product_Name,
        s.Quantity,
        p.Low_Stock_Threshold
      FROM Product p
      JOIN Stock s ON p.Product_ID = s.Product_ID
      WHERE s.Quantity <= p.Low_Stock_Threshold
    ''');
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

  Future<void> createDefaultAdmin() async {
    final db = await database;

    final result = await db.query(
      'User',
      where: 'Email = ?',
      whereArgs: ['admin@shop.com'],
      limit: 1,
    );

    if (result.isEmpty) {
      await db.insert('User', {
        'Full_Name': 'Admin',
        'Email': 'admin@shop.com',
        'Password': 'admin123',
        'Role': 'Admin',
      });
    }
  }
}
