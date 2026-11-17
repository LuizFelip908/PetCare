import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Política de Privacidade'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _PolicySection(
            title: '1. Armazenamento Local e Privacidade',
            body:
                'O aplicativo PetCare armazena todas as informações cadastradas (perfis dos animais, fotos, vacinas, medicamentos, agendamentos e registros de peso) exclusivamente no armazenamento local do seu dispositivo (banco de dados SQLite). Não enviamos, vendemos ou compartilhamos seus dados com servidores externos.',
          ),
          _PolicySection(
            title: '2. Permissões Utilizadas',
            body:
                '• Câmera e Galeria: utilizadas apenas quando você escolhe adicionar ou atualizar a foto de um animal.\n'
                '• Notificações Locais: utilizadas para enviar lembretes de medicamentos, consultas e vacinas agendadas por você.\n'
                'Nenhuma permissão é usada para rastreamento ou coleta de dados em segundo plano.',
          ),
          _PolicySection(
            title: '3. Controle e Exclusão dos Dados',
            body:
                'Você tem controle total sobre seus registros, podendo editar ou excluir qualquer animal ou histórico diretamente no aplicativo. Ao desinstalar o aplicativo, todos os dados locais são removidos do dispositivo.',
          ),
          _PolicySection(
            title: '4. Isenção de Responsabilidade Veterinária',
            body:
                'O PetCare tem finalidade exclusivamente organizacional. O aplicativo não realiza diagnósticos clínicos, não prescreve medicamentos e não substitui a consulta e orientação presencial de um médico-veterinário.',
          ),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(body, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

