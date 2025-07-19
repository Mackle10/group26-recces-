# Wellcome to Waste Management Flutter App

## Overview
A Flutter-based mobile application that revolutionizes waste collection and recycling by leveraging Google Maps API for efficient route planning and real-time coordination between households and waste management companies. The app addresses key challenges in urban waste management while promoting recycling and cashless transactions.

## Key Features

### For Households:
- 🗑️ Schedule waste pickups from your home
- 📍 Automatic location detection via GPS
- ♻️ Sort and sell recyclable materials (plastics, metals, paper)
- 💳 Mobile money payments for recyclables
- 🔔 Real-time notifications about pickup schedules

### For Waste Management Companies:
- 🗺️ Optimized route planning using Google Maps API
- 📊 Dashboard with daily pickup requests and locations
- 🔍 Search for available recyclable materials
- 💰 Payment system integration
- ⏱️ Efficient scheduling and time management

## Technical Implementation

### Core Technologies:
- **Flutter** - Cross-platform mobile development framework
- **Google Maps API** - For geolocation and route optimization
- **Firebase** - Backend services (authentication, database, cloud functions)
- **not done(Mobile Money API** - For cashless transactions)
- **not done(Location Services** - For real-time GPS tracking)

### Key Packages Used:
- `google_maps_flutter` - Interactive maps integration
- `location` - Precise geolocation services
- `http` - API communications
- `provider` or `bloc` - State management


## Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Google Maps API key
- Firebase project configuration
- Mobile money service API credentials (if applicable)

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/Mackle10/group26-recces-
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Add your Google Maps API key in `android/app/src/main/AndroidManifest.xml` and `ios/Runner/AppDelegate.swift`

4. Configure Firebase:
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) files

5. Run the app:
   ```bash
   flutter run
   ```

## Project Structure


## Screenshots
![image alt]()


## Future Enhancements
- AI-powered waste sorting suggestions
- Carbon footprint calculator for users
- Reward system for frequent recyclers
- Integration with municipal waste systems
- Multi-language support

## Contributing
Contributions are welcome! Please fork the repository and create a pull request with your improvements.

