import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../app/router.dart';
import '../../config/backend_mode.dart';
import '../../features/auth/screens/central/central_my_profile_screen.dart';
import 'fleetiq_brand.dart';
import 'central_organisation_switcher.dart';
import '../../features/auth/services/auth_service.dart';
import '../../features/auth/services/permission_service.dart';
import '../../features/auth/models/user_role.dart';
import '../../platform/platform_capabilities.dart';

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
      label: 'Compliance',
      route: AppRouter.compliance,
      icon: Icons.verified_user_outlined,
      isVisible: _canViewCompliance,
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
    AppShellDestination(
      label: 'Vehicle',
      route: AppRouter.driverVehicle,
      icon: Icons.local_shipping_outlined,
      isVisible: _isDriver,
    ),
    AppShellDestination(
      label: 'Inspection',
      route: AppRouter.driverInspection,
      icon: Icons.fact_check_outlined,
      isVisible: _isDriver,
    ),
    AppShellDestination(
      label: 'Compliance',
      route: AppRouter.driverCompliance,
      icon: Icons.verified_user_outlined,
      isVisible: _isDriver,
    ),
    AppShellDestination(
      label: 'Documents',
      route: AppRouter.driverDocuments,
      icon: Icons.folder_shared_outlined,
      isVisible: _isDriver,
    ),
    AppShellDestination(
      label: 'Profile',
      route: AppRouter.driverProfile,
      icon: Icons.person_outline,
      isVisible: _isDriver,
    ),
  ];

  static Iterable<AppShellDestination> visible(PermissionService permissions) {
    final capabilities = PlatformCapabilities.current();
    return all.where(
      (destination) =>
          capabilities.routeAvailable(destination.route) &&
          destination.isVisible(permissions),
    );
  }

  static bool _alwaysVisible(PermissionService _) => true;
  static bool _canViewVehicles(PermissionService p) => p.canViewVehicles;
  static bool _canViewDrivers(PermissionService p) => p.canViewDrivers;
  static bool _canManageUsers(PermissionService p) => p.canManageUsers;
  static bool _canAccessCalendar(PermissionService p) => p.canAccessCalendar;
  static bool _canAccessWorkshop(PermissionService p) => p.canAccessWorkshop;
  static bool _canViewCompliance(PermissionService p) => p.canViewCompliance;
  static bool _canViewReports(PermissionService p) => p.canViewReports;
  static bool _isDriver(PermissionService p) => p.isDriver;
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
          return (isAuthenticated ?? AuthService.instance.isLoggedIn)
              ? _MobileShell(
                  navigatorKey: navigatorKey,
                  currentRoute: currentRoute,
                  child: child,
                )
              : child;
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

class _MobileShell extends StatelessWidget {
  const _MobileShell({
    required this.navigatorKey,
    required this.currentRoute,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final ValueListenable<String> currentRoute;
  final Widget child;

  void _navigate(String route) {
    // Always reset to the selected module root. A feature screen may have been
    // pushed locally while currentRoute still points at the module, so treating
    // a same-route tap as a no-op traps users behind repeated Back presses.
    navigatorKey.currentState?.pushNamedAndRemoveUntil(route, (_) => false);
  }

  void _showMore(List<AppShellDestination> destinations) {
    navigatorKey.currentState?.push(
      MaterialPageRoute<void>(
        builder: (_) => _MobileMoreScreen(
          destinations: destinations,
          onNavigate: _navigate,
        ),
      ),
    );
  }

  void _openProfile() {
    navigatorKey.currentState?.push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => const CentralMyProfileScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: currentRoute,
      builder: (context, route, _) {
        final permissions = PermissionService.instance;
        final visible = AppShellDestinations.visible(permissions).toList();
        // When a role only has a small number of modules, show every one of
        // them directly. Requiring Drivers/Technicians to open More for one or
        // two permitted destinations adds needless navigation.
        final primary = permissions.isDriver
            ? visible
                  .where(
                    (destination) =>
                        destination.route == AppRouter.dashboard ||
                        destination.route == AppRouter.driverVehicle ||
                        destination.route == AppRouter.driverInspection ||
                        destination.route == AppRouter.driverCompliance,
                  )
                  .toList()
            : visible.length <= 5
            ? visible
            : visible
                  .where(
                    (destination) =>
                        destination.route == AppRouter.dashboard ||
                        destination.route == AppRouter.vehicles ||
                        destination.route == AppRouter.drivers ||
                        destination.route == AppRouter.workshop,
                  )
                  .take(4)
                  .toList();
        final primaryRoutes = primary
            .map((destination) => destination.route)
            .toSet();
        final secondary = visible
            .where((destination) => !primaryRoutes.contains(destination.route))
            .toList();
        final selectedPrimaryIndex = primary.indexWhere(
          (destination) => destination.route == route,
        );

        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppConstants.brandNavy,
            foregroundColor: Colors.white,
            titleSpacing: 0,
            leadingWidth: 52,
            leading: Padding(
              padding: const EdgeInsets.all(10),
              child: const FleetIqBrand.compact(height: 32),
            ),
            title: Text(_titleFor(route)),
            actions: [
              if (AuthService.instance.backendMode == BackendMode.supabase &&
                  !PermissionService.instance.isDriver)
                IconButton(
                  key: const Key('mobile-my-profile'),
                  tooltip: 'My Profile',
                  onPressed: _openProfile,
                  icon: const Icon(Icons.account_circle_outlined),
                ),
            ],
          ),
          body: child,
          bottomNavigationBar: _CompactBottomNavigation(
            destinations: primary,
            selectedIndex: selectedPrimaryIndex < 0 ? 0 : selectedPrimaryIndex,
            onNavigate: _navigate,
            onMore: secondary.isEmpty ? null : () => _showMore(secondary),
          ),
        );
      },
    );
  }

  String _titleFor(String route) {
    for (final destination in AppShellDestinations.all) {
      if (destination.route == route) return destination.label;
    }
    return 'Fleet Manager';
  }
}

