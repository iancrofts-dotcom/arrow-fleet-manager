import 'package:flutter/material.dart';

class AppPageScaffold extends StatelessWidget {
  const AppPageScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions,
    this.floatingActionButton,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: floatingActionButton,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final padding = constraints.maxWidth < 700 ? 20.0 : 24.0;
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1240),
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PageHeader(
                      title: title,
                      subtitle: subtitle,
                      actions: actions,
                      showBackButton: Navigator.of(context).canPop(),
                    ),
                    const SizedBox(height: 30),
                    Expanded(child: child),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.actions,
    this.showBackButton = false,
  });
  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<Widget>? actions;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(builder: (context, constraints) {
      final narrow = constraints.maxWidth < 700;
      final logoSize = narrow ? 56.0 : 80.0;
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(narrow ? 20 : 28),
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Wrap(
          spacing: 18,
          runSpacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (showBackButton)
              IconButton(
                tooltip: 'Back',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back),
              ),
            Image.asset(
              'assets/images/arrow_logo.png',
              width: logoSize,
              height: logoSize,
              fit: BoxFit.contain,
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: narrow ? constraints.maxWidth - 40 : 720,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Arrow Fleet Manager',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: scheme.onPrimaryContainer,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            if (icon != null) Icon(icon, color: scheme.onPrimaryContainer),
            if (actions != null) ...actions!,
          ],
        ),
      );
    });
  }
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({super.key, this.icon = Icons.inbox_outlined, required this.title, required this.message, this.action});
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 56, color: Theme.of(context).colorScheme.primary), const SizedBox(height: 16), Text(title, style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 8), Text(message, textAlign: TextAlign.center), if (action != null) ...[const SizedBox(height: 16), action!]])));
}

class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.child, this.title, this.padding = const EdgeInsets.all(20)});
  final Widget child;
  final String? title;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: padding,
          child: title == null
              ? child
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title!, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    child,
                  ],
                ),
        ),
      );
}

class AppLoadingState extends StatelessWidget {
  const AppLoadingState({super.key, this.label = 'Loading...'});
  final String label;
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const CircularProgressIndicator(), const SizedBox(height: 16), Text(label)]));
}

class AppErrorState extends StatelessWidget {
  const AppErrorState({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => AppEmptyState(
        icon: Icons.error_outline,
        title: 'Unable to load this page',
        message: message,
        action: onRetry == null ? null : FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Try again')),
      );
}
