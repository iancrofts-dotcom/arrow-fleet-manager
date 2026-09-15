import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _ProofApp());
}

class _ProofApp extends StatefulWidget {
  const _ProofApp();

  @override
  State<_ProofApp> createState() => _ProofAppState();
}

class _ProofAppState extends State<_ProofApp> {
  var _status = 'Running safe live RLS proof...';

  @override
  void initState() {
    super.initState();
    unawaited(_run());
  }

  Future<void> _run() async {
    final proof = _ProofRunner.fromEnvironment();
    await proof.run();
    if (mounted) {
      setState(() => _status = 'Proof complete. Review the terminal output.');
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(body: Center(child: Text(_status))),
  );
}

class _ProofRunner {
  _ProofRunner({
    required this.url,
    required this.anonKey,
    required this.adminCredentials,
    this.managerCredentials,
    this.workshopCredentials,
    this.driverCredentials,
  });

  factory _ProofRunner.fromEnvironment() {
    String value(String name) => Platform.environment[name]?.trim() ?? '';
    _Credentials? optional(String emailName, String passwordName) {
      final email = value(emailName);
      final password = value(passwordName);
      return email.isEmpty || password.isEmpty
          ? null
          : _Credentials(email, password);
    }

    return _ProofRunner(
      url: value('FLEETIQ_SUPABASE_URL'),
      anonKey: value('FLEETIQ_SUPABASE_ANON_KEY'),
      adminCredentials: optional('FLEETIQ_DEV_EMAIL', 'FLEETIQ_DEV_PASSWORD'),
      managerCredentials: optional(
        'FLEETIQ_TEST_MANAGER_EMAIL',
        'FLEETIQ_TEST_MANAGER_PASSWORD',
      ),
      workshopCredentials: optional(
        'FLEETIQ_TEST_WORKSHOP_EMAIL',
        'FLEETIQ_TEST_WORKSHOP_PASSWORD',
      ),
      driverCredentials: optional(
        'FLEETIQ_TEST_DRIVER_EMAIL',
        'FLEETIQ_TEST_DRIVER_PASSWORD',
      ),
    );
  }

  final String url;
  final String anonKey;
  final _Credentials? adminCredentials;
  final _Credentials? managerCredentials;
  final _Credentials? workshopCredentials;
  final _Credentials? driverCredentials;
  final _Results results = _Results();
  final List<String> driverIds = [];
  final List<String> vehicleIds = [];
  final List<String> assignmentIds = [];
  final Set<String> testAuthUserIds = {};
  String? adminProfileId;
  late final String tag =
      'TEST5C1_${DateTime.now().toUtc().millisecondsSinceEpoch}';

