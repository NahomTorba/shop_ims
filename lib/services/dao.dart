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

