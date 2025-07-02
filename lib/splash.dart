import 'package:audio_classification_final/main.dart';
import 'package:flutter/material.dart';

class Splash extends StatefulWidget {
  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyApp()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color.fromARGB(255, 234, 240, 239),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: Image.asset(
                  'assets/images/just_logo.png',
                  // height: 80,
                  width: 300,
                ),
              ),
              // SizedBox(
              //   height: 15,
              // ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Made with ", style: TextStyle(fontSize: 12)),
                  Icon(Icons.favorite, color: Colors.redAccent, size: 12),
                  Text(" In Hammer", style: TextStyle(fontSize: 12)),
                ],
              ),
              // if (Platform.isAndroid)
              //   CupertinoActivityIndicator(
              //     radius: 14,
              //   )
              // else
              //   CupertinoActivityIndicator(
              //     color: Colors.white,
              //   )
            ],
          ),
        ),
      ),
    );
  }
}
