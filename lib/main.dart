import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Describe Your Cat',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller = TextEditingController();
  String? _imageUrl;
  String? _ipfsUrl;

  Future<void> _fetchImage() async {
    final String apiKey = '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';
    final String apiUrl = 'https://api-inference.huggingface.co/models/ayoubkirouane/Stable-Cats-Generator';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "inputs": _controller.text,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _imageUrl = 'data:image/jpeg;base64,' + base64Encode(response.bodyBytes);
        });
        Uint8List imageData = response.bodyBytes;
        _ipfsUrl = await uploadToIPFS(imageData);
      } else {
        print("Error fetching image: ${response.statusCode} - ${response.body}");
        setState(() {
          _imageUrl = null;
          _ipfsUrl = null;
        });
      }
    } catch (e) {
      print("Exception occurred: $e");
    }
  }

  Future<String> uploadToIPFS(Uint8List imageData) async {
    final response = await http.post(
      Uri.parse('https://api.pinata.cloud/pinning/pinFileToIPFS'),
      headers: {
        'Content-Type': 'multipart/form-data',
        'pinata_api_key': 'YOUR_PINATA_API_KEY',
        'pinata_secret_api_key': 'YOUR_PINATA_SECRET_API_KEY',
      },
      body: imageData,
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return 'https://gateway.pinata.cloud/ipfs/${jsonResponse['IpfsHash']}';
    } else {
      throw Exception('Failed to upload image: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Describe Your Cat'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_ipfsUrl != null) ...[
              ElevatedButton(
                onPressed: () {
                  print('Minting NFT from: $_ipfsUrl');
                },
                child: Text('Mint NFT'),
              ),
              SizedBox(height: 10),
              Text('IPFS URL: $_ipfsUrl'),
              SizedBox(height: 20),
            ],
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter a description...',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchImage,
              child: Text('Go!'),
            ),
            if (_imageUrl != null) ...[
              SizedBox(height: 20),
              Image.memory(base64Decode(_imageUrl!.split(',')[1])),
            ],
          ],
        ),
      ),
    );
  }
}
