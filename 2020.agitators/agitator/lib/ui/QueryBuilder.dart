// ignore: import_of_legacy_library_into_null_safe
import 'package:cloud_firestore/cloud_firestore.dart';

FirebaseFirestore db = FirebaseFirestore.instance;

class QueryBuilder {
  QueryBuilder(this.querySpec);

  final Map<String, dynamic> querySpec;

  QueryBuilder where(
      {required String field,
      required String op,
      required String type,
      String? value,
      List<String>? values}) {
    dynamic newQuerySpec = querySpec;
    List<dynamic>? w = (newQuerySpec["where"] as List<dynamic>?)
        ?.where((e) => e["field"] != field || e["op"] != op)
        .toList();
    if (w == null) w = [];
    w.add({"field": field, "op": op, "type": type, "value": value});
    newQuerySpec["where"] = w;
    return QueryBuilder(newQuerySpec);
  }

  Query? build() {
    Query? query = makeCollRef();
    if (query == null)
      return null;
    else {
      querySpec["orderBy"]?.forEach((e) => query = buildOrderBy(query!, e));
      querySpec["where"]?.forEach((e) => query = buildFilter(query!, e));
    }
    int? limit = querySpec["limit"];
    if (limit != null) query = query?.limit(limit);

    return query;
  }

  Query? makeCollRef() {
    String? collectionGroup = querySpec["collectionGroup"];
    return makeSimpleCollRef() ?? db.collectionGroup(collectionGroup);
  }

  CollectionReference? makeSimpleCollRef() {
    String? collection = querySpec["collection"];
    if (collection != null) {
      CollectionReference c = db.collection(collection);
      querySpec["subCollections"]?.forEach(
          (e) => c = c.doc(e["document"]).collection(e["collection"]));
      return c;
    } else {
      return null;
    }
  }

  Query buildFilter(Query query, dynamic filter) {
    dynamic parseValue(String type, var value) {
      if (type == "boolean") return value == "true";
      if (type == "number") return num.parse(value);
      if (type == "string") return value as String;
      if (type == "null") return null;
      if (type == "list<string>") return value.map((e) => e as String).toList();
      return null;
    }

    String filterOp = filter["op"];
    String field = filter["field"];
    String type = filter["type"];
    dynamic value = filter["value"];
    dynamic values = filter["values"];

    if (filterOp == "sort") {
      return query.orderBy(field, descending: value == "true");
    } else if (filterOp == "==") {
      return query.where(field, isEqualTo: parseValue(type, value));
    } else if (filterOp == "!=") {
      return query.where(field, isNotEqualTo: parseValue(type, value));
    } else if (filterOp == ">=") {
      return query.where(field,
          isGreaterThanOrEqualTo: parseValue(type, value));
    } else if (filterOp == "<=") {
      return query.where(field, isLessThanOrEqualTo: parseValue(type, value));
    } else if (filterOp == ">") {
      return query.where(field, isGreaterThan: parseValue(type, value));
    } else if (filterOp == "<") {
      return query.where(field, isLessThan: parseValue(type, value));
    } else if (filterOp == "notIn") {
      return query.where(field, whereNotIn: parseValue(type, value));
    } else if (filterOp == "in") {
      return query.where(field, whereIn: parseValue(type, values));
    } else if (filterOp == "contains") {
      return query.where(field, arrayContains: parseValue(type, value));
    } else if (filterOp == "containsAny") {
      return query.where(field, arrayContainsAny: parseValue(type, values));
    } else {
      throw Exception();
    }
  }

  Query buildOrderBy(Query query, dynamic order) =>
      query.orderBy(order["field"], descending: order["descending"] == true);
}
