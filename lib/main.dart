
import 'package:flutter/material.dart';
import 'package:garage_app/controller/packagecontroller.dart';
import 'package:garage_app/task1.dart';
import 'package:provider/provider.dart';
import 'bottom_nav.dart';
import 'inspection.dart';
import 'login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();


  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PackageController()),
      ],
    child: const MyApp()
  ),);
}
var w;
var h;
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    h = MediaQuery.of(context).size.height;
    w = MediaQuery.of(context).size.width;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home:LoginPage(),
    );
  }
}