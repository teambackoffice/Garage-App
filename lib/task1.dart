import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Garage App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: GarageWhatsAppShare(),
    );
  }
}

class GarageWhatsAppShare extends StatefulWidget {
  @override
  _GarageWhatsAppShareState createState() => _GarageWhatsAppShareState();
}

class _GarageWhatsAppShareState extends State<GarageWhatsAppShare> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with garage app example data
    _messageController.text = "Hi! Check out this amazing garage service I found.";
    // Pre-fill the fixed link
    _linkController.text = "https://www.youtube.com/watch?v=Nz6jRNqSLuc";
  }

  Future<void> _shareToWhatsApp() async {
    if (_phoneController.text.isEmpty) {
      _showSnackBar("Please enter a phone number");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Clean phone number (remove non-digits)
      String cleanPhone = _phoneController.text.replaceAll(RegExp(r'\D'), '');

      // Combine message and link
      String fullMessage = _messageController.text;
      if (_linkController.text.isNotEmpty) {
        fullMessage += "\n\n${_linkController.text}";
      }

      // Encode message for URL
      String encodedMessage = Uri.encodeComponent(fullMessage);

      // Create WhatsApp URL
      String whatsappUrl = "https://wa.me/$cleanPhone?text=$encodedMessage";

      // Launch WhatsApp
      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(
          Uri.parse(whatsappUrl),
          mode: LaunchMode.externalApplication,
        );
        _showSnackBar("WhatsApp opened successfully!");
      } else {
        _showSnackBar("WhatsApp is not installed on this device");
      }

    } catch (e) {
      _showSnackBar("Error: ${e.toString()}");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
        backgroundColor: message.contains("Error") ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Garage App - WhatsApp Share'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Phone Number Input
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number (with country code)',
                hintText: 'e.g., 919876543210',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 16),

            // Message Input
            TextField(
              controller: _messageController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Message',
                hintText: 'Enter your message here...',
                prefixIcon: Icon(Icons.message),
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 16),

            // Your TextField - UNCHANGED and read-only
            TextField(
              controller: _linkController,
              enabled: false, // Cannot be edited
              decoration: InputDecoration(
                labelText: 'Link (optional)',
                hintText: 'https://www.youtube.com/watch?v=Nz6jRNqSLuc',
                prefixIcon: Icon(Icons.link),
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 24),

            // Share Button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _shareToWhatsApp,
              icon: _isLoading
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : Icon(Icons.share),
              label: Text(_isLoading ? 'Opening WhatsApp...' : 'Share via WhatsApp'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
                textStyle: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _messageController.dispose();
    _linkController.dispose();
    super.dispose();
  }
}