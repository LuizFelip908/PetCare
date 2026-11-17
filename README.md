# PetCare — Cuidados com animais de estimação

Aplicativo mobile em **Flutter** e **Dart** para tutores de cães e gatos organizarem a rotina de cuidados dos seus animais com armazenamento local persistente em **SQLite** e lembretes via **notificações locais**.

> **Aviso importante:** o PetCare é uma ferramenta de organização e acompanhamento. Ele **não realiza diagnósticos, não prescreve medicamentos e não substitui a orientação de um médico-veterinário**.

## Funcionalidades

- **Cadastro de animais (Meus Pets):** cães e gatos com foto (câmera/galeria), nome, espécie, raça, sexo, data de nascimento, peso atual e observações. Dados isolados por animal, com edição e exclusão segura (incluindo aviso de registros vinculados).
- **Carteira de vacinação:** registro de vacinas aplicadas, data da próxima dose, clínica veterinária, observações e lembretes.
- **Controle de medicamentos:** cadastro de medicamentos, dosagem, múltiplos horários diários, período de tratamento, orientações baseadas em prescrição veterinária, marcação de doses administradas e histórico completo.
- **Agenda:** calendário interativo (`table_calendar`) para consultas veterinárias, retornos, exames, vacinação e banho/tosa, com próximos compromissos destacados na tela inicial.
- **Histórico de saúde:** linha do tempo cronológica por animal reunindo vacinas, medicamentos, consultas e exames.
- **Acompanhamento de peso:** histórico de medições e gráfico de evolução (`fl_chart`), com sincronização automática do peso atual do animal.
- **Notificações locais:** lembretes configuráveis (ativar/desativar, antecedência de consultas) com atualização e cancelamento automático ao editar ou excluir registros.
- **Modo offline:** 100% funcional sem conexão à internet.

## Arquitetura do Projeto

```text
lib/
├── main.dart                     # Inicialização (pt_BR, notificações)
├── app.dart                      # MaterialApp, tema e MultiProvider
├── core/
│   ├── database/                 # DatabaseHelper (SQLite + foreign keys ON DELETE CASCADE)
│   ├── services/                 # NotificationService, SettingsService, DemoDataService
│   ├── theme/                    # Identidade visual (AppColors, AppTheme)
│   └── utils/                    # Formatadores de data (pt_BR) e validadores de formulário
├── data/
│   ├── models/                   # Pet, Vaccine, Medication, MedicationLog, Appointment, WeightRecord, HealthEvent
│   └── repositories/             # Acesso a dados SQLite separado por domínio
├── providers/                    # Gerenciamento de estado (ChangeNotifier + Provider)
├── widgets/                      # Componentes reutilizáveis (PetAvatar, WeightChart, diálogos, etc.)
└── features/
    ├── shell/                    # Navegação inferior com 5 abas
    ├── home/                     # Início
    ├── pets/                     # Meus Pets (lista, detalhes, formulário)
    ├── agenda/                   # Agenda (calendário, detalhes, formulário)
    ├── health/                   # Saúde (Vacinas, Medicamentos, Histórico, Peso)
    └── profile/                  # Perfil, configurações, dados de exemplo e Política de Privacidade
```

### Principais decisões técnicas

- **SQLite (`sqflite`) com `PRAGMA foreign_keys = ON`:** garante integridade referencial entre animais e seus registros (`ON DELETE CASCADE`).
- **Provider (`ChangeNotifier`):** separa interface, regras de negócio e repositórios de dados com baixo acoplamento e fácil testabilidade.
- **Notificações com IDs determinísticos:** cada compromisso, vacina e horário de medicamento gera um ID previsível para que edições e exclusões atualizem ou cancelem exatamente os alertas correspondentes.
- **Dados de exemplo opcionais:** o app inicia limpo e permite carregar/remover registros de exemplo claramente identificados na aba **Perfil**.

## Como executar o projeto

1. Certifique-se de ter o **Flutter SDK** (`>= 3.50.0`) e **Dart** (`>= 3.14.0`) no `PATH`.
2. Instale as dependências:
   ```bash
   flutter pub get
   ```
3. Execute em um emulador Android ou dispositivo conectado:
   ```bash
   flutter run
   ```
4. Execute os testes automatizados (unitários, banco de dados em memória e widget):
   ```bash
   flutter test
   ```
