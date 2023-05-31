import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.grey[800],
        appBar: AppBar(
          title: const Text('Hello World'),
          centerTitle: true,
          backgroundColor: Colors.red[600],
        ),
        body: const Center(
          child: Image(
            image: NetworkImage('https://picsum.photos/250?image=10'),
          ),
        ),
      ),
    ),
  );
}
