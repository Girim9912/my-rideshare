import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_functions/cloud_functions.dart';

void requestRide(LatLng pickup, LatLng dropoff) async {
  HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('matchRide');
  final result = await callable.call({
    'pickupLat': pickup.latitude,
    'pickupLong': pickup.longitude,
  });
  print(result.data); // List of drivers
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? mapController;
  LatLng? currentPosition;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  _getLocation() async {
    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      currentPosition = LatLng(position.latitude, position.longitude);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: currentPosition == null
          ? Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(target: currentPosition!, zoom: 14),
              onMapCreated: (controller) => mapController = controller,
            ),
    );
  }
}