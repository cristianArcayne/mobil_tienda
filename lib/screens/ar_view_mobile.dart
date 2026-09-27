import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';

Widget buildArView(String prendaUrl, List<String> coloresDisponibles) {
  return MobileArView(prendaUrl: prendaUrl, coloresDisponibles: coloresDisponibles);
}

class MobileArView extends StatefulWidget {
  final String prendaUrl;
  final List<String> coloresDisponibles;
  
  const MobileArView({Key? key, required this.prendaUrl, required this.coloresDisponibles}) : super(key: key);

  @override
  State<MobileArView> createState() => _MobileArViewState();
}

class _MobileArViewState extends State<MobileArView> {
  HttpServer? _localServer;
  String _serverUrl = "";
  InAppWebViewController? webViewController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _startLocalServer();
  }
  
  Future<void> _requestPermissions() async {
    await [Permission.camera, Permission.microphone].request();
  }

  Future<void> _startLocalServer() async {
    _localServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 8080);
    _localServer!.listen((HttpRequest request) async {
      try {
        final path = request.uri.path == '/' ? '/assets/lucy_ar_filter.html' : request.uri.path;
        final assetPath = path.startsWith('/') ? path.substring(1) : path;
        
        final byteData = await rootBundle.load(assetPath);
        
        if (assetPath.endsWith('.html')) {
          request.response.headers.contentType = ContentType.html;
        } else if (assetPath.endsWith('.js')) {
          request.response.headers.contentType = ContentType('application', 'javascript');
        } else if (assetPath.endsWith('.css')) {
          request.response.headers.contentType = ContentType('text', 'css');
        }
        
        request.response.add(byteData.buffer.asUint8List());
        await request.response.close();
      } catch (e) {
        request.response.statusCode = 404;
        await request.response.close();
      }
    });
    
    final baseUrl = 'http://127.0.0.1:8080/assets/lucy_ar_filter.html';
    final colorsStr = widget.coloresDisponibles.join(',');
    final url = '$baseUrl?garment=${widget.prendaUrl}&colors=$colorsStr';
    
    setState(() {
      _serverUrl = url;
    });
  }

  @override
  void dispose() {
    _localServer?.close(force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_serverUrl.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Colors.green));
    }

    return Stack(
      children: [
        InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(_serverUrl)),
          initialSettings: InAppWebViewSettings(
            mediaPlaybackRequiresUserGesture: false,
            allowsInlineMediaPlayback: true,
            iframeAllow: "camera; microphone",
            iframeAllowFullscreen: true,
            useHybridComposition: true,
            clearCache: true,
          ),
          onWebViewCreated: (controller) {
            webViewController = controller;
            controller.addJavaScriptHandler(handlerName: 'goBack', callback: (args) {
              Navigator.of(context).pop();
            });
          },
          onPermissionRequest: (controller, request) async {
            return PermissionResponse(
              resources: request.resources,
              action: PermissionResponseAction.GRANT,
            );
          },
          onLoadStop: (controller, url) {
            setState(() {
              _isLoading = false;
            });
          },
          onConsoleMessage: (controller, consoleMessage) {
            debugPrint("AR-LOG: \${consoleMessage.message}");
          },
        ),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
      ],
    );
  }
}
