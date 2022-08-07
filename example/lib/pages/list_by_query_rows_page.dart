import 'package:dblib/query_response.dart';
import 'package:flutter/material.dart';
import 'package:dblib/enums.dart';
import 'package:dblib/dblib.dart';

import '../constants.dart';

class ListByQueryRowsPage extends StatefulWidget {
  @override
  State<ListByQueryRowsPage> createState() => _ListByQueryRowsPageState();
}

class _ListByQueryRowsPageState extends State<ListByQueryRowsPage> {

  List<Card> _cards = List.filled(0, Card(), growable: true);
  final _db = DbLib();

  void _cardSetup(QueryRowsResponse qr){
    for(var r in qr.result) {
      var line = Card(
          child: ListTile(
            title: Text(r['EMPNO']!),
            subtitle: Text(r['ENAME']!),
          ));
      _cards.add(line);
    }
  }

  Future<int> _queryRows() async {
    _db.url = Constants.SERVER_URL;
    await _db.connect();
    var qr = await _db.queryRows("select ENAME,EMPNO from EMP order by EMPNO",100);
    if(qr.status==StatusEnum.normal){
      _cardSetup(qr);
    }
    await _db.disconnect();
    return Future.value(0);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _queryRows(),
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
              child: ListView(shrinkWrap: true,children: _cards,),
            ),
          );
        });
  }
}
