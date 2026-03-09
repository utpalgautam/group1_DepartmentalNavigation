# NITC Campus Navigator

A Flutter application designed to provide indoor and outdoor navigation, directory services, and offline maps for the National Institute of Technology Calicut (NITC) campus.

## Features

*   **Outdoor Navigation**: Route directions across the campus using a local GraphHopper instance.
*   **Indoor Navigation**: Detailed floor-by-floor navigation and instructions within campus buildings.
*   **Campus Directory**: Searchable directory for faculty, labs, and halls with direct navigation links.
*   **Offline Maps**: Interactive building floor plans available for offline viewing.
*   **Profile Management**: Save recent searches and customize app preferences like walking speed.

## Prerequisites

*   Flutter SDK (v3.19.0 or higher)
*   Dart SDK
*   Android Studio / Xcode for deploying to devices
*   Java Runtime Environment (for GraphHopper server)

## Getting Started

1.  **Clone the Repository**
    ```bash
    git clone https://github.com/utpalgautam/dept-nav-app.git
    cd dept_nav_app
    ```

2.  **Install Dependencies**
    ```bash
    flutter pub get
    ```

3.  **Run GraphHopper Local Server**
    The app requires a local GraphHopper routing engine instance.
    Navigate to the `graphhopper` directory and start the server:
    ```bash
    cd graphhopper
    java -jar graphhopper-web-9.1.jar server config.yml
    ```
    *Note: Ensure the `graphHopperBaseUrl` in `lib/core/constants/app_constants.dart` is updated with your machine's local IP address when testing on physical mobile devices.*

4.  **Run the Flutter App**
    ```bash
    flutter run
    ```

## Technologies Used

*   **Flutter & Dart**: Cross-platform application framework.
*   **Firebase**: Authentication and Cloud Firestore for backend data storage.
*   **GraphHopper**: Open-source routing engine for outdoor path calculation.
*   **Provider**: State management solution.
*   **Flutter Map**: For interactive outdoor map display.
