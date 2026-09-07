import 'package:flutter/material.dart';

class FleetIqBrand extends StatelessWidget {
  const FleetIqBrand.wide({super.key, this.height = 96}) : compact = false;

  const FleetIqBrand.compact({super.key, this.height = 36}) : compact = true;

  final bool compact;
  final double height;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: 'FleetIQ',
    child: Image.asset(
      compact
          ? 'assets/branding/fleetiq_icon_master.png'
          : 'assets/branding/fleetiq_logo_wide.png',
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) =>
          Text('FleetIQ', style: Theme.of(context).textTheme.headlineSmall),
    ),
  );
}
