# GoWithUs for iOS 26+

Open `gowithus1.xcodeproj` in Xcode, choose your signing team and device, then run.

This edition uses the iOS system TabView and navigation bars for Liquid Glass. Minimum iOS is 26.0. The compatible iOS 17+ edition remains in `../native-ios` and keeps its original navigation design.

Both editions include signed-in device management in Profile: view sessions, sign out a specific other device, and sign out all other devices. A fourth device asks which session to replace. The backend session migration must be deployed first.

The filter row keeps its full interactive glass visible at horizontal scroll edges.
