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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _hasPermissions 
          ? buildArView(widget.prendaUrl, widget.coloresDisponibles)
          : const Center(child: CircularProgressIndicator(color: Colors.green)),
    );
  }
}