import 'package:flutter/material.dart';

class DashboardGrid extends StatelessWidget {
  const DashboardGrid({
    super.key,
    required this.children,
    this.spacing = 24,
    this.desktopBreakpoint = 1000,
    this.tabletBreakpoint = 700,
  });

  final List<Widget> children;
  final double spacing;
  final double desktopBreakpoint;
  final double tabletBreakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 1;

        if (constraints.maxWidth >= desktopBreakpoint) {
          crossAxisCount = 2;
        } else if (constraints.maxWidth >= tabletBreakpoint) {
          crossAxisCount = 2;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: children.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: 1.4,
          ),
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}