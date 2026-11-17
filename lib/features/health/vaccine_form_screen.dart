import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/validators.dart';
import '../../data/models/vaccine.dart';
import '../../providers/pet_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/vaccine_provider.dart';
import '../../widgets/confirmation_dialog.dart';

class VaccineFormScreen extends StatefulWidget {
  const VaccineFormScreen({
    super.key,
    this.vaccine,
    this.initialPetId,
  });

  final Vaccine? vaccine;
  final int? initialPetId;

  @override
  State<VaccineFormScreen> createState() => _VaccineFormScreenState();
}

class _VaccineFormScreenState extends State<VaccineFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _clinicController;
  late final TextEditingController _notesController;

  int? _petId;
  late DateTime _appliedAt;
  DateTime? _nextDoseAt;
  late bool _reminderEnabled;
  bool _isSaving = false;

  bool get _isEditing => widget.vaccine != null;

  @override
  void initState() {
    super.initState();
    final v = widget.vaccine;
    final pets = context.read<PetProvider>().pets;
    _petId = v?.petId ??
        widget.initialPetId ??
        (pets.isNotEmpty ? pets.first.id : null);
    _appliedAt = v?.appliedAt ?? DateTime.now();
    _nextDoseAt = v?.nextDoseAt;
    _reminderEnabled = v?.reminderEnabled ?? true;
    _nameController = TextEditingController(text: v?.name ?? '');
    _clinicController = TextEditingController(text: v?.clinic ?? '');
    _notesController = TextEditingController(text: v?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _clinicController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickAppliedDate() async {
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('pt', 'BR'),
      initialDate: _appliedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _appliedAt = picked);
  }

  Future<void> _pickNextDoseDate() async {
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('pt', 'BR'),
      initialDate: _nextDoseAt ?? _appliedAt.add(const Duration(days: 365)),
      firstDate: _appliedAt.add(const Duration(days: 1)),
      lastDate: DateTime(2040),
    );
    if (picked != null) setState(() => _nextDoseAt = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_petId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um animal.')),
      );
      return;
    }

    final nextDoseError =
        AppValidators.validateNextDoseDate(_appliedAt, _nextDoseAt);
    if (nextDoseError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(nextDoseError)),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final pet = context.read<PetProvider>().getById(_petId!);
      final settings = context.read<SettingsProvider>();
      final vaccineProvider = context.read<VaccineProvider>();

      if (_isEditing) {
        final updated = widget.vaccine!.copyWith(
          petId: _petId!,
          name: _nameController.text.trim(),
          appliedAt: _appliedAt,
          nextDoseAt: _nextDoseAt,
          clearNextDose: _nextDoseAt == null,
          clinic: _clinicController.text.trim(),
          notes: _notesController.text.trim(),
          reminderEnabled: _reminderEnabled,
        );
        await vaccineProvider.updateVaccine(
          updated,
          petName: pet?.name ?? 'Pet',
          notificationsEnabled: settings.notificationsEnabled,
        );
      } else {
        final created = Vaccine(
          petId: _petId!,
          name: _nameController.text.trim(),
          appliedAt: _appliedAt,
          nextDoseAt: _nextDoseAt,
          clinic: _clinicController.text.trim(),
          notes: _notesController.text.trim(),
          reminderEnabled: _reminderEnabled,
          createdAt: DateTime.now(),
        );
        await vaccineProvider.addVaccine(
          created,
          petName: pet?.name ?? 'Pet',
          notificationsEnabled: settings.notificationsEnabled,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Excluir vacina',
      message: 'Deseja remover "${widget.vaccine!.name}" da carteira?',
    );
    if (!confirmed || !mounted) return;
    await context.read<VaccineProvider>().deleteVaccine(widget.vaccine!.id!);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final pets = context.watch<PetProvider>().pets;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Vacina' : 'Registrar Vacina'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<int>(
              initialValue: _petId,
              decoration: const InputDecoration(labelText: 'Animal *'),
              items: pets
                  .map(
                    (p) => DropdownMenuItem<int>(
                      value: p.id,
                      child: Text(p.name),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _petId = val),
              validator: (v) => v == null ? 'Selecione um animal.' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nome da vacina *',
                hintText: 'Ex.: V10, Antirrábica, V4',
              ),
              validator: (v) =>
                  AppValidators.requiredText(v, fieldName: 'O nome da vacina'),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickAppliedDate,
              borderRadius: BorderRadius.circular(14),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Data de aplicação *',
                  suffixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(DateFormatter.formatDate(_appliedAt)),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickNextDoseDate,
              borderRadius: BorderRadius.circular(14),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Próxima dose (indicada pelo veterinário)',
                  suffixIcon: _nextDoseAt != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _nextDoseAt = null),
                        )
                      : const Icon(Icons.event_repeat_outlined),
                ),
                child: Text(
                  _nextDoseAt != null
                      ? DateFormatter.formatDate(_nextDoseAt!)
                      : 'Opcional',
                  style: TextStyle(
                    color: _nextDoseAt != null
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _clinicController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Clínica veterinária',
                hintText: 'Local onde foi aplicada',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Observações',
                hintText: 'Lote, médico-veterinário ou reações...',
                alignLabelWithHint: true,
              ),
            ),
            if (_nextDoseAt != null) ...[
              const SizedBox(height: 12),
              Card(
                child: SwitchListTile(
                  title: const Text('Lembrete da próxima dose'),
                  subtitle: const Text(
                    'Notificar no dia previsto da próxima aplicação',
                  ),
                  activeThumbColor: AppColors.primary,
                  value: _reminderEnabled,
                  onChanged: (v) => setState(() => _reminderEnabled = v),
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: Text(_isEditing ? 'Salvar alterações' : 'Salvar Vacina'),
            ),
          ],
        ),
      ),
    );
  }
}