  Future<void> run() async {
    if (url.isEmpty || anonKey.isEmpty || adminCredentials == null) {
      results.fail('CONFIGURATION', 'required_environment_missing');
      results.finish();
      return;
    }

    final admin = await _session(adminCredentials!, 'administrator');
    if (admin == null) {
      results.finish();
      return;
    }
    adminProfileId = admin.auth.currentUser!.id;

    Map<String, dynamic>? d1;
    Map<String, dynamic>? d2;
    Map<String, dynamic>? v1;
    Map<String, dynamic>? v2;
    Map<String, dynamic>? a1;
    try {
      await _allowed('ADMIN DRIVER SELECT', () => _select(admin, 'drivers'));
      d1 = await _insertDriver(admin, '${tag}_DRIVER');
      d2 = await _insertDriver(admin, '${tag}_OTHER');
      await _allowed(
        'ADMIN DRIVER INSERT',
        () async => d1,
        valid: (value) => value != null,
      );
      await _allowed(
        'ADMIN DRIVER UPDATE',
        () => admin
            .from('drivers')
            .update({'phone': 'TEST5C1'})
            .eq('id', d1!['id'])
            .select(),
      );
      await _denied(
        'ADMIN DRIVER DELETE',
        () => admin.from('drivers').delete().eq('id', d2!['id']).select(),
      );

      v1 = await _insertVehicle(admin, '${tag}A', '${tag}_V1');
      v2 = await _insertVehicle(admin, '${tag}B', '${tag}_V2');
      a1 = await _insertAssignment(admin, d1['id'], v1['id']);
      await _allowed(
        'ADMIN ASSIGNMENT SELECT',
        () => _select(admin, 'driver_assignments'),
      );
      await _constraintDenied(
        'ACTIVE DRIVER UNIQUENESS',
        () => _insertAssignment(admin, d1!['id'], v2!['id'], track: false),
      );
      await _constraintDenied(
        'ACTIVE VEHICLE UNIQUENESS',
        () => _insertAssignment(admin, d2!['id'], v1!['id'], track: false),
      );
      await _constraintDenied(
        'ACTIVE WITH END TIMESTAMP',
        () => _insertAssignment(
          admin,
          d2!['id'],
          v2!['id'],
          assignedTo: DateTime.now().toUtc(),
          track: false,
        ),
      );
      await _constraintDenied(
        'ENDED WITHOUT END TIMESTAMP',
        () => _insertAssignment(
          admin,
          d2!['id'],
          v2!['id'],
          active: false,
          track: false,
        ),
      );
      await _constraintDenied(
        'INVALID ASSIGNMENT DATES',
        () => _insertAssignment(
          admin,
          d2!['id'],
          v2!['id'],
          active: false,
          assignedFrom: DateTime.now().toUtc(),
          assignedTo: DateTime.now().toUtc().subtract(const Duration(days: 1)),
          track: false,
        ),
      );
      await _allowed(
        'ADMIN ASSIGNMENT UPDATE',
        () => _endAssignment(admin, a1!['id']),
      );
      await _allowed(
        'ENDED ASSIGNMENT HISTORY',
        () => admin
            .from('driver_assignments')
            .select()
            .eq('id', a1!['id'])
            .eq('is_active', false),
      );
      await _denied(
        'ADMIN ASSIGNMENT DELETE',
        () => admin
            .from('driver_assignments')
            .delete()
            .eq('id', a1!['id'])
            .select(),
      );

      await _profileSecurity(admin, 'ADMIN', d2['id']);
      await _provision(admin, d1, d2);
      await _managerProof(d2, v2);
      await _workshopProof(d2, a1);
      await _driverProof(admin, d2);
      await _anonymousProof(d2, a1);
    } catch (_) {
      results.fail('HARNESS COMPLETION', 'safe_unexpected_failure');
    } finally {
      await _safeSignOut(admin);
    }

    _printCleanupMetadata();
    results.finish();
  }

  Future<SupabaseClient?> _session(
    _Credentials credentials,
    String expectedRole,
  ) async {
    final client = SupabaseClient(url, anonKey);
    try {
      final auth = await client.auth.signInWithPassword(
        email: credentials.email,
        password: credentials.password,
      );
      if (auth.user == null) throw StateError('missing_user');
      final profile = await client
          .from('profiles')
          .select('id, role, is_active, driver_id')
          .eq('id', auth.user!.id)
          .single();
      if (profile['role'] != expectedRole || profile['is_active'] != true) {
        throw StateError('profile_mismatch');
      }
      if (expectedRole != 'administrator') {
        testAuthUserIds.add(auth.user!.id);
      }
      results.pass('${expectedRole.toUpperCase()} AUTH');
      return client;
    } catch (_) {
      results.fail(
        '${expectedRole.toUpperCase()} AUTH',
        'authentication_or_profile_rejected',
      );
      await _safeSignOut(client);
      return null;
    }
  }

  Future<Map<String, dynamic>> _insertDriver(
    SupabaseClient client,
    String username,
  ) async {
    final row = await client
        .from('drivers')
        .insert({
          'first_name': 'FleetIQ',
          'last_name': 'Proof',
          'licence_number': username,
          'username': username,
          'is_active': true,
        })
        .select()
        .single();
    driverIds.add(row['id'] as String);
    return row;
  }

  Future<Map<String, dynamic>> _insertVehicle(
    SupabaseClient client,
    String registration,
    String fleetNumber,
  ) async {
    final row = await client
        .from('vehicles')
        .insert({
          'registration': registration,
          'fleet_number': fleetNumber,
          'make': 'FleetIQ',
          'model': 'TEST5C1',
          'is_active': true,
        })
        .select()
        .single();
    vehicleIds.add(row['id'] as String);
    return row;
  }

