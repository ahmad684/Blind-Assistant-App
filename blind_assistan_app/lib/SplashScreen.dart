import 'package:blind_assistan_app/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:splash_screen_view/SplashScreenView.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    Widget example2 = SplashScreenView(
      home: MyHome(),
      duration: 5000,
      imageSize: 400,
      imageSrc: "assests/images/splash.jpg",
      text: 'Blind Assistant App',
      textType: TextType.ColorizeAnimationText,
      textStyle: TextStyle(
        fontSize: 40.0,
      ),
      colors: [
        Colors.white,
        Colors.white,
        Colors.white,
        Colors.white,
      ],
      backgroundColor: Colors.redAccent,
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Splash screen Demo',
      home: example2,
    );
  }
}
