import 'package:sqflite/sqflite.dart';

import '../../../database/app_database.dart';
import '../models/user_entity.dart';
import '../models/user_role.dart';

class UserRepository {
  UserRepository({AppDatabase? database})
    : _database = database ?? AppDatabase();

  final AppDatabase _database;

  Future<Database> get _db async => await _database.database();

  Future<List<UserEntity>> getAllUsers() async {
    final db = await _db;

    final result = await db.query('users', orderBy: 'username');

    return result.map(UserEntity.fromMap).toList(growable: false);
  }

  Future<UserEntity?> getUserById(String id) async {
    final db = await _db;

    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return UserEntity.fromMap(result.first);
  }

  Future<UserEntity?> getUserByUsername(String username) async {
    final db = await _db;

    final result = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return UserEntity.fromMap(result.first);
  }

  Future<UserEntity?> getUserByDriverId(int driverId) async {
    final db = await _db;

    final result = await db.query(
      'users',
      where: 'driver_id = ?',
      whereArgs: [driverId],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return UserEntity.fromMap(result.first);
  }

  Future<void> insertUser(UserEntity user) async {
    final db = await _db;

    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  /// Returns whether a usable Administrator account exists.
  Future<bool> hasActiveAdministrator() async {
    final db = await _db;
    final result = await db.query(
      'users',
      columns: const ['id'],
      where: 'role = ? AND is_active = ?',
      whereArgs: [UserRole.admin.name, 1],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  Future<bool> hasAnotherActiveAdministrator(String excludedUserId) async {
    final db = await _db;
    final result = await db.query(
      'users',
      columns: const ['id'],
      where: 'role = ? AND is_active = ? AND id != ?',
      whereArgs: [UserRole.admin.name, 1, excludedUserId],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  /// Creates the initial Administrator only while none exists.
  ///
  /// The check and insert share a transaction so simultaneous first-run
  /// screens cannot both provision an Administrator.
  Future<bool> insertFirstAdministrator(UserEntity user) async {
    final db = await _db;

    return db.transaction((transaction) async {
      final existing = await transaction.query(
        'users',
        columns: const ['id'],
        where: 'role = ? AND is_active = ?',
        whereArgs: [UserRole.admin.name, 1],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        return false;
      }

      await transaction.insert(
        'users',
        user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      return true;
    });
  }

  Future<void> updateUser(UserEntity user) async {
    final db = await _db;

    await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<void> saveUser(UserEntity user) async {
    final existing = await getUserById(user.id);

    if (existing == null) {
      await insertUser(user);
    } else {
      await updateUser(user);
    }
  }

  Future<void> deleteUser(String id) async {
    final db = await _db;

    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }
}
