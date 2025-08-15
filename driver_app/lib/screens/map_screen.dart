import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/services/maps_service.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  bool _isLoading = true;
  bool _isOnline = false;
  String? _acceptedRideId;
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
      _isLoading = false;
    });

    // Update driver location in Firestore
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'location': GeoPoint(position.latitude, position.longitude),
        'online': _isOnline,
      });
    }
  }

  Future<void> _toggleOnlineStatus(bool newValue) async {
    setState(() {
      _isOnline = newValue;
    });
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'online': _isOnline,
      });
    }
  }

  Future<void> _acceptRide(String rideId, Map<String, dynamic> rideData) async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await FirebaseFirestore.instance.collection('rides').doc(rideId).update({
        'driverId': userId,
        'status': 'accepted',
      });
      setState(() {
        _acceptedRideId = rideId;
        _rideDetails = rideData;
      });
      // Get distance and ETA
      if (_rideDetails != null) {
        final pickup = _rideDetails!['pickup'] as GeoPoint;
        final dropoff = _rideDetails!['dropoff'] as GeoPoint;
        final distanceData = await MapsService().getDistanceAndTime(
          LatLng(pickup.latitude, pickup.longitude),
          LatLng(dropoff.latitude, dropoff.longitude),
        );
        setState(() {
          _rideDetails!['distance'] = distanceData['distance'];
          _rideDetails!['duration'] = distanceData['duration'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Driver Map'),
        actions: [
          Switch(
            value: _isOnline,
            onChanged: _toggleOnlineStatus,
            activeColor: Colors.green,
          ),
        ],
      ),
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
                      if (_currentPosition != null)
                        Marker(
                          markerId: MarkerId('current_location'),
                          position: _currentPosition!,
                          infoWindow: InfoWindow(title: 'You are here'),
                        ),
                      if (_rideDetails != null)
                        Marker(
                          markerId: MarkerId('pickup'),
                          position: LatLng(
                            _rideDetails!['pickup'].latitude,
                            _rideDetails!['pickup'].longitude,
                          ),
                          infoWindow: InfoWindow(title: 'Pickup'),
                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                        ),
                      if (_rideDetails != null)
                        Marker(
                          markerId: MarkerId('dropoff'),
                          position: LatLng(
                            _rideDetails!['dropoff'].latitude,
                            _rideDetails!['dropoff'].longitude,
                          ),
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
                if (_isOnline && _acceptedRideId == null)
                  Expanded(
                    child: StreamBuilder(
                      stream: FirebaseFirestore.instance
                          .collection('rides')
                          .where('status', isEqualTo: 'requested')
                          .snapshots(),
                      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                        return ListView(
                          children: snapshot.data!.docs.map((doc) {
                            var rideData = doc.data() as Map<String, dynamic>;
                            return ListTile(
                              title: Text('Ride Request'),
                              subtitle: Text(
                                'Pickup: ${rideData['pickup'].latitude}, ${rideData['pickup'].longitude}',
                              ),
                              trailing: ElevatedButton(
                                onPressed: () => _acceptRide(doc.id, rideData),
                                child: Text('Accept'),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
              ],
            ),
    );
  }
}