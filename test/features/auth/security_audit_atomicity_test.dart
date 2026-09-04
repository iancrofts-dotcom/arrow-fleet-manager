import 'dart:io';

import 'package:arrow_fleet_manager/database/app_database.dart';
import 'package:arrow_fleet_manager/features/auth/models/security_audit_event.dart';
import 'package:arrow_fleet_manager/features/auth/models/user.dart';
import 'package:arrow_fleet_manager/features/auth/models/user_entity.dart';
import 'package:arrow_fleet_manager/features/auth/models/user_role.dart';
import 'package:arrow_fleet_manager/features/auth/repositories/security_audit_repository.dart';
import 'package:arrow_fleet_manager/features/auth/repositories/user_repository.dart';
import 'package:arrow_fleet_manager/features/auth/services/password_service.dart';
import 'package:arrow_fleet_manager/features/auth/services/security_audit_service.dart';
import 'package:arrow_fleet_manager/features/auth/services/user_service.dart';
import 'package:arrow_fleet_manager/features/drivers/models/driver.dart';
import 'package:arrow_fleet_manager/features/drivers/models/driver_entity.dart';
import 'package:arrow_fleet_manager/features/drivers/repositories/driver_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('commits User creation and its audit event together', () async {
    final harness = await _Harness.create();
    addTearDown(harness.dispose);

    await harness.service.addUser(_user('new'), password: 'password1');

    expect((await harness.users.getUserById('new'))?.username, 'new.user');
    final events = await harness.audit.listRecent();
    expect(events, hasLength(1));
    expect(events.single.type, SecurityAuditEventType.userCreated);
    expect(events.single.targetUserId, 'new');
  });

  test('rolls User creation back when the audit insert fails', () async {
    final harness = await _Harness.create(failAuditInsertNumber: 1);
    addTearDown(harness.dispose);

    await expectLater(
      harness.service.addUser(_user('new'), password: 'password1'),
      throwsStateError,
    );

    expect(await harness.users.getUserById('new'), isNull);
    expect(await harness.audit.listRecent(), isEmpty);
  });

  test('records managed changes in deterministic event order', () async {
    final harness = await _Harness.create();
    addTearDown(harness.dispose);
    final before = _user('target');
    await harness.seed(_admin());
    await harness.seed(before);

    await harness.service.updateManagedUser(
      before.copyWith(
        username: 'renamed.user',
        role: UserRole.workshop,
        isActive: false,
      ),
      actingUserId: 'admin',
      newPassword: 'password2',
    );

    final rows = await (await harness.database.database()).query(
      'security_audit_events',
      orderBy: 'id ASC',
    );
    expect(rows.map((row) => row['event_type']), [
      SecurityAuditEventType.userUpdated.name,
      SecurityAuditEventType.roleChanged.name,
      SecurityAuditEventType.userDeactivated.name,
      SecurityAuditEventType.passwordChangedByAdministrator.name,
    ]);
    final events = await harness.audit.listRecent();
    expect(events.every((event) => event.actorUserId == 'admin'), isTrue);
  });

  test(
    'rolls back a managed update and earlier audit rows on late failure',
    () async {
      final harness = await _Harness.create(failAuditInsertNumber: 3);
      addTearDown(harness.dispose);
      final before = _user('target');
      await harness.seed(_admin());
      await harness.seed(before);

      await expectLater(
        harness.service.updateManagedUser(
          before.copyWith(
            username: 'renamed.user',
            role: UserRole.workshop,
            isActive: false,
          ),
          actingUserId: 'admin',
          newPassword: 'password2',
        ),
        throwsStateError,
      );

      await harness.expectPersistedUser(before);
      expect(await harness.audit.listRecent(), isEmpty);
    },
  );

  test('emits exact managed-update event sequences', () async {
    final cases =
        <
          ({
            User Function(User) update,
            String? password,
            List<SecurityAuditEventType> events,
          })
        >[
          (
            update: (user) => user.copyWith(username: 'renamed.user'),
            password: null,
            events: [SecurityAuditEventType.userUpdated],
          ),
          (
            update: (user) => user.copyWith(role: UserRole.workshop),
            password: null,
            events: [SecurityAuditEventType.roleChanged],
          ),
          (
            update: (user) => user.copyWith(isActive: false),
            password: null,
            events: [SecurityAuditEventType.userDeactivated],
          ),
          (
            update: (user) => user.copyWith(role: UserRole.workshop),
            password: 'password2',
            events: [
              SecurityAuditEventType.roleChanged,
              SecurityAuditEventType.passwordChangedByAdministrator,
            ],
          ),
          (
            update: (user) =>
                user.copyWith(role: UserRole.workshop, isActive: false),
            password: 'password2',
            events: [
              SecurityAuditEventType.roleChanged,
              SecurityAuditEventType.userDeactivated,
              SecurityAuditEventType.passwordChangedByAdministrator,
            ],
          ),
        ];

    for (final testCase in cases) {
      final harness = await _Harness.create();
      addTearDown(harness.dispose);
      final before = _user('target');
      await harness.seed(_admin());
      await harness.seed(before);
      await harness.service.updateManagedUser(
        testCase.update(before),
        actingUserId: 'admin',
        newPassword: testCase.password,
      );
      expect(await harness.eventTypesInInsertionOrder(), testCase.events);
    }
  });

  test('emits userActivated for an inactive User', () async {
    final harness = await _Harness.create();
    addTearDown(harness.dispose);
    final before = _user('target').copyWith(isActive: false);
    await harness.seed(_admin());
    await harness.seed(before);
    await harness.service.updateManagedUser(
      before.copyWith(isActive: true),
      actingUserId: 'admin',
    );
    expect(await harness.eventTypesInInsertionOrder(), [
      SecurityAuditEventType.userActivated,
    ]);
  });

  test('single-change audit failures roll User state back', () async {
    final cases = <({User Function(User) update, String? password})>[
      (
        update: (user) => user.copyWith(role: UserRole.workshop),
        password: null,
      ),
      (update: (user) => user.copyWith(isActive: false), password: null),
      (
        update: (user) => user.copyWith(username: 'renamed.user'),
        password: 'password2',
      ),
    ];
    for (final testCase in cases) {
      final harness = await _Harness.create(failAuditInsertNumber: 1);
      addTearDown(harness.dispose);
      final before = _user('target');
      await harness.seed(_admin());
      await harness.seed(before);
      await expectLater(
        harness.service.updateManagedUser(
          testCase.update(before),
          actingUserId: 'admin',
          newPassword: testCase.password,
        ),
        throwsStateError,
      );
      await harness.expectPersistedUser(before);
      expect(await harness.audit.listRecent(), isEmpty);
    }
  });

  test(
    'deletion commits its historical target snapshot and rolls back on audit failure',
    () async {
      final success = await _Harness.create();
      addTearDown(success.dispose);
      final target = _user('target');
      await success.seed(_admin());
      await success.seed(target);
      await success.service.deleteManagedUser(target.id, actingUserId: 'admin');
      final event = (await success.audit.listRecent()).single;
      expect(await success.users.getUserById(target.id), isNull);
      expect(event.type, SecurityAuditEventType.userDeleted);
      expect(event.targetUserId, target.id);
      expect(event.targetUsername, target.username);

      final failing = await _Harness.create(failAuditInsertNumber: 1);
      addTearDown(failing.dispose);
      await failing.seed(_admin());
      await failing.seed(target);
      await expectLater(
        failing.service.deleteManagedUser(target.id, actingUserId: 'admin'),
        throwsStateError,
      );
      await failing.expectPersistedUser(target);
      expect(await failing.audit.listRecent(), isEmpty);
    },
  );

  test('Driver-linked User creation is atomic', () async {
    final success = await _Harness.create();
    addTearDown(success.dispose);
    final driverId = await success.seedDriver();
    final linked = User(
      id: 'driver-user',
      username: 'driver.user',
      passwordHash: '',
      role: UserRole.driver,
      driverId: driverId,
    );
    await success.service.addUser(linked, password: 'password1');
    final saved = await success.users.getUserById(linked.id);
    expect(saved?.role, UserRole.driver);
    expect(saved?.driverId, driverId);
    expect(
      (await success.audit.listRecent()).single.type,
      SecurityAuditEventType.userCreated,
    );

    final failing = await _Harness.create(failAuditInsertNumber: 1);
    addTearDown(failing.dispose);
    final failingDriverId = await failing.seedDriver();
    final failingLinked = linked.copyWith(driverId: failingDriverId);
    await expectLater(
      failing.service.addUser(failingLinked, password: 'password1'),
      throwsStateError,
    );
    expect(await failing.users.getUserById(failingLinked.id), isNull);
    expect(await failing.audit.listRecent(), isEmpty);
  });
}

