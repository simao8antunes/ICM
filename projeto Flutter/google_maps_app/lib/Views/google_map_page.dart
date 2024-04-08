import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_map_app/Views/gallery.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';
import 'package:sensors/sensors.dart';

class GoogleMapPage extends StatefulWidget {
  final String username;
  const GoogleMapPage({Key? key, required this.username}) : super(key: key);

  @override
  State<GoogleMapPage> createState() => GoogleMapPageState();
}

class GoogleMapPageState extends State<GoogleMapPage> {
  Map<LatLng, String> images = {}; // Map to store images and their locations
  final Completer<GoogleMapController> _controller = Completer();
  List<LatLng> polylineCoordinates = [];
  LocationData? currentPosition;

  BitmapDescriptor sourceIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor poiIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);

  @override
  void initState() {
    super.initState();
    loadCustomMarkerIcon();
    getCurrentLocationAndDrawPolyline();
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  StreamSubscription<LocationData>? _locationSubscription;

  Future<void> getCurrentLocation() async {
    Location location = Location();
    currentPosition = await location.getLocation();

    _locationSubscription = location.onLocationChanged.listen((newLoc) {
      currentPosition = newLoc;
      if (mounted) {
        setState(() {});
      }
    });
  }

  // Method to handle selecting a point of interest and generating polyline
  Future<void> selectPointOfInterest(LatLng pointOfInterest) async {
    // Clear existing polyline coordinates
    setState(() {
      polylineCoordinates.clear();
    });

    // Get polyline points between current location and selected point of interest
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      "AIzaSyCLQtvRikSwF0GP5j_Pl2kbVOeCf7syky0",
      PointLatLng(currentPosition!.latitude!, currentPosition!.longitude!),
      PointLatLng(pointOfInterest.latitude, pointOfInterest.longitude),
      travelMode: TravelMode.walking,
    );

    // If polyline points are available, update polylineCoordinates list
    if (result.points.isNotEmpty) {
      setState(() {
        polylineCoordinates = result.points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();
      });
    }
  }

  Future<void> getPolyPoints() async {
    if (currentPosition == null) return;

    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      "AIzaSyCLQtvRikSwF0GP5j_Pl2kbVOeCf7syky0",
      PointLatLng(currentPosition!.latitude!, currentPosition!.longitude!),
      PointLatLng(currentPosition!.latitude!, currentPosition!.longitude!),
    );

    if (result.points.isNotEmpty) {
      polylineCoordinates = result.points
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();
    }
  }

  void loadCustomMarkerIcon() async {
    final Uint8List markerIcon =
        await getBytesFromAsset('lib/files/Icon-192.png', 100);
    sourceIcon = BitmapDescriptor.fromBytes(markerIcon);
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  Future<void> getCurrentLocationAndDrawPolyline() async {
    await getCurrentLocation();
    await getPolyPoints();
    await searchNearbyPlaces();
    setState(() {});
  }

  void updateCameraPosition(double latitude, double longitude) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        target: LatLng(latitude, longitude),
        zoom: 18,
      ),
    ));
  }

  Future<void> searchNearbyPlaces() async {
    if (currentPosition == null) return;

    final apiKey = 'AIzaSyCLQtvRikSwF0GP5j_Pl2kbVOeCf7syky0';
    final radius = 1000; // in meters
    final url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${currentPosition!.latitude},${currentPosition!.longitude}&radius=$radius&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);
    final results = data['results'];

    // Process the results and display on the map
    if (results != null && results.isNotEmpty) {
      for (final result in results) {
        final location = result['geometry']['location'];
        final lat = location['lat'];
        final lng = location['lng'];
        final name = result['name'];

        setState(() {
          nearbyPlacesMarkers.add(
            Marker(
              markerId: MarkerId(name),
              icon: poiIcon,
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(title: name),
            ),
          );
        });
      }
    }
  }

  Set<Marker> nearbyPlacesMarkers = {};

  Future<void> _openCamera() async {
    final ImagePicker _picker = ImagePicker();
    final imageFile = await _picker.pickImage(source: ImageSource.camera);

    if (imageFile != null) {
      // Get current location
      Location location = Location();
      LocationData? currentLocation = await location.getLocation();

      // Update UI
      setState(() {
        // Add a green marker where the picture was taken
        images[LatLng(currentLocation.latitude!, currentLocation.longitude!)] =
            imageFile.path;
      });
    }
  }

  Widget _registerButton() {
    return ElevatedButton(
      onPressed: () {
        _showRegisterOptions(context);
      },
      child: Text('Register'),
    );
  }

  void _showRegisterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Options',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera),
              title: const Text('Photo It'),
              onTap: () {
                Navigator.pop(context);
                _openCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.vibration),
              title: const Text('Shake It'),
              onTap: () {
                Navigator.pop(context);
                _startShakeDetection();
              },
            ),
          ],
        );
      },
    );
  }

  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  Timer? _shakeTimer;
  bool _isShaking = false;

  void _startShakeDetection() {
    _gyroscopeSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
      // Check the event to detect significant shaking
      if (event.x.abs() > 1.5 ||
          event.y.abs() > 1.5 ||
          event.z.abs() > 1.5) {
        if (!_isShaking) {
          _isShaking = true;
          _shakeTimer = Timer(Duration(milliseconds: 500), () {
            // Complete task after shake detection
            print("Task completed by shaking!");
            _resetShakeDetection();
            Navigator.of(context).pop();
          });
        }
      } else {
        // Stop detecting shaking and reset timer if movement stops
        _resetShakeDetection();
      }
    });
  }

  void _resetShakeDetection() {
    _isShaking = false;
    _shakeTimer?.cancel();
  }

  @override
  void dispose() {
    _gyroscopeSubscription?.cancel();
    _shakeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "RoamRight",
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.add_location),
            onPressed: () => _showRegisterOptions(context),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GalleryPage(images: images,),
                ),
              );
            },
            child: Text('Open Gallery'),
          ),
        ],
      ),
      body: currentPosition == null
          ? const Center(child: Text("Loading"))
          : GestureDetector(
              onDoubleTap: () {
                // Update camera position on double tap
                updateCameraPosition(
                    currentPosition!.latitude!, currentPosition!.longitude!);
              },
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                      currentPosition!.latitude!, currentPosition!.longitude!),
                  zoom: 18,
                ),
                polylines: {
                  Polyline(
                    polylineId: PolylineId("route"),
                    points: polylineCoordinates,
                    width: 6,
                    color: Colors.blue,
                  ),
                },
                markers: {
                  ...nearbyPlacesMarkers,
                  ...images.entries.map((entry) {
                    return Marker(
                      markerId: MarkerId(entry.key.toString()),
                      position: entry.key,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueGreen),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            content: Image.file(File(entry.value)),
                            actions: [
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text('Close'),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }).toSet(),
                  Marker(
                    markerId: const MarkerId("currentLocation"),
                    icon: sourceIcon,
                    position: LatLng(currentPosition!.latitude!,
                        currentPosition!.longitude!),
                  ),
                },
                onTap: (LatLng point) {
                  // Handle tap on the map
                  selectPointOfInterest(point);
                },
                onMapCreated: (mapController) {
                  _controller.complete(mapController);
                },
              ),
            ),
    );
  }
}



void main() {
  runApp(MaterialApp(
    home: GoogleMapPage(username: 'YourUsername'),
  ));
}