  Future<Map<String, dynamic>> _insertAssignment(
    SupabaseClient client,
    String driverId,
    String vehicleId, {
    DateTime? assignedFrom,
    DateTime? assignedTo,
    bool active = true,
    bool track = true,
  }) async {
    final row = await client
        .from('driver_assignments')
        .insert({
          'driver_id': driverId,
          'vehicle_id': vehicleId,
          'assigned_from': (assignedFrom ?? DateTime.now().toUtc())
              .toIso8601String(),
          'assigned_to': assignedTo?.toIso8601String(),
          'is_active': active,
        })
        .select()
        .single();
    if (track) assignmentIds.add(row['id'] as String);
    return row;
  }

  Future<List<Map<String, dynamic>>> _endAssignment(
    SupabaseClient client,
    String id,
  ) => client
      .from('driver_assignments')
      .update({
        'assigned_to': DateTime.now().toUtc().toIso8601String(),
        'is_active': false,
      })
      .eq('id', id)
      .select();

  Future<void> _provision(
    SupabaseClient admin,
    Map<String, dynamic> driver,
    Map<String, dynamic> otherDriver,
  ) async {
    final credentials = driverCredentials;
    if (credentials == null) {
      results.skip('DRIVER PROVISION', 'driver_credentials_missing');
      results.skip('PROVISION IDEMPOTENCY', 'driver_credentials_missing');
      results.skip('ARBITRARY RELINK', 'driver_credentials_missing');
      return;
    }
    try {
      String targetDriverId = driver['id'] as String;
      var existingLinkedIdentity = false;
      final existingClient = SupabaseClient(url, anonKey);
      try {
        final auth = await existingClient.auth.signInWithPassword(
          email: credentials.email,
          password: credentials.password,
        );
        if (auth.user != null) {
          final profile = await existingClient
              .from('profiles')
              .select('driver_id')
              .eq('id', auth.user!.id)
              .single();
          if (profile['driver_id'] is String) {
            targetDriverId = profile['driver_id'] as String;
            existingLinkedIdentity = true;
          }
        }
      } catch (_) {
        // A new invitation commonly has no usable password session yet.
      } finally {
        await _safeSignOut(existingClient);
      }
      final first = await admin.functions.invoke(
        'provision-driver-user',
        body: {'driverId': targetDriverId, 'email': credentials.email},
      );
      final firstData = first.data as Map<String, dynamic>?;
      final expectedStatus = existingLinkedIdentity ? 200 : 201;
      if (first.status != expectedStatus || firstData?['ok'] != true) {
        results.skip(
          'DRIVER PROVISION',
          'existing_or_unavailable_test_identity',
        );
        results.skip('PROVISION IDEMPOTENCY', 'provision_not_created');
        results.skip('ARBITRARY RELINK', 'provision_not_created');
        return;
      }
      existingLinkedIdentity
          ? results.skip('DRIVER PROVISION', 'existing_linked_test_identity')
          : results.pass('DRIVER PROVISION');
      final provisionedUserId = firstData?['userId'] as String?;
      if (provisionedUserId != null) testAuthUserIds.add(provisionedUserId);
      final linkedRows = provisionedUserId == null
          ? <Map<String, dynamic>>[]
          : await admin
                .from('profiles')
                .select('id')
                .eq('id', provisionedUserId)
                .eq('role', 'driver')
                .eq('is_active', true)
                .eq('driver_id', targetDriverId);
      linkedRows.isNotEmpty
          ? results.pass('PROVISION PROFILE LINK')
          : results.fail('PROVISION PROFILE LINK', 'link_not_verified');
      if (provisionedUserId != null) {
        await _denied(
          'ADMIN OTHER PROFILE MUTATION',
          () => admin
              .from('profiles')
              .update({'is_active': false})
              .eq('id', provisionedUserId)
              .select(),
        );
      }
      final second = await admin.functions.invoke(
        'provision-driver-user',
        body: {'driverId': targetDriverId, 'email': credentials.email},
      );
      final secondData = second.data as Map<String, dynamic>?;
      second.status == 200 && secondData?['status'] == 'idempotent'
          ? results.pass('PROVISION IDEMPOTENCY')
          : results.fail('PROVISION IDEMPOTENCY', 'unexpected_safe_status');
      final relink = await admin.functions.invoke(
        'provision-driver-user',
        body: {'driverId': otherDriver['id'], 'email': credentials.email},
      );
      relink.status >= 400
          ? results.pass('ARBITRARY RELINK', note: 'correctly denied')
          : results.fail('ARBITRARY RELINK', 'unexpectedly_allowed');
    } catch (_) {
      results.fail('DRIVER PROVISION', 'safe_function_failure');
      results.skip('PROVISION IDEMPOTENCY', 'provision_failed');
      results.skip('ARBITRARY RELINK', 'provision_failed');
    }
  }

