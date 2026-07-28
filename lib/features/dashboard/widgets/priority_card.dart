import 'package:flutter/material.dart';

enum PriorityLevel {
  critical,
  warning,
  info,
  success,
}

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

    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      onEnter: (_) => setState(() => hovering = true),
      onExit: (_) => setState(() => hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: Matrix4.translationValues(
          0,
          hovering ? -2 : 0,
          0,
        ),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: colour,
            width: hovering ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: hovering ? 0.10 : 0.05,
              ),
              blurRadius: hovering ? 18 : 6,
              offset: Offset(0, hovering ? 8 : 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor:
                        colour.withValues(alpha: 0.15),
                    child: Icon(
                      widget.icon,
                      color: colour,
                    ),
                  ),

                  const SizedBox(width: 18),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.description,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Chip(
                        backgroundColor:
                            colour.withValues(alpha: 0.15),
                        side: BorderSide(
                          color:
                              colour.withValues(alpha: 0.35),
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
          ),
        ),
      ),
    );
  }
}