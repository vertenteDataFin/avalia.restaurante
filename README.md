# 🍽️ Avalia Restaurante - App de Feedback & Gestão de Refeições

Aplicativo móvel e web desenvolvido em **Flutter** integrado ao **Firebase**, criado para modernizar, agilizar e centralizar a coleta e o gerenciamento de feedbacks sobre as refeições servidas no restaurante/refeitório corporativo.

---

## 🎯 Para que serve o aplicativo?

O **Avalia Restaurante** tem como objetivo fornecer um canal direto, acessível e transparente para que os colaboradores possam avaliar a alimentação do dia a dia, servindo como uma ponte eficiente entre os funcionários, a equipe de nutrição/facilities, o RH e a empresa fornecedora de refeições.

### Principais Benefícios:
- **Melhoria Contínua da Qualidade**: Identificação rápida de desvios na preparação, sabor, temperatura ou apresentação dos alimentos.
- **Evidências Visuais**: Possibilidade de anexar fotos diretamente da câmera ou galeria para comprovação de ocorrências.
- **Substituição de Processos Manuais**: Elimina caixas de papel ou formulários físicos, garantindo armazenamento seguro e em tempo real.
- **Gestão Eficiente**: Painel exclusivo para nutricionistas e gestores acompanharem o índice de satisfação e as demandas prioritárias.

---

## 📱 Como o aplicativo funciona?
```

### 1. Área Pública (Colaborador / Sem necessidade de login)
- **Acesso Rápido**: O usuário não precisa criar conta nem memorizar senhas para registrar seu parecer.
- **Seleção de Unidade/Restaurante**: Permite indicar a unidade específica onde a refeição foi consumida.
- **Categorização Direta**:
  - 🔴 **Reclamação**: Para reportar problemas com alimentos, falta de itens, higiene, etc.
  - 🟡 **Sugestão**: Ideias de novos pratos, melhorias no cardápio ou no fluxo de atendimento.
  - 🟢 **Elogio**: Reconhecimento de pratos bem avaliados, atendimento e qualidade.
- **Anexo de Imagem**: Upload de fotos tiradas na hora ou enviadas da galeria.
- **Timestamp Automático**: Registro exato de data e horário do envio.

---

### 2. Área de Gestão / Administrativa (Acesso Restrito)
- **Autenticação Segura**: Login exclusivo para a equipe de gestão e nutricionistas via Firebase Auth.
- **Controle de Aprovação**: Novos cadastros de administradores necessitam de validação prévia para liberação de acesso.
- **Painel em Abas**:
  - Aba de **Reclamações** para ações corretivas urgentes.
  - Aba de **Sugestões** para planejamento de cardápio.
  - Aba de **Elogios** para feedback positivo às equipes de cozinha.
- **Cards com Fotos em Alta Resolução**: Permite zoom e visualização clara dos registros enviados.

---

## 🛠️ Tecnologias Utilizadas

- **Framework**: [Flutter](https://flutter.dev/) (Suporte multiplataforma: Android, iOS e Web PWA).
- **Linguagem**: [Dart](https://dart.dev/).
- **Autenticação**: Firebase Authentication.
- **Banco de Dados**: Cloud Firestore (NoSQL em tempo real).
- **Armazenamento de Fotos**: Cloud Storage for Firebase.
- **Hospedagem Web**: GitHub Pages (deploy automático via GitHub Actions a cada push na branch `main`). O Firebase Hosting foi abandonado por instabilidade de acesso em redes Starlink; o banco Firestore, o Auth e o Storage continuam no mesmo projeto Firebase.
- **Design System**: Material 3 com paleta corporativa Verde Bandeira Escuro (`#005A2B`).

---

## 📂 Estrutura do Projeto

```text
appMobAlimento/
├── lib/
│   ├── core/
│   │   └── theme/
│   │       └── app_theme.dart          # Tema visual e paleta de cores (#005A2B)
│   ├── data/
│   │   ├── models/
│   │   │   ├── feedback_item.dart      # Modelo de dados de feedback/reclamação
│   │   │   └── admin_user.dart         # Modelo de usuário administrador
│   │   └── services/
│   │       ├── auth_service.dart       # Autenticação e permissões de admins
│   │       └── feedback_service.dart   # Operações no Firestore e Storage
│   ├── ui/
│   │   └── screens/
│   │       ├── unit_selection_screen.dart   # Seleção de unidade/refeitório
│   │       ├── public_feedback_screen.dart  # Envio público de feedbacks
│   │       ├── admin_login_screen.dart      # Login e cadastro de gestores
│   │       └── admin_dashboard_screen.dart  # Painel de gestão por abas
│   ├── firebase_options.dart                # Configuração do Firebase
│   └── main.dart                            # Ponto de entrada do aplicativo
├── web/                                     # Configurações para Web PWA
├── android/                                 # Configurações do app Android
└── pubspec.yaml                             # Dependências do projeto
```

---

## 🚀 Como Executar o Projeto

### Pré-requisitos:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) instalado.
- Dispositivo Android/iOS conectado ou navegador web (Chrome/Edge).

### Passos:
1. **Instalar dependências**:
   ```bash
   flutter pub get
   ```

2. **Executar em modo desenvolvimento**:
   ```bash
   flutter run
   ```

3. **Gerar build para Web**:
   ```bash
   flutter build web --release
   ```

4. **Gerar APK para Android**:
   ```bash
   flutter build apk --release
   ```
"# avaliaRestaurante" 
