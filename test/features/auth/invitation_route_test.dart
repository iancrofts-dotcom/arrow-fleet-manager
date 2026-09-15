import 'package:arrow_fleet_manager/app/router.dart';
import 'package:arrow_fleet_manager/features/auth/invitation/invitation_route.dart';
import 'package:arrow_fleet_manager/features/auth/screens/set_password_screen.dart';
import 'package:arrow_fleet_manager/features/auth/widgets/protected_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Web path callback opens the set-password route', () {
    expect(
      InvitationRoute.initialRoute(
        uri: Uri.parse('https://fleet.example/set-password?code=secret'),
        isWeb: true,
      ),
      AppRouter.setPassword,
    );
  });

  test('Web query callback opens the set-password route under a base path', () {
    expect(
      InvitationRoute.initialRoute(
        uri: Uri.parse(
          'https://fleet.example/app/?route=set-password&code=secret',
        ),
        isWeb: true,
      ),
      AppRouter.setPassword,
    );
  });

  test('normal Web application startup remains on the root route', () {
    expect(
      InvitationRoute.initialRoute(
        uri: Uri.parse('https://fleet.example/app/'),
        isWeb: true,
      ),
      AppRouter.root,
    );
  });

  test('native startup remains on the normal root route', () {
    expect(
      InvitationRoute.initialRoute(
        uri: Uri.parse('file:///set-password'),
        isWeb: false,
      ),
      AppRouter.root,
    );
  });

  test('sanitization preserves only the hosting-safe route marker', () {
    expect(
      InvitationRoute.sanitizedLocation(
        Uri.parse(
          'https://fleet.example/app/?route=set-password&code=secret'
          '#access_token=secret',
        ),
      ),
      '/app/?route=set-password',
    );
    expect(
      InvitationRoute.sanitizedLocation(
        Uri.parse('https://fleet.example/set-password?code=secret'),
      ),
      '/set-password',
    );
  });

  testWidgets('set-password route is direct and not protected', (tester) async {
    final route = AppRouter.routes[AppRouter.setPassword]!;
    late Widget built;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            built = route(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(built, isA<SetPasswordScreen>());
    expect(built, isNot(isA<ProtectedScreen>()));
  });
}
