# GoWithUs - Native iOS App

## 📱 Overview

Native iOS app สำหรับ GoWithUs - แพลตฟอร์มหาเพื่อนเที่ยว พัฒนาด้วย **SwiftUI** และ **MVVM Architecture**

## ✨ Features

### ✅ Implemented
- **Authentication** - Login/Register with JWT
- **Trip Listing** - Browse, search, and filter trips
- **Trip Details** - View details, join/leave trips
- **Create Trip** - Create new trips with validation
- **Profile** - View user profile and travel style
- **Tab Navigation** - Home, Find Buddy, Profile

### 🚧 In Progress
- Edit Trip functionality
- Edit Profile functionality
- Find Buddy (AI matching)

## 🏗️ Architecture

```
GoWithUs/
├── App/
│   ├── GoWithUsApp.swift          # App entry point
│   └── ContentView.swift          # Root view with auth routing
├── Models/
│   ├── User.swift                 # User data model
│   ├── Trip.swift                 # Trip data model
│   └── Participant.swift          # Participant data model
├── Services/
│   ├── APIService.swift           # Generic API client
│   ├── KeychainService.swift      # Secure token storage
│   ├── AuthService.swift          # Authentication API
│   └── TripService.swift          # Trip CRUD API
├── ViewModels/
│   ├── AuthViewModel.swift        # Auth state management
│   ├── TripListViewModel.swift    # Trip list logic
│   └── TripDetailViewModel.swift  # Trip detail logic
└── Views/
    ├── Auth/
    │   ├── LoginView.swift
    │   └── RegisterView.swift
    ├── Home/
    │   ├── HomeView.swift
    │   └── TripCardView.swift
    ├── TripDetail/
    │   └── TripDetailView.swift
    ├── CreateTrip/
    │   └── CreateTripView.swift
    ├── Profile/
    │   └── ProfileView.swift
    └── FindBuddy/
        └── FindBuddyView.swift
```

## 🚀 Getting Started

### Prerequisites
- **Xcode 16.0+**
- **iOS 17.0+**
- **macOS Sonoma+**

### Setup Instructions

#### 1. Create Xcode Project

```bash
# Open Xcode
# File > New > Project
# Choose "iOS" > "App"
# Product Name: GoWithUs
# Organization Identifier: com.gowithus
# Interface: SwiftUI
# Language: Swift
```

#### 2. Add Source Files

1. Delete the default `ContentView.swift` and `GoWithUsApp.swift` that Xcode creates
2. Drag and drop all folders from `native-ios/GoWithUs/` into your Xcode project
3. Make sure "Copy items if needed" is checked
4. Select "Create groups" for folders

#### 3. Configure Info.plist

Replace the default `Info.plist` with the one in `Resources/Info.plist`

#### 4. Update API Base URL

In `Services/APIService.swift`, update the `baseURL`:

```swift
private let baseURL = "YOUR_BACKEND_URL/api"
// Example: "https://your-app.vercel.app/api"
// Or for local: "http://localhost:3000/api"
```

#### 5. Build and Run

1. Select a simulator (iPhone 15 recommended)
2. Press `Cmd + R` to build and run

## 🔧 Configuration

### Backend URL

Update in `APIService.swift`:
```swift
private let baseURL = "http://localhost:3000/api"  // Development
// or
private let baseURL = "https://api.gowithus.app/api"  // Production
```

### App Transport Security

The app allows HTTP connections for development. For production, update `Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
</dict>
```

## 📦 Dependencies

**None!** This app uses only native iOS frameworks:
- SwiftUI
- Foundation
- Security (for Keychain)
- Combine (for reactive programming)

## 🎨 Design System

### Colors
- **Primary**: `#6366F1` (Indigo)
- **Secondary**: `#8B5CF6` (Purple)
- **Accent**: `#EC4899` (Pink)
- **Background**: `#F9FAFB` (Light Gray)

### Typography
- **System Font** with various weights
- **Bold** for headings
- **Semibold** for buttons
- **Regular** for body text

## 🧪 Testing

### Manual Testing Checklist

- [ ] Login with valid credentials
- [ ] Register new account
- [ ] View trip list
- [ ] Search trips
- [ ] Filter by category
- [ ] View trip details
- [ ] Join a trip
- [ ] Leave a trip
- [ ] Create new trip
- [ ] Delete trip (as creator/admin)
- [ ] View profile
- [ ] Logout

### Test Accounts

Create test accounts via the Register screen or use your backend's seed data.

## 📱 Screenshots

(Add screenshots here after building the app)

## 🐛 Known Issues

- Edit trip functionality not yet implemented
- Edit profile functionality not yet implemented
- Find Buddy is placeholder only
- No offline support yet
- No image upload yet

## 🚀 Next Steps

1. **Implement Edit Trip** - Allow creators to edit their trips
2. **Implement Edit Profile** - Allow users to update their info
3. **Find Buddy Feature** - AI-powered buddy matching
4. **Image Upload** - Add trip photos
5. **Push Notifications** - Notify users of trip updates
6. **Offline Support** - Cache data with Core Data

## 📄 License

Private project - All rights reserved

## 👨‍💻 Developer

Built with ❤️ for GoWithUs
