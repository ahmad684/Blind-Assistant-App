import 'package:blind_assistan_app/Message/Send.dart';
import 'package:blind_assistan_app/Shared%20Preference/sharedPreference.dart';
import 'package:blind_assistan_app/main.dart';
import 'package:blind_assistan_app/textToSpeech.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:country_codes/country_codes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sms/sms.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:telephony/telephony.dart' as tel;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

TextToSpeech _textToSpeech = new TextToSpeech();
MessageApp sms = new MessageApp();
final FlutterTts flutterTts1 = FlutterTts();

class MessageApp extends StatefulWidget {
  @override
  _MessageAppState createState() => _MessageAppState();
}

class _MessageAppState extends State<MessageApp> {
  FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  var searchController;
  stt.SpeechToText _speechToText;
  bool _isListening = true;
  List<Contact> contacts = [];
  List<Contact> contactsFiltered = [];
  String countryCode;
  SmsQuery query = new SmsQuery();
  List<SmsMessage> messages = [];
  List<SmsMessage> unreadMessages = [];
  Map<int, bool> messageStatus = {};

  @override
  initState() {
    // TODO: implement initState
    super.initState();
    _textToSpeech.speak('Message Opened');
    country();
    getAllContacts();
    _speechToText = stt.SpeechToText();
    initPlatformState();
    initializeSetting();
    tz.initializeTimeZones();
    Future.delayed(const Duration(milliseconds: 1500), () {
      setState(() {
        fetchSMS().whenComplete(
            () => getMap().whenComplete(() => unreadMessage(true)));
      });
    });
  }

  void country() async {
    await CountryCodes.init();
    final CountryDetails details = CountryCodes.detailsForLocale();
    countryCode = '+92';
  }

