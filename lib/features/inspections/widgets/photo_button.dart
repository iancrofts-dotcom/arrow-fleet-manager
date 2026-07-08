import 'package:flutter/material.dart';

class PhotoButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const PhotoButton({
    super.key,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed ??
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Photo capture will be available in v0.4.0',
                ),
              ),
            );
          },
      icon: const Icon(Icons.camera_alt_outlined),
      label: const Text('Add Photo'),
    );
  }
}