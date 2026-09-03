import 'package:flutter/material.dart';

enum PriorityLevel { critical, warning, info, success }

class PriorityCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final PriorityLevel level;
  final VoidCallback? onTap;

  const PriorityCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.level,
    this.onTap,
  });

  @override
  State<PriorityCard> createState() => _PriorityCardState();
}

class _PriorityCardState extends State<PriorityCard> {
  bool hovering = false;

  Color get colour {
    switch (widget.level) {
      case PriorityLevel.critical:
        return Colors.red;

      case PriorityLevel.warning:
        return Colors.orange;

      case PriorityLevel.info:
        return Colors.blue;

      case PriorityLevel.success:
        return Colors.green;
    }
  }

  String get label {
    switch (widget.level) {
      case PriorityLevel.critical:
        return "Critical";

      case PriorityLevel.warning:
        return "Warning";

      case PriorityLevel.info:
        return "Information";

      case PriorityLevel.success:
        return "Healthy";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final desktop = MediaQuery.sizeOf(context).width > 480;

    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      onEnter: (_) => setState(() => hovering = true),
      onExit: (_) => setState(() => hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: Matrix4.translationValues(0, hovering ? -2 : 0, 0),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: hovering ? 0.08 : 0.03),
              blurRadius: hovering ? 12 : 5,
              offset: Offset(0, hovering ? 5 : 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: widget.onTap,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Container(width: 3, color: colour),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(desktop ? 16 : 18),
                  child: Row(
                    children: [
                      Container(
                        width: desktop ? 42 : 48,
                        height: desktop ? 42 : 48,
                        decoration: BoxDecoration(
                          color: colour.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(widget.icon, color: colour),
                      ),

                      SizedBox(width: desktop ? 14 : 18),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: desktop ? 4 : 6),
                            Text(
                              widget.description,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(width: desktop ? 12 : 16),

                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Chip(
                            backgroundColor: colour.withValues(alpha: 0.15),
                            side: BorderSide(
                              color: colour.withValues(alpha: 0.35),
                            ),
                            label: Text(
                              label,
                              style: TextStyle(
                                color: colour,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          if (widget.onTap != null) ...[
                            const SizedBox(height: 8),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                          ],
                        ],
                      ),
                    ],
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
