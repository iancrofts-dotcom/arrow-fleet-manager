import 'app_database.dart';

class DatabaseService {
  DatabaseService({AppDatabase? database}) : _database = database ?? AppDatabase();

  final AppDatabase _database;

  Future<AppDatabase> initialize() async {
    await _database.database();
    return _database;
  }

  AppDatabase get database => _database;
}
