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
![image alt](https://github.com/Mackle10/group26-recces-/blob/2a8b9b3ac99da4113c6732f51f883ef95549684c/Screenshot%202025-07-19%20091409.jpg)
![image alt](https://github.com/Mackle10/group26-recces-/blob/c6b8319c367cd0e7f154156a4cc65317cc4b43fb/Screenshot%202025-07-19%20100009.jpg)
![image alt](https://github.com/Mackle10/group26-recces-/blob/c6b8319c367cd0e7f154156a4cc65317cc4b43fb/Screenshot%202025-07-19%20100101.jpg)
![Screenshot 2025-07-19 091610](https://github.com/user-attachments/assets/9c0ae3b6-a95c-462e-81f6-32e2f1aca8d0)
![Screenshot 2025-07-19 091705](https://github.com/user-attachments/assets/ddfbf082-8846-4353-9e59-192716e71456)
![Screenshot 2025-07-19 100009](https://github.com/user-attachments/assets/01d0e1ac-10af-474b-859d-eeb7bb6706a1)
![Screenshot 2025-07-19 100101](https://github.com/user-attachments/assets/f44dbf58-4957-4f66-84ff-90e4c0de5052)

)
![image alt]()
![image alt]()

## Future Enhancements
- AI-powered waste sorting suggestions
- Carbon footprint calculator for users
- Reward system for frequent recyclers
- Integration with municipal waste systems
- Multi-language support

## Contributing
Contributions are welcome! Please fork the repository and create a pull request with your improvements.

