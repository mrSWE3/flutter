import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kristoffers personal card',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Kristoffers personal card'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    double currentWidth = MediaQuery.of(context).size.width;
    double currentHeight = MediaQuery.of(context).size.height;
    const minRatio = 760 / 944;

    if (currentWidth / currentHeight > minRatio){
      currentWidth = currentHeight * minRatio;
    }


    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(
          'Personal card',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: currentWidth),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              CircleAvatar(
                radius: 0.25 * currentWidth,
                backgroundImage: AssetImage("assets/images/profil.jpg"),
              ),
              Container(
                margin: EdgeInsets.only(bottom: 10),
                child: Text(
                  "Kristoffer Gustafsson",
                  style: GoogleFonts.pacifico(
                    fontSize: currentWidth * 0.08,
                    color: Colors.black,
                  ),
                ),
              ),
              Container(
                width: currentWidth * 0.8,
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 184, 214, 255), // background color
                  borderRadius: BorderRadius.circular(15), // rounded corners
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(255, 0, 0, 0),
                      offset: const Offset(0, 2.0),
                      blurRadius: 5.0,
                      spreadRadius: 0.01,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Student",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: currentWidth * 0.04,
                      ),
                    ),
                    Row(
                      mainAxisSize:
                          MainAxisSize.min, // Wrap content horizontally
                      children: [
                        Icon(Icons.star, color: Colors.orange, size: currentWidth * 0.03,),
                        SizedBox(width: 8), // Spacing between icon and text
                        Text(
                          'I am a good programmer',
                          style: TextStyle(fontSize: currentWidth * 0.03),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize:
                          MainAxisSize.min, // Wrap content horizontally
                      children: [
                        Icon(
                          Icons.location_city,
                          color: const Color.fromARGB(255, 34, 0, 255),
                          size: currentWidth * 0.03,
                        ),
                        SizedBox(width: 8), // Spacing between icon and text
                        Text(
                          'I live in Gothenburg',
                          style: TextStyle(fontSize: currentWidth * 0.03),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize:
                          MainAxisSize.min, // Wrap content horizontally
                      children: [
                        Icon(
                          Icons.subway,
                          color: const Color.fromARGB(255, 151, 78, 0),
                          size: currentWidth * 0.03,
                        ),
                        SizedBox(width: 8), // Spacing between icon and text
                        Text(
                          'I ride the tram every day',
                          style: TextStyle(fontSize: currentWidth * 0.03),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
