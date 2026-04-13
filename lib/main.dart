import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Conteo en Líneas',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ScannerPage(),
    );
  }
}

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  Map<String, int> conteo = {};
  final player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  void cargarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('conteo');
    if (data != null) {
      conteo = Map<String, int>.from(json.decode(data));
      setState(() {});
    }
  }

  void guardarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('conteo', json.encode(conteo));
  }

  void procesarCodigo(String codigo) async {
    setState(() {
      conteo[codigo] = (conteo[codigo] ?? 0) + 1;
    });

    guardarDatos();

    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 100);
    }

    try {
      await player.play(AssetSource('beep.mp3'));
    } catch (_) {}
  }

  void limpiar() {
    setState(() {
      conteo.clear();
    });
    guardarDatos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conteo en Líneas'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: limpiar,
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: MobileScanner(
              onDetect: (barcode, args) {
                final String? code = barcode.rawValue;
                if (code != null) {
                  procesarCodigo(code);
                }
              },
            ),
          ),
          Expanded(
            flex: 3,
            child: ListView(
              children: conteo.entries.map((e) {
                return ListTile(
                  title: Text(e.key),
                  trailing: Text(
                    e.value.toString(),
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 20,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
