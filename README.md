# Fatec Shop

Um aplicativo de carrinho de compras desenvolvido em Flutter como um projeto de exemplo. O aplicativo demonstra conceitos fundamentais do desenvolvimento com Flutter, incluindo gerenciamento de estado, consumo de API e integração com serviços como o Firebase.

## 🚀 Funcionalidades

- **Visualização de Produtos**: Tela inicial que exibe uma lista de produtos disponíveis.
- **Detalhes do Produto**: Tela dedicada para mostrar informações detalhadas de um produto específico.
- **Carrinho de Compras**: Adicione e remova produtos do carrinho de compras.
- **Tela de Pedidos**: Visualize um histórico de pedidos realizados (simulado).
- **Gerenciamento de Produtos**: Telas para administradores adicionarem e editarem produtos.
- **Notificações Push**: Integração com Firebase Cloud Messaging para receber notificações.

## 🛠️ Tecnologias Utilizadas

- **Flutter & Dart**: Framework e linguagem principal para o desenvolvimento do aplicativo.
- **Provider**: Para gerenciamento de estado de forma reativa e simples.
- **http**: Para realizar chamadas a uma API REST para busca e manipulação de produtos.
- **intl**: Para formatação de datas e números.
- **Firebase**:
  - `firebase_core`: Para inicialização do Firebase no projeto.
  - `firebase_messaging`: Para implementação de notificações push.

## ⚙️ Começando

Siga as instruções abaixo para configurar e executar o projeto em sua máquina local.

### Pré-requisitos

- **Flutter SDK**: Certifique-se de ter o Flutter instalado. Para mais detalhes, veja a [documentação oficial do Flutter](https://flutter.dev/docs/get-started/install).
- **Um editor de código**: VS Code com a extensão do Flutter ou Android Studio.
- **Um emulador ou dispositivo físico**: Para executar o aplicativo.

### Instalação

1.  **Clone o repositório:**
    ```sh
    git clone <URL_DO_REPOSITORIO>
    cd carrinho_fatec
    ```

2.  **Instale as dependências:**
    ```sh
    flutter pub get
    ```

### Configuração do Firebase

Este projeto utiliza Firebase. Para que a integração funcione corretamente, você precisa configurar seu próprio projeto no Firebase.

1.  Acesse o [console do Firebase](https://console.firebase.google.com/).
2.  Crie um novo projeto.
3.  Adicione um aplicativo Android e/ou iOS ao seu projeto Firebase.
4.  Siga as instruções para registrar o aplicativo:
    - **Para Android**: Faça o download do arquivo `google-services.json` e coloque-o na pasta `android/app/`.
    - **Para iOS**: Faça o download do arquivo `GoogleService-Info.plist` e coloque-o na pasta `ios/Runner/` via Xcode.
5.  Ative o **Cloud Messaging** no seu console do Firebase.

### Executando o Aplicativo

Após a instalação das dependências e configuração do Firebase, execute o seguinte comando para iniciar o aplicativo:

```sh
flutter run
```

## 📂 Estrutura do Projeto

O código-fonte do projeto está localizado no diretório `lib/` e é organizado da seguinte forma:

```
lib/
├── models/         # Contém os modelos de dados (ex: Product).
├── providers/      # Lógica de negócio e gerenciamento de estado (ex: CartProvider).
├── screens/        # As diferentes telas da aplicação.
├── services/       # Serviços para comunicação com APIs externas (ex: ProductsService).
└── main.dart       # Ponto de entrada da aplicação.
```