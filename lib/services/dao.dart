import 'package:shop_ims/models/models.dart';
import 'package:shop_ims/services/db_helper.dart';

class UserDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Insert a user
  Future<int> insertUser(User user) async {
    final db = await _dbHelper.database;
    return await db.insert('User', user.toMap());
  }

  // Get all users
  Future<List<User>> getUsers() async {
    final db = await _dbHelper.database;
    final result = await db.query('User');
    return result.map((json) => User.fromMap(json)).toList();
  }

  // Get user by email and password (for login)
  Future<User?> login(String email, String password) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'User',
      where: 'Email = ? AND Password = ?',
      whereArgs: [email, password],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }

  // Update a user
  Future<int> updateUser(User user) async {
    final db = await _dbHelper.database;
    return await db.update(
      'User',
      user.toMap(),
      where: 'User_ID = ?',
      whereArgs: [user.id],
    );
  }

  // Delete a user
  Future<int> deleteUser(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'User',
      where: 'User_ID = ?',
      whereArgs: [id],
    );
  }
}

class SupplierDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Insert a supplier
  Future<int> insertSupplier(Supplier supplier) async {
    final db = await _dbHelper.database;
    return await db.insert('Supplier', supplier.toMap());
  }

  // Get all suppliers
  Future<List<Supplier>> getSuppliers() async {
    final db = await _dbHelper.database;
    final result = await db.query('Supplier');
    return result.map((json) => Supplier.fromMap(json)).toList();
  }

  // Update a supplier
  Future<int> updateSupplier(Supplier supplier) async {
    final db = await _dbHelper.database;
    return await db.update(
      'Supplier',
      supplier.toMap(),
      where: 'Supplier_ID = ?',
      whereArgs: [supplier.id],
    );
  }

  // Delete a supplier
  Future<int> deleteSupplier(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'Supplier',
      where: 'Supplier_ID = ?',
      whereArgs: [id],
    );
  }
}

class CategoryDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Insert a category
  Future<int> insertCategory(Category category) async {
    final db = await _dbHelper.database;
    return await db.insert('Category', category.toMap());
  }

  // Get all categories
  Future<List<Category>> getCategories() async {
    final db = await _dbHelper.database;
    final result = await db.query('Category');
    return result.map((json) => Category.fromMap(json)).toList();
  }

  // Update a category
  Future<int> updateCategory(Category category) async {
    final db = await _dbHelper.database;
    return await db.update(
      'Category',
      category.toMap(),
      where: 'Category_ID = ?',
      whereArgs: [category.id],
    );
  }

  // Delete a category
  Future<int> deleteCategory(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'Category',
      where: 'Category_ID = ?',
      whereArgs: [id],
    );
  }
}

class ProductDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Insert a product (Stock initialized by trigger)
  Future<int> insertProduct(Product product) async {
    final db = await _dbHelper.database;
    return await db.insert('Product', product.toMap());
  }

  // Get all products with current stock
  Future<List<Product>> getProducts() async {
    final db = await _dbHelper.database;
    // Join Product and Stock tables
    final result = await db.rawQuery('''
      SELECT p.*, s.Quantity 
      FROM Product p
      LEFT JOIN Stock s ON p.Product_ID = s.Product_ID
    ''');
    return result.map((json) => Product.fromMap(json)).toList();
  }

  // Get product by ID with current stock
  Future<Product?> getProductById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT p.*, s.Quantity 
      FROM Product p
      LEFT JOIN Stock s ON p.Product_ID = s.Product_ID
      WHERE p.Product_ID = ?
    ''', [id]);

    if (result.isNotEmpty) {
      return Product.fromMap(result.first);
    }
    return null;
  }

  // Update a product
  Future<int> updateProduct(Product product) async {
    final db = await _dbHelper.database;
    return await db.update(
        'Product',
        product.toMap(),
        where: 'Product_ID = ?',
        whereArgs: [product.id],
      );
  }

  // Delete a product
  Future<int> deleteProduct(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'Product',
      where: 'Product_ID = ?',
      whereArgs: [id],
    );
  }
}

class StockDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> updateStock(int productId, int quantity) async {
    final db = await _dbHelper.database;
    return await db.update(
      'Stock',
      {'Quantity': quantity, 'Last_Updated': DateTime.now().toIso8601String()},
      where: 'Product_ID = ?',
      whereArgs: [productId],
    );
  }

  Future<Stock?> getStock(int productId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'Stock',
      where: 'Product_ID = ?',
      whereArgs: [productId],
    );
    if (result.isNotEmpty) {
      return Stock.fromMap(result.first);
    }
    return null;
  }
}

class InventoryMovementDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insertMovement(InventoryMovement movement) async {
    final db = await _dbHelper.database;
    return await db.insert('Inventory_Movement', movement.toMap());
  }

  Future<List<InventoryMovement>> getMovements() async {
    final db = await _dbHelper.database;
    final result = await db.query('Inventory_Movement', orderBy: 'Movement_Date DESC');
    return result.map((json) => InventoryMovement.fromMap(json)).toList();
  }
  
  Future<List<InventoryMovement>> getMovementsByProduct(int productId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'Inventory_Movement', 
      where: 'Product_ID = ?', 
      whereArgs: [productId],
      orderBy: 'Movement_Date DESC'
    );
    return result.map((json) => InventoryMovement.fromMap(json)).toList();
  }
}
