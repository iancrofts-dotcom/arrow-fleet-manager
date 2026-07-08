import 'app_database.dart';

class DatabaseService {
  final AppDatabase _database = AppDatabase();

  Future<AppDatabase> initialize() async {
    await _database.database();
    return _database;
  }

  AppDatabase get database => _database;
}