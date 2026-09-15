import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'production legal identity is FleetIQ and not a limited company fiction',
    () {
      final privacy = File('docs/legal/PRIVACY_NOTICE.md').readAsStringSync();
      expect(privacy, contains('Ian Crofts trading as FleetIQ'));
      expect(privacy, contains('20 Tunstall Drive'));
      expect(privacy, contains('NG5 1LZ'));
      expect(privacy, contains('privacy@fleetiq.org.uk'));
      expect(privacy, contains('support@fleetiq.org.uk'));
      expect(privacy, contains('www.fleetiq.org.uk'));
    },
  );

  test('subprocessor register confirms only assessed infrastructure', () {
    final register = File('docs/legal/SUBPROCESSORS.md').readAsStringSync();
    expect(register, contains('Supabase'));
    expect(
      register.toLowerCase(),
      contains('confirmed production infrastructure provider'),
    );
    expect(register, contains('only if and when'));
  });

  test('new migration versions legal copy and preserves old audit records', () {
    final migration = File(
      'supabase/migrations/20260915081500_legal_production_identity.sql',
    ).readAsStringSync();
    expect(migration, contains("set active = false"));
    expect(migration, contains("'2026-09-15.2'"));
    expect(migration, contains('Ian Crofts trading as FleetIQ'));
    expect(migration, contains('on conflict (kind, version) do update'));
    expect(
      migration,
      isNot(contains('delete from public.fleet_legal_documents')),
    );
  });

  test(
    'launch candidate still requires final legal and supplier verification',
    () {
      final review = File(
        'docs/legal/README_LEGAL_REVIEW.md',
      ).readAsStringSync();
      expect(review, contains('qualified UK solicitor'));
      expect(review, contains('verify Supabase project region'));
      expect(review, contains('create the branded mailboxes'));
    },
  );
}
