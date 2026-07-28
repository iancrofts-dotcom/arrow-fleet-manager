import 'package:flutter/material.dart';

class ResponsiveDashboardLayout extends StatelessWidget {
  const ResponsiveDashboardLayout({
    super.key,
    required this.leftColumn,
    required this.rightColumn,
    this.spacing = 24,
    this.desktopBreakpoint = 1100,
  });

  final List<Widget> leftColumn;
  final List<Widget> rightColumn;
  final double spacing;
  final double desktopBreakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= desktopBreakpoint;

        if (!isDesktop) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ..._buildVertical(leftColumn),
              if (rightColumn.isNotEmpty) ...[
                SizedBox(height: spacing),
                ..._buildVertical(rightColumn),
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: _buildVertical(leftColumn),
              ),
            ),

            SizedBox(width: spacing),

            Expanded(
              child: Column(
                children: _buildVertical(rightColumn),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildVertical(List<Widget> widgets) {
    final result = <Widget>[];

    for (var i = 0; i < widgets.length; i++) {
      result.add(widgets[i]);

      if (i != widgets.length - 1) {
        result.add(SizedBox(height: spacing));
      }
    }

    return result;
  }
}