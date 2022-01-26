import 'package:blind_assistan_app/Battery/battery.dart';
import 'package:blind_assistan_app/Message/message.dart';
import 'package:blind_assistan_app/Notes/getNotes.dart';
import 'package:blind_assistan_app/Phone/Phone.dart';
import 'package:blind_assistan_app/textToSpeech.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'SplashScreen.dart';

TextToSpeech _textToSpeech = new TextToSpeech();
bool isAllPermissionAllowed = false;
void main() async {
  isAllPermissionAllowed = false;
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await [
    Permission.sms,
    Permission.contacts,
    Permission.phone,
    Permission.microphone,
    Permission.storage
  ].request();
  final PermissionStatus smsPermission = await Permission.sms.status;
  final PermissionStatus contactPermission = await Permission.contacts.status;
  final PermissionStatus phonePermission = await Permission.phone.status;
  final PermissionStatus macPermission = await Permission.microphone.status;
  final PermissionStatus storagePermission = await Permission.storage.status;

  if (smsPermission.isGranted &&
      contactPermission.isGranted &&
      phonePermission.isGranted &&
      macPermission.isGranted && storagePermission.isGranted) {
    isAllPermissionAllowed = true;
  }
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    initialRoute: '/',
    routes: {
      '/': (context) => SplashScreen(),
      '/second': (context) => MyHome(),
    },
  ));
}

class MyHome extends StatefulWidget {
  // This widget is the root of your application.
  @override
  State<MyHome> createState() => _MyHomeState();
}

class _MyHomeState extends State<MyHome> {
  String noteText = '';
  stt.SpeechToText _speechToText;
  bool _isListening = true;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _speechToText = stt.SpeechToText();
    _textToSpeech.speak('Home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Voice Assistant App'),
        backgroundColor: Colors.redAccent,
      ),
      body: isAllPermissionAllowed
          ? SafeArea(
              child: InkWell(
                onTap: () {
                  _listing();
                },
                child: Container(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Container(
                                    color: Colors.redAccent,
                                    height: 310,
                                    width: 150,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.call,
                                          size: 70,
                                          color: Colors.white,
                                        ),
                                        Text(
                                          'CALL',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 30,
                                              fontWeight: FontWeight.bold),
                                        )
                                      ],
                                    )),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Container(
                                    color: Colors.redAccent,
                                    height: 310,
                                    width: 150,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.sms,
                                          size: 70,
                                          color: Colors.white,
                                        ),
                                        Text(
                                          'MASSAGES',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 30,
                                              fontWeight: FontWeight.bold),
                                        )
                                      ],
                                    )),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Container(
                                    color: Colors.redAccent,
                                    height: 310,
                                    width: 150,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_comment_sharp,
                                          size: 70,
                                          color: Colors.white,
                                        ),
                                        Text(
                                          'NOTES',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 30,
                                              fontWeight: FontWeight.bold),
                                        )
                                      ],
                                    )),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Container(
                                    color: Colors.redAccent,
                                    height: 310,
                                    width: 150,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.battery_charging_full_outlined,
                                          size: 70,
                                          color: Colors.white,
                                        ),
                                        Text(
                                          'BATTERY',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 30,
                                              fontWeight: FontWeight.bold),
                                        )
                                      ],
                                    )),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : SafeArea(
              child: InkWell(
                onTap: () => SystemNavigator.pop(),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Container(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      child: Center(
                          child: Text(
                        'Please Allow All Permissions for Use his App',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ))),
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
              noteText = val.recognizedWords.toString();
              print(noteText);
              if (noteText.toLowerCase() == "open message"||noteText.toLowerCase() == "open messages") {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => MessageApp()));
              }
              if (noteText.toLowerCase() == "open call") {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => ReadContacts()));
              }
              if (noteText.toLowerCase() == "open notes"||noteText.toLowerCase() == "open note") {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => ReadNotes()));
              }
              if (noteText.toLowerCase() == "open battery") {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => HomePage()));
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
