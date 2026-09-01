import 'package:arrow_fleet_manager/features/auth/models/user.dart';
import 'package:arrow_fleet_manager/features/auth/models/user_entity.dart';
import 'package:arrow_fleet_manager/features/auth/models/user_role.dart';
import 'package:arrow_fleet_manager/features/auth/repositories/user_repository.dart';
import 'package:arrow_fleet_manager/features/auth/services/password_service.dart';
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

  test(
    'addUser rejects a seven-character password before persistence',
    () async {
      final users = _FakeUserRepository();
      final service = UserService(repository: users);

      expect(
        () => service.addUser(_user('new', 'new.user'), password: '1234567'),
        throwsArgumentError,
      );
      expect(await service.getUserById('new'), isNull);
    },
  );

  test(
    'addUser accepts an eight-character password and stores a hash',
    () async {
      final users = _FakeUserRepository();
      final service = UserService(repository: users);

      await service.addUser(_user('new', 'new.user'), password: '12345678');

      final saved = await service.getUserById('new');
      expect(saved, isNotNull);
      expect(saved!.passwordHash, isNot('12345678'));
    },
  );

  test(
    'addUser rejects an unlinked Driver account before persistence',
    () async {
      final users = _FakeUserRepository();
      final service = UserService(repository: users);
      final invalidDriver = User(
        id: 'driver',
        username: 'invalid.driver',
        passwordHash: '',
        role: UserRole.driver,
      );

      await expectLater(
        service.addUser(invalidDriver, password: '12345678'),
        throwsA(
          isA<UserManagementException>().having(
            (error) => error.message,
            'message',
            'Driver accounts must be created from Driver Management.',
          ),
        ),
      );
      expect(await service.getUserById(invalidDriver.id), isNull);
    },
  );

  test(
    'addUser permits a linked Driver account and hashes its password',
    () async {
      final users = _FakeUserRepository();
      final service = UserService(repository: users);
      final linkedDriver = User(
        id: 'driver',
        username: 'linked.driver',
        passwordHash: '',
        role: UserRole.driver,
        driverId: 7,
      );

      await service.addUser(linkedDriver, password: '12345678');

      final saved = await service.getUserById(linkedDriver.id);
      expect(saved!.role, UserRole.driver);
      expect(saved.driverId, 7);
      expect(saved.passwordHash, isNot('12345678'));
    },
  );

  test(
    'updateUser cannot convert a non-Driver account to unlinked Driver',
    () async {
      final original = _user('manager', 'manager.user');
      final users = _FakeUserRepository()..seed(original);
      final service = UserService(repository: users);

      await expectLater(
        service.updateUser(original.copyWith(role: UserRole.driver)),
        throwsA(isA<UserManagementException>()),
      );
      expect((await service.getUserById(original.id))!.role, UserRole.manager);
    },
  );

  test('updateUser permits ordinary non-Driver role changes', () async {
    final original = _user('manager', 'manager.user');
    final users = _FakeUserRepository()..seed(original);
    final service = UserService(repository: users);

    await service.updateUser(original.copyWith(role: UserRole.workshop));

    expect((await service.getUserById(original.id))!.role, UserRole.workshop);
  });

  test(
    'legacy unlinked Driver account can be converted to a generic role',
    () async {
      final legacyDriver = User(
        id: 'legacy-driver',
        username: 'legacy.driver',
        passwordHash: 'hash',
        role: UserRole.driver,
      );
      final users = _FakeUserRepository()..seed(legacyDriver);
      final service = UserService(repository: users);

      await service.updateUser(
        legacyDriver.copyWith(role: UserRole.technician),
      );

      final saved = await service.getUserById(legacyDriver.id);
      expect(saved!.role, UserRole.technician);
      expect(saved.driverId, isNull);
    },
  );

  test('createFirstAdministrator rejects a seven-character password', () async {
    final users = _FakeUserRepository();
    final service = UserService(repository: users);

    expect(
      () => service.createFirstAdministrator(
        _user('admin', 'first.admin'),
        password: '1234567',
      ),
      throwsArgumentError,
    );
    expect(await service.getUserById('admin'), isNull);
  });

  test(
    'createFirstAdministrator accepts eight characters and stores a hash',
    () async {
      final users = _FakeUserRepository();
      final service = UserService(repository: users);

      final created = await service.createFirstAdministrator(
        _user('admin', 'first.admin'),
        password: '12345678',
      );

      final saved = await service.getUserById('admin');
      expect(created, isTrue);
      expect(saved, isNotNull);
      expect(saved!.role, UserRole.admin);
      expect(saved.isActive, isTrue);
      expect(saved.passwordHash, isNot('12345678'));
    },
  );

  test('updateUser rejects a seven-character replacement password', () async {
    final original = User(
      id: 'user',
      username: 'existing.user',
      passwordHash: 'existing-hash',
      role: UserRole.technician,
      driverId: 42,
      isActive: false,
    );
    final users = _FakeUserRepository()..seed(original);
    final service = UserService(repository: users);

    expect(
      () => service.updateUser(
        original.copyWith(username: 'updated.user'),
        newPassword: '1234567',
      ),
      throwsArgumentError,
    );

    final saved = await service.getUserById(original.id);
    expect(saved, original);
  });

  test(
    'updateUser accepts eight characters and preserves user fields',
    () async {
      final original = User(
        id: 'user',
        username: 'existing.user',
        passwordHash: 'existing-hash',
        role: UserRole.technician,
        driverId: 42,
        isActive: false,
      );
      final users = _FakeUserRepository()..seed(original);
      final service = UserService(repository: users);
      final updated = original.copyWith(username: 'updated.user');

      await service.updateUser(updated, newPassword: '12345678');

      final saved = await service.getUserById(original.id);
      expect(saved, isNotNull);
      expect(saved!.id, updated.id);
      expect(saved.username, updated.username);
      expect(saved.role, updated.role);
      expect(saved.driverId, updated.driverId);
      expect(saved.isActive, updated.isActive);
      expect(saved.passwordHash, isNot(original.passwordHash));
      expect(saved.passwordHash, isNot('12345678'));
    },
  );

  test('login accepts an existing bcrypt-hashed short password', () async {
    const passwords = PasswordService(workFactor: 4);
    final historicUser = _user(
      'historic',
      'historic.short',
    ).copyWith(passwordHash: passwords.hash('1234'));
    final users = _FakeUserRepository()..seed(historicUser);
    final service = UserService(repository: users, passwordService: passwords);

    final authenticated = await service.login(
      username: historicUser.username,
      password: '1234',
    );

    expect(authenticated, historicUser);
  });

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
      await tester.enterText(find.byType(TextFormField).at(2), 'password');
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

  testWidgets('UserForm rejects a seven-character new password', (
    tester,
  ) async {
    var saves = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UserForm(
            onSave: (_, _, _, _) async {
              saves++;
            },
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'new.user');
    await tester.enterText(find.byType(TextFormField).at(1), '1234567');
    await tester.enterText(find.byType(TextFormField).at(2), '1234567');
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(saves, 0);
    expect(
      find.text('Password must be at least 8 characters.'),
      findsOneWidget,
    );
  });

  testWidgets('UserForm accepts an eight-character new password', (
    tester,
  ) async {
    var saves = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UserForm(
            onSave: (_, _, _, _) async {
              saves++;
            },
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'new.user');
    await tester.enterText(find.byType(TextFormField).at(1), '12345678');
    await tester.enterText(find.byType(TextFormField).at(2), '12345678');
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(saves, 1);
  });

  testWidgets('UserForm rejects a mismatched password confirmation', (
    tester,
  ) async {
    var saves = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UserForm(
            onSave: (_, _, _, _) async {
              saves++;
            },
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'new.user');
    await tester.enterText(find.byType(TextFormField).at(1), '12345678');
    await tester.enterText(find.byType(TextFormField).at(2), '87654321');
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(saves, 0);
    expect(find.text('Passwords do not match'), findsOneWidget);
  });

  testWidgets('generic UserForm defaults to Technician and excludes Driver', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: UserForm(onSave: (_, _, _, _) async {})),
      ),
    );

    expect(find.text('Technician'), findsOneWidget);
    await tester.tap(_roleDropdown());
    await tester.pump();

    expect(find.text('Driver'), findsNothing);
  });

  testWidgets('non-Driver UserForm edit excludes Driver', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UserForm(
            user: _user('manager', 'manager.user'),
            onSave: (_, _, _, _) async {},
          ),
        ),
      ),
    );

    await tester.tap(_roleDropdown());
    await tester.pump();

    expect(find.text('Driver'), findsNothing);
  });

  testWidgets(
    'legacy unlinked Driver role can be changed away but not selected again',
    (tester) async {
      final legacyDriver = User(
        id: 'legacy-driver',
        username: 'legacy.driver',
        passwordHash: 'hash',
        role: UserRole.driver,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserForm(user: legacyDriver, onSave: (_, _, _, _) async {}),
          ),
        ),
      );

      expect(find.text('Driver'), findsOneWidget);
      await tester.tap(_roleDropdown());
      await tester.pump();
      await tester.tap(find.text('Technician').last);
      await tester.pump();
      await tester.tap(_roleDropdown());
      await tester.pump();

      expect(find.text('Driver'), findsNothing);
    },
  );
}

Finder _roleDropdown() => find.byWidgetPredicate(
  (widget) => widget is DropdownButtonFormField<UserRole>,
);

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

  @override
  Future<void> insertUser(UserEntity user) async {
    _users[user.id] = user;
  }

  @override
  Future<void> updateUser(UserEntity user) async {
    _users[user.id] = user;
  }

  @override
  Future<bool> hasActiveAdministrator() async =>
      _users.values.any((user) => user.role == UserRole.admin && user.isActive);

  @override
  Future<bool> insertFirstAdministrator(UserEntity user) async {
    if (await hasActiveAdministrator()) return false;
    _users[user.id] = user;
    return true;
  }
}
