import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/validators.dart';
import '../../data/models/appointment.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/pet_provider.dart';
import '../../providers/settings_provider.dart';

class AppointmentFormScreen extends StatefulWidget {
  const AppointmentFormScreen({
    super.key,
    this.appointment,
    this.initialPetId,
    this.initialDate,
  });

  final Appointment? appointment;
  final int? initialPetId;
  final DateTime? initialDate;

  @override
  State<AppointmentFormScreen> createState() => _AppointmentFormScreenState();
}

class _AppointmentFormScreenState extends State<AppointmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _locationController;
  late final TextEditingController _notesController;

  int? _petId;
  late AppointmentType _type;
  late DateTime _date;
  late TimeOfDay _time;
  late bool _reminderEnabled;
  bool _isSaving = false;

  bool get _isEditing => widget.appointment != null;

  @override
  void initState() {
    super.initState();
    final appt = widget.appointment;
    final pets = context.read<PetProvider>().pets;
    _petId = appt?.petId ??
        widget.initialPetId ??
        (pets.isNotEmpty ? pets.first.id : null);

    _type = appt?.type ?? AppointmentType.consultation;
    final initialDt =
        appt?.dateTime ?? widget.initialDate ?? DateTime.now().add(const Duration(days: 1));
    _date = DateTime(initialDt.year, initialDt.month, initialDt.day);
    _time = TimeOfDay(
      hour: appt?.dateTime.hour ?? 10,
      minute: appt?.dateTime.minute ?? 0,
    );
    _reminderEnabled = appt?.reminderEnabled ?? true;
    _titleController = TextEditingController(text: appt?.title ?? '');
    _locationController = TextEditingController(text: appt?.location ?? '');
    _notesController = TextEditingController(text: appt?.notes ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('pt', 'BR'),
      initialDate: _date,
      firstDate: DateTime(2015),
      lastDate: DateTime(2040),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_petId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um animal.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final combined = DateTime(
        _date.year,
        _date.month,
        _date.day,
        _time.hour,
        _time.minute,
      );
      final pet = context.read<PetProvider>().getById(_petId!);
      final settings = context.read<SettingsProvider>();
      final apptProvider = context.read<AppointmentProvider>();

      if (_isEditing) {
        final updated = widget.appointment!.copyWith(
          petId: _petId!,
          type: _type,
          title: _titleController.text.trim(),
          dateTime: combined,
          location: _locationController.text.trim(),
          notes: _notesController.text.trim(),
          reminderEnabled: _reminderEnabled,
        );
        await apptProvider.updateAppointment(
          updated,
          petName: pet?.name ?? 'Pet',
          notificationsEnabled: settings.notificationsEnabled,
          leadMinutes: settings.appointmentLeadMinutes,
        );
      } else {
        final created = Appointment(
          petId: _petId!,
          type: _type,
          title: _titleController.text.trim(),
          dateTime: combined,
          location: _locationController.text.trim(),
          notes: _notesController.text.trim(),
          reminderEnabled: _reminderEnabled,
          createdAt: DateTime.now(),
        );
        await apptProvider.addAppointment(
          created,
          petName: pet?.name ?? 'Pet',
          notificationsEnabled: settings.notificationsEnabled,
          leadMinutes: settings.appointmentLeadMinutes,
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
        title: Text(_isEditing ? 'Editar Compromisso' : 'Novo Compromisso'),
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
            DropdownButtonFormField<AppointmentType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Tipo de compromisso *'),
              items: AppointmentType.values
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(t.label),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _type = val);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Título / Descrição *',
                hintText: 'Ex.: Consulta de rotina, Hemograma, Banho',
              ),
              validator: (v) =>
                  AppValidators.requiredText(v, fieldName: 'O título'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(14),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Data *',
                        suffixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      child: Text(DateFormatter.formatDate(_date)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _pickTime,
                    borderRadius: BorderRadius.circular(14),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Horário *',
                        suffixIcon: Icon(Icons.access_time),
                      ),
                      child: Text(
                        '${_time.hour.toString().padLeft(2, '0')}:'
                        '${_time.minute.toString().padLeft(2, '0')}',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Local',
                hintText: 'Clínica, laboratório ou pet shop',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Observações',
                hintText: 'Jejum, documentos ou orientações...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: SwitchListTile(
                title: const Text('Lembrete por notificação'),
                subtitle: const Text(
                  'Receber aviso antes do horário agendado',
                ),
                activeThumbColor: AppColors.primary,
                value: _reminderEnabled,
                onChanged: (v) => setState(() => _reminderEnabled = v),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: Text(
                _isEditing ? 'Salvar alterações' : 'Agendar Compromisso',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

