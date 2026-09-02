import 'package:flutter/material.dart';

class DashboardHeroHeader extends StatelessWidget {
  const DashboardHeroHeader({
    super.key,
    required this.onRefresh,
    required this.onLogout,
  });

  final VoidCallback onRefresh;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 800;
        final actions = Wrap(
          spacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
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
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(24),
          ),
          child: narrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    brand,
                    const SizedBox(height: 20),
                    identity,
                    const SizedBox(height: 20),
                    actions,
                  ],
                )
              : Row(
                  children: [
                    SizedBox(width: 360, child: brand),
                    const SizedBox(width: 32),
                    Expanded(child: identity),
                    actions,
                  ],
                ),
        );
      },
    );
  }
}
