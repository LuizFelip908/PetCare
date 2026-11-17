import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/validators.dart';
import '../../data/models/medication.dart';
import '../../providers/medication_provider.dart';
import '../../providers/pet_provider.dart';
import '../../providers/settings_provider.dart';

class MedicationFormScreen extends StatefulWidget {
  const MedicationFormScreen({
    super.key,
    this.medication,
    this.initialPetId,
  });

  final Medication? medication;
  final int? initialPetId;

  @override
  State<MedicationFormScreen> createState() => _MedicationFormScreenState();
}

class _MedicationFormScreenState extends State<MedicationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _dosageController;
  late final TextEditingController _instructionsController;

  int? _petId;
  late List<String> _schedules;
  late DateTime _startDate;
  DateTime? _endDate;
  late bool _reminderEnabled;
  late bool _isActive;
  bool _isSaving = false;

  bool get _isEditing => widget.medication != null;

  @override
  void initState() {
    super.initState();
    final med = widget.medication;
    final pets = context.read<PetProvider>().pets;
    _petId = med?.petId ??
        widget.initialPetId ??
        (pets.isNotEmpty ? pets.first.id : null);
    _schedules = List<String>.from(med?.schedules ?? ['08:00']);
    _startDate = med?.startDate ?? DateTime.now();
    _endDate = med?.endDate;
    _reminderEnabled = med?.reminderEnabled ?? true;
    _isActive = med?.isActive ?? true;
    _nameController = TextEditingController(text: med?.name ?? '');
    _dosageController = TextEditingController(text: med?.dosage ?? '');
    _instructionsController =
        TextEditingController(text: med?.instructions ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _addScheduleTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked == null) return;
    final formatted =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    if (!_schedules.contains(formatted)) {
      setState(() {
        _schedules.add(formatted);
        _schedules.sort();
      });
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('pt', 'BR'),
      initialDate: _startDate,
      firstDate: DateTime(2015),
      lastDate: DateTime(2040),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('pt', 'BR'),
      initialDate: _endDate ?? _startDate.add(const Duration(days: 7)),
      firstDate: _startDate,
      lastDate: DateTime(2040),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_petId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um animal.')),
      );
      return;
    }

    final timesError = AppValidators.validateMedicationTimes(_schedules);
    if (timesError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(timesError)),
      );
      return;
    }

    final rangeError = AppValidators.validateDateRange(_startDate, _endDate);
    if (rangeError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(rangeError)),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final pet = context.read<PetProvider>().getById(_petId!);
      final settings = context.read<SettingsProvider>();
      final medProvider = context.read<MedicationProvider>();

      if (_isEditing) {
        final updated = widget.medication!.copyWith(
          petId: _petId!,
          name: _nameController.text.trim(),
          dosage: _dosageController.text.trim(),
          schedules: _schedules,
          startDate: _startDate,
          endDate: _endDate,
          clearEndDate: _endDate == null,
          instructions: _instructionsController.text.trim(),
          reminderEnabled: _reminderEnabled,
          isActive: _isActive,
        );
        await medProvider.updateMedication(
          updated,
          petName: pet?.name ?? 'Pet',
          notificationsEnabled: settings.notificationsEnabled,
        );
      } else {
        final created = Medication(
          petId: _petId!,
          name: _nameController.text.trim(),
          dosage: _dosageController.text.trim(),
          schedules: _schedules,
          startDate: _startDate,
          endDate: _endDate,
          instructions: _instructionsController.text.trim(),
          reminderEnabled: _reminderEnabled,
          isActive: _isActive,
          createdAt: DateTime.now(),
        );
        await medProvider.addMedication(
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

  @override
  Widget build(BuildContext context) {
    final pets = context.watch<PetProvider>().pets;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Editar Medicamento' : 'Novo Medicamento',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.alertLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.alert, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Registre apenas medicamentos e orientações prescritos por um médico-veterinário.',
                      style: TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
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
                labelText: 'Nome do medicamento *',
                hintText: 'Ex.: Antipulgas, Suplemento',
              ),
              validator: (v) => AppValidators.requiredText(
                v,
                fieldName: 'O nome do medicamento',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dosageController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Dose / Quantidade',
                hintText: 'Ex.: 1 comprimido, 2 ml',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Horários de administração *',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                TextButton.icon(
                  onPressed: _addScheduleTime,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Adicionar horário'),
                ),
              ],
            ),
            if (_schedules.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Nenhum horário definido. Adicione ao menos um horário.',
                  style: TextStyle(color: AppColors.danger, fontSize: 13),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _schedules
                    .map(
                      (time) => Chip(
                        label: Text(time),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() => _schedules.remove(time));
                        },
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickStartDate,
                    borderRadius: BorderRadius.circular(14),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Data de início *',
                        suffixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      child: Text(DateFormatter.formatDate(_startDate)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _pickEndDate,
                    borderRadius: BorderRadius.circular(14),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Término',
                        suffixIcon: _endDate != null
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => setState(() => _endDate = null),
                              )
                            : const Icon(Icons.event_outlined),
                      ),
                      child: Text(
                        _endDate != null
                            ? DateFormatter.formatDate(_endDate!)
                            : 'Contínuo',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _instructionsController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Orientações da prescrição veterinária',
                hintText: 'Ex.: Dar junto com a refeição',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Lembretes de horário'),
                    subtitle: const Text('Notificar nos horários cadastrados'),
                    activeThumbColor: AppColors.primary,
                    value: _reminderEnabled,
                    onChanged: (v) => setState(() => _reminderEnabled = v),
                  ),
                  if (_isEditing) ...[
                    const Divider(),
                    SwitchListTile(
                      title: const Text('Tratamento ativo'),
                      activeThumbColor: AppColors.primary,
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: Text(
                _isEditing ? 'Salvar alterações' : 'Cadastrar Medicamento',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

