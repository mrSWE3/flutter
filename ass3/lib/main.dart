
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; 
import 'auth/secrets.dart';
import 'package:intl/intl.dart';

Position? globalPos;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (await _checkLocationPermissionOnce()) {
    globalPos = await Geolocator.getCurrentPosition();
    print("got pos");
    runApp(MyApp());
  }else{
    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Premission denied",
    home: Scaffold(
      body: Center(
        child:  Text('Please enable location permission in settings and restart the app.'),
      ),
    ),
  ));
  }

}
//Inspired by https://fernandoptr.medium.com/how-to-get-users-current-location-address-in-flutter-geolocator-geocoding-be563ad6f66a
Future<bool> _checkLocationPermissionOnce() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) return false;

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  return permission == LocationPermission.always ||
      permission == LocationPermission.whileInUse;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      theme: ThemeData(
        colorScheme: ColorScheme(
          brightness: Brightness.dark,
          primary: const Color.fromARGB(255, 85, 179, 255),
          onPrimary: Colors.blue,
          surface: Colors.white,
          onSurface: Colors.black,
          error: Colors.red,
          onError: Colors.white,
          secondary: Colors.amber,
          onSecondary: const Color.fromRGBO(0, 0, 0, 1),
        ),
        appBarTheme: AppBarTheme(elevation: 6, shadowColor: Colors.black),
      ),
      
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(title: 'Weather App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

Position? getPosition() {
  return globalPos;
}


class _MyHomePageState extends State<MyHomePage> {
  HomePage homePage = HomePage();
  ForcastPage forcastPage = ForcastPage();
  AboutPage aboutPage = AboutPage();
  int currentPage = 0;

  Widget HotBarItem(IconData icon, String text, int goTo) {
    Color iconColor = Colors.grey;
    if (currentPage == goTo) {
      iconColor = Colors.blue;
    }
    return InkWell(
      onTap: () {
        setState(() {
          currentPage = goTo;
        });
      },
      child: Column(
        children: [
          Icon(icon, color: iconColor),
          Text(text),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: IndexedStack(
              index: currentPage,
              children: [homePage, forcastPage, aboutPage],
            ),
          ),
          Container(
            color: Color.fromARGB(255, 240, 240, 240),
            padding: EdgeInsets.only(top: 10, bottom: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HotBarItem(Icons.home, "Home", 0),
                HotBarItem(Icons.bar_chart, "Forcast", 1),
                HotBarItem(Icons.info, "About", 2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<Map<String, dynamic>> fetchWeatherData(Position pos) async {
  double lat = pos.latitude;
  double lon = pos.longitude;
  final url = Uri.parse(
    'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$API_KEY&units=metric',
  );
  final response = await http.get(url);
  if (response.statusCode == 200) {
    Map<String, dynamic> body = jsonDecode(response.body);
    String iconName = body["weather"][0]["icon"];
    final url = Uri.parse('https://openweathermap.org/img/wn/$iconName@2x.png');
    final responseIcon = await http.get(url);
    return {
      "description": body["weather"][0]["description"],
      "icon": Image.memory(responseIcon.bodyBytes, fit: BoxFit.fill),
      "iconName": iconName,
      "temp": body["main"]["temp"],
    };
  }
  return {};
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Map<String, dynamic> _cachedData = {};
  int timeUntillRefresh = 0;


  Future<Map<String, dynamic>> loadData() async {
    Position? pos = getPosition();
    if (pos == null) {
      return {};
    }
    Map<String, dynamic> dict = {"position": pos};
    Map<String, dynamic> weatherData = await fetchWeatherData(pos);
    dict.addAll(weatherData);
    List<Placemark> placemarks = await placemarkFromCoordinates(
      pos.latitude,
      pos.longitude,
    );
    if (placemarks.isNotEmpty) {
      dict["Location"] = placemarks[0];
    }
    dict["time"] = DateTime.now();
    return dict;
  }

  @override
  void initState() {
    super.initState();
    Timer.periodic(Duration(seconds: 10), (timer) async {
    var dict = await loadData();
    setState(() {
      _cachedData.addAll(dict);
    });
  });
  }

  @override
  Widget build(BuildContext context) {
    if (_cachedData.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }
    Image icon = _cachedData["icon"] ?? Icons.home;
    Placemark location = _cachedData["Location"];
    String country = [
      location.isoCountryCode,
      location.country,
      location.administrativeArea,
    ].firstWhere((v) => v != null && v != "", orElse: () => "")!;
    String palce = [
      location.subLocality,
      location.locality,
      location.subAdministrativeArea,
    ].firstWhere((v) => v != null && v != "", orElse: () => "")!;
    DateTime date = _cachedData["time"];
    String description = _cachedData["description"];
    description =
        description.substring(0, 1).toUpperCase() +
        description.substring(1, description.length);
    double temp = _cachedData["temp"].toDouble();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "${temp.round()} °C",
                  style: TextStyle(fontSize: 60, fontWeight: FontWeight.bold),
                ),
                Container(
                  margin: EdgeInsets.only(bottom: 5),
                  child: Container(
                    padding: EdgeInsets.only(bottom: 5),
                    decoration: BoxDecoration(
                      color: Colors.lightBlueAccent,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                        bottom: Radius.circular(20),
                      ),
                    ),
                    child: SizedBox(width: 200, height: 200, child: icon),
                  ),
                ),

                Transform.translate(
                  offset: Offset(0, -42),
                  child: Column(
                    children: [
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 22,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          shadows: List.generate(
                            20,
                            (_) => Shadow(blurRadius: 5),
                          ),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 15),
                        child: Text(
                          "$country, $palce",
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: EdgeInsets.only(bottom: 10),
              child: Column(
                children: [
                  Text(DateFormat('EEEE, MMMM d, yyyy hh:mm a').format(date)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<List<Map<String, dynamic>>> fetchForcast(Position pos) async {
  double lat = pos.latitude;
  double lon = pos.longitude;
  final url = Uri.parse(
    'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=$API_KEY&units=metric',
  );
  final response = await http.get(url);
  if (response.statusCode == 200) {
    Map<String, dynamic> body = jsonDecode(response.body);
    List<dynamic> forcasts = body["list"];
    return await Future.wait(
      forcasts.map((e) async {
        String iconName = e["weather"][0]["icon"];
        final url = Uri.parse(
          'https://openweathermap.org/img/wn/$iconName@2x.png',
        );
        final responseIcon = await http.get(url);
        return {
          "time": DateTime.fromMillisecondsSinceEpoch(e["dt"] * 1000),
          "description": e["weather"][0]["description"],
          "icon": Image.memory(responseIcon.bodyBytes),
          "iconName": iconName,
          "temp": e["main"]["temp"],
        };
      }).toList(),
    );
  }
  return [];
}

class ForcastPage extends StatefulWidget {
  const ForcastPage({super.key});

  @override
  State<ForcastPage> createState() => _ForcastPageState();
}

class _ForcastPageState extends State<ForcastPage> {
  final Map<String, dynamic> _cachedData = {};
  int timeUntillRefresh = 0;

  Future<Map<String, dynamic>> loadData() async {
    Position? pos = getPosition();
    if (pos == null) {
      return {};
    }
    Map<String, dynamic> dict = {"position": pos};
    dict["time"] = DateTime.now();
    List<Placemark> placemarks = await placemarkFromCoordinates(
      pos.latitude,
      pos.longitude,
    );
    if (placemarks.isNotEmpty) {
      dict["Location"] = placemarks[0];
    }
    dict["forcasts"] = await fetchForcast(pos);
    return dict;
  }


  @override
  void initState() {
    super.initState();
    Timer.periodic(Duration(seconds: 10), (timer) async {
    var dict = await loadData();
    setState(() {
      _cachedData.addAll(dict);
    });
  });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cachedData.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }
    List<dynamic> forcastDatas = _cachedData["forcasts"];
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            children: forcastDatas.map((e) {
              DateTime time = e["time"];
              String description = e["description"];
              Image icon = e["icon"];
              double temp = (e["temp"] as num).toDouble();
              return Container(
                margin: EdgeInsets.only(top: 20, left: 20, right: 20),
                child: Row(
                  children: [
                    Container(
                      margin: EdgeInsets.only(bottom: 5),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.lightBlueAccent,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: SizedBox(width: 40, height: 40, child: icon),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.only(left: 10),
                        child: Wrap(
                          alignment: WrapAlignment.start,
                          children: [
                            Text(
                              DateFormat(
                                'EEEE, MMMM d, yyyy hh:mm a - ',
                              ).format(time),
                            ),
                            Text("$temp °C - "),
                            Text(description),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Project Weather", style: TextStyle(fontSize: 30)),
            Text(
              "This is an app that is developed for the course 1DV535 at Linnaeus University using Flutter and the OpenWeatherMap API.",
              textAlign: TextAlign.center,
            ),
            Text(
              "Developed by Kristoffer Gustafsson",
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
