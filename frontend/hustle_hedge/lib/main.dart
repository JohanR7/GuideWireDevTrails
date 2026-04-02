import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();

  String responseText = "";

  Future<void> sendData() async {
    final url = Uri.parse("http://10.0.2.2:5000/api/data"); 
    // ⚠️ Use 10.0.2.2 for Android emulator instead of localhost

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": nameController.text,
        "age": ageController.text,
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        responseText = response.body;
      });
    } else {
      setState(() {
        responseText = "Error: ${response.statusCode}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Flutter + Flask Demo")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: ageController,
              decoration: InputDecoration(labelText: "Age"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: sendData,
              child: Text("Send POST Request"),
            ),
            SizedBox(height: 20),
            Text(responseText),
          ],
        ),
      ),
    );
  }
}