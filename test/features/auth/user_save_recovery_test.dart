import 'package:arrow_fleet_manager/features/auth/models/user.dart';
import 'package:arrow_fleet_manager/features/auth/models/user_entity.dart';
import 'package:arrow_fleet_manager/features/auth/models/user_role.dart';
import 'package:arrow_fleet_manager/features/auth/repositories/user_repository.dart';
import 'package:arrow_fleet_manager/features/auth/services/user_service.dart';
import 'package:arrow_fleet_manager/features/auth/widgets/user_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'username availability excludes the User currently being edited',
    () async {
      final users = _FakeUserRepository()
        ..seed(_user('first', 'first.username'))
        ..seed(_user('second', 'second.username'));
      final service = UserService(repository: users);

      expect(
        await service.isUsernameAvailable(
          'first.username',
          excludingUserId: 'first',
        ),
        isTrue,
      );
      expect(
        await service.isUsernameAvailable(
          'second.username',
          excludingUserId: 'first',
        ),
        isFalse,
      );
      expect(
        (await service.getUserById('second'))!.username,
        'second.username',
      );
    },
  );

  testWidgets(
    'UserForm resets saving state after a failed save so it can retry',
    (tester) async {
      var attempts = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserForm(
              onSave: (_, _, _, _) async {
                attempts++;
                throw StateError('Write failed');
              },
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'new.user');
      await tester.enterText(find.byType(TextFormField).at(1), 'password');
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      await tester.pump();

      expect(attempts, 1);
      expect(find.text('Unable to save the user. Try again.'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );

      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      await tester.pump();
      expect(attempts, 2);
    },
  );
}

User _user(String id, String username) => User(
  id: id,
  username: username,
  passwordHash: 'hash',
  role: UserRole.manager,
);

class _FakeUserRepository extends UserRepository {
  final _users = <String, UserEntity>{};

  void seed(User user) {
    _users[user.id] = UserEntity.fromUser(user);
  }

  @override
  Future<UserEntity?> getUserByUsername(String username) async {
    for (final user in _users.values) {
      if (user.username == username) return user;
    }
    return null;
  }

  @override
  Future<UserEntity?> getUserById(String id) async => _users[id];
}
