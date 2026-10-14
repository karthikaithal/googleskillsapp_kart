import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CloudSkillsApp());
}

class CloudSkillsApp extends StatelessWidget {
  const CloudSkillsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cloud Skills Commute',
      theme: ThemeData(
        primarySwatch: Colors.blue, 
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const VideoDashboard(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class VideoDashboard extends StatefulWidget {
  const VideoDashboard({super.key});

  @override
  State<VideoDashboard> createState() => _VideoDashboardState();
}

class _VideoDashboardState extends State<VideoDashboard> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent('Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Mobile Safari/537.36')
      // Create a communication channel between the webpage and Flutter
      ..addJavaScriptChannel(
        'FullscreenChannel',
        onMessageReceived: (JavaScriptMessage message) {
          setState(() {
            _isFullscreen = message.message == 'true';
            
            if (_isFullscreen) {
              // Hide Android status bar & navigation buttons
              SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
              // Force the phone into landscape mode
              SystemChrome.setPreferredOrientations([
                DeviceOrientation.landscapeLeft,
                DeviceOrientation.landscapeRight,
              ]);
            } else {
              // Restore normal UI and allow portrait mode again
              SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
              SystemChrome.setPreferredOrientations([
                DeviceOrientation.portraitUp,
                DeviceOrientation.portraitDown,
                DeviceOrientation.landscapeLeft,
                DeviceOrientation.landscapeRight,
              ]);
            }
          });
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
            // Inject JavaScript to listen for the web player's fullscreen button
            _controller.runJavaScript('''
              document.addEventListener('fullscreenchange', function() {
                FullscreenChannel.postMessage(document.fullscreenElement != null ? 'true' : 'false');
              });
              document.addEventListener('webkitfullscreenchange', function() {
                FullscreenChannel.postMessage(document.webkitFullscreenElement != null ? 'true' : 'false');
              });
            ''');
          },
        ),
      )
      ..loadRequest(Uri.parse('https://www.cloudskillsboost.google/catalog'));
  }

  @override
  void dispose() {
    // Reset orientation if the app is closed while in fullscreen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isFullscreen
          ? null 
          : AppBar(
              title: const Text('Google Cloud Skills'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () async {
                    if (await _controller.canGoBack()) {
                      _controller.goBack();
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => _controller.reload(),
                ),
              ],
            ),
      body: SafeArea(
        top: !_isFullscreen,
        bottom: !_isFullscreen,
        left: !_isFullscreen,
        right: !_isFullscreen,
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}
