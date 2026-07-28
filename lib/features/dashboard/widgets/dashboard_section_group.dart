import 'package:flutter/material.dart';

class DashboardSectionGroup extends StatelessWidget {
  const DashboardSectionGroup({
    super.key,
    required this.children,
    this.spacing = 24,
    this.breakpoint = 1000,
  });

  final List<Widget> children;
  final double spacing;
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Mobile layout
        if (constraints.maxWidth < breakpoint) {
          return Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1)
                  SizedBox(height: spacing),
              ],
            ],
          );
        }

        // Desktop/tablet layout
        return Column(
          children: [
            for (int i = 0; i < children.length; i += 2) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: children[i]),
                  SizedBox(width: spacing),
                  Expanded(
                    child: i + 1 < children.length
                        ? children[i + 1]
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
              if (i + 2 < children.length)
                SizedBox(height: spacing),
            ],
          ],
        );
      },
    );
  }
}