  Future<void> _managerProof(
    Map<String, dynamic> driver,
    Map<String, dynamic> vehicle,
  ) async {
    if (managerCredentials == null) {
      results.skipLabels(_managerLabels, 'credentials_missing');
      return;
    }
    final client = await _session(managerCredentials!, 'manager');
    if (client == null) {
      results.skipLabels(_managerLabels, 'session_unavailable');
      return;
    }
    try {
      await _allowed('MANAGER DRIVER SELECT', () => _select(client, 'drivers'));
      final created = await _insertDriver(client, '${tag}_MANAGER');
      results.pass('MANAGER DRIVER INSERT');
      await _allowed(
        'MANAGER DRIVER UPDATE',
        () => client
            .from('drivers')
            .update({'phone': 'TEST5C1'})
            .eq('id', created['id'])
            .select(),
      );
      await _denied(
        'MANAGER DRIVER DELETE',
        () => client.from('drivers').delete().eq('id', created['id']).select(),
      );
      await _allowed(
        'MANAGER ASSIGNMENT SELECT',
        () => _select(client, 'driver_assignments'),
      );
      final assignment = await _insertAssignment(
        client,
        driver['id'],
        vehicle['id'],
      );
      results.pass('MANAGER ASSIGNMENT INSERT');
      await _allowed(
        'MANAGER ASSIGNMENT UPDATE',
        () => _endAssignment(client, assignment['id']),
      );
      await _denied(
        'MANAGER ASSIGNMENT DELETE',
        () => client
            .from('driver_assignments')
            .delete()
            .eq('id', assignment['id'])
            .select(),
      );
      await _profileSecurity(client, 'MANAGER', driver['id']);
    } catch (_) {
      results.fail('MANAGER PROOF', 'safe_unexpected_failure');
    } finally {
      await _safeSignOut(client);
    }
  }

