library dblib;
import 'enums.dart';

class QueryResponse {
  StatusEnum status = StatusEnum.normal;
  late Map<String,dynamic> result;
}

class QueryRowsResponse {
  StatusEnum status = StatusEnum.normal;
  late List<Map<String,dynamic>> result;
}