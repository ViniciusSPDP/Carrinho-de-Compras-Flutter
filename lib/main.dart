import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'providers/cart_provider.dart';
import 'screens/products_overview_screen.dart';

// --- CONFIGURAÇÃO FIREBASE BACKGROUND ---
// Essa função precisa ser fora de qualquer classe (Top Level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Se quiser fazer algo quando o app estiver fechado e chegar notificação
  await Firebase.initializeApp();
  print("Mensagem em Background: ${message.messageId}");
}
// ----------------------------------------

void main() async {
  // Garante que o Flutter esteja pronto antes de carregar o Firebase
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa o Firebase
  try {
    await Firebase.initializeApp();
    
    // Configura o handler de background
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    print("Erro ao inicializar Firebase (Se estiver na Web/Windows precisa de config extra): $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  
  @override
  void initState() {
    super.initState();
    _setupFirebaseNotifications();
  }

  void _setupFirebaseNotifications() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // 1. Pede permissão ao usuário (importante para iOS/Android 13+)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('Permissão concedida: ${settings.authorizationStatus}');

    // 2. Obtém o Token do dispositivo (Identidade dele para enviar msg)
    String? token = await messaging.getToken();
    print("========================================");
    print("SEU TOKEN DO FIREBASE: $token");
    print("========================================");

    // 3. Ouve mensagens quando o App está ABERTO (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Mensagem recebida com app aberto: ${message.notification?.title}');
      
      if (message.notification != null) {
        // Mostra um alerta simples na tela (SnackBar)
        // Usamos um GlobalKey ou um hack simples aqui, mas o ideal é um serviço de navegação
        // Como estamos no root, vamos apenas imprimir por enquanto ou usar um pacote de toast
        // Mas para fins didáticos, vamos confiar que a notificação nativa aparece
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => CartProvider()),
      ],
      child: MaterialApp(
        title: 'Fatec Shop',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const ProductsOverviewScreen(), 
      ),
    );
  }
}