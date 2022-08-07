import 'package:dblib/enums.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dblib/dblib.dart';

void dumpQueryRowsResult(qrs){
  for(var row in qrs.result){
    print('---------');
    row.forEach((key,value){
      print(key);
      print(value);
    });
  }
}

void dumpRow(res){
  print('---------');
  res.forEach((key,item){
    print('$key = $item');
  });
}

Future<void> main() async {
  test('dblib test', () async {
    //
    final dblib = DbLib();
    //
    //dblib.url = "http://172.20.10.13";
    dblib.url = "http://192.168.128.108";
    // dblib.url = "http://192.168.0.155";
    dblib.verbose = true;
    var st = await dblib.connect();

    //
    var res = await dblib.query("select * from EMP");
    while (res.status==StatusEnum.normal){
      dumpRow(res.result);
      res = await dblib.fetch();
    }
    st = await dblib.endQuery();

    var resr = await dblib.queryRows("select * from EMP ORDER BY EMPNO",3);
    dumpQueryRowsResult(resr);

    //
    st = await dblib.beginTrans();
    st = await dblib.execute("insert into EMP (ENAME,EMPNO) values ('JOHNSON',9998)");
    // st = await dblib.commitTrans();
    st = await dblib.rollbackTrans();
    res = await dblib.query("select ENAME,EMPNO from EMP where ENAME='JACKSON'");
    dumpRow(res.result);
    //
    // st = await dblib.execute("update EMP set name='scott' where EMPID=12123");
    //
    st = await dblib.disconnect();
    print(st);
  });
}
