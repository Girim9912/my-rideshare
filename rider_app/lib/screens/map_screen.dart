import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rider_app/services/maps_service.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  LatLng? _pickupPosition;
  LatLng? _dropoffPosition;
  bool _isLoading = true;
  String? _rideId;
  Map<String, dynamic>? _rideDetails;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndGetLocation();
  }

  Future<void> _checkPermissionsAndGetLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enable location services')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location permissions denied')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location permissions permanently denied')),
      );
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _pickupPosition = _currentPosition; // Default pickup
      _dropoffPosition = LatLng(
        position.latitude + 0.01,
        position.longitude + 0.01,
      ); // Default dropoff (offset for testing)
      _isLoading = false;
    });

    // Update user location in Firestore
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'location': GeoPoint(position.latitude, position.longitude),
      });
    }

    // Listen for ride status updates
    if (userId != null) {
      FirebaseFirestore.instance
          .collection('rides')
          .where('riderId', isEqualTo: userId)
          .where('status', isEqualTo: 'accepted')
          .snapshots()
          .listen((snapshot) async {
        if (snapshot.docs.isNotEmpty) {
          var ride = snapshot.docs.first;
          setState(() {
            _rideId = ride.id;
            _rideDetails = ride.data();
          });
          // Get distance and ETA
          if (_pickupPosition != null && _dropoffPosition != null) {
            final distanceData = await MapsService().getDistanceAndTime(
              _pickupPosition!,
              _dropoffPosition!,
            );
            setState(() {
              _rideDetails!['distance'] = distanceData['distance'];
              _rideDetails!['duration'] = distanceData['duration'];
            });
          }
        }
      });
    }
  }

  Future<void> _requestRide() async {
    if (_pickupPosition == null || _dropoffPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select pickup and dropoff locations')),
      );
      return;
    }

    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      var rideRef = await FirebaseFirestore.instance.collection('rides').add({
        'riderId': userId,
        'pickup': GeoPoint(_pickupPosition!.latitude, _pickupPosition!.longitude),
        'dropoff': GeoPoint(_dropoffPosition!.latitude, _dropoffPosition!.longitude),
        'status': 'requested',
        'startTime': FieldValue.serverTimestamp(),
      });
      setState(() {
        _rideId = rideRef.id;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ride requested')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Rider Map')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _currentPosition ?? LatLng(0, 0),
                      zoom: 14,
                    ),
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                    markers: {
                      if (_pickupPosition != null)
                        Marker(
                          markerId: MarkerId('pickup'),
                          position: _pickupPosition!,
                          infoWindow: InfoWindow(title: 'Pickup'),
                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                        ),
                      if (_dropoffPosition != null)
                        Marker(
                          markerId: MarkerId('dropoff'),
                          position: _dropoffPosition!,
                          infoWindow: InfoWindow(title: 'Dropoff'),
                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                        ),
                    },
                  ),
                ),
                if (_rideDetails != null)
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Ride Accepted! Distance: ${_rideDetails!['distance'] ?? 'N/A'}, ETA: ${_rideDetails!['duration'] ?? 'N/A'}',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
              ],
            ),
      floatingActionButton: _rideId == null
          ? FloatingActionButton(
              onPressed: _requestRide,
              child: Icon(Icons.directions_car),
              tooltip: 'Request Ride',
            )
          : null,
    );
  }
}