import 'dart:io';

import 'package:open_filex/open_filex.dart';

import 'package:flutter/material.dart';

import '../models/fleet_document.dart';
import '../services/document_service.dart';

class DocumentListScreen extends StatefulWidget {
  const DocumentListScreen({super.key});

  @override
  State<DocumentListScreen> createState() =>
      _DocumentListScreenState();
}

class _DocumentListScreenState
    extends State<DocumentListScreen> {
  final DocumentService _service =
      DocumentService();

  late Future<List<FleetDocument>>
      _documentsFuture;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  void _loadDocuments() {
    _documentsFuture = _service.getAll();
  }

  Future<void> _refresh() async {
  setState(() {
    _loadDocuments();
  });

  await _documentsFuture;
}

Future<void> _openDocument(
  FleetDocument document,
) async {
  if (document.filePath.isEmpty) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No file attached.'),
      ),
    );
    return;
  }

  final file = File(document.filePath);

  if (!await file.exists()) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Attached file not found.'),
      ),
    );
    return;
  }

  await OpenFilex.open(document.filePath);
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<List<FleetDocument>>(
        future: _documentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
              ),
            );
          }

          final documents =
              snapshot.data ?? [];

          if (documents.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Icon(
                    Icons.folder_open,
                    size: 72,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: Text(
                      'No documents found',
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              itemCount: documents.length,
              separatorBuilder: (context, index) =>
                      const Divider(height: 1),
              itemBuilder: (context, index) {
                final document =
                    documents[index];

                final status =
                    _service.status(
                  document.expiryDate,
                );

                return ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.description),
                  ),
                  title: Text(document.title),
                  subtitle: Text(
                    document.category.name
                        .toUpperCase(),
                  ),
                trailing: Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    if (document.filePath.isNotEmpty)
      const Padding(
        padding: EdgeInsets.only(right: 8),
        child: Icon(
          Icons.attach_file,
          size: 20,
        ),
      ),
    Chip(
      label: Text(status),
      backgroundColor: _statusColor(status),
    ),
  ],
),
                  onTap: () => _openDocument(document),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () {
          // Add document (Sprint 10.4)
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Document'),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Expired':
        return Colors.red.shade100;

      case 'Due Soon':
        return Colors.orange.shade100;

      default:
        return Colors.green.shade100;
    }
  }
}