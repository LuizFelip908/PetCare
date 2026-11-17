import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/date_formatter.dart';
import '../../core/utils/validators.dart';
import '../../data/models/weight_record.dart';
import '../../providers/pet_provider.dart';
import '../../providers/weight_provider.dart';

class WeightFormScreen extends StatefulWidget {
  const WeightFormScreen({
    super.key,
    this.record,
    this.initialPetId,
  });

  final WeightRecord? record;
  final int? initialPetId;

  @override
  State<WeightFormScreen> createState() => _WeightFormScreenState();
}

class _WeightFormScreenState extends State<WeightFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _weightController;
  late final TextEditingController _notesController;

  int? _petId;
  late DateTime _recordedAt;
  bool _isSaving = false;

  bool get _isEditing => widget.record != null;

  @override
  void initState() {
    super.initState();
    final rec = widget.record;
    final pets = context.read<PetProvider>().pets;
    _petId = rec?.petId ??
        widget.initialPetId ??
        (pets.isNotEmpty ? pets.first.id : null);
    _recordedAt = rec?.recordedAt ?? DateTime.now();
    _weightController = TextEditingController(
      text: rec != null ? rec.weightKg.toStringAsFixed(2) : '',
    );
    _notesController = TextEditingController(text: rec?.notes ?? '');
  }

  @override
  void dispose() {
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('pt', 'BR'),
      initialDate: _recordedAt,
      firstDate: DateTime(2005),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _recordedAt = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_petId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um animal.')),
      );
      return;
    }

    final weight = AppValidators.parseWeight(_weightController.text);
    if (weight == null || weight <= 0) return;

    setState(() => _isSaving = true);
    try {
      final weightProvider = context.read<WeightProvider>();
      final petProvider = context.read<PetProvider>();

      if (_isEditing) {
        await weightProvider.updateRecord(
          widget.record!.copyWith(
            petId: _petId!,
            weightKg: weight,
            recordedAt: _recordedAt,
            notes: _notesController.text.trim(),
          ),
        );
      } else {
        await weightProvider.addRecord(
          WeightRecord(
            petId: _petId!,
            weightKg: weight,
            recordedAt: _recordedAt,
            notes: _notesController.text.trim(),
          ),
        );
      }
      await petProvider.loadPets();
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
        title: Text(_isEditing ? 'Editar Peso' : 'Registrar Peso'),
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
              onChanged: _isEditing
                  ? null
                  : (val) => setState(() => _petId = val),
              validator: (v) => v == null ? 'Selecione um animal.' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _weightController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Peso (kg) *',
                hintText: 'Ex.: 12.4',
                suffixText: 'kg',
              ),
              validator: (v) => AppValidators.positiveWeight(v, required: true),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(14),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Data da medição *',
                  suffixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(DateFormatter.formatDate(_recordedAt)),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Observações',
                hintText: 'Ex.: Pesagem na clínica',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: Text(_isEditing ? 'Salvar alterações' : 'Salvar Peso'),
            ),
          ],
        ),
      ),
    );
  }
}