class _Harness {
  _Harness._(
    this.directory,
    this.database,
    this.users,
    this.audit,
    this.service,
  );

  final Directory directory;
  final AppDatabase database;
  final UserRepository users;
  final SecurityAuditService audit;
  final UserService service;

  static Future<_Harness> create({int? failAuditInsertNumber}) async {
    final directory = await Directory.systemTemp.createTemp('arrow_audit_');
    final database = AppDatabase(databasePath: '${directory.path}/audit.db');
    final users = UserRepository(database: database);
    final repository = failAuditInsertNumber != null
        ? _FailingAuditRepository(
            database: database,
            failOnInsertNumber: failAuditInsertNumber,
          )
        : SecurityAuditRepository(database: database);
    final audit = SecurityAuditService(
      repository: repository,
      now: () => DateTime(2026, 9, 4, 9, 32),
    );
    return _Harness._(
      directory,
      database,
      users,
      audit,
      UserService(
        repository: users,
        passwordService: const PasswordService(workFactor: 4),
        securityAuditService: audit,
      ),
    );
  }

  Future<void> dispose() async {
    await database.close();
    await directory.delete(recursive: true);
  }

  Future<void> seed(User user) async {
    await users.insertUser(UserEntity.fromUser(user));
  }

  Future<void> expectPersistedUser(User expected) async {
    final actual = await users.getUserById(expected.id);
    expect(actual, isNotNull);
    expect(actual!.id, expected.id);
    expect(actual.username, expected.username);
    expect(actual.passwordHash, expected.passwordHash);
    expect(actual.role, expected.role);
    expect(actual.driverId, expected.driverId);
    expect(actual.isActive, expected.isActive);
  }

