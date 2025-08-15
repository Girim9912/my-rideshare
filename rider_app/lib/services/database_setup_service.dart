// Create this file: lib/services/database_setup_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseSetupService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Call this method ONCE to initialize all Firestore collections with sample data
  /// This will create the proper structure for your rideshare app
  static Future<void> initializeDatabase() async {
    try {
      print('🔄 Initializing Firestore database...');

      // 1. Create USERS collection with sample rider
      await _createSampleRider();
      
      // 2. Create USERS collection with sample driver
      await _createSampleDriver();
      
      // 3. Create RIDES collection with sample ride
      await _createSampleRide();
      
      // 4. Create DRIVER VERIFICATIONS collection
      await _createSampleDriverVerification();

      // 5. Create RIDE HISTORY collection
      await _createSampleRideHistory();

      // 6. Create NOTIFICATIONS collection
      await _createSampleNotification();

      print('✅ Database initialized successfully!');
      print('📱 You can now check Firebase Console to see all collections');
      
    } catch (e) {
      print('❌ Error initializing database: $e');
    }
  }

  // Create sample rider user
  static Future<void> _createSampleRider() async {
    await _firestore.collection('users').doc('rider_sample_123').set({
      // Basic Info
      'userId': 'rider_sample_123',
      'role': 'rider',
      'name': 'John Doe',
      'email': 'john.rider@example.com',
      'phone': '+1234567890',
      'profileImageUrl': '',
      
      // Location (NYC coordinates)
      'location': GeoPoint(40.7128, -74.0060),
      'address': '123 Main St, New York, NY 10001',
      
      // Preferences for matching
      'preferences': {
        'genderPreference': 'any', // 'male', 'female', 'any'
        'religionPreference': 'any', // 'same', 'any'
        'languagePreference': 'English',
      },
      
      // Personal details (for matching features)
      'gender': 'male',
      'religion': 'Christian',
      'age': 28,
      
      // Family/Network features
      'familyNetwork': [], // Array of user IDs for trusted network
      'emergencyContacts': [
        {
          'name': 'Jane Doe',
          'phone': '+1234567891',
          'relationship': 'spouse'
        }
      ],
      
      // App status
      'isActive': true,
      'isVerified': true,
      'lastSeen': FieldValue.serverTimestamp(),
      
      // Ratings
      'rating': 4.8,
      'totalRides': 25,
      'totalRatings': 23,
      
      // Timestamps
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    print('✅ Sample rider created');
  }

  // Create sample driver user
  static Future<void> _createSampleDriver() async {
    await _firestore.collection('users').doc('driver_sample_456').set({
      // Basic Info
      'userId': 'driver_sample_456',
      'role': 'driver',
      'name': 'Sarah Smith',
      'email': 'sarah.driver@example.com',
      'phone': '+0987654321',
      'profileImageUrl': '',
      
      // Location (NYC coordinates)
      'location': GeoPoint(40.7589, -73.9851),
      'address': '456 Broadway, New York, NY 10013',
      
      // Driver-specific fields
      'isOnline': true,
      'isAvailable': true,
      'currentRideId': null,
      
      // Vehicle info
      'vehicle': {
        'make': 'Toyota',
        'model': 'Camry',
        'year': 2020,
        'color': 'Blue',
        'plateNumber': 'NYC123',
        'seats': 4,
      },
      
      // Driver preferences
      'preferences': {
        'maxDistance': 15, // km radius for accepting rides
        'acceptCash': true,
        'acceptCard': true,
      },
      
      // Personal details
      'gender': 'female',
      'religion': 'Muslim',
      'age': 32,
      'languages': ['English', 'Spanish'],
      
      // Verification status
      'isVerified': true,
      'verificationStatus': 'approved',
      'documentsSubmitted': true,
      
      // Ratings and earnings
      'rating': 4.9,
      'totalRides': 150,
      'totalRatings': 148,
      'totalEarnings': 2450.75,
      'weeklyEarnings': 380.50,
      
      // Activity tracking
      'hoursOnline': 35.5,
      'lastRideCompleted': FieldValue.serverTimestamp(),
      
      // Timestamps
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    print('✅ Sample driver created');
  }

  // Create sample ride request
  static Future<void> _createSampleRide() async {
    await _firestore.collection('rides').doc('ride_sample_789').set({
      // Ride identification
      'rideId': 'ride_sample_789',
      'riderId': 'rider_sample_123',
      'driverId': null, // Will be assigned when driver accepts
      
      // Location details
      'pickup': {
        'location': GeoPoint(40.7128, -74.0060),
        'address': '123 Main St, New York, NY 10001',
        'landmark': 'Near Starbucks',
      },
      'dropoff': {
        'location': GeoPoint(40.7589, -73.9851),
        'address': '456 Broadway, New York, NY 10013',
        'landmark': 'Times Square',
      },
      
      // Ride status and timing
      'status': 'requested', // requested, accepted, in-progress, completed, cancelled
      'timestamps': {
        'requested': FieldValue.serverTimestamp(),
        'accepted': null,
        'driverArrived': null,
        'rideStarted': null,
        'rideCompleted': null,
      },
      
      // Trip details
      'distance': '2.5 km',
      'estimatedDuration': '12 mins',
      'estimatedFare': 15.50,
      'actualFare': null,
      'paymentMethod': 'card',
      
      // Ride preferences
      'preferences': {
        'genderPreference': 'female',
        'religionPreference': 'any',
        'carType': 'standard', // economy, standard, premium
        'notes': 'Please call when you arrive',
      },
      
      // Additional info
      'passengers': 1,
      'scheduledFor': null, // For future rides
      'promoCode': null,
      'discount': 0,
      
      // Real-time tracking
      'driverLocation': null, // Will be updated during ride
      'route': [], // Array of coordinates for route tracking
      
      // Ratings (filled after ride completion)
      'riderRating': null,
      'driverRating': null,
      'feedback': '',
      
      // Timestamps
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    print('✅ Sample ride request created');
  }

  // Create sample driver verification document
  static Future<void> _createSampleDriverVerification() async {
    await _firestore.collection('driverVerifications').doc('driver_sample_456').set({
      // Driver reference
      'driverId': 'driver_sample_456',
      'driverName': 'Sarah Smith',
      'driverEmail': 'sarah.driver@example.com',
      
      // Document uploads
      'documents': {
        'drivingLicense': {
          'url': '', // Firebase Storage URL will go here
          'uploadedAt': FieldValue.serverTimestamp(),
          'verified': true,
        },
        'vehicleRegistration': {
          'url': '',
          'uploadedAt': FieldValue.serverTimestamp(),
          'verified': true,
        },
        'insurance': {
          'url': '',
          'uploadedAt': FieldValue.serverTimestamp(),
          'verified': true,
        },
        'profilePhoto': {
          'url': '',
          'uploadedAt': FieldValue.serverTimestamp(),
          'verified': true,
        },
        'vehiclePhotos': {
          'front': '',
          'back': '',
          'interior': '',
          'uploadedAt': FieldValue.serverTimestamp(),
        }
      },
      
      // Vehicle details
      'vehicleInfo': {
        'make': 'Toyota',
        'model': 'Camry',
        'year': 2020,
        'color': 'Blue',
        'plateNumber': 'NYC123',
        'vin': 'ABCD1234567890',
      },
      
      // Verification status
      'status': 'approved', // pending, approved, rejected, resubmission_required
      'overallVerified': true,
      
      // Review process
      'submittedAt': FieldValue.serverTimestamp(),
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': 'admin_user_123',
      'adminNotes': 'All documents verified successfully',
      
      // Background check (if implemented)
      'backgroundCheck': {
        'status': 'passed',
        'completedAt': FieldValue.serverTimestamp(),
      },
      
      // Timestamps
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    print('✅ Sample driver verification created');
  }

  // Create sample ride history
  static Future<void> _createSampleRideHistory() async {
    await _firestore.collection('rideHistory').doc('history_sample_001').set({
      // Ride reference
      'rideId': 'completed_ride_001',
      'riderId': 'rider_sample_123',
      'driverId': 'driver_sample_456',
      
      // Completed ride details
      'pickup': {
        'location': GeoPoint(40.7128, -74.0060),
        'address': '123 Main St, New York, NY',
      },
      'dropoff': {
        'location': GeoPoint(40.7589, -73.9851),
        'address': '456 Broadway, New York, NY',
      },
      
      // Trip summary
      'distance': '2.3 km',
      'duration': '14 mins',
      'fare': 16.25,
      'tip': 2.50,
      'totalAmount': 18.75,
      'paymentMethod': 'card',
      
      // Ratings and feedback
      'riderRating': 5,
      'driverRating': 5,
      'riderFeedback': 'Great ride, very professional driver!',
      'driverFeedback': 'Polite passenger, easy pickup and dropoff.',
      
      // Timestamps
      'completedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    print('✅ Sample ride history created');
  }

  // Create sample notification
  static Future<void> _createSampleNotification() async {
    await _firestore.collection('notifications').doc('notification_sample_001').set({
      // Target user
      'userId': 'rider_sample_123',
      'userRole': 'rider',
      
      // Notification content
      'title': 'Ride Completed!',
      'body': 'Your ride to Times Square has been completed. Rate your driver!',
      'type': 'ride_completed', // ride_accepted, ride_completed, driver_arrived, etc.
      
      // Related data
      'rideId': 'ride_sample_789',
      'driverId': 'driver_sample_456',
      
      // Status
      'isRead': false,
      'isDelivered': true,
      
      // Actions (for interactive notifications)
      'actions': {
        'primary': {
          'text': 'Rate Driver',
          'action': 'open_rating',
        },
        'secondary': {
          'text': 'View Receipt',
          'action': 'view_receipt',
        }
      },
      
      // Timestamps
      'createdAt': FieldValue.serverTimestamp(),
      'scheduledFor': null, // For scheduled notifications
    });
    print('✅ Sample notification created');
  }

  // Helper method to create a new user (call this during registration)
  static Future<void> createUser({
    required String userId,
    required String role, // 'rider' or 'driver'
    required String name,
    required String email,
    required String phone,
    String? gender,
    String? religion,
  }) async {
    await _firestore.collection('users').doc(userId).set({
      'userId': userId,
      'role': role,
      'name': name,
      'email': email,
      'phone': phone,
      'gender': gender,
      'religion': religion,
      'location': GeoPoint(0, 0), // Will be updated with actual location
      'isActive': true,
      'isVerified': false,
      'rating': 5.0,
      'totalRides': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      
      // Role-specific defaults
      if (role == 'driver') ...{
        'isOnline': false,
        'isAvailable': false,
        'verificationStatus': 'pending',
        'totalEarnings': 0.0,
      },
      
      if (role == 'rider') ...{
        'familyNetwork': [],
        'preferences': {
          'genderPreference': 'any',
          'religionPreference': 'any',
        },
      },
    });
  }
}