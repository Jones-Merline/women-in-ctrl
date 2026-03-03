# 🌸 Women In Ctrl  
### A Smart AI-Driven Women Safety Application

---

## 🚀 Overview

**Women In Ctrl** is a Flutter-based women safety application designed to enhance personal security through intelligent route analysis, real-time emergency detection, and smart arrival monitoring.

The application integrates mapping, CCTV density-based route scoring, sensor-triggered SOS alerts, and guardian monitoring into one unified platform.

Built to address real-world safety challenges faced by women in urban environments.

---

## 🛡 Core Features

### 🗺 1️⃣ SheShield Navigator – Smart Safe Route Detection

- Uses OpenStreetMap + OSRM routing
- Generates multiple route alternatives
- Calculates safety score based on:
  - CCTV density proximity (within 500m radius)
- Normalizes safety scores
- Highlights:
  - 🟢 Safest Route
  - 🟠 Alternative (Less Safe) Routes
- Displays:
  - Current Location
  - Destination Marker
  - CCTV markers
  - Route Safety Scores

---

### 🚨 2️⃣ SafeTrigger – Emergency Detection System

Automatically detects danger situations using:

- 📳 Shake Detection (Accelerometer)
- 🔊 Scream Detection (Noise Meter - dB threshold)

When triggered:
- Shows emergency alert dialog
- Simulates SOS activation logic
- Includes cooldown protection to avoid false triggers

---

### 🏠 3️⃣ HomeSure – Safe Arrival Monitoring

- User selects expected arrival time
- App starts journey monitoring
- On arrival time:
  - Requests confirmation
  - If confirmed → Guardian notified (simulated)
  - If no response → Alert triggered automatically

Smart logic using:
- Countdown timers
- Confirmation timeout window
- Auto-alert fallback

---

## 🧠 How Safety Scoring Works

1. App fetches multiple alternative routes
2. Each route is broken into coordinate points
3. For every point:
   - Distance to nearby CCTV locations is calculated
4. Routes with more CCTV proximity get higher scores
5. Scores are normalized between 0–1
6. Highest score = Safest route

---

## 🛠 Tech Stack

- Flutter
- Dart
- OpenStreetMap
- OSRM Routing API
- Geolocator
- Sensors Plus
- Noise Meter
- Permission Handler
- LatLong2
- HTTP Package

---

## 📱 Application Architecture

- Splash Screen
- Themed Menu Interface
- Feature-based Navigation
- Stateful Route Processing
- Real-time Sensor Monitoring
- JSON-based CCTV dataset

---

## 🔐 Permissions Used

- Location Access
- Microphone Access
- Motion Sensors

All permissions are used strictly for safety-related features.

---

## 🎯 Problem It Solves

Women often face:

- Unsafe navigation in unfamiliar areas
- Lack of real-time emergency detection
- No passive safety monitoring during travel

This app provides:

- Intelligent route awareness
- Automatic SOS triggering
- Guardian-backed safe arrival tracking

---

## 🌍 Future Enhancements

- Real SMS/Call API integration
- Live Guardian location tracking
- AI-based risk heatmap analysis
- Real-time crowd density integration
- Facial recognition-based CCTV integration (Edge AI)

---

## 👩‍💻 Developed By

Women In Ctrl Team  
Flutter-Based Women Safety Solution

---

## ⭐ Why This Project Matters

Safety should not depend on chance.  
Technology should actively protect, monitor, and respond.

Women In Ctrl transforms smartphones into intelligent safety companions.
