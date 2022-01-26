import 'dart:async';
import 'package:blind_assistan_app/textToSpeech.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:telephony/telephony.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../main.dart';

TextToSpeech _textToSpeech;

class SendSmsPage extends StatefulWidget {
  final String name;
  SendSmsPage({this.name});
  @override
  _SendSmsPageState createState() => _SendSmsPageState();
}

class _SendSmsPageState extends State<SendSmsPage> {
  final telephony = Telephony.instance;
  final _formKey = GlobalKey<FormState>();
  stt.SpeechToText _speechToText;
  bool _isListening = true;
  List<Contact> contacts = [];
  List<Contact> contactsFiltered = [];
  TextEditingController searchController = TextEditingController();
  TextEditingController smsController = TextEditingController();
  final double size = 36;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    searchController.text = widget.name.trim();
    _speechToText = stt.SpeechToText();
    getAllContacts().whenComplete(() {
      filterContacts();
      _textToSpeech = new TextToSpeech();
    });
/*    searchController.addListener(() {
      filterContacts();
    });*/
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('Send Message'), backgroundColor: Colors.redAccent),
      body: GestureDetector(
        onTap: () => _listing(),
        onDoubleTap: () => _textToSpeech.speak(smsController.text),
        onLongPress: () => _sendSms(),
        child: AbsorbPointer(
          child: Container(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          TextFormField(
                            controller: searchController,
                            //keyboardType: TextInputType.phone,
                            readOnly: true,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                          ),
                          TextFormField(
                            controller: smsController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Type sms...';
                              }
                              return null;
                            },
                            maxLines: 25,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    )),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _listing() async {
    FocusManager.instance.primaryFocus?.unfocus();
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
                  "clear text") {
                smsController.clear();
                _textToSpeech.speak("cleared");
              } else if (val.recognizedWords.toString().toLowerCase() ==
                  'back to home') {
                smsController.clear();
                Navigator.pushAndRemoveUntil<dynamic>(
                  context,
                  MaterialPageRoute<dynamic>(
                    builder: (BuildContext context) => MyHome(),
                  ),
                  (route) =>
                      false, //if you want to disable back feature set to false
                );
              } else if (val.recognizedWords.toString().toLowerCase() ==
                  'back') {
                _textToSpeech.speak("Message opened");
                Navigator.pop(context);
              } else {
                smsController.text =
                    smsController.text + " " + val.recognizedWords.toString();
              }
            });
          },
          listenFor: Duration(minutes: 10),
          pauseFor: Duration(seconds: 10),
          partialResults: false,
        );
      }
    }
  }

  Future<PermissionStatus> _getPermission() async {
    final PermissionStatus permission = await Permission.contacts.status;
    if (permission != PermissionStatus.granted ||
        permission != PermissionStatus.denied) {
      final Map<Permission, PermissionStatus> permissionStatus =
          await [Permission.contacts].request();
      return permissionStatus[Permission.contacts] ?? PermissionStatus.denied;
    } else {
      return permission;
    }
  }

  Future<void> getAllContacts() async {
    final PermissionStatus permissionStatus = await _getPermission();
    if (permissionStatus == PermissionStatus.granted) {
      List<Contact> _contacts = await ContactsService.getContacts(
        withThumbnails: false,
        photoHighResolution: false,
      );
      setState(() {
        contacts = _contacts;
      });
    }
  }

  filterContacts() {
    List<Contact> _contact = [];
    _contact.addAll(contacts);
    if (searchController.text.isNotEmpty) {
      _contact.retainWhere((contact) {
        String searchTerm = searchController.text.toLowerCase();
        String contactName = contact.displayName.toLowerCase();
        return contactName.contains(searchTerm);
      });
      setState(() {
        contactsFiltered = _contact;
      });
      setTextField();
    }
  }

  void setTextField() {
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        if (contactsFiltered.isNotEmpty &&
            contactsFiltered[0].phones.elementAt(0).value.isNotEmpty &&
            contactsFiltered[0]
                .displayName
                .toLowerCase()
                .contains(widget.name)) {
          searchController.text = contactsFiltered[0].phones.elementAt(0).value;
          _textToSpeech.speak('Type Message');
        } else {
          _textToSpeech.speak("${widget.name} contact is not found");
          Navigator.pop(context);
        }
      });
    });
  }

  void _sendSms() async {
    if (smsController.text.isNotEmpty) {
      await telephony.sendSms(
          to: searchController.text, message: smsController.text);
      smsController.clear();
      _textToSpeech.speak("Message sent");
      Navigator.pop(context);
    } else {
      _textToSpeech.speak("Please tap on screen and speak message");
    }
  }
}

class AlwaysDisabledFocusNode extends FocusNode {
  @override
  bool get hasFocus => false;
}