  Future<int> seedDriver() async {
    final repository = DriverRepository(database: database);
    return repository.insertDriver(
      DriverEntity.fromDriver(
        const Driver(
          firstName: 'Test',
          lastName: 'Driver',
          licenceNumber: 'TEST-LICENCE',
          username: 'test.driver',
        ),
      ),
    );
  }

  Future<List<SecurityAuditEventType>> eventTypesInInsertionOrder() async {
    final rows = await (await database.database()).query(
      'security_audit_events',
      orderBy: 'id ASC',
    );
    return rows
        .map(
          (row) => SecurityAuditEventType.values.firstWhere(
            (type) => type.name == row['event_type'],
          ),
        )
        .toList(growable: false);
  }
}

class _FailingAuditRepository extends SecurityAuditRepository {
  _FailingAuditRepository({
    required super.database,
    required this.failOnInsertNumber,
  });

  final int failOnInsertNumber;
  var _insertCount = 0;

  @override
  Future<void> insert(SecurityAuditEvent event, {executor}) {
    _insertCount++;
    if (_insertCount == failOnInsertNumber) {
      throw StateError('Injected audit insert failure');
    }
    return super.insert(event, executor: executor);
  }
}

User _user(String id) => User(
  id: id,
  username: '$id.user',
  passwordHash: '',
  role: UserRole.manager,
);

User _admin() => User(
  id: 'admin',
  username: 'admin.user',
  passwordHash: 'existing-hash',
  role: UserRole.admin,
);
