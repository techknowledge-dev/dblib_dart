import 'package:dblib/query_response.dart';
import 'package:flutter/material.dart';
import 'package:dblib/enums.dart';
import 'package:dblib/dblib.dart';

import '../constants.dart';

class ListByQueryPage extends StatefulWidget {
  @override
  State<ListByQueryPage> createState() => _ListByQueryPageState();
}

class _ListByQueryPageState extends State<ListByQueryPage> {
  List<Card> _cards = List.filled(0, Card(), growable: true);
  final _db = DbLib();

  void _cardSetup(QueryResponse qr) {
    var line = Card(
        child: ListTile(
      title: Text(qr.result['EMPNO']!),
      subtitle: Text(qr.result['ENAME']!),
    ));
    _cards.add(line);
  }

  Future<int> _query() async {
    _db.url = Constants.SERVER_URL;
    await _db.connect();
    var qr = await _db.query("select ENAME,EMPNO from EMP order by EMPNO");
    while (qr.status == StatusEnum.normal) {
      _cardSetup(qr);
      qr = await _db.fetch();
    }
    await _db.disconnect();
    return Future.value(0);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _query(),
        builder: (BuildContext context, AsyncSnapshot<int> as) {
          if (as.hasError) {
            return Text('network error');
          }
          switch (as.connectionState) {
            case ConnectionState.waiting:
              return Center(child: SizedBox(height: 100.0, width: 100.0, child: CircularProgressIndicator()));
            case ConnectionState.done:
              break;
          }
          return Scaffold(
              appBar: AppBar(
                title: const Text('EMP list'),
              ),
              body: SafeArea(
                  child: ListView(
                    shrinkWrap: true,
                    children: _cards,
                  ),
                ),
              );
        });
  }
}
