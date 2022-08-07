library dblib;

enum StatusEnum {
  normal,
  notConnected,
  connectFail,
  endOfData,
  methodSequenceError,
  parseXMLError,
  netwrokFail,
  sqlEmpty,
  serverError,
  httpError,
  fatal,
}

enum MethodType {
  none,
  connect,
  disconnect,
  execute,
  query,
  fetch,
  endQuery,
  queryRows,
  beginTrans,
  commitTrans,
  rollbackTrans,
}