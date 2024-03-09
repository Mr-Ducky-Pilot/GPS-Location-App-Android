import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
// import 'dart:convert';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Location Transmitter',
      home: LocationApp(),
    );
  }
}

class LocationApp extends StatefulWidget {
  const LocationApp({Key? key}) : super(key: key);

  @override
  _LocationAppState createState() => _LocationAppState();
}

class _LocationAppState extends State<LocationApp> {
  String _location = "No location data";
  late StreamSubscription<Position> _positionStream;
  Timer? _fallbackTimer;
  bool _isTransmitting = false;
  List<String> _transmissionLog = [];
  String _vehicleId = 'Vehicle ID correspoding to server';
  final String _serverUrl = 'Your IP ADDRESS'; //TODO ADD IP ADDRESS
  IO.Socket? _socket;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _connectToWebSocket();
  }

  @override
  void dispose() {
    _positionStream.cancel();
    _fallbackTimer?.cancel();
    _socket?.disconnect();
    super.dispose();
  }

  void _connectToWebSocket() {
    try {
      _socket = IO.io(_serverUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
      });

      _socket?.onConnect((_) {
        print('Connected!');
        setState(() {});
      });

      _socket?.on('locationUpdated', (data) {
        print('Received from server: $data');
        setState(() {});
      });

      _socket?.onDisconnect((_) => print('Disconnected'));
    } catch (e) {
      print('WebSocket connection error: $e');
    }
  }

  void _getUserLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    ).listen((Position position) {
      setState(() {
        _location =
            "Latitude: ${position.latitude}, Longitude: ${position.longitude}";
        _resetFallbackTimer();
      });

      if (_isTransmitting) {
        if (_socket?.connected == true) {
          _transmitLocation(position);
        }
      }
    });

    _startFallbackTimer();
  }

  void _startFallbackTimer() {
    _fallbackTimer = Timer.periodic(const Duration(seconds: 40), (timer) {
      _getCurrentLocation();
    });
  }

  void _resetFallbackTimer() {
    _fallbackTimer?.cancel();
    _startFallbackTimer();
  }

  void _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _location =
          "Latitude: ${position.latitude}, Longitude: ${position.longitude}";
    });
  }

  void _transmitLocation(Position position) {
    final data = {
      'vehicleId': _vehicleId,
      'lat': position.latitude,
      'lng': position.longitude,
    };
    _socket?.emit('updateLocation', data);
    print('Location Transmitted: $data');
    _transmissionLog.add('Location Transmitted: $data');
  }

  void _toggleTransmission() {
    setState(() {
      _isTransmitting = !_isTransmitting;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Transmitter'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_location),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _getCurrentLocation,
              child: const Text("Get Location"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _toggleTransmission,
              child: Text(
                  _isTransmitting ? 'Stop Transmission' : 'Start Transmission'),
            ),
            const SizedBox(height: 20),
            Text(
                'Connection Status: ${_socket != null ? 'Connected' : 'Disconnected'}'),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _transmissionLog.length,
                itemBuilder: (context, index) {
                  return Text(_transmissionLog[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}




//----------------------Maybe works, maybe doesnt-------------
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'dart:async';
// import 'package:web_socket_channel/io.dart';
// import 'dart:convert';

// void main() => runApp(const MyApp());

// class MyApp extends StatelessWidget {
//   const MyApp({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Location Fetcher',
//       home: LocationApp(),
//     );
//   }
// }

// class LocationApp extends StatefulWidget {
//   const LocationApp({Key? key}) : super(key: key);

//   @override
//   _LocationAppState createState() => _LocationAppState();
// }

// class _LocationAppState extends State<LocationApp> {
//   String _location = "No location data";
//   late StreamSubscription<Position> _positionStream;
//   Timer? _fallbackTimer;
//   late IOWebSocketChannel _channel;
//   bool _isTransmitting = false;
//   List<String> _transmissionLog = [];
//   String _vehicleId = '6969'; // Update with your vehicle ID

//   @override
//   void initState() {
//     super.initState();
//     _getUserLocation();
//     _connectToWebSocket();
//   }

//   @override
//   void dispose() {
//     _positionStream.cancel();
//     _fallbackTimer?.cancel();
//     _channel.sink.close();
//     super.dispose();
//   }

//   void _connectToWebSocket() {
//     _channel = IOWebSocketChannel.connect(Uri.parse('ADD URL')); //TODO ADD URL
//   }

//   void _getUserLocation() async {
//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied ||
//         permission == LocationPermission.deniedForever) {
//       permission = await Geolocator.requestPermission();
//     }

//     _positionStream = Geolocator.getPositionStream(
//       locationSettings: const LocationSettings(
//         accuracy: LocationAccuracy.high,
//       ),
//     ).listen((Position position) {
//       setState(() {
//         _location =
//             "Latitude: ${position.latitude}, Longitude: ${position.longitude}";
//         _resetFallbackTimer();

//         if (_isTransmitting && _channel.sink != null) {
//           final data = {
//             'vehicleId': _vehicleId,
//             'lat': position.latitude,
//             'lng': position.longitude,
//           };
//           _channel.sink.add(jsonEncode(data)); // Send as JSON
//           _transmissionLog.add('Location Transmitted: $data');
//         }
//       });
//     });

//     _startFallbackTimer();
//   }

//   void _startFallbackTimer() {
//     _fallbackTimer = Timer.periodic(const Duration(seconds: 40), (timer) {
//       _getCurrentLocation();
//     });
//   }

//   void _resetFallbackTimer() {
//     _fallbackTimer?.cancel();
//     _startFallbackTimer();
//   }

//   void _getCurrentLocation() async {
//     Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high);
//     setState(() {
//       _location =
//           "Latitude: ${position.latitude}, Longitude: ${position.longitude}";
//     });
//   }

//   void _toggleTransmission() {
//     setState(() {
//       _isTransmitting = !_isTransmitting;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Location Transmitter'),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(_location),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _getCurrentLocation,
//               child: const Text("Get Location"),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _toggleTransmission,
//               child: Text(
//                   _isTransmitting ? 'Stop Transmission' : 'Start Transmission'),
//             ),
//             const SizedBox(height: 20),
//             Text(
//                 'Connection Status: ${_channel.sink == null ? 'Disconnected' : 'Connected'}'),
//             const SizedBox(height: 20),
//             Expanded(
//               child: ListView.builder(
//                 itemCount: _transmissionLog.length,
//                 itemBuilder: (context, index) {
//                   return Text(_transmissionLog[index]);
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }





//Displays user location everytime there is a change in device location or every 40 sec
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'dart:async';

// void main() => runApp(const MyApp());

// class MyApp extends StatelessWidget {
//   const MyApp({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Location Fetcher',
//       home: LocationApp(),
//     );
//   }
// }

// class LocationApp extends StatefulWidget {
//   const LocationApp({Key? key}) : super(key: key);

//   @override
//   _LocationAppState createState() => _LocationAppState();
// }

// class _LocationAppState extends State<LocationApp> {
//   String _location = "No location data";
//   late StreamSubscription<Position> _positionStream;
//   Timer? _fallbackTimer;

//   @override
//   void initState() {
//     super.initState();
//     _getUserLocation();
//   }

//   @override
//   void dispose() {
//     _positionStream.cancel();
//     _fallbackTimer?.cancel();
//     super.dispose();
//   }

//   void _getUserLocation() async {
//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied ||
//         permission == LocationPermission.deniedForever) {
//       permission = await Geolocator.requestPermission();
//     }

//     _positionStream = Geolocator.getPositionStream(
//       locationSettings: const LocationSettings(
//         accuracy: LocationAccuracy.high,
//       ),
//     ).listen((Position position) {
//       setState(() {
//         _location =
//             "Latitude: ${position.latitude}, Longitude: ${position.longitude}";
//         _resetFallbackTimer(); // Reset timer on location update
//       });
//     });

//     _startFallbackTimer();
//   }

//   void _startFallbackTimer() {
//     _fallbackTimer = Timer.periodic(const Duration(seconds: 40), (timer) {
//       _getCurrentLocation(); // Fetch location if no update in 40 seconds
//     });
//   }

//   void _resetFallbackTimer() {
//     _fallbackTimer?.cancel();
//     _startFallbackTimer();
//   }

//   void _getCurrentLocation() async {
//     Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high);
//     setState(() {
//       _location =
//           "Latitude: ${position.latitude}, Longitude: ${position.longitude}";
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Location Fetcher'),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(_location),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _getCurrentLocation,
//               child: const Text("Get Location"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


//Shows user device location in app

// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';

// void main() => runApp(const MyApp());

// class MyApp extends StatelessWidget {
//   const MyApp({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Location Fetcher',
//       home: LocationApp(),
//     );
//   }
// }

// class LocationApp extends StatefulWidget {
//   const LocationApp({Key? key}) : super(key: key);

//   @override
//   _LocationAppState createState() => _LocationAppState();
// }

// class _LocationAppState extends State<LocationApp> {
//   String _location = "No location data";

//   Future<void> _getCurrentLocation() async {
//     // Check permissions
//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied ||
//         permission == LocationPermission.deniedForever) {
//       permission = await Geolocator.requestPermission();
//     }

//     // Get location with high accuracy
//     Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high);

//     setState(() {
//       _location =
//           "Latitude: ${position.latitude}, Longitude: ${position.longitude}";
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Location Fetcher'),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(_location),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _getCurrentLocation,
//               child: const Text("Get Location"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
