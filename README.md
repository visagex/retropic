# Retropic

Retropic is an iOS app built with Swift and SwiftUI that lets game developers and pixel artists quickly generate retro-style textures directly from their phone. By combining image downscaling with color filters, it streamlines the process of turning any image into something that feels right at home in a classic 8-bit or 16-bit game — no desktop tools required.

---

## Features

### Image Downscaling
Reduce image resolution to achieve the low-fidelity, blocky look characteristic of retro game sprites and textures. Downscaling is handled with pixel-accurate control to preserve the aesthetic rather than just compressing quality.

### Color Filters
Apply color filters to shift the palette of any image toward a retro feel. Filters allow users to quickly experiment with different looks without manually editing individual pixels.

---

## Tech Stack

- **Swift** — Core application logic
- **SwiftUI** — Declarative UI framework for the primary interface
- **UIKit** — Used alongside SwiftUI for components and interactions where UIKit provides greater control
- **CoreImage** — Image processing pipeline powering the filters and downscaling transformations
- **SwiftData** — Persistent storage for saving user presets and edited images

---

## Status

Core features are working. Active development is ongoing — planned features include additional filter presets and export options optimized for common game engine formats.

---

## Getting Started

1. Clone the repository
2. Open `retropic.xcodeproj` in Xcode
3. Build and run on a simulator or physical iOS device
