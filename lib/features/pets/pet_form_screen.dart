import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/validators.dart';
import '../../data/models/pet.dart';
import '../../providers/pet_provider.dart';

class PetFormScreen extends StatefulWidget {
  const PetFormScreen({super.key, this.pet});

  final Pet? pet;

  @override
  State<PetFormScreen> createState() => _PetFormScreenState();
}

class _PetFormScreenState extends State<PetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _breedController;
  late final TextEditingController _weightController;
  late final TextEditingController _notesController;

  late PetSpecies _species;
  late PetSex _sex;
  DateTime? _birthDate;
  String? _photoPath;
  bool _isSaving = false;

  bool get _isEditing => widget.pet != null;

  @override
  void initState() {
    super.initState();
    final pet = widget.pet;
    _nameController = TextEditingController(text: pet?.name ?? '');
    _breedController = TextEditingController(text: pet?.breed ?? '');
    _weightController = TextEditingController(
      text: pet?.currentWeight != null
          ? pet!.currentWeight!.toStringAsFixed(1)
          : '',
    );
    _notesController = TextEditingController(text: pet?.notes ?? '');
    _species = pet?.species ?? PetSpecies.dog;
    _sex = pet?.sex ?? PetSex.male;
    _birthDate = pet?.birthDate;
    _photoPath = pet?.photoPath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 900,
        maxHeight: 900,
        imageQuality: 85,
      );
      if (picked == null) return;

      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory(p.join(appDir.path, 'pet_photos'));
      if (!photosDir.existsSync()) {
        await photosDir.create(recursive: true);
      }
      final fileName =
          'pet_${DateTime.now().millisecondsSinceEpoch}${p.extension(picked.path)}';
      final savedFile =
          await File(picked.path).copy(p.join(photosDir.path, fileName));

      if (mounted) {
        setState(() => _photoPath = savedFile.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível selecionar a foto: $e')),
        );
      }
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Escolher da galeria'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Tirar foto'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.camera);
              },
            ),
            if (_photoPath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.danger),
                title: const Text(
                  'Remover foto',
                  style: TextStyle(color: AppColors.danger),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _photoPath = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('pt', 'BR'),
      initialDate: _birthDate ?? DateTime(now.year - 1, now.month, now.day),
      firstDate: DateTime(1990),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final birthError = AppValidators.validateBirthDate(_birthDate);
    if (birthError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(birthError)),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final now = DateTime.now();
      final weight = AppValidators.parseWeight(_weightController.text);
      final petProvider = context.read<PetProvider>();

      if (_isEditing) {
        final updated = widget.pet!.copyWith(
          name: _nameController.text.trim(),
          species: _species,
          breed: _breedController.text.trim(),
          sex: _sex,
          birthDate: _birthDate,
          clearBirthDate: _birthDate == null,
          currentWeight: weight,
          clearWeight: weight == null,
          photoPath: _photoPath,
          clearPhoto: _photoPath == null,
          notes: _notesController.text.trim(),
          updatedAt: now,
        );
        await petProvider.updatePet(updated);
      } else {
        final newPet = Pet(
          name: _nameController.text.trim(),
          species: _species,
          breed: _breedController.text.trim(),
          sex: _sex,
          birthDate: _birthDate,
          currentWeight: weight,
          photoPath: _photoPath,
          notes: _notesController.text.trim(),
          createdAt: now,
          updatedAt: now,
        );
        await petProvider.addPet(newPet);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = _photoPath != null && File(_photoPath!).existsSync();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Pet' : 'Novo Pet'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: GestureDetector(
                onTap: _showPhotoOptions,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: AppColors.primaryLight,
                      backgroundImage:
                          hasPhoto ? FileImage(File(_photoPath!)) : null,
                      child: !hasPhoto
                          ? const Icon(
                              Icons.pets_rounded,
                              size: 42,
                              color: AppColors.primaryDark,
                            )
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Toque para adicionar uma foto',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nome do animal *',
                hintText: 'Ex.: Thor, Luna',
              ),
              validator: (v) =>
                  AppValidators.requiredText(v, fieldName: 'O nome do animal'),
            ),
            const SizedBox(height: 16),
            Text(
              'Espécie *',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<PetSpecies>(
              segments: const [
                ButtonSegment(
                  value: PetSpecies.dog,
                  label: Text('Cão'),
                  icon: Icon(Icons.pets_rounded),
                ),
                ButtonSegment(
                  value: PetSpecies.cat,
                  label: Text('Gato'),
                  icon: Icon(Icons.pets_rounded),
                ),
              ],
              selected: {_species},
              onSelectionChanged: (val) => setState(() => _species = val.first),
            ),
            const SizedBox(height: 16),
            Text(
              'Sexo *',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<PetSex>(
              segments: const [
                ButtonSegment(
                  value: PetSex.male,
                  label: Text('Macho'),
                  icon: Icon(Icons.male),
                ),
                ButtonSegment(
                  value: PetSex.female,
                  label: Text('Fêmea'),
                  icon: Icon(Icons.female),
                ),
              ],
              selected: {_sex},
              onSelectionChanged: (val) => setState(() => _sex = val.first),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _breedController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Raça',
                hintText: 'Ex.: Golden Retriever, SRD',
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectBirthDate,
              borderRadius: BorderRadius.circular(14),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Data de nascimento',
                  suffixIcon: _birthDate != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _birthDate = null),
                        )
                      : const Icon(Icons.calendar_today_outlined),
                ),
                child: Text(
                  _birthDate != null
                      ? DateFormatter.formatDate(_birthDate!)
                      : 'Selecionar data (opcional)',
                  style: TextStyle(
                    color: _birthDate != null
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _weightController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Peso atual (kg)',
                hintText: 'Ex.: 12.5',
                suffixText: 'kg',
              ),
              validator: (v) =>
                  AppValidators.positiveWeight(v, required: false),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Observações',
                hintText: 'Alergias, comportamento, alimentação...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_isEditing ? 'Salvar alterações' : 'Cadastrar Pet'),
            ),
          ],
        ),
      ),
    );
  }
}

