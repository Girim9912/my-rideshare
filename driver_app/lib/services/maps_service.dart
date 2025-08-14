import 'package:http/http.dart' as http;
     import 'dart:convert';

     class MapsService {
       static const String _apiKey = 'AIzaSyC-Nqv0mM_AcD6i7QmXtY18D7h0D5QaZF0'; // Replace with your key
       static const String _baseUrl = 'https://maps.googleapis.com/maps/api/distancematrix/json';

       Future<Map<String, dynamic>> getDistanceAndTime(LatLng origin, LatLng destination) async {
         final url = '$_baseUrl?origins=${origin.latitude},${origin.longitude}&destinations=${destination.latitude},${destination.longitude}&key=$_apiKey';
         final response = await http.get(Uri.parse(url));
         if (response.statusCode == 200) {
           final data = jsonDecode(response.body);
           return {
             'distance': data['rows'][0]['elements'][0]['distance']['text'],
             'duration': data['rows'][0]['elements'][0]['duration']['text'],
           };
         } else {
           throw Exception('Failed to fetch distance');
         }
       }
     }