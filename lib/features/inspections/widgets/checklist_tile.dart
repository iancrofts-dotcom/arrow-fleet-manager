import 'dart:io';

import 'package:flutter/material.dart';

import '../models/inspection_item.dart';
import '../services/photo_service.dart';
import 'photo_button.dart';

class ChecklistTile extends StatefulWidget {
  final InspectionItem item;
  final ValueChanged<InspectionStatus> onStatusChanged;
  final ValueChanged<String> onNotesChanged;

  const ChecklistTile({
    super.key,
    required this.item,
    required this.onStatusChanged,
    required this.onNotesChanged,
  });

  @override
  State<ChecklistTile> createState() =>
      _ChecklistTileState();
}

class _ChecklistTileState
    extends State<ChecklistTile> {
  final PhotoService _photoService =
      PhotoService();

  Future<void> _addPhoto() async {
    final imagePath =
        await _photoService.pickPhoto();

    if (imagePath == null) return;

    setState(() {
      widget.item.photoPath = imagePath;
    });
  }

  Future<void> _removePhoto() async {
    await _photoService.deletePhoto(
      widget.item.photoPath,
    );

    setState(() {
      widget.item.photoPath = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    final isFailed =
        item.status == InspectionStatus.fail;

    return Card(
      elevation: 2,
      margin:
          const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            SegmentedButton<InspectionStatus>(
              segments: const [
                ButtonSegment(
                  value:
                      InspectionStatus.pass,
                  icon: Icon(
                    Icons.check_circle,
                  ),
                  label: Text("PASS"),
                ),
                ButtonSegment(
                  value:
                      InspectionStatus.fail,
                  icon: Icon(Icons.cancel),
                  label: Text("FAIL"),
                ),
                ButtonSegment(
                  value: InspectionStatus
                      .notApplicable,
                  icon: Icon(
                    Icons.remove_circle,
                  ),
                  label: Text("N/A"),
                ),
              ],
              selected: {item.status},
              onSelectionChanged:
                  (selection) {
                widget.onStatusChanged(
                  selection.first,
                );
              },
            ),

            if (isFailed) ...[
              const SizedBox(height: 16),

              TextField(
                controller:
                    TextEditingController(
                  text: item.notes,
                )..selection =
                    TextSelection.fromPosition(
                  TextPosition(
                    offset:
                        item.notes.length,
                  ),
                ),
                decoration:
                    const InputDecoration(
                  labelText:
                      "Defect Notes",
                  border:
                      OutlineInputBorder(),
                ),
                onChanged:
                    widget.onNotesChanged,
              ),

              const SizedBox(height: 12),
                            PhotoButton(
                onPressed: _addPhoto,
              ),

              if (item.photoPath != null) ...[
                const SizedBox(height: 16),

                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(8),
                  child: Image.file(
                    File(item.photoPath!),
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) {
                      return Container(
                        height: 180,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius:
                              BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Unable to load photo',
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _addPhoto,
                      icon: const Icon(
                        Icons.refresh,
                      ),
                      label: const Text(
                        'Replace Photo',
                      ),
                    ),

                    const SizedBox(width: 12),

                    OutlinedButton.icon(
                      onPressed: _removePhoto,
                      icon: const Icon(
                        Icons.delete_outline,
                      ),
                      label: const Text(
                        'Remove',
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}