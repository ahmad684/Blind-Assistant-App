import 'package:blind_assistan_app/textToSpeech.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:async';
import 'package:device_information/device_information.dart';

import '../main.dart';

TextToSpeech _textToSpeech = new TextToSpeech();

class AddNotes extends StatefulWidget {
  @override
  _AddNotesState createState() => _AddNotesState();
}

class _AddNotesState extends State<AddNotes> {
  final db = FirebaseFirestore.instance;
  TextEditingController noteText = new TextEditingController();
  stt.SpeechToText _speechToText;
  bool _isListening = true;
  String _imeiNo = "", _deviceName = "";

  @override
  void initState() {
    super.initState();
    _speechToText = stt.SpeechToText();
    initPlatformState();
    _textToSpeech = new TextToSpeech();
    _textToSpeech.speak('Type Notes');
  }

  Future<void> initPlatformState() async {
    String imeiNo = '', deviceName = '';

    try {
      imeiNo = await DeviceInformation.deviceIMEINumber;
      deviceName = await DeviceInformation.deviceName;
    } catch (e) {
      print(e.message);
    }

    if (!mounted) return;

    setState(() {
      _imeiNo = imeiNo;
      _deviceName = deviceName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notes'),
        backgroundColor: Colors.redAccent,
      ),
      /*floatingActionButton: Container(
        margin: EdgeInsets.fromLTRB(32, 0, 0, 0),
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.red),
            ),
            onPressed: () {
              if (noteText.text != '') {
                _textToSpeech.speak(noteText.text + 'Long Press for Save Note');
              } else {
                _textToSpeech.speak('Please Speak something for write');
                _listing();
              }
            },
            onLongPress: () {
              Map<String, dynamic> data = {
                'deviceInformation': "$_deviceName$_imeiNo",
                'description': noteText.text,
                'Entry': DateTime.now()
              };
              if (noteText.text != '') {
                db.collection('notes').add(data);
                _textToSpeech.speak('Notes Added');
                noteText.clear();
                Navigator.pop(context);
              } else {
                _textToSpeech.speak('Please Speak something for write');
                _listing();
              }
            },
            child: Text('Add Notes')),
      ),*/
      body: GestureDetector(
        onTap: () => _listing(),
        onDoubleTap: () => _textToSpeech.speak(noteText.text),
        onLongPress: () {
          Map<String, dynamic> data = {
            'deviceInformation': "$_deviceName$_imeiNo",
            'description': noteText.text,
            'Entry': DateTime.now()
          };
          if (noteText.text != '') {
            db.collection('notes').add(data);
            _textToSpeech.speak('Notes Added');
            noteText.clear();
            Navigator.pop(context);
          } else {
            _textToSpeech.speak('Please Speak something for write');
            _listing();
          }
        },
        child: AbsorbPointer(
          child: Container(
            child: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: TextField(
                          textAlignVertical: TextAlignVertical.top,
                          maxLines: null,
                          expands: true,
                          controller: noteText,
                          readOnly: true,
                          decoration: InputDecoration(
                              hintText: 'Enter Text Here',
                              labelText: 'Note:',
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                              labelStyle: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                              )),
                          // onTap: () {
                          //   _listing();
                          // }
                        ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
              if (val.recognizedWords.toString().toLowerCase() == 'back to home') {
                Navigator.pushAndRemoveUntil<dynamic>(
                  context,
                  MaterialPageRoute<dynamic>(
                    builder: (BuildContext context) => MyHome(),
                  ),
                      (route) => false,//if you want to disable back feature set to false
                );
              }
              else if (val.recognizedWords.toString().toLowerCase() == 'back') {
                _textToSpeech.speak("Notes opened");
                Navigator.pop(context);
              }
              else if (val.recognizedWords.toString().toLowerCase() ==
                  "clear text") {
                noteText.clear();
                _textToSpeech.speak("cleared");
              }
              else {
                noteText.text += val.recognizedWords.toString() + " ";
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
