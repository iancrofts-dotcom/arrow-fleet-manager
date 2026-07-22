import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'package:flutter/material.dart';
import '../../../database/database_service.dart';
import '../../../database/vehicle_repository.dart';
import '../../drivers/models/driver_entity.dart';
import '../../drivers/repositories/driver_repository.dart';
import '../../vehicles/models/vehicle.dart';
import '../models/fleet_document.dart';
import '../services/document_service.dart';
import 'package:file_picker/file_picker.dart';

enum DocumentOwnerType {
  driver,
  vehicle,
}

class EditDocumentScreen extends StatefulWidget {
  const EditDocumentScreen({
    super.key,
    this.document,
  });

  final FleetDocument? document;

  @override
  State<EditDocumentScreen> createState() =>
      _EditDocumentScreenState();

      }

class _EditDocumentScreenState
    extends State<EditDocumentScreen> {
  final _formKey = GlobalKey<FormState>();

  final DocumentService _service =
      DocumentService();

final DriverRepository _driverRepository =
    DriverRepository();

late final VehicleRepository _vehicleRepository;

List<DriverEntity> _drivers = [];
List<Vehicle> _vehicles = [];

DocumentOwnerType _ownerType =
    DocumentOwnerType.driver;

DriverEntity? _selectedDriver;
Vehicle? _selectedVehicle;

  late TextEditingController _titleController;
  late TextEditingController _notesController;
  String? _selectedFilePath;

  late DocumentCategory _category;

  late DateTime _issueDate;
  late DateTime _expiryDate;

  @override
  void initState() {
    super.initState();
    _vehicleRepository = VehicleRepository(
  databaseService: DatabaseService(),
);

_loadOwners();


    final document = widget.document;

    _titleController = TextEditingController(
      text: document?.title ?? '',
    );

    _notesController = TextEditingController(
      text: document?.notes ?? '',
    );

    _category =
        document?.category ??
        DocumentCategory.other;

    _issueDate =
        document?.issueDate ??
        DateTime.now();

    _expiryDate =
        document?.expiryDate ??
        DateTime.now().add(
          const Duration(days: 365),
        );
  }
Future<void> _loadOwners() async {
  final drivers =
      await _driverRepository.getAllDrivers();

  final vehicles =
      await _vehicleRepository.getVehicles();

  if (!mounted) return;

  setState(() {
    _drivers = drivers;
    _vehicles = vehicles;

    if (_drivers.isNotEmpty) {
      _selectedDriver = _drivers.first;
    }

    if (_vehicles.isNotEmpty) {
      _selectedVehicle = _vehicles.first;
    }
  });
}

Future<void> _pickFile() 
async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: [
      'pdf',
      'jpg',
      'jpeg',
      'png',
    ],
  );

  if (result == null) {
    return;
  }

  setState(() {
    _selectedFilePath = result.files.single.path;
  });
}

Future<String?> _copySelectedFile() async {
  if (_selectedFilePath == null) {
    return null;
  }

  final sourceFile = File(_selectedFilePath!);

  if (!await sourceFile.exists()) {
    return null;
  }

  final appDirectory =
      await getApplicationDocumentsDirectory();

  final documentsDirectory = Directory(
    path.join(
      appDirectory.path,
      'fleet_documents',
    ),
  );

  if (!await documentsDirectory.exists()) {
    await documentsDirectory.create(
      recursive: true,
    );
  }

  final fileName = path.basename(
    _selectedFilePath!,
  );

  final destination = File(
    path.join(
      documentsDirectory.path,
      fileName,
    ),
  );

  await sourceFile.copy(destination.path);

  return destination.path;
}
  Future<void> _pickIssueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _issueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      _issueDate = picked;
    });
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      _expiryDate = picked;
    });
  }

  Future<void> _save() async {
    final storedFile =
    await _copySelectedFile();
if (_ownerType == DocumentOwnerType.driver &&
    _selectedDriver == null) {
  if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Please select a driver.'),
    ),
  );
  return;
}

