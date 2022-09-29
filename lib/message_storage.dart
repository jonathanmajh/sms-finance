import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:telephony/telephony.dart' as tele;

part 'message_storage.g.dart';

class Messages extends Table {
  IntColumn get id => integer()();
  TextColumn get author => text()();
  TextColumn get content => text()();
  IntColumn get date => integer()();
  BoolColumn get processed => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName("Category")
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}

class Vendors extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get defaultVendor => integer().references(Categories, #id)();
}

class Transactions extends Table {
  IntColumn get id => integer().references(Messages, #id)();
  IntColumn get account => integer()();
  IntColumn get amount => integer()();
  TextColumn get vendor => text()();
  IntColumn get category => integer()();
  BoolColumn get uploaded => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class MessagesWithTransactions {
  MessagesWithTransactions(this.message, this.transaction);

  final Message message;
  final Transaction transaction;
}

@DriftDatabase(tables: [Messages, Categories, Vendors, Transactions])
class MyDatabase extends _$MyDatabase {
  MyDatabase() : super(_openConnection());

  // you should bump this number whenever you change or add a table definition.
  @override
  int get schemaVersion => 1;

  Future<void> addMessages(List<tele.SmsMessage> smsMessages) async {
    List<MessagesCompanion> inserts = [];
    for (final message in smsMessages) {
      inserts.add(MessagesCompanion.insert(
        id: Value(message.id ?? 0),
        author: message.address ?? '',
        content: message.body ?? '',
        date: message.date ?? 0,
      ));
    }
    await batch((batch) {
      batch.insertAll(messages, inserts);
    });
  }

  Future<int> updateTransaction(TransactionsCompanion transaction) {
    return into(transactions).insertOnConflictUpdate(transaction);
  }

  Future<List<MessagesWithTransactions>> getAllMessagesWithTransactions() {
    final query = select(messages).join([
      leftOuterJoin(transactions, transactions.id.equalsExp(messages.id)),
    ]);
    return query.map((row) {
      final message = row.readTable(messages);
      final transaction = row.readTable(transactions);
      return MessagesWithTransactions(
        message,
        transaction,
      );
    }).get();
  }
}

LazyDatabase _openConnection() {
  // the LazyDatabase util lets us find the right location for the file async.
  return LazyDatabase(() async {
    // put the database file, called db.sqlite here, into the documents folder
    // for your app.
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}