class _CompactBottomNavigation extends StatelessWidget {
  const _CompactBottomNavigation({
    required this.destinations,
    required this.selectedIndex,
    required this.onNavigate,
    this.onMore,
  });

  final List<AppShellDestination> destinations;
  final int selectedIndex;
  final ValueChanged<String> onNavigate;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const Key('compact-bottom-navigation'),
      color: Colors.white,
      child: SizedBox(
        height: 64,
        child: SafeArea(
          top: false,
          child: Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppConstants.borderColor)),
            ),
            child: Row(
              children: [
                for (var index = 0; index < destinations.length; index++)
                  Expanded(
                    child: _CompactNavigationDestination(
                      destination: destinations[index],
                      selected: index == selectedIndex,
                      onTap: () => onNavigate(destinations[index].route),
                    ),
                  ),
                if (onMore != null)
                  Expanded(
                    child: _CompactNavigationDestination(
                      label: 'More',
                      icon: Icons.more_horiz,
                      selected: false,
                      onTap: onMore!,
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

class _CompactNavigationDestination extends StatelessWidget {
  const _CompactNavigationDestination({
    this.destination,
    this.label,
    this.icon,
    required this.selected,
    required this.onTap,
  }) : assert(destination != null || (label != null && icon != null));

  final AppShellDestination? destination;
  final String? label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final destinationLabel = destination?.label ?? label!;
    final destinationIcon = destination?.icon ?? icon!;
    final color = selected ? AppConstants.arrowBlue : AppConstants.neutralColor;

    return Semantics(
      button: true,
      selected: selected,
      label: destinationLabel,
      child: InkWell(
        key: Key('compact-destination-$destinationLabel'),
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(destinationIcon, color: color, size: 21),
              const SizedBox(height: 2),
              Text(
                destinationLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileMoreScreen extends StatelessWidget {
  const _MobileMoreScreen({
    required this.destinations,
    required this.onNavigate,
  });

  final List<AppShellDestination> destinations;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.spaceMd),
        children: [
          for (final destination in destinations)
            ListTile(
              leading: Icon(destination.icon),
              title: Text(destination.label),
              onTap: () => onNavigate(destination.route),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () => AuthService.instance.logout(),
          ),
        ],
      ),
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
    // Reset to the module root even when currentRoute already matches. Deep
    // feature screens are commonly pushed without changing the route notifier.
    navigatorKey.currentState?.pushNamedAndRemoveUntil(route, (route) => false);
  }

  void _openProfile() {
    navigatorKey.currentState?.push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => const CentralMyProfileScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final permissions = PermissionService.instance;
    final destinations = AppShellDestinations.visible(permissions);
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
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppConstants.borderColor),
                        ),
                        child: const FleetIqBrand.compact(height: 88),
                      ),
                      const SizedBox(height: AppConstants.spaceXs),
                      const Text(
                        'FleetIQ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
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
                if (AuthService.instance.backendMode == BackendMode.supabase &&
                    !PermissionService.instance.isDriver) ...[
                  const CentralOrganisationSwitcher(),
                  const SizedBox(height: AppConstants.spaceXs),
                ],
                const Divider(color: Color(0x55FFFFFF)),
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  onTap:
                      AuthService.instance.backendMode ==
                              BackendMode.supabase &&
                          !PermissionService.instance.isDriver
                      ? _openProfile
                      : null,
                  leading: const CircleAvatar(
                    child: Icon(Icons.person_outline),
                  ),
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
