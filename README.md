# Finanças Pessoais - App Flutter

Um aplicativo completo de controle financeiro pessoal desenvolvido em Flutter com design moderno e funcionalidades avançadas.

## 🚀 Funcionalidades

### 💰 Gestão Financeira
- **Transações**: Controle completo de receitas e despesas
- **Categorização**: Organização por categorias personalizáveis
- **Filtros por período**: Visualização mensal/anual dos dados
- **Relatórios**: Gráficos e estatísticas detalhadas

### 💳 Cartões de Crédito
- **Gerenciamento de cartões**: Cadastro e controle de múltiplos cartões
- **Parcelas**: Sistema completo de parcelamento
- **Limites e vencimentos**: Controle de limites e datas

### 🏦 Financiamentos
- **Consórcios, Empréstimos e Financiamentos**: Gestão completa
- **Controle de parcelas**: Interface visual para marcar parcelas pagas
- **Descontos e valores**: Registro de descontos obtidos
- **Progresso visual**: Acompanhamento do percentual pago

### 🤖 IA Advisor
- **Recomendações inteligentes**: Sugestões baseadas em padrões de gastos
- **Análise de comportamento**: Insights sobre hábitos financeiros
- Comparativo receitas vs despesas
- Análise mensal detalhada
- Filtros por período
- Exportação de dados

### 💳 Controle de Cartões de Crédito
- Cadastro de múltiplos cartões
- Controle de limites e saldos
- Alertas de vencimento
- Monitoramento de utilização
- Cores personalizadas

## 🛠️ Tecnologias Utilizadas

- **Flutter** - Framework de desenvolvimento
- **Provider** - Gerenciamento de estado
- **SharedPreferences** - Armazenamento local
- **fl_chart** - Gráficos e visualizações
- **Google Fonts** - Tipografia
- **flutter_animate** - Animações
- **intl** - Internacionalização
- **uuid** - Identificadores únicos

## 📱 Estrutura do Projeto

```
lib/
├── models/           # Modelos de dados
│   ├── transaction.dart
│   ├── credit_card.dart
│   └── ai_recommendation.dart
├── providers/        # Gerenciamento de estado
│   ├── transaction_provider.dart
│   ├── credit_card_provider.dart
│   └── ai_provider.dart
├── screens/          # Telas do aplicativo
│   ├── home_screen.dart
│   ├── add_transaction_screen.dart
│   ├── ai_advisor_screen.dart
│   ├── reports_screen.dart
│   ├── credit_cards_screen.dart
│   └── add_credit_card_screen.dart
├── widgets/          # Componentes reutilizáveis
│   ├── balance_card.dart
│   ├── transaction_item.dart
│   └── credit_card_widget.dart
└── main.dart         # Arquivo principal
```

## 🎨 Design System

### Cores
- **Primária**: Azul (#2196F3)
- **Sucesso**: Verde (#4CAF50)
- **Atenção**: Laranja (#FF9800)
- **Erro**: Vermelho (#F44336)
- **Info**: Roxo (#9C27B0)

### Tipografia
- **Fonte**: Google Fonts - Poppins
- **Títulos**: 18-24px, Bold
- **Corpo**: 14-16px, Regular
- **Legendas**: 12-14px, Medium

### Componentes
- Cards com bordas arredondadas (12px)
- Sombras suaves para profundidade
- Gradientes para destaque
- Animações fluidas

## 🚀 Como Executar

### Desenvolvimento Local

1. **Instalar dependências:**
   ```bash
   flutter pub get
   ```

2. **Configurar variáveis de ambiente:**
   ```bash
   # Copie o arquivo de exemplo
   cp .env.example .env.local
   
   # Edite .env.local com suas credenciais do Supabase
   SUPABASE_URL=https://seu-projeto.supabase.co
   SUPABASE_ANON_KEY=sua-chave-anon-aqui
   ```

3. **Executar o aplicativo:**
   ```bash
   # Mobile
   flutter run
   
   # Web com variáveis de ambiente
   flutter run -d chrome --dart-define=SUPABASE_URL=sua-url --dart-define=SUPABASE_ANON_KEY=sua-chave
   ```

### Deploy no Netlify

1. **Configurar variáveis de ambiente no Netlify:**
   - Acesse seu dashboard do Netlify
   - Vá em Site settings > Environment variables
   - Adicione:
     - `SUPABASE_URL`: URL do seu projeto Supabase
     - `SUPABASE_ANON_KEY`: Chave anônima do Supabase

2. **Deploy automático:**
   - O arquivo `netlify.toml` já está configurado
   - Push para o repositório GitHub conectado ao Netlify
   - Build será executado automaticamente

3. **Build manual:**
   ```bash
   flutter build web --dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
   ```

## 📋 Pré-requisitos

- Flutter SDK 3.0.0 ou superior
- Dart 2.17.0 ou superior
- Android Studio / VS Code
- Emulador Android ou dispositivo físico

## 🔧 Configuração

1. Clone o repositório
2. Execute `flutter pub get`
3. Configure um emulador ou conecte um dispositivo
4. Execute `flutter run`

## 📱 Funcionalidades Principais

### Dashboard
- Visão geral financeira
- Saldo atual em destaque
- Ações rápidas
- Transações recentes

### Transações
- Adicionar receitas e despesas
- Categorização automática
- Histórico completo
- Filtros avançados

### IA Financeira
- Análise inteligente
- Recomendações personalizadas
- Alertas de gastos
- Dicas de economia

### Relatórios
- Gráficos interativos
- Análise por categoria
- Comparativos mensais
- Exportação de dados

### Cartões de Crédito
- Controle de múltiplos cartões
- Alertas de vencimento
- Monitoramento de limites
- Cores personalizadas

## 🤝 Contribuição

1. Faça um fork do projeto
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Push para a branch
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo LICENSE para mais detalhes.

## 👨‍💻 Desenvolvido por

Sistema de Finanças Pessoais com IA - Flutter App

---

**Versão**: 1.0.0  
**Última atualização**: Janeiro 2025 