import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isOnline = false;
  DocumentSnapshot? _rideRequest;

  @override
  void initState() {
    super.initState();
    _listenForRideRequests();
  }

  Future<void> _toggleOnline() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    if (!_isOnline) {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'online': true,
        'location': GeoPoint(position.latitude, position.longitude),
      });
    } else {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'online': false,
        'location': null,
      });
    }
    setState(() {
      _isOnline = !_isOnline;
    });
  }

  void _listenForRideRequests() {
    FirebaseFirestore.instance
        .collection('rides')
        .where('status', isEqualTo: 'requested')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _rideRequest = snapshot.docs.first;
        });
      } else {
        setState(() {
          _rideRequest = null;
        });
      }
    });
  }

  Future<void> _acceptRide(String rideId) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('rides').doc(rideId).update({
      'driverId': userId,
      'status': 'accepted',
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ride accepted')));
    setState(() {
      _rideRequest = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Driver Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_isOnline ? 'You are online' : 'You are offline'),
            ElevatedButton(
              onPressed: _toggleOnline,
              child: Text(_isOnline ? 'Go Offline' : 'Go Online'),
            ),
            if (_rideRequest != null)
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text('New Ride Request!'),
                    ElevatedButton(
                      onPressed: () => _acceptRide(_rideRequest!.id),
                      child: Text('Accept Ride'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}