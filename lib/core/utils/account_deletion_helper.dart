import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AccountDeletionHelper {
  static const String deletionBaseUrl = 'https://indexinformatics.in/account_deletion.php';

  /// Constructs the official Index Care account deletion URL with parameters
  static String buildDeletionUrl({String? phone}) {
    String cleanPhone = '';
    if (phone != null && phone.trim().isNotEmpty) {
      final digits = phone.replaceAll(RegExp(r'\D'), '');
      if (digits.startsWith('91') && digits.length == 12) {
        cleanPhone = digits.substring(2);
      } else {
        cleanPhone = digits.isNotEmpty ? digits : phone.trim();
      }
    }

    final queryParams = <String, String>{
      'app': 'index_care',
    };
    if (cleanPhone.isNotEmpty) {
      queryParams['phone'] = cleanPhone;
    }

    final uri = Uri.parse(deletionBaseUrl).replace(queryParameters: queryParams);
    return uri.toString();
  }

  /// Opens the Index Care account deletion WebView
  static void openDeletionWebView({
    required BuildContext context,
    String? phoneNumber,
    VoidCallback? onAccountDeleted,
  }) {
    final url = buildDeletionUrl(phone: phoneNumber);

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'AccountDeletion',
        onMessageReceived: (JavaScriptMessage message) {
          if (message.message == 'deleted') {
            Navigator.of(context).pop();
            onAccountDeleted?.call();
          }
        },
      )
      ..loadRequest(Uri.parse(url));

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Index Care Account Deletion'),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1E293B),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: Colors.grey[200]),
          ),
        ),
        body: WebViewWidget(controller: controller),
      ),
    ));
  }
}
