// dblib.dart
// Copyright (C) 2022 TechKnowledge.
//

library dblib;

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:xml/xml.dart';
import 'package:logger/logger.dart';
import 'enums.dart';
import 'query_response.dart';

///
/// DbLib class or Oracle/SQL Server/PSQL Connectors
///
class DbLib {
  /// server url
  late String url;

  /// true if need logging
  bool verbose = false;

  /// true if server is installed sub folder. set full path to url.
  bool rawUrl = false;

  /// network time out in micro seconds
  int networkTimeout = 10000;

  /// last exception occurred
  dynamic lastException = null;

  /// last server error
  String lastServerError = "";

  /// last http status code
  int lastHttpStatusCode = 0;

  late var _dio = null;
  late String _strUrl;
  final Logger _logger = Logger();
  late var _cookieJar;
  MethodType _mt = MethodType.none;
  final _soapHttpHeader = {
    "Content-Type": "text/xml; charset=utf-8",
    "Accept-Encoding": "gzip",
    "Connection": "keep-alive",
  };
  final _soapRequestHeader =
      '<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body>';
  final _soapRequestFooter = '</soap:Body></soap:Envelope>';

  void _setup() {
    if (_dio != null) {
      return;
    }
    _dio = Dio(BaseOptions(
        connectTimeout: networkTimeout, // in ms
        receiveTimeout: networkTimeout,
        sendTimeout: networkTimeout,
        responseType: ResponseType.plain,
        followRedirects: false,
        validateStatus: (status) {
          return true;
        }));
    _cookieJar = CookieJar();
    _dio.interceptors.add(CookieManager(_cookieJar));
    _strUrl = url;
    if (!rawUrl) {
      _strUrl += "/dbLibServer.asmx";
    }
  }

  Map<String, String> _buildHTTPHeader(String methodName) {
    var hdr = _soapHttpHeader;
    var entry = [MapEntry("SOAPAction", "http://tempuri.org/$methodName")];
    hdr.addEntries(entry);
    return hdr;
  }

  Future<QueryResponse> _requestSoap(String soapMsg, String method) async {
    var qr = QueryResponse();
    try {
      var httpHeader = _buildHTTPHeader(method);
      var response = await _dio.post(
        _strUrl,
        options: Options(headers: httpHeader),
        data: soapMsg,
      );
      lastHttpStatusCode = response.statusCode;
      if (response.statusCode == 200) {
        var res = _parseQueryResult(response.data);
        if (res.isEmpty) {
          qr.status = StatusEnum.endOfData;
        } else {
          qr.status = StatusEnum.normal;
        }
        qr.result = res;
        return Future.value(qr);
      }
    } catch (e, s) {
      if (verbose) {
        _logger.e(e);
        _logger.e(s);
      }
      lastException = e;
    }
    return Future.value(qr);
  }

  Future<QueryRowsResponse> _requestQueryRowsSoap(
      String soapMsg, String methodName) async {
    var resp = QueryRowsResponse();
    try {
      var header = _buildHTTPHeader(methodName);
      var response = await _dio.post(
        _strUrl,
        options: Options(headers: header),
        data: soapMsg,
      );
      lastHttpStatusCode = response.statusCode;
      if (response.statusCode == 200) {
        var list = _parseQueryRowsResult(response.data);
        resp.status = StatusEnum.normal;
        resp.result = list;
        return Future.value(resp);
      }
      resp.status = StatusEnum.httpError;
      return Future.value(resp);
    } catch (e, s) {
      if (verbose) {
        _logger.e(e);
        _logger.e(s);
      }
      lastException = e;
    }
    resp.status = StatusEnum.fatal;
    return Future.value(resp);
  }

  Future<StatusEnum> _requestNoParameterMethod(String methodName) async {
    try {
      var header = _buildHTTPHeader(methodName);
      var msg = _soapRequestHeader + _soapRequestFooter;
      print(msg);
      var response = await _dio.post(
        _strUrl,
        options: Options(headers: header),
        data: msg,
      );
      lastHttpStatusCode = response.statusCode;
      if (response.statusCode == 200) {
        return _parseBooleanResult(response.data);
      } else {
        return Future.value(StatusEnum.httpError);
      }
    } catch (e, s) {
      if (verbose) {
        _logger.e(e);
        _logger.e(s);
      }
      lastException = e;
    }
    return Future.value(StatusEnum.netwrokFail);
  }

  Map<String, dynamic> _parseQueryResult(String str) {
    var result = Map<String, dynamic>();
    try {
      if (verbose) {
        _logger.i(str);
      }
      var xml = XmlDocument.parse(str);
      var serverResult = xml.findAllElements('result');
      if (serverResult.first.innerText == 'false') {
        var lastErrorText = xml.findAllElements('lastErrorText');
        if (lastErrorText != null && lastErrorText.isNotEmpty) {
          lastServerError = lastErrorText.first.innerText;
        }
        return result;
      }
      var row = xml.findAllElements("row");
      for (var r in row) {
        var cols = r.findAllElements("Col");
        for (var c in cols) {
          var nameElem = c.findElements("name");
          var valElem = c.findElements("value");
          if (nameElem.isNotEmpty) {
            var name = nameElem.first.innerText;
            if (valElem.isNotEmpty) {
              result[name] = valElem.first.innerText;
            } else {
              result[name] = '';
            }
          }
        }
      }
      return result;
    } catch (e, s) {
      if (verbose) {
        _logger.e(e);
        _logger.e(s);
      }
      lastException = e;
      return result;
    }
  }

