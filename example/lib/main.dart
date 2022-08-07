import 'package:flutter/material.dart';

import 'pages/list_by_query_page.dart';
import 'pages/list_by_query_rows_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'dblib example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'dblib example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(onPressed: () {
              Navigator.of(context)
                  .push(
                MaterialPageRoute(
                  builder: (context) => ListByQueryPage(),
                ),
              );
            }, child: Text('Query')),
            ElevatedButton(onPressed: () {
              Navigator.of(context)
                  .push(
                  MaterialPageRoute(
                    builder: (context) => ListByQueryRowsPage(),
                  ),
              );
            }, child: Text('QueryRows')),
          ],
        ),
      ),
    );
  }
}