if (_ownerType == DocumentOwnerType.vehicle &&
    _selectedVehicle == null) {
  if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Please select a vehicle.'),
    ),
  );
  return;
}

    if (!_formKey.currentState!.validate()) {
      return;
      
    }

    final document = FleetDocument(
      id: widget.document?.id,
      title: _titleController.text.trim(),
      category: _category,
      filePath: storedFile ?? '',
      issueDate: _issueDate,
      expiryDate: _expiryDate,
      lastUpdated: DateTime.now(),
      notes: _notesController.text.trim(),
     driverId: _ownerType == DocumentOwnerType.driver
    ? _selectedDriver?.id
    : null,

vehicleId: _ownerType == DocumentOwnerType.vehicle
    ? _selectedVehicle?.id
    : null,
    );

    await _service.save(document);

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.document == null
              ? 'Add Document'
              : 'Edit Document',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Document Title',
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Enter a title';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<DocumentCategory>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
              ),
              items: DocumentCategory.values
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _category = value;
                });
              },
            ),

const SizedBox(height: 16),

const Text(
  'Document Owner',
  style: TextStyle(
    fontWeight: FontWeight.bold,
  ),
),

RadioGroup<DocumentOwnerType>(
  groupValue: _ownerType,
  onChanged: (DocumentOwnerType? value) {
    if (value == null) return;

    setState(() {
      _ownerType = value;
    });
  },
  child: Column(
    children: [
      RadioListTile<DocumentOwnerType>(
        title: const Text('Driver'),
        value: DocumentOwnerType.driver,
      ),
      RadioListTile<DocumentOwnerType>(
        title: const Text('Vehicle'),
        value: DocumentOwnerType.vehicle,
      ),
    ],
  ),
),

const SizedBox(height: 12),

if (_ownerType == DocumentOwnerType.driver)
  DropdownButtonFormField<DriverEntity>(
    initialValue: _selectedDriver,
    decoration: const InputDecoration(
      labelText: 'Driver',
    ),
    items: _drivers
        .map(
          (driver) => DropdownMenuItem(
            value: driver,
            child: Text(
              '${driver.firstName} ${driver.lastName}',
            ),
          ),
        )
        .toList(),
    onChanged: (driver) {
      setState(() {
        _selectedDriver = driver;
      });
    },
  ),

  if (_ownerType == DocumentOwnerType.vehicle)
  DropdownButtonFormField<Vehicle>(
    initialValue: _selectedVehicle,
    decoration: const InputDecoration(
      labelText: 'Vehicle',
    ),
    items: _vehicles
        .map(
          (vehicle) => DropdownMenuItem(
            value: vehicle,
            child: Text(vehicle.fleetNumber),
          ),
        )
        .toList(),
    onChanged: (vehicle) {
      setState(() {
        _selectedVehicle = vehicle;
      });
    },
  ),

            const SizedBox(height: 16),

            ListTile(
              title: const Text('Issue Date'),
              subtitle: Text(
                '${_issueDate.day}/${_issueDate.month}/${_issueDate.year}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickIssueDate,
            ),

            ListTile(
              title: const Text('Expiry Date'),
              subtitle: Text(
                '${_expiryDate.day}/${_expiryDate.month}/${_expiryDate.year}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickExpiryDate,
            ),

            const SizedBox(height: 16),

const SizedBox(height: 16),

OutlinedButton.icon(
  onPressed: _pickFile,
  icon: const Icon(Icons.attach_file),
  label: const Text('Attach Document'),
),

if (_selectedFilePath != null)
  Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Text(
      _selectedFilePath!,
      style: Theme.of(context)
          .textTheme
          .bodySmall,
    ),
  ),

            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                
                labelText: 'Notes',
              ),
              maxLines: 4,
            ),

            const SizedBox(height: 32),

            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Save Document'),
            ),
          ],
        ),
      ),
    );
  }
}