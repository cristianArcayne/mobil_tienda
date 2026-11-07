// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

Widget buildArView(String prendaUrl, List<String> coloresDisponibles, [String? prendaNombre]) {
  final viewId = 'lucy-ar-view-${DateTime.now().millisecondsSinceEpoch}';
  final nom = prendaNombre ?? 'Camiseta básica de algodón celeste';
  
  ui_web.platformViewRegistry.registerViewFactory(viewId, (int id) {
    final iframe = html.IFrameElement()
      ..width = '100%'
      ..height = '100%'
      ..src = 'assets/assets/lucy_ar_filter.html?garment=${Uri.encodeComponent(prendaUrl)}&name=${Uri.encodeComponent(nom)}&colors=${Uri.encodeComponent(coloresDisponibles.join(','))}'
      ..style.border = 'none'
      ..allow = 'camera; microphone';
    return iframe;
  });

  html.window.onMessage.listen((event) {
    if (event.data == 'goBack') {
      html.window.history.back();
    }
  });

  return HtmlElementView(viewType: viewId);
}
