// lib/recipe_webview_screen.dart

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class RecipeWebviewScreen extends StatefulWidget {
  final String initialUrl;
  final String itemTitle;

  const RecipeWebviewScreen({
    super.key,
    required this.initialUrl,
    required this.itemTitle,
  });

  @override
  State<RecipeWebviewScreen> createState() => _RecipeWebviewScreenState();
}

class _RecipeWebviewScreenState extends State<RecipeWebviewScreen> {
  late final WebViewController _controller;
  int _loadingPercentage = 0;

  @override
  void initState() {
    super.initState();

    // Inisialisasi controller WebView
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _loadingPercentage = 0;
            });
          },
          onProgress: (int progress) {
            setState(() {
              _loadingPercentage = progress;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _loadingPercentage = 100;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ide Olahan ${widget.itemTitle}'),
        elevation: 1,
        // Tampilkan loading bar di bawah AppBar
        bottom: _loadingPercentage < 100
            ? PreferredSize(
                preferredSize: const Size.fromHeight(4.0),
                child: LinearProgressIndicator(
                  value: _loadingPercentage / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                ),
              )
            : null,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}