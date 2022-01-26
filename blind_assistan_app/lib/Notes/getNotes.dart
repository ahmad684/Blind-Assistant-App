import 'package:blind_assistan_app/Notes/addNotes.dart';
import 'package:blind_assistan_app/textToSpeech.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:async';
import 'package:device_information/device_information.dart';
import '../main.dart';

FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
TextToSpeech _textToSpeech = new TextToSpeech();

class ReadNotes extends StatefulWidget {
  @override
  _ReadNotesState createState() => _ReadNotesState();
}

class _ReadNotesState extends State<ReadNotes> {
  DateTime dateTime = DateTime.parse('2021-11-30 17:08:00.090427+0500');
  final DateTime now = DateTime.now();
  final DateFormat formatter = DateFormat('yyyy-MM-dd');
  stt.SpeechToText _speechToText;
  bool _isListening = true;

  String _imeiNo = "", _deviceName = "";

  @override
  void initState() {
    super.initState();
    initializeSetting();
    tz.initializeTimeZones();
    _speechToText = stt.SpeechToText();
    initPlatformState();
    _textToSpeech.speak('Notes opened');
  }

  Future<void> initPlatformState() async {
    String imeiNo = '', deviceName = '';

    try {
      imeiNo = await DeviceInformation.deviceIMEINumber;
      deviceName = await DeviceInformation.deviceName;
    } catch (e) {
      print(e);
    }
    if (!mounted) return;
    setState(() {
      _imeiNo = imeiNo;
      _deviceName = deviceName;
    });
  }

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance.collection('notes');
    return Scaffold(
      appBar: AppBar(
        title: Text('Notes'),
        backgroundColor: Colors.redAccent,
      ),
      body: SafeArea(
        child: StreamBuilder(
            stream: db
                .where("deviceInformation", isEqualTo: "$_deviceName$_imeiNo")
                .snapshots(),
            builder:
                (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasData ? snapshot.data.docs.isNotEmpty : false) {
                return ListView.builder(
                    itemCount: snapshot.data.docs.length,
                    itemBuilder: (context, index) {
                      DocumentSnapshot ds = snapshot.data.docs[index];
                      return Column(
                        children: [
                          ListTile(
                            title: Text(
                              ds['description'],
                              style: TextStyle(
                                  overflow: TextOverflow.ellipsis,
                                  fontSize: 16),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 16.0, horizontal: 16.0),
                            dense: true,
                            subtitle: Text(formatTimestamp(ds['Entry'])),
                            onTap: () {
                              _listing();
                            },
                            onLongPress: () {
                              _textToSpeech.speak(ds['description']);
                            },
                          ),
                          Divider(
                            thickness: 10,
                          ),
                        ],
                      );
                    });
              } else {
                return InkWell(
                  onTap: () => _listing(),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Container(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height,
                        child: Center(
                            child: Text(
                          'No data found! Click for add new note',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ))),
                  ),
                );
              }
            }),
      ),
    );
  }

  String formatTimestamp(Timestamp timestamp) {
    var format = new DateFormat('d-MM-y    hh:mm:ss'); // 'hh:mm' for hour & min
    return format.format(timestamp.toDate());
  }

  void _listing() async {
    if (_isListening) {
      bool available = await _speechToText.initialize(
        onStatus: (val) {
          print('onStatues:$val');
        },
        onError: (val) {
          print('onError:$val');
        },
      );
      if (available) {
        setState(() {
          _isListening = true;
        });
        _speechToText.listen(
          onResult: (val) {
            setState(() {
              if (val.recognizedWords.toString().toLowerCase() ==
                      "add new notes" ||
                  val.recognizedWords.toString().toLowerCase() ==
                      "add new note") {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => AddNotes()));
              }
              if (val.recognizedWords.toString().toLowerCase() ==
                      'back to home' ||
                  val.recognizedWords.toString().toLowerCase() == 'back') {
                Navigator.pushAndRemoveUntil<dynamic>(
                  context,
                  MaterialPageRoute<dynamic>(
                    builder: (BuildContext context) => MyHome(),
                  ),
                  (route) =>
                      false, //if you want to disable back feature set to false
                );
              }
            });
          },
          listenFor: Duration(minutes: 12),
          pauseFor: Duration(seconds: 5),
          partialResults: false,
        );
      }
    }
  }
}

void initializeSetting() async {
  var initializeSetting = new AndroidInitializationSettings('ic_launcher');
  var androidSetting = new InitializationSettings(android: initializeSetting);
  _flutterLocalNotificationsPlugin.initialize(androidSetting);
}
