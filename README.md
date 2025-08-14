My RideShare
 A ride-sharing app inspired by Uber/Lyft, built with Flutter and Firebase. Features include:
 - Separate rider and driver apps.
 - Real-time ride matching and tracking.
 - Driver verification with license and car details.
 - Custom features: neighboring, same-religion matching, female-only matching.

 ## Setup
 1. Clone the repo: `git clone https://github.com/Girim9912/my-rideshare.git`
 2. Install Flutter: https://flutter.dev/docs/get-started/install
 3. Set up Firebase: https://console.firebase.google.com/
 4. Run `flutter pub get` in `driver_app` and `rider_app`.
 5. Deploy functions: `cd functions && firebase deploy --only functions`.

 ## Structure
 - `driver_app/`: Flutter app for drivers.
 - `rider_app/`: Flutter app for riders.
 - `functions/`: Firebase Cloud Functions for backend logic.
