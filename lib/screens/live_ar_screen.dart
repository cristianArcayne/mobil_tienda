import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'ar_view_stub.dart'
    if (dart.library.html) 'ar_view_web.dart'
    if (dart.library.io) 'ar_view_mobile.dart';

class LiveArScreen extends StatefulWidget {
  final String prendaUrl;
  final String prendaNombre;
  final List<String> coloresDisponibles;

  const LiveArScreen({
    Key? key,
    required this.prendaUrl,
    required this.prendaNombre,
    this.coloresDisponibles = const [],
  }) : super(key: key);

  @override
  _LiveArScreenState createState() => _LiveArScreenState();
}

class _LiveArScreenState extends State<LiveArScreen> {
  bool _hasPermissions = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final status = await Permission.camera.request();
    await Permission.microphone.request();
    if (status.isGranted) {
      setState(() {
        _hasPermissions = true;
      });
    } else {
      // En Web los permisos se solicitan directo por el navegador
      setState(() {
        _hasPermissions = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: _hasPermissions 
          ? buildArView(widget.prendaUrl, widget.coloresDisponibles, widget.prendaNombre)
          : const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5))),
    );
  }
}
