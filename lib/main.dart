import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  StreamSubscription _intentDataStreamSubscription;
  TextEditingController _serverController = new TextEditingController();
  TextEditingController _sharedController = new TextEditingController();
  String errorText = "";

  @override
  void initState() {
    super.initState();
    () async {
      final SharedPreferences prefs = await _prefs;
      String s = prefs.getString("server_url");
      print("updating button: $s");
      _serverController.text = s;
    }();

    // For sharing or opening urls/text coming from outside the app while the app is in the memory
    _intentDataStreamSubscription =
        ReceiveSharingIntent.getTextStream().listen((String value) {
      setState(() {
        _sharedController.text = value;
        print("Shared: ${_sharedController.text}");
      });
    }, onError: (err) {
      print("getLinkStream error: $err");
    });

    // For sharing or opening urls/text coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialText().then((String value) {
      setState(() {
        _sharedController.text = value;
        print("Shared: ${_sharedController.text}");
      });
    });
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  void onTextBoxSubmit(String s) async {
      final SharedPreferences prefs = await _prefs;
      if (await prefs.setString("server_url", s)) {
        setError("");
      } else {
        setError("Cannot set server value");
      }
  }

  void sendReqButton() async {
    http.Response resp = await http.post(_serverController.text);
    int code = resp.statusCode;
    if (code == 200) {
      setError("");
    } else {
      setError ("Error while sending request: $code");
    }
  }

  void setError(String err) {
    if (err != "") print(err);
    setState(() {
        errorText = err;
      }
    );
  }
    
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('ShareUrl'),
        ),
        body: Container(
          margin: EdgeInsets.symmetric(horizontal: 50),
          child: Center(
            child: Column(
              children: <Widget>[
                SizedBox(height: 50),
                TextField(
                  controller: _serverController,
                  onSubmitted:  onTextBoxSubmit,
                  decoration: InputDecoration(
                    labelText: "Server",
                  ),
                ),
                SizedBox(height: 50),
                TextField(
                  controller: _sharedController,
                  decoration: InputDecoration(
                    labelText: "Shared URL",
                  ),
                ),
                SizedBox(height: 50),
                RaisedButton(
                  child: Text("Send request"),
                  onPressed: sendReqButton,
                ),
                SizedBox(height: 50),
                Text(
                  "$errorText",
                  style: TextStyle(
                    color: Colors.red,
                  ),
                ),
              ]
            ),
          ),
        ),
      ),
    );
  }
}
