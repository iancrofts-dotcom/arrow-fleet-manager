import 'package:flutter/material.dart';

import 'app_page_scaffold.dart';

class FormSection extends StatelessWidget {
  const FormSection({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.all(20),
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => SectionCard(
    margin: const EdgeInsets.only(bottom: 20),
    title: title,
    subtitle: subtitle,
    trailing: trailing,
    padding: padding,
    child: child,
  );
}