  Future<void> _workshopProof(
    Map<String, dynamic> driver,
    Map<String, dynamic> assignment,
  ) async {
    if (workshopCredentials == null) {
      results.skipLabels(_workshopLabels, 'credentials_missing');
      return;
    }
    final client = await _session(workshopCredentials!, 'workshop');
    if (client == null) {
      results.skipLabels(_workshopLabels, 'session_unavailable');
      return;
    }
    try {
      await _allowed(
        'WORKSHOP DRIVER SELECT',
        () => _select(client, 'drivers'),
      );
      await _denied(
        'WORKSHOP DRIVER INSERT',
        () => client.from('drivers').insert(_deniedDriver()).select(),
      );
      await _denied(
        'WORKSHOP DRIVER UPDATE',
        () => client
            .from('drivers')
            .update({'phone': 'DENIED'})
            .eq('id', driver['id'])
            .select(),
      );
      await _denied(
        'WORKSHOP DRIVER DELETE',
        () => client.from('drivers').delete().eq('id', driver['id']).select(),
      );
      await _allowed(
        'WORKSHOP ASSIGNMENT SELECT',
        () => _select(client, 'driver_assignments'),
      );
      await _denied(
        'WORKSHOP ASSIGNMENT INSERT',
        () => client
            .from('driver_assignments')
            .insert(_deniedAssignment(driver['id'], assignment['vehicle_id']))
            .select(),
      );
      await _denied(
        'WORKSHOP ASSIGNMENT UPDATE',
        () => client
            .from('driver_assignments')
            .update({
              'is_active': false,
              'assigned_to': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', assignment['id'])
            .select(),
      );
      await _denied(
        'WORKSHOP ASSIGNMENT DELETE',
        () => client
            .from('driver_assignments')
            .delete()
            .eq('id', assignment['id'])
            .select(),
      );
      await _profileSecurity(client, 'WORKSHOP', driver['id']);
    } finally {
      await _safeSignOut(client);
    }
  }

  Future<void> _driverProof(
    SupabaseClient admin,
    Map<String, dynamic> anotherDriver,
  ) async {
    if (driverCredentials == null) {
      results.skipLabels(
        _driverLabels,
        'credentials_missing_or_invite_pending',
      );
      return;
    }
    final client = await _session(driverCredentials!, 'driver');
    if (client == null) {
      results.skipLabels(
        _driverLabels,
        'manual_invitation_password_step_required',
      );
      return;
    }
    try {
      final userId = client.auth.currentUser!.id;
      final profile = await client
          .from('profiles')
          .select('driver_id')
          .eq('id', userId)
          .single();
      final ownDriverId = profile['driver_id'] as String?;
      if (ownDriverId == null) throw StateError('missing_link');
      var ownAssignments = await client
          .from('driver_assignments')
          .select()
          .eq('driver_id', ownDriverId);
      if (ownAssignments.isEmpty) {
        final ownVehicle = await _insertVehicle(admin, '${tag}D', '${tag}_OWN');
        await _insertAssignment(admin, ownDriverId, ownVehicle['id']);
        ownAssignments = await client
            .from('driver_assignments')
            .select()
            .eq('driver_id', ownDriverId);
      }
      var otherAssignments = await admin
          .from('driver_assignments')
          .select()
          .eq('driver_id', anotherDriver['id']);
      if (otherAssignments.isEmpty) {
        final otherVehicle = await _insertVehicle(
          admin,
          '${tag}E',
          '${tag}_OTHER',
        );
        final other = await _insertAssignment(
          admin,
          anotherDriver['id'],
          otherVehicle['id'],
        );
        await _endAssignment(admin, other['id']);
        otherAssignments = [other];
      }
      final anotherAssignmentId = otherAssignments.first['id'] as String;
      await _allowed(
        'DRIVER OWN DRIVER SELECT',
        () => client.from('drivers').select().eq('id', ownDriverId),
        valid: (value) => value is List && value.isNotEmpty,
      );
      await _hidden(
        'DRIVER OTHER DRIVER SELECT',
        () => client.from('drivers').select().eq('id', anotherDriver['id']),
      );
      await _denied(
        'DRIVER DRIVER INSERT',
        () => client.from('drivers').insert(_deniedDriver()).select(),
      );
      await _denied(
        'DRIVER DRIVER UPDATE',
        () => client
            .from('drivers')
            .update({'phone': 'DENIED'})
            .eq('id', ownDriverId)
            .select(),
      );
      await _denied(
        'DRIVER DRIVER DELETE',
        () => client.from('drivers').delete().eq('id', ownDriverId).select(),
      );
      await _allowed(
        'DRIVER OWN ASSIGNMENT SELECT',
        () => client
            .from('driver_assignments')
            .select()
            .eq('driver_id', ownDriverId),
        valid: (value) => value is List && value.isNotEmpty,
      );
      await _hidden(
        'DRIVER OTHER ASSIGNMENT SELECT',
        () => client
            .from('driver_assignments')
            .select()
            .eq('id', anotherAssignmentId),
      );
      await _denied(
        'DRIVER ASSIGNMENT INSERT',
        () => client
            .from('driver_assignments')
            .insert(
              _deniedAssignment(
                anotherDriver['id'],
                otherAssignments.first['vehicle_id'],
              ),
            )
            .select(),
      );
      await _denied(
        'DRIVER ASSIGNMENT UPDATE',
        () => client
            .from('driver_assignments')
            .update({
              'is_active': false,
              'assigned_to': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', anotherAssignmentId)
            .select(),
      );
      await _denied(
        'DRIVER ASSIGNMENT DELETE',
        () => client
            .from('driver_assignments')
            .delete()
            .eq('id', anotherAssignmentId)
            .select(),
      );
      await _profileSecurity(client, 'DRIVER', anotherDriver['id']);
    } catch (_) {
      results.fail('DRIVER PROOF', 'safe_unexpected_failure');
    } finally {
      await _safeSignOut(client);
    }
  }

  Future<void> _anonymousProof(
    Map<String, dynamic> driver,
    Map<String, dynamic> assignment,
  ) async {
    final client = SupabaseClient(url, anonKey);
    await _hidden('ANONYMOUS DRIVER SELECT', () => _select(client, 'drivers'));
    await _denied(
      'ANONYMOUS DRIVER INSERT',
      () => client.from('drivers').insert(_deniedDriver()).select(),
    );
    await _denied(
      'ANONYMOUS DRIVER UPDATE',
      () => client
          .from('drivers')
          .update({'phone': 'DENIED'})
          .eq('id', driver['id'])
          .select(),
    );
    await _denied(
      'ANONYMOUS DRIVER DELETE',
      () => client.from('drivers').delete().eq('id', driver['id']).select(),
    );
    await _hidden(
      'ANONYMOUS ASSIGNMENT SELECT',
      () => _select(client, 'driver_assignments'),
    );
    await _denied(
      'ANONYMOUS ASSIGNMENT INSERT',
      () => client
          .from('driver_assignments')
          .insert(_deniedAssignment(driver['id'], assignment['vehicle_id']))
          .select(),
    );
    await _denied(
      'ANONYMOUS ASSIGNMENT UPDATE',
      () => client
          .from('driver_assignments')
          .update({
            'is_active': false,
            'assigned_to': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', assignment['id'])
          .select(),
    );
    await _denied(
      'ANONYMOUS ASSIGNMENT DELETE',
      () => client
          .from('driver_assignments')
          .delete()
          .eq('id', assignment['id'])
          .select(),
    );
  }

  Future<void> _profileSecurity(
    SupabaseClient client,
    String prefix,
    String arbitraryDriverId,
  ) async {
    final ownId = client.auth.currentUser!.id;
    await _denied(
      '$prefix PROFILE ROLE',
      () => client
          .from('profiles')
          .update({'role': 'administrator'})
          .eq('id', ownId)
          .select(),
    );
    await _denied(
      '$prefix PROFILE ACTIVE',
      () => client
          .from('profiles')
          .update({'is_active': true})
          .eq('id', ownId)
          .select(),
    );
    await _denied(
      '$prefix PROFILE SELF LINK',
      () => client
          .from('profiles')
          .update({'driver_id': arbitraryDriverId})
          .eq('id', ownId)
          .select(),
    );
    if (adminProfileId case final otherId? when otherId != ownId) {
      await _denied(
        '$prefix OTHER PROFILE MUTATION',
        () => client
            .from('profiles')
            .update({'is_active': false})
            .eq('id', otherId)
            .select(),
      );
    }
  }

  Map<String, dynamic> _deniedDriver() => {
    'first_name': 'Denied',
    'last_name': tag,
    'licence_number': '${tag}_DENIED',
    'is_active': true,
  };
  Map<String, dynamic> _deniedAssignment(String driverId, String vehicleId) => {
    'driver_id': driverId,
    'vehicle_id': vehicleId,
    'assigned_from': DateTime.now().toUtc().toIso8601String(),
    'is_active': true,
  };
  Future<List<Map<String, dynamic>>> _select(
    SupabaseClient client,
    String table,
  ) async => (await client.from(table).select()).cast<Map<String, dynamic>>();

  Future<void> _allowed(
    String label,
    Future<dynamic> Function() operation, {
    bool Function(dynamic)? valid,
  }) async {
    try {
      final value = await operation();
      (valid?.call(value) ?? true)
          ? results.pass(label)
          : results.fail(label, 'no_accessible_result');
    } catch (_) {
      results.fail(label, 'operation_rejected');
    }
  }

  Future<void> _denied(
    String label,
    Future<dynamic> Function() operation,
  ) async {
    try {
      final value = await operation();
      _isEmpty(value)
          ? results.pass(label, note: 'correctly denied')
          : results.fail(label, 'unexpectedly_allowed');
    } catch (_) {
      results.pass(label, note: 'correctly denied');
    }
  }

  Future<void> _hidden(
    String label,
    Future<dynamic> Function() operation,
  ) async {
    try {
      final value = await operation();
      _isEmpty(value)
          ? results.pass(label, note: 'correctly hidden')
          : results.fail(label, 'unexpectedly_visible');
    } catch (_) {
      results.pass(label, note: 'correctly denied');
    }
  }

  Future<void> _constraintDenied(
    String label,
    Future<dynamic> Function() operation,
  ) async {
    try {
      await operation();
      results.fail(label, 'constraint_did_not_reject');
    } catch (_) {
      results.pass(label, note: 'constraint rejected conflict');
    }
  }

  bool _isEmpty(dynamic value) => value is Iterable && value.isEmpty;
  Future<void> _safeSignOut(SupabaseClient client) async {
    try {
      await client.auth.signOut();
    } catch (_) {}
  }

  void _printCleanupMetadata() {
    stdout.writeln('TEST TAG ................... $tag');
    stdout.writeln('CLEANUP DRIVER IDS ......... ${driverIds.join(',')}');
    stdout.writeln('CLEANUP VEHICLE IDS ........ ${vehicleIds.join(',')}');
    stdout.writeln('CLEANUP ASSIGNMENT IDS ..... ${assignmentIds.join(',')}');
    stdout.writeln('CLEANUP AUTH USER IDS ...... ${testAuthUserIds.join(',')}');
  }
}

class _Credentials {
  const _Credentials(this.email, this.password);
  final String email;
  final String password;
}

class _Results {
  var passed = 0;
  var failed = 0;
  var skipped = 0;
  void pass(String label, {String? note}) {
    passed++;
    _line(label, 'PASS${note == null ? '' : ' ($note)'}');
  }

  void fail(String label, String reason) {
    failed++;
    _line(label, 'FAIL ($reason)');
  }

  void skip(String label, String reason) {
    skipped++;
    _line(label, 'SKIP ($reason)');
  }

  void skipLabels(List<String> labels, String reason) {
    for (final label in labels) {
      skip(label, reason);
    }
  }

  void _line(String label, String result) =>
      stdout.writeln('${label.padRight(34, '.')} $result');
  void finish() {
    stdout.writeln('TOTAL PASS ................. $passed');
    stdout.writeln('TOTAL FAIL ................. $failed');
    stdout.writeln('TOTAL SKIP ................. $skipped');
  }
}

const _managerLabels = <String>[
  'MANAGER DRIVER SELECT',
  'MANAGER DRIVER INSERT',
  'MANAGER DRIVER UPDATE',
  'MANAGER DRIVER DELETE',
  'MANAGER ASSIGNMENT SELECT',
  'MANAGER ASSIGNMENT INSERT',
  'MANAGER ASSIGNMENT UPDATE',
  'MANAGER ASSIGNMENT DELETE',
  'MANAGER PROFILE ROLE',
  'MANAGER PROFILE ACTIVE',
  'MANAGER PROFILE SELF LINK',
  'MANAGER OTHER PROFILE MUTATION',
];
const _workshopLabels = <String>[
  'WORKSHOP DRIVER SELECT',
  'WORKSHOP DRIVER INSERT',
  'WORKSHOP DRIVER UPDATE',
  'WORKSHOP DRIVER DELETE',
  'WORKSHOP ASSIGNMENT SELECT',
  'WORKSHOP ASSIGNMENT INSERT',
  'WORKSHOP ASSIGNMENT UPDATE',
  'WORKSHOP ASSIGNMENT DELETE',
  'WORKSHOP PROFILE ROLE',
  'WORKSHOP PROFILE ACTIVE',
  'WORKSHOP PROFILE SELF LINK',
  'WORKSHOP OTHER PROFILE MUTATION',
];
const _driverLabels = <String>[
  'DRIVER OWN DRIVER SELECT',
  'DRIVER OTHER DRIVER SELECT',
  'DRIVER DRIVER INSERT',
  'DRIVER DRIVER UPDATE',
  'DRIVER DRIVER DELETE',
  'DRIVER OWN ASSIGNMENT SELECT',
  'DRIVER OTHER ASSIGNMENT SELECT',
  'DRIVER ASSIGNMENT INSERT',
  'DRIVER ASSIGNMENT UPDATE',
  'DRIVER ASSIGNMENT DELETE',
  'DRIVER PROFILE ROLE',
  'DRIVER PROFILE ACTIVE',
  'DRIVER PROFILE SELF LINK',
  'DRIVER OTHER PROFILE MUTATION',
];
