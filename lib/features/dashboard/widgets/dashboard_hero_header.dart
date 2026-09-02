import 'package:flutter/material.dart';

class DashboardHeroHeader extends StatelessWidget {
  const DashboardHeroHeader({
    super.key,
    required this.onRefresh,
    required this.onLogout,
    this.showBrand = true,
    this.showLogout = true,
    this.showIdentity = true,
  });

  final VoidCallback onRefresh;
  final VoidCallback onLogout;
  final bool showBrand;
  final bool showLogout;
  final bool showIdentity;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 800;
        final compact = MediaQuery.sizeOf(context).width < 960;
        final actions = Wrap(
          spacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
            if (showLogout)
              FilledButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
              ),
          ],
        );
        final brand = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/arrow_logo.png',
              width: narrow ? 150 : 178,
              height: narrow ? 52 : 62,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 16),
            Flexible(
              child: Text(
                'Arrow Fleet Manager',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
        final identity = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Dashboard',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Fleet overview and operational status.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: scheme.onPrimaryContainer),
            ),
          ],
        );
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(compact ? 16 : 24),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(24),
          ),
          child: narrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showBrand) brand,
                    if (showBrand || showIdentity)
                      const SizedBox(height: 20),
                    if (showIdentity) identity,
                    if (showIdentity) const SizedBox(height: 20),
                    actions,
                  ],
                )
              : Row(
                  children: [
                    if (showBrand) ...[
                      SizedBox(width: 360, child: brand),
                      const SizedBox(width: 32),
                    ],
                    if (showIdentity) Expanded(child: identity),
                    actions,
                  ],
                ),
        );
      },
    );
  }
}