  Future<PermissionStatus> _getPermission() async {
    final PermissionStatus permission = await Permission.sms.status;
    if (permission != PermissionStatus.granted ||
        permission != PermissionStatus.denied) {
      final Map<Permission, PermissionStatus> permissionStatus =
          await [Permission.sms].request();
      return permissionStatus[Permission.sms] ?? PermissionStatus.denied;
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
    if (searchController.isNotEmpty) {
      _contact.retainWhere((contact) {
        String searchTerm = searchController.text.toLowerCase();
        String contactName = contact.displayName.toLowerCase();
        return contactName.contains(searchTerm);
      });
      setState(() {
        contactsFiltered = _contact;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
        appBar: AppBar(
          title: Text("SMS Inbox"),
          backgroundColor: Colors.redAccent,
          actions: [IconButton(onPressed: () {}, icon: Icon(Icons.contacts))],
        ),
        body: FutureBuilder(
          future: fetchSMS(),
          builder: (context, snapshot) {
            return ListView.separated(
                separatorBuilder: (context, index) =>
                    Divider(color: Colors.black),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ListTile(
                      onTap: () {
                        _listing();
                      },
                      onLongPress: () => flutterTts1.stop(),
                      leading: Icon(Icons.markunread, color: Colors.pink),
                      title: Text(searchName(messages[index].sender) ??
                          messages[index].sender ??
                          'Unknown'),
                      subtitle: Text(messages[index].body, maxLines: 2),
                      trailing: Column(
                        children: [
                          Text(
                              "${messages[index].date.hour}:${messages[index].date.minute}"),
                          Text(
                              "${messages[index].date.day}/${messages[index].date.month}/${messages[index].date.year}")
                        ],
                      ),
                    ),
                  );
                });
          },
        ));
  }

  String searchName(String num) {
    final numericRegex = RegExp(r'^\+?(([0-9]*)|([0-9]*))$');
    if (num != null &&
        numericRegex.hasMatch(num) &&
        num.replaceAll(' ', '').length > 10) {
      String num1 = num.replaceAll('-', '').replaceAll(' ', '');
      if ((num1.substring(0, num1.length - 10)) == countryCode ||
          num1.substring(0, 1) == '0') {
        for (int i = 0; i < contacts.length; i++) {
          Contact con = contacts[i];
          List a = con.phones;
          if (a.isNotEmpty) {
            if (con.phones
                .elementAt(0)
                .value
                .replaceFirst(countryCode, '')
                .replaceFirst('+', '')
                .replaceFirst('00', '')
                .replaceAll(' ', '')
                .replaceAll('-', '')
                .contains(num1
                    .replaceFirst(countryCode, '')
                    .replaceFirst('+', '')
                    .replaceFirst('00', '')
                    .replaceAll(' ', '')
                    .replaceAll('-', ''))) {
              return con.displayName;
            }
          }
        }
      } else {
        return num;
      }
    } else {
      return num;
    }
  }

  Future<void> fetchSMS() async {
    messages = await query.querySms(kinds: [SmsQueryKind.Inbox]);
  }

  Future<void> getMap() async {
    bool keyContain = await HelperFunction.isSharedPreferenceContainKey();
    if (keyContain) {
      String decodeMap =
          await HelperFunction.getMessageStatusSharedPreference();
      decodeMap = decodeMap
          .replaceAll("{", "")
          .replaceAll("}", "")
          .replaceAll(" ", "")
          .trim();
      List a = decodeMap.split(",");
      List b = [];
      messageStatus = {};
      a.forEach((element) {
        b = [];
        b = element.split(":");
        try {
          messageStatus[int.parse(b[0])] = b[1] == 'true' ? true : false;
        } on FormatException {
          print('error');
        }
      });
      for (int i = 0; i < messages.length; i++) {
        if (!messageStatus.containsKey(messages[i].id)) {
          messageStatus[messages[i].id] = false;
        }
      }
      HelperFunction.clearSharedPreference();
      String encodedMap = messageStatus.toString();
      HelperFunction.saveMessageStatusSharedPreference(
          encodedMap.replaceAll(" ", "").trim());
    } else {
      for (int i = 0; i < messages.length; i++) {
        messageStatus[messages[i].id] = true;
      }
      HelperFunction.clearSharedPreference();
      String encodedMap1 = messageStatus.toString();
      HelperFunction.saveMessageStatusSharedPreference(
          encodedMap1.replaceAll(" ", "").trim());
    }
  }

  Future<void> setMap() async {
    HelperFunction.clearSharedPreference();
    String encodedMap = messageStatus.toString();
    HelperFunction.saveMessageStatusSharedPreference(
        encodedMap.replaceAll(" ", "").trim());
  }

  Future<void> unreadMessage(bool isRead) async {
    String text = '';
    unreadMessages = [];
    for (int i = 0; i < messages.length; i++) {
      if (!messageStatus[messages[i].id]) {
        unreadMessages.add(messages[i]);
      }
    }
    text = "you have ${unreadMessages.length} unread messages";
    for (int j = 0; j < unreadMessages.length; j++) {
      String nn = searchName(unreadMessages[j].sender) ??
          unreadMessages[j].sender ??
          'Unknown';
      text = text +
          ("message ${j + 1} from $nn is ${unreadMessages[j].body} at ${unreadMessages[j].date.hour}:${unreadMessages[j].date.minute}");
      messageStatus[unreadMessages[j].id] = true;
    }
    if (isRead) {
      setMap();
      await speak1(text);
    }
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
              if (val.recognizedWords
                  .toString()
                  .toLowerCase()
                  .contains('message to')) {
                String searchName = val.recognizedWords
                    .toString()
                    .toLowerCase()
                    .replaceAll('message to', '')
                    .trim();
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SendSmsPage(name: searchName)));
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

  String _message = "";
  String number = '';
  final telephony = tel.Telephony.instance;
  onMessage(tel.SmsMessage message) async {
    number = searchName(message.address);
    _message = message.body ?? "Error reading message body.";
    setState(() {
      number = searchName(message.address);
      _message = message.body ?? "Error reading message body.";
    });
    displayNotification(number, _message);
  }

  static onBackgroundMessage(tel.SmsMessage message) async {}

  Future<void> initPlatformState() async {
    final bool result = await telephony.requestPhoneAndSmsPermissions;

    if (result != null && result) {
      telephony.listenIncomingSms(
          onNewMessage: onMessage, onBackgroundMessage: onBackgroundMessage);
    }

    if (!mounted) return;
  }

  Future<void> displayNotification(String numbers, String msg) async {
    _flutterLocalNotificationsPlugin.zonedSchedule(
        0,
        numbers,
        msg,
        tz.TZDateTime.now(tz.local).add(Duration(seconds: 1)),
        NotificationDetails(
            android: AndroidNotificationDetails('channel id', 'channel name')),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidAllowWhileIdle: true);
    fetchSMS()
        .whenComplete(() => getMap().whenComplete(() => unreadMessage(false)));
    Future.delayed(const Duration(milliseconds: 1000), () {
      setState(() {
        fetchSMS().whenComplete(
            () => getMap().whenComplete(() => unreadMessage(true)));
      });
    });
  }

  void initializeSetting() async {
    var initializeSetting = new AndroidInitializationSettings('ic_launcher');
    var androidSetting = new InitializationSettings(android: initializeSetting);
    _flutterLocalNotificationsPlugin.initialize(androidSetting);
  }
}

String nameString(String txt) {
  RegExp rex = new RegExp(r"^(([A-Z].?\s?)*([A-Z][a-z]+\s?)+)");
  String b = '';
  List<String> a = txt.split(" ");
  for (int j = 0; j < a.length; j++) {
    if (rex.hasMatch(a[j].toString())) {
      b = b + a[j] + ' ';
    }
  }
  return b.trim();
}

List clearList(List<String> a) {
  List b = [];
  for (int i = 0; i < a.length; i++) {
    b.add(a[i].replaceAll(" ", "").trim());
  }
  return b;
}

Future<void> speak1(String text) async {
  await flutterTts1.stop();
  await flutterTts1.awaitSpeakCompletion(true);
  await flutterTts1.speak(text);
  await flutterTts1.setPitch(1);
  await flutterTts1.awaitSynthCompletion(true);
  await flutterTts1.setSpeechRate(0.2);
}
