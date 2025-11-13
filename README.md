# 🏋️ GYM TRACKER

> Aplicativo móvel para planejamento, registro e acompanhamento de treinos com foco em autonomia, usabilidade e persistência local.

[![Flutter](https://img.shields.io/badge/Flutter-3.24.0-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.5.0-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## 📋 Sobre o Projeto

O **GYM TRACKER** é um aplicativo móvel desenvolvido em Flutter que permite aos praticantes de musculação planejar, registrar e acompanhar seus treinos de forma autônoma e eficiente. O app prioriza **funcionamento 100% offline** (arquitetura local-first), dando ao usuário controle total sobre seus dados.

### 🎯 Principais Diferenciais

- ✅ **Funcionamento Offline Completo** - Nenhuma dependência de internet ou servidores externos
- ✅ **Registro Retroativo** - Corrija lacunas editando data/hora de treinos passados
- ✅ **Rotinas Reutilizáveis** - Crie templates de treino e reutilize sempre que quiser
- ✅ **Interface Intuitiva** - Design limpo seguindo Material Design 3
- ✅ **Histórico Completo** - Acompanhe sua evolução com gráficos e métricas
- ✅ **Gratuito e Sem Anúncios** - Todas as funcionalidades disponíveis sem paywall

---

## ✨ Funcionalidades

### 📝 Gestão de Treinos

- **Criar Rotinas**: Monte templates de treino com exercícios e número de séries
- **Iniciar Treinos**: Comece treinos a partir de rotinas ou crie do zero
- **Registro de Séries**: Anote reps, peso (kg), RPE e observações
- **Edição Flexível**: Adicione/remova exercícios durante o treino
- **Conclusão Automática**: Salve treinos no histórico com métricas calculadas

### 📊 Acompanhamento e Análise

- **Histórico Completo**: Visualize todos os treinos realizados
- **Gráficos de Progresso**: Acompanhe volume total ao longo do tempo (7/30/90 dias)
- **Métricas Detalhadas**: Total de treinos mensais, streak de dias consecutivos, exercícios únicos
- **Registro Retroativo**: Ajuste data e hora de treinos para manter histórico consistente

### 🎨 Experiência do Usuário

- **Catálogo de Exercícios**: +40 exercícios pré-cadastrados organizados por grupo muscular
- **Exercícios Personalizados**: Crie seus próprios exercícios
- **Interface Reativa**: Atualizações automáticas em tempo real
- **Performance Otimizada**: Interface fluida (60fps) sem lags

---

## 🛠️ Tecnologias Utilizadas

### Core Framework

- **Flutter 3.24.0** - Framework multiplataforma
- **Dart 3.5.0** - Linguagem de programação

### Principais Dependências

| Pacote | Versão | Função |
|--------|--------|--------|
| `flutter_riverpod` | 2.5.1 | Gerenciamento de estado reativo |
| `drift` | 2.18.0 | ORM reativo para SQLite |
| `drift_sqflite` | 2.0.0 | Backend SQLite para Drift |
| `go_router` | 14.0.0 | Navegação declarativa |
| `fl_chart` | 0.68.0 | Gráficos e visualizações |
| `uuid` | 4.3.3 | Geração de identificadores únicos |
| `intl` | 0.19.0 | Formatação de datas/números |
| `path_provider` | 2.1.2 | Acesso a diretórios do sistema |

### Dev Dependencies

- `build_runner` 2.4.8 - Geração de código
- `drift_dev` 2.18.0 - Gerador Drift
- `flutter_lints` 3.0.1 - Lints recomendadas

---

## 🏗️ Arquitetura

O projeto segue uma **arquitetura em camadas** com separação clara de responsabilidades:

```
┌─────────────────────────────────────────┐
│   Camada de Apresentação (UI/Widgets)   │
│   - Widgets Flutter                      │
│   - Interface declarativa                │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│   Camada de Controle (Providers)        │
│   - Riverpod State Management           │
│   - Lógica de negócio                   │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│   Camada de Dados (Repository)          │
│   - Repository Pattern                   │
│   - Abstração de acesso a dados         │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│   Camada de Persistência (Drift/SQLite) │
│   - Drift ORM                           │
│   - Banco de dados local                │
└─────────────────────────────────────────┘
```

### 📁 Estrutura de Pastas

```
lib/
├── main.dart              # Entry point da aplicação
├── app.dart               # Widget raiz e configuração
├── data/                  # Camada de dados
│   └── db/               # Definições Drift (tabelas)
├── features/             # Funcionalidades por contexto
│   ├── today/           # Tela inicial
│   ├── history/         # Histórico e estatísticas
│   ├── workout/         # Detalhes e edição de treino
│   └── routines/        # Gestão de rotinas
├── widgets/              # Componentes reutilizáveis
├── core/                 # Código compartilhado
│   ├── constants/       # Constantes da aplicação
│   ├── theme/           # Tema e estilos
│   └── utils/           # Utilidades
└── router/               # Configuração de rotas
```

---

## 🗄️ Modelo de Dados

O banco de dados SQLite é estruturado em **6 tabelas relacionais**:

### Tabelas Principais

1. **Exercises** - Catálogo de exercícios (padrão + personalizados)
2. **Routines** - Templates de treino reutilizáveis
3. **RoutineExercises** - Exercícios vinculados a cada rotina
4. **Workouts** - Treinos executados (histórico)
5. **WorkoutExercises** - Exercícios de cada treino
6. **Sets** - Séries registradas (reps, peso, RPE)

### Características do Banco

- ✅ Normalização completa (3FN)
- ✅ Integridade referencial com CASCADE DELETE
- ✅ Queries tipadas em tempo de compilação (Drift)
- ✅ Streams reativos para atualizações em tempo real
- ✅ Transações ACID para consistência

---

## 🚀 Como Executar

### Pré-requisitos

- Flutter SDK 3.24.0 ou superior
- Dart SDK 3.5.0 ou superior
- Android Studio / VS Code com extensões Flutter
- Dispositivo Android (API 26+) ou iOS (em breve)

### Instalação

1. **Clone o repositório**

```bash
git clone https://github.com/seu-usuario/gym-tracker.git
cd gym-tracker
```

2. **Instale as dependências**

```bash
flutter pub get
```

3. **Gere o código do Drift**

```bash
dart run build_runner build --delete-conflicting-outputs
```

4. **Execute o aplicativo**

```bash
flutter run
```

### Build para Produção

```bash
# Android APK
flutter build apk --release

# Android App Bundle (para Play Store)
flutter build appbundle --release
```

---

## 📊 Requisitos do Sistema

### Requisitos Funcionais (RF)

| Código | Descrição |
|--------|-----------|
| RF01 | Criar e editar rotinas de treino |
| RF02 | Iniciar treinos a partir de rotinas ou do zero |
| RF03 | Adicionar/remover exercícios durante treino |
| RF04 | Registrar séries com reps, peso, RPE e observações |
| RF05 | Concluir treinos e salvar no histórico |
| RF06 | Visualizar histórico completo de treinos |
| RF07 | Detalhar treinos passados |
| RF08 | Gerenciar catálogo de exercícios |
| RF09 | Visualizar métricas e gráficos de progresso |
| RF10 | Registrar treinos com data/hora retroativa |

### Requisitos Não Funcionais (RNF)

| Código | Descrição |
|--------|-----------|
| RNF01 | **Funcionamento Offline** - 100% operacional sem internet |
| RNF02 | **Performance** - Operações de BD <100ms, UI a 60fps |
| RNF03 | **Usabilidade** - Seguir Material Design 3 e heurísticas de Nielsen |
| RNF04 | **Arquitetura** - Código modular com baixo acoplamento (SOLID) |
| RNF05 | **Compatibilidade** - Android 8.0+ (API 26+) |
| RNF06 | **Persistência Automática** - Salvamento sem botão "Salvar" |
| RNF07 | **Integridade** - Transações ACID e validações de entrada |
| RNF08 | **Manutenibilidade** - Código limpo e bem documentado |

---

## 🧪 Testes e Validação

### Tipos de Testes Realizados

- ✅ **Testes Funcionais**: Validação de todos os fluxos principais
- ✅ **Testes de Usabilidade**: Validação com 5 usuários reais
- ✅ **Testes de Performance**: Banco com 100+ treinos, 2000+ séries
- ✅ **Testes de Persistência**: Validação offline e recuperação após crash

### Resultados

- 📱 Funcionamento offline 100% validado
- ⚡ Latência média de operações: <100ms
- 🎯 Taxa de satisfação dos usuários: Alta
- 📊 Performance mantida com grandes volumes de dados

---

## 📈 Trabalhos Futuros

### Features Planejadas

- [ ] Sincronização opcional em nuvem (Firebase)
- [ ] Análises avançadas (progressão por exercício, detecção de PRs)
- [ ] Timer de descanso entre séries
- [ ] Integração com wearables
- [ ] Sistema de gamificação (conquistas, badges)
- [ ] Modo treinador (prescrição de treinos)
- [ ] Exportação de dados (CSV, JSON)
- [ ] Suporte para iOS

---

## 🤝 Contribuindo

Contribuições são bem-vindas! Por favor:

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/MinhaFeature`)
3. Commit suas mudanças (`git commit -m 'feat: Adiciona MinhaFeature'`)
4. Push para a branch (`git push origin feature/MinhaFeature`)
5. Abra um Pull Request

### Convenção de Commits

Seguimos o padrão [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` Nova funcionalidade
- `fix:` Correção de bug
- `refactor:` Refatoração sem mudança de comportamento
- `docs:` Documentação
- `test:` Testes

---

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

---

## 👨‍💻 Autor

**José Vilanir de Souza Brito Neto**

- GitHub: [@seu-usuario](https://github.com/seu-usuario)
- LinkedIn: [Seu Nome](https://linkedin.com/in/seu-perfil)
- Email: seu.email@exemplo.com

---

## 🙏 Agradecimentos

- **Instituto Federal do Rio Grande do Norte (IFRN)** - Pela formação acadêmica
- **Prof. M.e. Gracon Huttennberg Eliatan Leite de Lima** - Pela orientação
- **Comunidade Flutter** - Pelos excelentes recursos e documentação
- **Testadores Beta** - Pelo feedback valioso durante o desenvolvimento

---
