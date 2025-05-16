import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class OnlinePlay extends StatefulWidget {
  const OnlinePlay({super.key});

  @override
  State<OnlinePlay> createState() => _OnlinePlayState();
}

class _OnlinePlayState extends State<OnlinePlay> {
  late final WebViewController controller;
  bool isLoading = true; // Tracks whether the WebView is still loading

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading state based on progress
            if (progress == 100) {
              setState(() {
                isLoading = false; // Loading complete
              });
            }
          },
          onPageStarted: (String url) {
            setState(() {
              isLoading = true; // Start loading
            });
          },
          onPageFinished: (String url) {
            setState(() {
              isLoading = false; // Loading complete
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              isLoading = false; // Hide loader on error
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith(
                'https://dynamochess.in/multiplayer/randomMultiplayer/600/')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(
          'https://dynamochess.in/multiplayer/randomMultiplayer/600/'));
  }

//name, phone, email paword,select county reffaral code
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Dynamo Chess',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          // Background Image
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/board.jpg'),
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),
          // WebView with semi-transparent background
          Container(
            color: Colors.black.withOpacity(0.7), // Semi-transparent overlay
            child: Stack(
              children: [
                WebViewWidget(controller: controller),
                if (isLoading)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
