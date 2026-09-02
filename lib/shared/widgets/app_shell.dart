import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../app/router.dart';
import '../../features/auth/services/auth_service.dart';
import '../../features/auth/services/permission_service.dart';
import '../../features/auth/models/user_role.dart';

class AppShellDestination {
  const AppShellDestination({
    required this.label,
    required this.route,
    required this.icon,
    required this.isVisible,
  });

  final String label;
  final String route;
  final IconData icon;
  final bool Function(PermissionService permissions) isVisible;
}

class AppShellDestinations {
  const AppShellDestinations._();

  static const all = <AppShellDestination>[
    AppShellDestination(
      label: 'Dashboard',
      route: AppRouter.dashboard,
      icon: Icons.dashboard_outlined,
      isVisible: _alwaysVisible,
    ),
    AppShellDestination(
      label: 'Fleet',
      route: AppRouter.vehicles,
      icon: Icons.local_shipping_outlined,
      isVisible: _canViewVehicles,
    ),
    AppShellDestination(
      label: 'Drivers',
      route: AppRouter.drivers,
      icon: Icons.people_outline,
      isVisible: _canViewDrivers,
    ),
    AppShellDestination(
      label: 'Users',
      route: AppRouter.users,
      icon: Icons.manage_accounts_outlined,
      isVisible: _canManageUsers,
    ),
    AppShellDestination(
      label: 'Calendar',
      route: AppRouter.calendar,
      icon: Icons.calendar_month_outlined,
      isVisible: _canAccessCalendar,
    ),
    AppShellDestination(
      label: 'Workshop',
      route: AppRouter.workshop,
      icon: Icons.build_outlined,
      isVisible: _canAccessWorkshop,
    ),
    AppShellDestination(
      label: 'Reports',
      route: AppRouter.reports,
      icon: Icons.assessment_outlined,
      isVisible: _canViewReports,
    ),
    AppShellDestination(
      label: 'Documents',
      route: AppRouter.documents,
      icon: Icons.folder_outlined,
      isVisible: _canViewVehicles,
    ),
  ];

  static bool _alwaysVisible(PermissionService _) => true;
  static bool _canViewVehicles(PermissionService p) => p.canViewVehicles;
  static bool _canViewDrivers(PermissionService p) => p.canViewDrivers;
  static bool _canManageUsers(PermissionService p) => p.canManageUsers;
  static bool _canAccessCalendar(PermissionService p) => p.canAccessCalendar;
  static bool _canAccessWorkshop(PermissionService p) => p.canAccessWorkshop;
  static bool _canViewReports(PermissionService p) => p.canViewReports;
}

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.navigatorKey,
    required this.currentRoute,
    required this.child,
    this.isAuthenticated,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final ValueListenable<String> currentRoute;
  final Widget child;
  final bool? isAuthenticated;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 960 ||
            !(isAuthenticated ?? AuthService.instance.isLoggedIn)) {
          return child;
        }
        return Row(
          children: [
            _DesktopSidebar(
              navigatorKey: navigatorKey,
              currentRoute: currentRoute,
            ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.navigatorKey,
    required this.currentRoute,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final ValueListenable<String> currentRoute;

  bool _isSelected(String route, String currentRoute) {
    if (route == AppRouter.dashboard) {
      return currentRoute == AppRouter.dashboard;
    }
    return currentRoute == route;
  }

  void _navigate(String route) {
    if (currentRoute.value == route) return;
    navigatorKey.currentState?.pushNamedAndRemoveUntil(route, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final permissions = PermissionService.instance;
    final destinations = AppShellDestinations.all.where(
      (d) => d.isVisible(permissions),
    );
    return SizedBox(
      width: 264,
      child: Material(
        color: AppConstants.brandNavy,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spaceMd),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.06),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: SizedBox(
                  width: 160,
                  height: 132,
                  child: Image.asset(
                    'assets/images/arrow_logo_high.png',
                    key: const Key('sidebar-official-logo'),
                    fit: BoxFit.contain,
                    alignment: Alignment.centerLeft,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spaceXs),
              const Text(
                'Fleet Manager',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppConstants.spaceMd),
              Expanded(
                child: ValueListenableBuilder<String>(
                  valueListenable: currentRoute,
                  builder: (context, route, _) => ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      for (final destination in destinations)
                        _SidebarDestination(
                          destination: destination,
                          selected: _isSelected(destination.route, route),
                          onTap: () => _navigate(destination.route),
                        ),
                    ],
                  ),
                ),
              ),
              const Divider(color: Color(0x55FFFFFF)),
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                title: Text(
                  user?.username ?? 'Signed in',
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  user == null ? '' : user.role.displayName,
                  style: const TextStyle(color: Color(0xFFD0D5DD)),
                ),
              ),
              TextButton.icon(
                onPressed: () => AuthService.instance.logout(),
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarDestination extends StatelessWidget {
  const _SidebarDestination({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final AppShellDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
            const radius = BorderRadius.all(Radius.circular(10));
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spaceXxs),
      child: Semantics(
        selected: selected,
        button: true,
        label: destination.label,
        child: Ink(
          key: Key('sidebar-destination-${destination.route}'),
          height: 44,
          decoration: BoxDecoration(
            color: selected ? AppConstants.arrowBlue : Colors.transparent,
            borderRadius: radius,
          ),
          child: InkWell(
            borderRadius: radius,
            hoverColor: selected
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.08),
            highlightColor: Colors.white.withValues(alpha: 0.10),
            splashFactory: NoSplash.splashFactory,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spaceSm,
              ),
              child: Row(
                children: [
                  Icon(destination.icon, color: Colors.white, size: 20),
                  const SizedBox(width: AppConstants.spaceSm),
                  Text(
                    destination.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
