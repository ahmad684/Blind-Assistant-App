import 'dart:async';
import 'package:battery/battery.dart';
import 'package:blind_assistan_app/main.dart';
import 'package:blind_assistan_app/textToSpeech.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;


TextToSpeech _textToSpeech = new TextToSpeech();

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  _HomePageState(){
    speakBatteryStatus();
  }
  stt.SpeechToText _speechToText;
  bool _isListening = true;
  Battery _battery = Battery();
  BatteryState _batteryState;
  int _batterLevel;
  StreamSubscription<BatteryState> _batteryStateSubscription;
  @override
  void initState() {
    super.initState();
    _getLevel();
    _batteryStateSubscription =
        _battery.onBatteryStateChanged.listen((BatteryState state) {
      setState(() {
        _batteryState = state;
      });
    });
    _speechToText = stt.SpeechToText();
  }

  Future<void> _getLevel() async {
    final int batteryLevel = await _battery.batteryLevel;
    setState(() {
      _batterLevel = batteryLevel;
    });
  }

  @override
  void dispose() {
    super.dispose();
    if (_batteryStateSubscription != null) {
      _batteryStateSubscription.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Battery Level'),
        backgroundColor: Colors.redAccent,
      ),
      body: GestureDetector(
    onTap: () => _listing(),
    onDoubleTap: ()=> speakBatteryStatus(),
    onLongPress: () => speakBatteryStatus(),
        child: AbsorbPointer(
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    child: Container(
                      height: 500,
                      width: 500,
                      child: Icon(
                        Icons.battery_charging_full_outlined,
                        size: 150,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                  Text(
                    '$_batteryState',
                    style: TextStyle(fontSize: 20),
                  ),
                  Text(
                    'Battery Level : $_batterLevel %',
                    style: TextStyle(fontSize: 20),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  void speakBatteryStatus(){
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        _getLevel();
        _textToSpeech.speak(
            '$_batteryState and battery level is $_batterLevel percent');
      });
    });
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
              if (val.recognizedWords.toString().toLowerCase() == 'back to home' || val.recognizedWords.toString().toLowerCase() == 'back') {
                Navigator.pushAndRemoveUntil<dynamic>(
                  context,
                  MaterialPageRoute<dynamic>(
                    builder: (BuildContext context) => MyHome(),
                  ),
                      (route) => false,//if you want to disable back feature set to false
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
