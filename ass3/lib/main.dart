import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth/secrets.dart';

void main() async {
  runApp(MyApp());
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
          onSecondary: Colors.black,
        ),
        appBarTheme: AppBarTheme(elevation: 6, shadowColor: Colors.black),
      ),
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

//Taken form https://fernandoptr.medium.com/how-to-get-users-current-location-address-in-flutter-geolocator-geocoding-be563ad6f66a
Future<bool> _handleLocationPermission(BuildContext context) async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Location services are disabled. Please enable the services',
        ),
      ),
    );
    return false;
  }
  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permissions are denied')),
      );
      return false;
    }
  }
  if (permission == LocationPermission.deniedForever) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Location permissions are permanently denied, we cannot request permissions.',
        ),
      ),
    );
    return false;
  }
  return true;
}

Future<Position?> getPosition(BuildContext context) {
  return _handleLocationPermission(context).then((value) {
    if (value) {
      return Geolocator.getCurrentPosition();
    }
    return null;
  });
}

Future<Placemark?> getLocation(Position pos) {
  return placemarkFromCoordinates(pos.latitude, pos.longitude).then((value) {
    if (value.isEmpty) {
      return null;
    }
    return value[0];
  });
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
    'https://api.openweathermap.org/data/2.5/lat=$lat&lon=$lon&appid=$API_KEY&units=metric',
  );
  final response = await http.get(url);
  if (response.statusCode == 200) {
    Map<String, dynamic> body = jsonDecode(response.body);
    print(body.toString());
    String iconName = body["weather"][0]["icon"];
    final url = Uri.parse(
    'https://openweathermap.org/img/wn/$iconName@2x.png',
  );
    final responseIcon = await http.get(url);
    
    return {
      "description": body["weather"][0]["description"],
      "icon": Image.memory(responseIcon.bodyBytes),
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

  Future<void> loadForever() async {
    while(true){
      Future delay= Future.delayed(Duration(seconds: 10));
      await loadData();
      await delay;
    }
  }

  Future<void> loadData() async {
    Position? pos = await getPosition(context);
    if (pos == null) {
      return;
    }
    print("Got pos $pos");
    Map<String, dynamic> dict = {"position": pos};
    dict.addAll(await fetchWeatherData(pos));
    List<Placemark> placemarks = await placemarkFromCoordinates(
      pos.latitude,
      pos.longitude,
    );
    if (!placemarks.isEmpty) {
      dict["Location"] = placemarks[0];
    }
    dict["time"] = DateTime.now();
    _cachedData.addAll(dict);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    loadForever();
  }

  @override
  Widget build(BuildContext context) {
    if (_cachedData.isEmpty) {
      return CircularProgressIndicator();
    }

    return Text(_cachedData.toString());
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
    return await Future.wait(forcasts.map((e) async {
      String iconName = e["weather"][0]["icon"];
    final url = Uri.parse('https://openweathermap.org/img/wn/$iconName@2x.png');
    final responseIcon = await http.get(url);
      return {
        "time": DateTime.fromMillisecondsSinceEpoch(e["dt"] * 1000),
        "description": e["weather"][0]["description"],
        "icon": Image.memory(responseIcon.bodyBytes),
        "temp": e["main"]["temp"],
      };
    }).toList());
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

  Future<void> loadForever() async {
    while(true){
      Future delay= Future.delayed(Duration(seconds: 10));
      await loadData();
      await delay;
    }
  }

  Future<void> loadData() async {
    Position? pos = await getPosition(context);
    if (pos == null) {
      return;
    }
    print("Got pos $pos");
    Map<String, dynamic> dict = {"position": pos};
    dict["time"] = DateTime.now();
    List<Placemark> placemarks = await placemarkFromCoordinates(
      pos.latitude,
      pos.longitude,
    );
    if (!placemarks.isEmpty) {
      dict["Location"] = placemarks[0];
    }
    dict["forcasts"] = await fetchForcast(pos);
    _cachedData.addAll(dict);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    loadForever();
  }

  @override
  Widget build(BuildContext context) {
    if (_cachedData.isEmpty) {
      return CircularProgressIndicator();
    }

    return Text(_cachedData.toString());
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
    return Text("About");
  }
}
