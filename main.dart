import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:sensors_plus/sensors_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:noise_meter/noise_meter.dart';

void main() {
  runApp(const WomenSafetyApp());
}

class WomenSafetyApp extends StatelessWidget {
  const WomenSafetyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}

////////////////////////////////////////////////////////////
/// SPLASH SCREEN
////////////////////////////////////////////////////////////

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MenuScreen()),
          );
        },
        child: SizedBox.expand(
          child: Image.asset(
            "assets/images/screen1.jpeg",
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// MENU SCREEN
////////////////////////////////////////////////////////////

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset(
              "assets/images/screen2.jpeg",
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            bottom: 120,
            left: 30,
            right: 30,
            child: Column(
              children: [
                buildButton(context, "SheShield Navigator", () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SafeRouteScreen()));
                }),
                const SizedBox(height: 20),
                buildButton(context, "SafeTrigger", () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const TriggerScreen()));
                }),
                const SizedBox(height: 20),
                buildButton(context, "HomeSure", () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const HomeSureScreen()));
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildButton(BuildContext context, String text, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      onPressed: onPressed,
      child: SizedBox(
        width: double.infinity,
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// SAFE ROUTE SCREEN
////////////////////////////////////////////////////////////

class SafeRouteScreen extends StatefulWidget {
  const SafeRouteScreen({super.key});

  @override
  State<SafeRouteScreen> createState() => _SafeRouteScreenState();
}

class _SafeRouteScreenState extends State<SafeRouteScreen> {
  LatLng? currentPosition;
  LatLng? destination;

  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  List<List<LatLng>> allRoutes = [];
  List<double> routeScores = [];
  int safestRouteIndex = -1;

  List<LatLng> cctvPoints = [];

  @override
  void initState() {
    super.initState();
    initializeSystem();
  }

  Future<void> initializeSystem() async {
    await Permission.location.request();
    await loadCCTVData();
    await getLocation();
  }

  Future<void> loadCCTVData() async {
    final response = await rootBundle.loadString('assets/cctv_data.json');
    final List<dynamic> data = json.decode(response);

    setState(() {
      cctvPoints =
          data.map((item) => LatLng(item['lat'], item['lon'])).toList();
    });
  }

  Future<void> getLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      currentPosition = LatLng(position.latitude, position.longitude);
    });
  }

  Future<void> searchLocation(String query) async {
    if (query.isEmpty) return;

    final url = Uri.parse(
        "https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1");

    final response =
        await http.get(url, headers: {"User-Agent": "women_safety_app"});

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data.isNotEmpty) {
        double lat = double.parse(data[0]["lat"]);
        double lon = double.parse(data[0]["lon"]);

        setState(() {
          destination = LatLng(lat, lon);
        });

        _mapController.move(destination!, 13);
        await getRoutes();
      }
    }
  }

  Future<void> getRoutes() async {
    if (currentPosition == null || destination == null) return;

    final url = Uri.parse(
        "https://router.project-osrm.org/route/v1/driving/"
        "${currentPosition!.longitude},${currentPosition!.latitude};"
        "${destination!.longitude},${destination!.latitude}"
        "?alternatives=true&overview=full&geometries=geojson");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      List<List<LatLng>> tempRoutes = [];
      List<double> tempScores = [];

      for (var route in data['routes']) {
        final coords = route['geometry']['coordinates'];
        List<LatLng> points = [];

        for (var coord in coords) {
          points.add(LatLng(coord[1], coord[0]));
        }

        tempRoutes.add(points);
        tempScores.add(calculateSafetyScore(points));
      }

      double maxScore = tempScores.reduce((a, b) => a > b ? a : b);
      double minScore = tempScores.reduce((a, b) => a < b ? a : b);

      List<double> normalized = tempScores.map((score) {
        if (maxScore == minScore) return 1.0;
        return (score - minScore) / (maxScore - minScore);
      }).toList();

      int safest = 0;
      for (int i = 1; i < normalized.length; i++) {
        if (normalized[i] > normalized[safest]) safest = i;
      }

      setState(() {
        allRoutes = tempRoutes;
        routeScores = normalized;
        safestRouteIndex = safest;
      });
    }
  }

  double calculateSafetyScore(List<LatLng> route) {
    double score = 0;
    final distance = Distance();

    for (var point in route) {
      for (var cam in cctvPoints) {
        double meters = distance.as(LengthUnit.Meter, point, cam);
        if (meters < 500) score += 1;
      }
    }
    return score;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("SheShield Navigator")),
      body: currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: "Enter destination",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          searchLocation(_searchController.text);
                        },
                        child: const Text("Search"),
                      ),
                    ],
                  ),
                ),
                if (routeScores.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int i = 0; i < routeScores.length; i++)
                          Text(
                            i == safestRouteIndex
                                ? "Route ${i + 1} (Safest): ${routeScores[i].toStringAsFixed(2)}"
                                : "Route ${i + 1} (Unsafe): ${routeScores[i].toStringAsFixed(2)}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: i == safestRouteIndex
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                      ],
                    ),
                  ),
                Expanded(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      center: currentPosition!,
                      zoom: 13,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName:
                            'com.example.women_safety',
                      ),
                      PolylineLayer(
                        polylines: [
                          for (int i = 0; i < allRoutes.length; i++)
                            Polyline(
                              points: allRoutes[i],
                              strokeWidth: 5,
                              color: i == safestRouteIndex
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: currentPosition!,
                            width: 40,
                            height: 40,
                            builder: (ctx) => const Icon(
                              Icons.my_location,
                              color: Colors.blue,
                              size: 40,
                            ),
                          ),
                          if (destination != null)
                            Marker(
                              point: destination!,
                              width: 50,
                              height: 50,
                              builder: (ctx) => const Icon(
                                Icons.flag,
                                color: Colors.red,
                                size: 45,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

////////////////////////////////////////////////////////////
/// SAFE TRIGGER SCREEN (UNCHANGED)
////////////////////////////////////////////////////////////

class TriggerScreen extends StatefulWidget {
  const TriggerScreen({super.key});

  @override
  State<TriggerScreen> createState() => _TriggerScreenState();
}

class _TriggerScreenState extends State<TriggerScreen> {
  StreamSubscription? _accelerometerSubscription;
  NoiseMeter? _noiseMeter;
  StreamSubscription<NoiseReading>? _noiseSubscription;

  double shakeThreshold = 18.0;
  double screamThreshold = 85.0;

  bool isSOSActive = false;
  bool screamCooldown = false;

  @override
  void initState() {
    super.initState();
    startDetection();
  }

  Future<void> startDetection() async {
    await Permission.microphone.request();
    startShakeDetection();
    startScreamDetection();
  }

  void startShakeDetection() {
    _accelerometerSubscription =
        accelerometerEvents.listen((event) {
      double acceleration =
          (event.x * event.x +
              event.y * event.y +
              event.z * event.z);

      if (acceleration >
          shakeThreshold * shakeThreshold) {
        triggerSOS("Shake Detected");
      }
    });
  }

  void startScreamDetection() {
    _noiseMeter = NoiseMeter();
    _noiseSubscription =
        _noiseMeter!.noise.listen((reading) {
      double decibel = reading.meanDecibel;

      if (!screamCooldown &&
          !isSOSActive &&
          decibel > screamThreshold) {
        screamCooldown = true;
        triggerSOS("Scream Detected");

        Future.delayed(const Duration(seconds: 10), () {
          screamCooldown = false;
        });
      }
    });
  }

  void triggerSOS(String reason) {
    if (isSOSActive) return;
    isSOSActive = true;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("🚨 SOS Triggered"),
        content:
            Text("Emergency Alert Activated\nReason: $reason"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              isSOSActive = false;
            },
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _noiseSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("SafeTrigger")),
      body: const Center(
        child: Text("Shake or Scream to Trigger SOS"),
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// HOMESURE SCREEN (NEW IMPLEMENTATION)
////////////////////////////////////////////////////////////

class HomeSureScreen extends StatefulWidget {
  const HomeSureScreen({super.key});

  @override
  State<HomeSureScreen> createState() => _HomeSureScreenState();
}

class _HomeSureScreenState extends State<HomeSureScreen> {
  TimeOfDay? selectedTime;
  Duration remaining = const Duration();
  Timer? countdownTimer;
  Timer? responseTimer;

  bool monitoringStarted = false;
  bool waitingForConfirmation = false;
  bool isSafe = false;
  bool isAlert = false;

  Future<void> pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        selectedTime = time;
      });
    }
  }

  void startMonitoring() {
    if (selectedTime == null) return;

    final now = DateTime.now();
    final arrival = DateTime(
      now.year,
      now.month,
      now.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    remaining = arrival.difference(now);

    if (remaining.isNegative) {
      remaining = const Duration(seconds: 5);
    }

    monitoringStarted = true;

    countdownTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remaining.inSeconds <= 0) {
        timer.cancel();
        showConfirmation();
      } else {
        setState(() {
          remaining -= const Duration(seconds: 1);
        });
      }
    });

    setState(() {});
  }

  void showConfirmation() {
    setState(() {
      waitingForConfirmation = true;
    });

    responseTimer = Timer(const Duration(seconds: 10), () {
      if (!isSafe) {
        setState(() {
          isAlert = true;
          waitingForConfirmation = false;
        });
      }
    });
  }

  void confirmArrival() {
    responseTimer?.cancel();
    setState(() {
      isSafe = true;
      waitingForConfirmation = false;
    });
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    responseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("HomeSure")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            if (!monitoringStarted && !isSafe && !isAlert) ...[
              ElevatedButton(
                onPressed: pickTime,
                child: const Text("Select Arrival Time"),
              ),
              const SizedBox(height: 10),
              if (selectedTime != null)
                Text("Selected: ${selectedTime!.format(context)}"),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: startMonitoring,
                child: const Text("Start Monitoring"),
              ),
            ],

            if (monitoringStarted &&
                !waitingForConfirmation &&
                !isSafe &&
                !isAlert) ...[
              const Text(
                "Monitoring Journey...",
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              Text(
                "${remaining.inMinutes.remainder(60).toString().padLeft(2, '0')}:"
                "${remaining.inSeconds.remainder(60).toString().padLeft(2, '0')}",
                style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold),
              ),
            ],

            if (waitingForConfirmation) ...[
              const Text(
                "Confirm Arrival",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: confirmArrival,
                child: const Text("Confirm (Fingerprint Simulated)"),
              ),
              const SizedBox(height: 10),
              const Text("Auto alert in 10 seconds if no response"),
            ],

            if (isSafe) ...[
              const Icon(Icons.check_circle,
                  color: Colors.green, size: 80),
              const SizedBox(height: 20),
              const Text(
                "Arrival Confirmed\nGuardian Notified",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            ],

            if (isAlert) ...[
              const Icon(Icons.warning,
                  color: Colors.red, size: 80),
              const SizedBox(height: 20),
              const Text(
                "No Response Detected\nAlert Sent to Guardian",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            ],
          ],
        ),
      ),
    );
  }
}