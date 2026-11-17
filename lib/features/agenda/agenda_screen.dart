import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/appointment.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/pet_provider.dart';
import '../../widgets/empty_state_card.dart';
import 'appointment_detail_screen.dart';
import 'appointment_form_screen.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final pets = context.watch<PetProvider>().pets;
    final apptProvider = context.watch<AppointmentProvider>();
    final dayAppointments = apptProvider.forDay(_selectedDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda'),
      ),
      body: pets.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: EmptyStateCard(
                  icon: Icons.calendar_month_outlined,
                  title: 'Cadastre um pet primeiro',
                  subtitle:
                      'Para agendar consultas, vacinas ou banho e tosa, cadastre pelo menos um animal em Meus Pets.',
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TableCalendar<Appointment>(
                      locale: 'pt_BR',
                      firstDay: DateTime(2018),
                      lastDay: DateTime(2040),
                      focusedDay: _focusedDay,
                      calendarFormat: _calendarFormat,
                      availableCalendarFormats: const {
                        CalendarFormat.month: 'Mês',
                        CalendarFormat.twoWeeks: '2 semanas',
                        CalendarFormat.week: 'Semana',
                      },
                      selectedDayPredicate: (day) =>
                          isSameDay(_selectedDay, day),
                      eventLoader: (day) => apptProvider.forDay(day),
                      onDaySelected: (selected, focused) {
                        setState(() {
                          _selectedDay = selected;
                          _focusedDay = focused;
                        });
                      },
                      onFormatChanged: (format) {
                        setState(() => _calendarFormat = format);
                      },
                      headerStyle: const HeaderStyle(
                        formatButtonShowsNext: false,
                        titleCentered: true,
                      ),
                      calendarStyle: CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        todayTextStyle: const TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                        selectedDecoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        markerDecoration: const BoxDecoration(
                          color: AppColors.alert,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Compromissos em ${DateFormatter.formatDate(_selectedDay)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                if (dayAppointments.isEmpty)
                  EmptyStateCard(
                    icon: Icons.event_available_outlined,
                    title: 'Nenhum compromisso neste dia',
                    subtitle:
                        'Toque em "Novo Compromisso" para agendar consulta, exame, vacinação ou banho e tosa.',
                    actionLabel: 'Novo Compromisso',
                    onAction: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => AppointmentFormScreen(
                            initialDate: _selectedDay,
                          ),
                        ),
                      );
                    },
                  )
                else
                  ...dayAppointments.map((appt) {
                    final pet = context.read<PetProvider>().getById(appt.petId);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: appt.completed
                                ? AppColors.surfaceCream
                                : AppColors.primaryLight,
                            child: Icon(
                              _iconForType(appt.type),
                              color: appt.completed
                                  ? AppColors.textMuted
                                  : AppColors.primaryDark,
                            ),
                          ),
                          title: Text(
                            appt.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              decoration: appt.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          subtitle: Text(
                            [
                              pet?.name ?? 'Pet',
                              appt.type.label,
                              DateFormatter.formatTime(appt.dateTime),
                              if (appt.location.isNotEmpty) appt.location,
                            ].join(' • '),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            if (appt.id == null) return;
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => AppointmentDetailScreen(
                                  appointmentId: appt.id!,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }),
              ],
            ),
      floatingActionButton: pets.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => AppointmentFormScreen(
                      initialDate: _selectedDay,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Agendar'),
            ),
    );
  }

  IconData _iconForType(AppointmentType type) {
    switch (type) {
      case AppointmentType.consultation:
        return Icons.medical_services_outlined;
      case AppointmentType.followUp:
        return Icons.assignment_return_outlined;
      case AppointmentType.exam:
        return Icons.biotech_outlined;
      case AppointmentType.vaccination:
        return Icons.vaccines_outlined;
      case AppointmentType.grooming:
        return Icons.content_cut_outlined;
    }
  }
}

