import 'package:flutter/material.dart';

import '../../app/constants.dart';

enum SectionCardVariant {
  standard,
  kpi,
  action,
  alert,
  compact,
  dashboardPanel,
}

class AppPageScaffold extends StatelessWidget {
  const AppPageScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions,
    this.customHeader,
    this.floatingActionButton,
    this.maxContentWidth = AppConstants.contentMaxWidth,
    this.showBackButton,
    this.bodySpacing = AppConstants.spaceXl,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget>? actions;
  final Widget? customHeader;
  final Widget? floatingActionButton;
  final double maxContentWidth;
  final bool? showBackButton;
  final double bodySpacing;

  @override
  Widget build(BuildContext context) => Scaffold(
    floatingActionButton: floatingActionButton,
    body: LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 960;
        final phone = constraints.maxWidth <= 480;
        final padding = phone
            ? AppConstants.spaceSm
            : compact
            ? AppConstants.spaceMd
            : AppConstants.spaceLg;
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  customHeader ??
                      PageHeader(
                        title: title,
                        subtitle: subtitle,
                        actions: actions,
                        showBackButton:
                            showBackButton ?? Navigator.of(context).canPop(),
                      ),
                  SizedBox(
                    height: phone
                        ? AppConstants.spaceMd
                        : compact
                        ? AppConstants.spaceLg
                        : bodySpacing,
                  ),
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

class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.actions,
    this.showBackButton = false,
    this.brandLabel = 'FleetIQ',
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<Widget>? actions;
  final bool showBackButton;
  final String brandLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = MediaQuery.sizeOf(context).width < 960;
        final phone = MediaQuery.sizeOf(context).width <= 480;
        final logoSize = compact ? 56.0 : 80.0;
        return Container(
          key: const Key('page-header'),
          width: double.infinity,
          padding: phone
              ? const EdgeInsets.all(AppConstants.spaceSm)
              : EdgeInsets.all(compact ? AppConstants.spaceMd : 28),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(compact ? 16 : 24),
          ),
          child: Wrap(
            spacing: phone ? AppConstants.spaceSm : 18,
            runSpacing: phone ? AppConstants.spaceXs : AppConstants.spaceMd,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (showBackButton)
                IconButton(
                  key: const Key('page-header-back'),
                  tooltip: 'Back',
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: phone
                      ? IconButton.styleFrom(
                          minimumSize: const Size(40, 40),
                          padding: const EdgeInsets.all(8),
                        )
                      : null,
                  icon: const Icon(Icons.arrow_back),
                ),
              if (!compact)
                Image.asset(
                  'assets/images/arrow_logo.png',
                  width: logoSize,
                  height: logoSize,
                  fit: BoxFit.contain,
                ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!compact) ...[
                      Text(
                        brandLabel,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                    ],
                    Text(
                      title,
                      style:
                          (phone
                                  ? Theme.of(context).textTheme.titleLarge
                                  : Theme.of(context).textTheme.headlineMedium)
                              ?.copyWith(
                                color: scheme.onPrimaryContainer,
                                fontWeight: FontWeight.w900,
                              ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: phone ? AppConstants.spaceXxs : 6),
                      Text(
                        subtitle!,
                        style:
                            (phone
                                    ? Theme.of(context).textTheme.bodyMedium
                                    : Theme.of(context).textTheme.bodyLarge)
                                ?.copyWith(color: scheme.onPrimaryContainer),
                      ),
                    ],
                  ],
                ),
              ),
              if (icon != null) Icon(icon, color: scheme.onPrimaryContainer),
              if (actions != null && actions!.isNotEmpty)
                Wrap(
                  spacing: AppConstants.spaceXs,
                  runSpacing: AppConstants.spaceXs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: actions!,
                ),
            ],
          ),
        );
      },
    );
  }
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: AppConstants.spaceMd),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppConstants.spaceXs),
            Text(message, textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: AppConstants.spaceMd),
              action!,
            ],
          ],
        ),
      ),
    ),
  );
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.all(AppConstants.padding),
    this.margin,
    this.variant = SectionCardVariant.standard,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final SectionCardVariant variant;

  Color? _surfaceColor(ColorScheme scheme) => switch (variant) {
    SectionCardVariant.kpi => scheme.surfaceContainerLow,
    SectionCardVariant.action => scheme.surfaceContainerLowest,
    SectionCardVariant.alert => scheme.errorContainer,
    SectionCardVariant.compact => scheme.surface,
    SectionCardVariant.dashboardPanel => scheme.surfaceContainerLow,
    SectionCardVariant.standard => null,
  };

  @override
  Widget build(BuildContext context) => Card(
    margin: margin,
    elevation: variant == SectionCardVariant.action ? 1 : 0,
    color: _surfaceColor(Theme.of(context).colorScheme),
    child: Padding(
      padding: variant == SectionCardVariant.compact
          ? const EdgeInsets.all(AppConstants.spaceMd)
          : padding,
      child: title == null
          ? child
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title!,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: AppConstants.spaceSm),
                      trailing!,
                    ],
                  ],
                ),
                const SizedBox(height: AppConstants.spaceSm),
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
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppConstants.spaceLg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            height: 28,
            width: 28,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: AppConstants.spaceSm),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.title = 'Unable to load this page',
  });

  final String message;
  final VoidCallback? onRetry;
  final String title;

  @override
  Widget build(BuildContext context) => AppEmptyState(
    icon: Icons.error_outline,
    title: title,
    message: message,
    action: onRetry == null
        ? null
        : FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
  );
}
