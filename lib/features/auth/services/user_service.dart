import '../models/user.dart';
import '../models/user_entity.dart';
import '../models/user_role.dart';
import '../repositories/user_repository.dart';

class UserService {
  UserService._();

  static final UserService instance = UserService._();

  final UserRepository _repository = UserRepository();

  /// Attempts to authenticate a user.
/// Attempts to authenticate a user.
Future<User?> login({
  required String username,
  required String password,
}) async {

  final users = await getUsers();

   try {
    final result = users.firstWhere(
      (user) =>
          user.username == username &&
          user.passwordHash == password &&
          user.isActive,
    );


    return result;
  } on StateError {
       return null;
  }
}
  /// Returns all users.
  Future<List<User>> getUsers() async {
       final entities = await _repository.getAllUsers();

    return entities
        .map((entity) => entity.toUser())
        .toList(growable: false);
  }

  /// Generic user finder.
  ///
  /// Any supplied parameter is used as a filter.
  /// If multiple parameters are supplied, they must all match.
  Future<User?> findUser({
    String? id,
    String? username,
    String? password,
    int? driverId,
    UserRole? role,
    bool? isActive,
  }) async {
    assert(
      id != null ||
          username != null ||
          password != null ||
          driverId != null ||
          role != null ||
          isActive != null,
      'At least one search parameter must be provided.',
    );

    final users = await getUsers();

    try {
      return users.firstWhere((user) {
        if (id != null && user.id != id) {
          return false;
        }

        if (username != null && user.username != username) {
          return false;
        }

        if (password != null && user.passwordHash != password) {
          return false;
        }

        if (driverId != null && user.driverId != driverId) {
          return false;
        }

        if (role != null && user.role != role) {
          return false;
        }

        if (isActive != null && user.isActive != isActive) {
          return false;
        }

        return true;
      });
    } on StateError {
      return null;
    }
  }

  Future<User?> getUserById(
    String id,
  ) async {
    final entity = await _repository.getUserById(id);

    return entity?.toUser();
  }

  Future<User?> getUserByUsername(
    String username,
  ) async {
    final entity =
        await _repository.getUserByUsername(username);

    return entity?.toUser();
  }

  Future<User?> getUserByDriverId(
    int driverId,
  ) async {
    final entity =
        await _repository.getUserByDriverId(driverId);

    return entity?.toUser();
  }
    /// Adds a new user.
  Future<void> addUser(
    User user,
  ) async {
    await _repository.insertUser(
      UserEntity.fromUser(user),
    );
  }

  /// Updates an existing user.
  Future<void> updateUser(
    User user,
  ) async {
    await _repository.updateUser(
      UserEntity.fromUser(user),
    );
  }

  /// Saves a user.
  ///
  /// Updates an existing user if it already exists,
  /// otherwise creates a new one.
  Future<void> saveUser(
    User user,
  ) async {
    await _repository.saveUser(
      UserEntity.fromUser(user),
    );
  }

  /// Deletes a user.
  Future<void> deleteUser(
    String id,
  ) async {
    await _repository.deleteUser(id);
  }
}