  List<Map<String, dynamic>> _parseQueryRowsResult(String str) {
    var result = List.filled(0, Map<String, dynamic>(), growable: true);
    try {
      if (verbose) {
        _logger.i(str);
      }
      var xml = XmlDocument.parse(str);
      var serverResult = xml.findAllElements('result');
      if (serverResult.first.innerText == 'false') {
        var lastErrorText = xml.findAllElements('lastErrorText');
        if (lastErrorText != null && lastErrorText.isNotEmpty) {
          lastServerError = lastErrorText.first.innerText;
        }
        return result;
      }
      var rows = xml.findAllElements("rows");
      for (var row in rows) {
        for (var ac in row.findAllElements("ArrayOfCol")) {
          var m = Map<String, dynamic>();
          for (var c in ac.findAllElements("Col")) {
            var nameElem = c.findElements("name");
            var valElem = c.findElements("value");
            if (nameElem.isNotEmpty) {
              var name = nameElem.first.innerText;
              if (valElem.isNotEmpty) {
                m[name] = valElem.first.innerText;
              } else {
                m[name] = '';
              }
            }
          }
          result.add(m);
        }
      }
      return result;
    } catch (e, s) {
      // XmlParseException or XmlTagException
      if (verbose) {
        _logger.e(e);
        _logger.e(s);
      }
      lastException = e;
      return result;
    }
  }

  StatusEnum _parseBooleanResult(String str) {
    try {
      if (verbose) {
        _logger.i(str);
      }
      var xml = XmlDocument.parse(str);
      var serverResult = xml.findAllElements('result');
      if (serverResult.first.innerText == 'false') {
        var lastErrorText = xml.findAllElements('lastErrorText');
        if (lastErrorText != null && lastErrorText.isNotEmpty) {
          lastServerError = lastErrorText.first.innerText;
        }
        return StatusEnum.serverError;
      }
      return StatusEnum.normal;
    } catch (e, s) {
      if (verbose) {
        _logger.e('xml parse fail $e');
        _logger.e(s);
      }
      lastException = e;
      return StatusEnum.parseXMLError;
    }
  }

  Future<StatusEnum> connect() async {
    try {
      _setup();

      var header = _buildHTTPHeader("Login");
      String soapMsg = _soapRequestHeader +
          '<Login xmlns="http://tempuri.org/"><udid>123456123456</udid><cns></cns></Login>' +
          _soapRequestFooter;
      var response = await _dio.post(
        _strUrl,
        options: Options(headers: header),
        data: soapMsg,
      );
      _mt = MethodType.connect;
      if (response.statusCode == 200) {
        return _parseBooleanResult(response.data);
      }
      return Future.value(StatusEnum.httpError);
    } catch (e, s) {
      if (verbose) {
        _logger.e(e);
        _logger.w(s);
      }
      lastException = e;
    }
    return Future.value(StatusEnum.connectFail);
  }

  Future<StatusEnum> disconnect() async {
    _mt = MethodType.disconnect;
    return await _requestNoParameterMethod("Logout");
  }

  Future<QueryResponse> query(String sql) async {
    String body = '<Query xmlns="http://tempuri.org/"><sql>$sql</sql></Query>';
    String msg = _soapRequestHeader + body + _soapRequestFooter;
    _mt = MethodType.query;
    return await _requestSoap(msg, "Query");
  }

  Future<QueryResponse> fetch() async {
    if (_mt != MethodType.query && _mt != MethodType.fetch) {
      var r = QueryResponse();
      r.status = StatusEnum.methodSequenceError;
      return r;
    }
    String body = '<Fetch xmlns="http://tempuri.org/"></Fetch>';
    String msg = _soapRequestHeader + body + _soapRequestFooter;
    _mt = MethodType.fetch;
    return await _requestSoap(msg, "Fetch");
  }

  Future<StatusEnum> endQuery() async {
    if (_mt != MethodType.query && _mt != MethodType.fetch) {
      return StatusEnum.methodSequenceError;
    }
    _mt = MethodType.endQuery;
    return await _requestNoParameterMethod("EndQuery");
  }

  Future<QueryRowsResponse> queryRows(String sql, [int maxRows = 0]) async {
    String body =
        '<QueryRows xmlns="http://tempuri.org/"><sql>$sql</sql><maxRows>$maxRows</maxRows></QueryRows>';
    String msg = _soapRequestHeader + body + _soapRequestFooter;
    _mt = MethodType.queryRows;
    return await _requestQueryRowsSoap(msg, "QueryRows");
  }

  Future<StatusEnum> execute(String sql) async {
    try {
      String body =
          '<Execute xmlns="http://tempuri.org/"><sql>$sql</sql></Execute>';
      String msg = _soapRequestHeader + body + _soapRequestFooter;
      _mt = MethodType.execute;

      var header = _buildHTTPHeader("Execute");
      var response = await _dio.post(
        _strUrl,
        options: Options(headers: header),
        data: msg,
      );
      lastHttpStatusCode = response.statusCode;
      if (response.statusCode == 200) {
        return _parseBooleanResult(response.data);
      } else {
        return Future.value(StatusEnum.httpError);
      }
    } catch (e, s) {
      if (verbose) {
        _logger.e(e);
        _logger.e(s);
      }
      lastException = e;
    }
    return Future.value(StatusEnum.fatal);
  }

  Future<StatusEnum> beginTrans() async {
    _mt = MethodType.beginTrans;
    return await _requestNoParameterMethod("BeginTrans");
  }

  Future<StatusEnum> commitTrans() async {
    _mt = MethodType.commitTrans;
    return await _requestNoParameterMethod("CommitTrans");
  }

  Future<StatusEnum> rollbackTrans() async {
    _mt = MethodType.rollbackTrans;
    return await _requestNoParameterMethod("RollbackTrans");
  }
}
