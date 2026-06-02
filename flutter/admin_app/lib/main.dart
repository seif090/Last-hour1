import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'injector.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await initializeAdminDependencies();

  runApp(const LastHourAdminApp());
}
