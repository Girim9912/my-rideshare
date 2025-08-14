import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'maps_service.dart'; // Add this import for MapsService

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  bool _isLoading = true;

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

    // Update user location in Firestore
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'online': true,
        'location': GeoPoint(position.latitude, position.longitude),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Driver Map')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition ?? LatLng(0, 0),
                    zoom: 14,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  markers: _currentPosition != null
                      ? {
                          Marker(
                            markerId: MarkerId('current_location'),
                            position: _currentPosition!,
                            infoWindow: InfoWindow(title: 'You are here'),
                          ),
                        }
                      : {},
                ),
                // Bottom sheet for ride requests
                DraggableScrollableSheet(
                  initialChildSize: 0.3,
                  minChildSize: 0.1,
                  maxChildSize: 0.7,
                  builder: (context, scrollController) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            margin: EdgeInsets.symmetric(vertical: 8),
                            height: 4,
                            width: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text(
                              'Ride Requests',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('rides')
                                  .where('status', isEqualTo: 'requested')
                                  .snapshots(),
                              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                                if (!snapshot.hasData) {
                                  return Center(child: CircularProgressIndicator());
                                }
                                
                                if (snapshot.data!.docs.isEmpty) {
                                  return Center(
                                    child: Text(
                                      'No ride requests available',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  );
                                }
                                
                                return ListView.builder(
                                  controller: scrollController,
                                  itemCount: snapshot.data!.docs.length,
                                  itemBuilder: (context, index) {
                                    var doc = snapshot.data!.docs[index];
                                    var pickup = doc['pickup'] as GeoPoint;
                                    var dropoff = doc['dropoff'] as GeoPoint;
                                    
                                    return Card(
                                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      child: ListTile(
                                        leading: Icon(Icons.directions_car, color: Colors.blue),
                                        title: Text('Ride Request'),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Pickup: ${pickup.latitude.toStringAsFixed(4)}, ${pickup.longitude.toStringAsFixed(4)}'),
                                            Text('Dropoff: ${dropoff.latitude.toStringAsFixed(4)}, ${dropoff.longitude.toStringAsFixed(4)}'),
                                          ],
                                        ),
                                        trailing: ElevatedButton(
                                          onPressed: () async {
                                            try {
                                              await FirebaseFirestore.instance
                                                  .collection('rides')
                                                  .doc(doc.id)
                                                  .update({
                                                'driverId': FirebaseAuth.instance.currentUser?.uid,
                                                'status': 'accepted',
                                                'acceptedTime': FieldValue.serverTimestamp(),
                                              });
                                              
                                              // Calculate ETA after accepting ride
                                              final pickup = doc['pickup'] as GeoPoint;
                                              final dropoff = doc['dropoff'] as GeoPoint;
                                              
                                              try {
                                                final distanceData = await MapsService().getDistanceAndTime(
                                                  LatLng(pickup.latitude, pickup.longitude),
                                                  LatLng(dropoff.latitude, dropoff.longitude),
                                                );
                                                print('Distance: ${distanceData['distance']}, ETA: ${distanceData['duration']}');
                                                
                                                // Update ride document with ETA information
                                                await FirebaseFirestore.instance
                                                    .collection('rides')
                                                    .doc(doc.id)
                                                    .update({
                                                  'estimatedDistance': distanceData['distance'],
                                                  'estimatedDuration': distanceData['duration'],
                                                });
                                                
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Ride accepted! ETA: ${distanceData['duration']}'),
                                                    duration: Duration(seconds: 4),
                                                  ),
                                                );
                                              } catch (etaError) {
                                                print('Error calculating ETA: $etaError');
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Ride accepted! (ETA calculation failed)')),
                                                );
                                              }
                                            } catch (e) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Error accepting ride: $e')),
                                              );
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: Text('Accept'),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }
}