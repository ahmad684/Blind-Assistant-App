import 'package:flutter/material.dart';
class Call extends StatefulWidget {
  @override
  _CallState createState() => _CallState();
}

class _CallState extends State<Call> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Call'),
        backgroundColor: Colors.redAccent,

      ),
      body: SafeArea(
        child: Text('make a call'),
      ),
    );
  }
}
