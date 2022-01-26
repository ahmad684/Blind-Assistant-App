import 'dart:async';
import 'package:blind_assistan_app/main.dart';
import 'package:blind_assistan_app/textToSpeech.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ReadContacts extends StatefulWidget {
  const ReadContacts({Key key}) : super(key: key);

  @override
  _ReadContactsState createState() => _ReadContactsState();
}

TextToSpeech _textToSpeech = new TextToSpeech();

class _ReadContactsState extends State<ReadContacts> {
  stt.SpeechToText _speechToText;
  bool _isListening = true;
  List<Contact> contacts = [];
  List<Contact> contactsFiltered = [];
  TextEditingController searchController = TextEditingController();
  final double size = 36;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _textToSpeech.speak('contacts opened');
    _speechToText = stt.SpeechToText();
    getAllContacts();
    searchController.addListener(() {
      filterContacts();
    });
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
        iOSLocalizedLabels: false,
        androidLocalizedLabels: false,
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
        if (contactsFiltered.isEmpty) {
          _textToSpeech.speak("Contact not found");
          searchController.clear();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isSearching = searchController.text.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact'),
        backgroundColor: Colors.redAccent,
        actions: [
          IconButton(
              onPressed: () {
                searchController.clear();
                _listing();
              },
              icon: Icon(Icons.search))
        ],
      ),
      body: GestureDetector(
        onTap: () {
          searchController.clear();
          _listing();
        },
        child: Container(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 0.0, vertical: 5.0),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                          labelText: 'search',
                          border: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Theme.of(context).primaryColor)),
                          prefixIcon: Icon(Icons.search, color: Colors.red)),
                    )),
                ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount:
                        isSearching ? contactsFiltered.length : contacts.length,
                    itemBuilder: (context, index) {
                      if (isSearching
                          ? contactsFiltered[index].phones.isNotEmpty
                          : contacts[index].phones.isNotEmpty) {
                        Contact contact = isSearching
                            ? contactsFiltered[index]
                            : contacts[index];
                        return ListTile(
                            title: Text(contact.displayName),
                            subtitle: Text(contact.phones.elementAt(0).value),
                            leading: Container(
                                width: size,
                                height: size,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: getColorGradient(Colors.red)),
                                child: (contact.avatar != null &&
                                        contact.avatar.isNotEmpty)
                                    ? CircleAvatar(
                                        backgroundImage:
                                            MemoryImage(contact.avatar))
                                    : CircleAvatar(
                                        child: Text(contact.initials(),
                                            style: const TextStyle(
                                                color: Colors.white)),
                                        backgroundColor: Colors.transparent)),
                            trailing: InkWell(
                              child: Icon(
                                Icons.call,
                                color: Colors.red,
                              ),
                              onTap: () {
                                _callNumber(contact.phones.elementAt(0).value);
                              } /*() {
                                FlutterPhoneDirectCaller.directCall(
                                    contact.phones.elementAt(0).value);
                                _makePhoneCall("tel:${contact.phones.elementAt(0).value}");
                              }*/
                              ,
                            ));
                      } else {
                        return Container();
                      }
                    })
              ],
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
              searchController.text =
                  nameString(val.recognizedWords.toString());
              filterContacts();
              if (val.recognizedWords.toLowerCase().contains('call')) {
                _textToSpeech.speak("Call made");
                Future.delayed(const Duration(milliseconds: 1000), () {
                  setState(() {
                    _callNumber(contactsFiltered[0].phones.elementAt(0).value);
                  });
                });
                searchController.clear();
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
          listenFor: Duration(minutes: 10),
          pauseFor: Duration(seconds: 10),
          partialResults: false,
        );
      }
    }
  }
}

String nameString(String txt) {
/*  String b = '';
  List<String> a = txt.split(" ");
  for (int j = 2; j < a.length; j++) {
    b = b + a[j] + ' ';
  }
  return b.trim();*/
  //print(txt);
  RegExp rex = new RegExp(r"^(([A-Z].?\s?)*([A-Z][a-z]+\s?)+)");
  String b = '';
  List<String> a = txt.split(" ");
  for (int j = 0; j < a.length; j++) {
    if (rex.hasMatch(a[j].toString())) {
      //print(a[j]);
      b = b + a[j] + ' ';
    }
  }
  return b.trim();
}

_callNumber(String number) async {
  await FlutterPhoneDirectCaller.callNumber(number);
}

LinearGradient getColorGradient(Color color) {
  var baseColor = color as dynamic;
  Color color1 = baseColor[800];
  Color color2 = baseColor[400];
  return LinearGradient(colors: [
    color1,
    color2,
  ], begin: Alignment.bottomLeft, end: Alignment.topRight);
}
