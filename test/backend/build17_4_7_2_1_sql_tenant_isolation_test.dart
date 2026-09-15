import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Source contracts only: these do not claim to execute PostgreSQL or prove RLS.
void main() {
  final sql = File(
    'supabase/migrations/20260915090000_critical_sql_tenant_isolation.sql',
  ).readAsStringSync().replaceAll('\r\n', '\n');
  String body(String name) =>
      sql.split('create or replace function public.$name(')[1].split(r'$$;')[0];
  void before(String source, String check, String operation) {
    expect(source, contains(check));
    expect(source, contains(operation));
    expect(source.indexOf(check), lessThan(source.indexOf(operation)));
  }

  for (final name in [
    'workshop_list_technicians',
    'fleet_assign_driver',
    'fleet_end_driver_assignment',
    'workshop_create_inspection',
    'workshop_create_inspection_from_template',
  ]) {
    test('$name explicitly authorizes active tenant membership', () {
      final source = body(name);
      expect(source, contains('security definer'));
      before(source, 'fleet_current_organisation_id()', 'select m.role');
      expect(source, contains('m.user_id = auth.uid()'));
      expect(source, contains('m.organisation_id = v_org'));
      expect(source, contains('m.is_active and p.is_active and o.is_active'));
      expect(source, contains('for share of m, p, o'));
      expect(source, contains("using errcode = '42501'"));
      expect(source, isNot(contains('has_fleetiq_role')));
      expect(sql, contains('revoke all on function public.$name('));
      expect(sql, contains('grant execute on function public.$name('));
    });
  }

  test(
    'technician listing uses company membership rather than global role',
    () {
      final query = body('workshop_list_technicians').split('return query')[1];
      expect(query, contains('m.organisation_id = v_org'));
      expect(query, contains("m.role = 'technician'"));
      expect(query, contains('m.is_active and p.is_active'));
      expect(query, contains("v_role = 'technician' and p.id = auth.uid()"));
    },
  );

  test('assignment creation checks both subjects before idempotent return', () {
    final source = body('fleet_assign_driver');
    for (final subject in ['driver', 'vehicle']) {
      before(
        source,
        'id = p_${subject}_id and organisation_id = v_org and is_active',
        'select * into v_row',
      );
    }
    before(
      source,
      'where organisation_id = v_org and driver_id',
      'return v_row',
    );
    expect(source, contains('where organisation_id = v_org and is_active'));
    expect(
      source,
      contains('values (v_org, p_driver_id, p_vehicle_id, v_when, true)'),
    );
  });

  test(
    'ending assignments scopes lookup and validates links before return',
    () {
      final source = body('fleet_end_driver_assignment');
      before(
        source,
        'where id = p_assignment_id and organisation_id = v_org',
        'if not v_row.is_active',
      );
      for (final subject in ['driver', 'vehicle']) {
        before(
          source,
          'id = v_row.${subject}_id and organisation_id = v_org',
          'if not v_row.is_active',
        );
      }
      expect(source, contains("raise exception 'Assignment not found.'"));
      expect(
        source.split('where id = p_assignment_id and organisation_id = v_org'),
        hasLength(3),
      );
    },
  );

  test('inspection validates vehicle and technician before creating rows', () {
    final source = body('workshop_create_inspection');
    before(
      source,
      'id = p_vehicle_id and organisation_id = v_org',
      'insert into public.workshop_inspections',
    );
    before(
      source,
      "m.organisation_id = v_org and m.is_active and m.role = 'technician'",
      'p_technician_profile_id := auth.uid()',
    );
    expect(source, contains('v_org, v_number, p_vehicle_id'));
    expect(source, contains("raise exception 'Active vehicle not found'"));
    expect(source, contains("raise exception 'Active technician not found'"));
  });

  test('template lookup and copied children are both company scoped', () {
    final source = body('workshop_create_inspection_from_template');
    before(
      source,
      'id=p_template_id and organisation_id = v_org',
      'if v_template_type',
    );
    expect(
      source,
      contains('ti.template_id=p_template_id and ti.organisation_id = v_org'),
    );
    expect(source, contains('where id=v_id and organisation_id = v_org'));
    expect(source, contains('select v_org, v_id, ti.id'));
    expect(source, contains('public.workshop_create_inspection(p_vehicle_id'));
    expect(
      source,
      contains("raise exception 'Active inspection template not found'"),
    );
  });

  test('preserves same-company workflows and changes only five functions', () {
    expect(RegExp('create or replace function').allMatches(sql), hasLength(5));
    expect(sql, startsWith('-- FleetIQ 17.4.7.2.1'));
    expect(sql.trim(), endsWith('commit;'));
    expect(sql, isNot(contains('drop table')));
    expect(sql, isNot(contains('delete from')));
    expect(
      body('fleet_assign_driver'),
      contains('if found then\n    return v_row;'),
    );
    expect(
      body('fleet_end_driver_assignment'),
      contains('if not v_row.is_active then\n    return v_row;'),
    );
    expect(
      body('workshop_create_inspection'),
      contains('p_technician_profile_id := auth.uid()'),
    );
    expect(
      body('workshop_create_inspection_from_template'),
      contains('ti.photo_required_on_fail, ti.allow_notes'),
    );
  });
}
