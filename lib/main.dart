import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:sms_finance/message_storage.dart';
import 'package:telephony/telephony.dart';

backgrounMessageHandler(SmsMessage message) async {
  debugger();
  debugPrint("onBackgroundMessage called ${message.body}");
}

MyDatabase? database;

void main() {
  database = MyDatabase();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  final telephony = Telephony.instance;
  String _message = "";
  List<SmsMessage> messages = [];

  @override
  void initState() {
    super.initState();
    initPlatformState();
    final inbox = Telephony.instance.getInboxSms();
  }

  onMessage(SmsMessage message) async {
    setState(() {
      _message = message.body ?? "Error reading message body.";
    });
  }

  Future<void> initPlatformState() async {
    // Platform messages may fail, so we use a try/catch PlatformException.
    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.

    final bool? result = await telephony.requestPhoneAndSmsPermissions;

    if (result != null && result) {
      telephony.listenIncomingSms(
          onNewMessage: onMessage,
          onBackgroundMessage: backgrounMessageHandler);
    }

    final messages1 = await telephony.getInboxSms(
        // columns: [SmsColumn.ADDRESS, SmsColumn.BODY],
        // filter: SmsFilter.where(SmsColumn.ADDRESS).equals("266898"),
        // sortOrder: [
        //   OrderBy(SmsColumn.DATE, sort: Sort.ASC),
        // ],
        );
    debugPrint('number of messages ${messages1.length}');
    setState(() {
      messages = messages1;
    });

    if (!mounted) return;
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

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
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
            Text(_message),
            Expanded(
                child: ListView.builder(
              itemCount: _counter,
              prototypeItem: const ListTile(title: Text('uh oh')),
              itemBuilder: (context, index) {
                return ListTile(title: Text(messages[index].body ?? 'uh oh'));
              },
            )),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
