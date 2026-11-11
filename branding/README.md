# GoWithUs brand assets

Original artwork and SwiftUI splash supplied in Downloads/SplashView. These masters preserve the supplied art.

- `Logo.png`: transparent artwork for in-app headers and authentication.
- `SplashView.swift` and `SplashAssets.xcassets`: supplied animated splash masters. Runtime copies live in both native editions; the web uses the same layers with CSS animation.
- `app-icon.png`: opaque 1024px iOS icon, aspect-fitted on white without cropping.
- `icon-192.png`, `icon-512.png`, `apple-touch-icon.png`: web icons.
- `icon-maskable-512.png`: extra padding for platform masks.

Regenerate packaged icons on macOS:

```sh
xcrun swiftc -sdk "$(xcrun --sdk macosx --show-sdk-path)" branding/scripts/export-icons.swift -o /tmp/gowithus-export-icons
/tmp/gowithus-export-icons "$PWD/branding"
```

Copy regenerated files to the corresponding native AppIcon asset sets and `web-frontend/public/brand/`. The web also keeps `public/logo.svg` as a self-contained copy for existing links.
