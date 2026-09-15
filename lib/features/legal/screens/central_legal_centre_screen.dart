import 'package:flutter/material.dart';

import '../../../backend/legal/central_legal_service.dart';

class CentralLegalCentreScreen extends StatefulWidget {
  const CentralLegalCentreScreen({super.key});

  @override
  State<CentralLegalCentreScreen> createState() =>
      _CentralLegalCentreScreenState();
}

class _CentralLegalCentreScreenState extends State<CentralLegalCentreScreen> {
  final _service = CentralLegalService();
  late final Future<List<CentralLegalDocument>> _documents = _service
      .listCurrentDocuments();
  Set<String> _required = {};

  @override
  void initState() {
    super.initState();
    _loadRequired();
  }

  Future<void> _loadRequired() async {
    final required = await _service.requiredAcceptances();
    if (mounted) {
      setState(() => _required = required.toSet());
    }
  }

  Future<void> _accept(CentralLegalDocument document) async {
    await _service.accept(kind: document.kind, version: document.version);
    await _loadRequired();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${document.title} accepted.')));
    }
  }

  Future<void> _request(String type) async {
    final controller = TextEditingController();
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('$type request'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Details'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Submit'),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        await _service.createDataRequest(
          requestType: type,
          details: controller.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request recorded for review.')),
          );
        }
      }
    } finally {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Legal & Privacy Centre')),
      body: FutureBuilder<List<CentralLegalDocument>>(
        future: _documents,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text('Unable to load legal information.'),
            );
          }
          final documents = snapshot.data ?? const [];
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'FleetIQ Legal & Privacy',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Review current legal documents, your acceptance status and privacy request options.',
              ),
              const SizedBox(height: 20),
              ...documents.map((document) {
                final key = '${document.kind}:${document.version}';
                return Card(
                  child: ExpansionTile(
                    title: Text(document.title),
                    subtitle: Text(
                      'Version ${document.version}${_required.contains(key) ? ' • Acceptance required' : ''}',
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: SelectableText(document.content),
                      ),
                      if (document.requiresAcceptance &&
                          _required.contains(key))
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: FilledButton(
                            onPressed: () => _accept(document),
                            child: const Text('Accept current version'),
                          ),
                        ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
              const Text(
                'Privacy requests',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => _request('access'),
                    child: const Text('Request access/export'),
                  ),
                  OutlinedButton(
                    onPressed: () => _request('rectification'),
                    child: const Text('Request correction'),
                  ),
                  OutlinedButton(
                    onPressed: () => _request('erasure'),
                    child: const Text('Request erasure'),
                  ),
                  OutlinedButton(
                    onPressed: () => _request('restriction'),
                    child: const Text('Request restriction'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Requests are reviewed rather than automatically deleting operational or audit records. Legal and contractual retention requirements may apply.',
              ),
            ],
          );
        },
      ),
    );
  }
}
