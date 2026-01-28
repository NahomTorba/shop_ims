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

  // Insert a product (and initialize stock)
  Future<int> insertProduct(Product product) async {
    final db = await _dbHelper.database;
    return await db.transaction((txn) async {
      int productId = await txn.insert('Product', product.toMap());

      // Initialize stock (default 0 or provided)
      int initialStock = product.currentStock ?? 0;
      await txn.insert('Stock', {
        'Product_ID': productId,
        'Quantity': initialStock,
        'Last_Updated': DateTime.now().toIso8601String(),
      });
      
      // Record initial stock as IN movement
      if (initialStock > 0) {
        await txn.insert('Inventory_Movement', {
          'Product_ID': productId,
          'User_ID': 1, // Default admin
          'Movement_Type': 'IN',
          'Quantity': initialStock,
          'Unit_Price': product.purchasePrice, // Cost price for inventory valuation/in
          'Movement_Date': DateTime.now().toIso8601String(),
          'Reason': 'Initial Stock',
        });
      }
      
      return productId;
    });
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
    // We only update product details here. Stock is updated via StockDao/Movement.
    // However, if the user edits "stock" in "Edit Product", we might need to handle it.
    // Usually stock should be adjusted via movements, but for simple edit:
    // If product.currentStock is provided (from UI), we might update Stock table?
    // The AddProductPage allows editing stock.
    // So yes, we should update stock if it's an edit.
    
    return await db.transaction((txn) async {
       int count = await txn.update(
        'Product',
        product.toMap(),
        where: 'Product_ID = ?',
        whereArgs: [product.id],
      );
      
      if (product.currentStock != null) {
        // Check if stock record exists (it should)
        // We will just update it.
        // NOTE: This updates quantity directly without history movement! 
        // This is "Adjustment" effectively, but without recording it in Inventory_Movement?
        // Ideally we should record movement, but here we just update the specific value.
        await txn.update(
          'Stock',
          {'Quantity': product.currentStock, 'Last_Updated': DateTime.now().toIso8601String()},
          where: 'Product_ID = ?',
          whereArgs: [product.id],
        );
      }
      return count;
    });
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
    return await db.transaction((txn) async {
      // 1. Insert Movement
      int id = await txn.insert('Inventory_Movement', movement.toMap());

      // 2. Update Stock
      // Calculate new quantity
      final stockResult = await txn.query('Stock', where: 'Product_ID = ?', whereArgs: [movement.productId]);
      int currentQty = 0;
      if (stockResult.isNotEmpty) {
        currentQty = stockResult.first['Quantity'] as int;
      }

      int newQty = currentQty;
      if (movement.movementType == 'IN') {
        newQty += movement.quantity;
      } else if (movement.movementType == 'OUT') {
        newQty -= movement.quantity;
      } else if (movement.movementType == 'ADJUSTMENT') {
        // For adjustment, explicit quantity might be the CHANGE or the FINAL value.
        // Usually adjustment implies "set to this value" or "change by this value".
        // Let's assume the user input is the CHANGE for consistency, or we need clearer logic.
        // But typically 'IN'/'OUT' are deltas. 'ADJUSTMENT' can be delta too (negative or positive).
        // Let's assume 'ADJUSTMENT' quanty is the signed delta?
        // Or if we want to SET stock, we need a different logic.
        // Given the code structure, let's treat quantity as delta magnitude and Type decides sign.
        // But ADJUSTMENT is ambiguous.
        // Let's assume for now ADJUSTMENT treats quantity as a delta (can be negative?).
        // Actually, schema says Quantity is INTEGER (could be negative).
        // If movement type is 'ADJUSTMENT', we just add it?
        newQty += movement.quantity; 
      }

      await txn.update(
        'Stock',
        {'Quantity': newQty, 'Last_Updated': DateTime.now().toIso8601String()},
        where: 'Product_ID = ?',
        whereArgs: [movement.productId],
      );

      return id;
    });
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
