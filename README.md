# iOS-240-FPS-Capturing-Photos

# Ultra Slow Motion Photo Capture

This project demonstrates how to capture ultra slow-motion photo using Swift and the AVFoundation framework on an iPhone. It supports frame rates up to 240 fps, depending on the capabilities of the device.

## Features

- Capture ultra slow-motion video frames at high frame rates.
- Display camera output using `AVCaptureVideoPreviewLayer`.
- Save captured video frames as a video file in the Photos library.

## Requirements

- iOS 14.0+
- Xcode 12.0+
- Swift 5.0+
- An iPhone capable of capturing high frame rate photo (e.g., iPhone 13 Pro)

## Setup

1. **Clone the repository:**

    ```bash
    git clone https://github.com/AbdulKareemios/iOS-240-FPS-Capturing-Photos
    cd iOS-240-FPS-Capturing-Photos
    ```

2. **Open the project in Xcode:**

    ```bash
    open UltraSlowMoCapture.xcodeproj
    ```

3. **Configure Info.plist:**

    Add the following keys to `Info.plist`:

    ```xml
    <key>NSCameraUsageDescription</key>
    <string>We need access to your camera for ultra slow-motion video capture.</string>
    <key>NSPhotoLibraryAddUsageDescription</key>
    <string>We need access to your photo library to save captured Photos.</string>
    ```

4. **Build and run the project on a compatible iPhone:**

    - Connect your iPhone.
    - Select your device as the build target.
    - Click the **Run** button in Xcode.

## Usage

1. **Start capturing photo:**

    - The camera preview will be displayed on the screen.
    - Press the **Start Recording** button to begin capturing Photo frames.

2. **Stop capturing Photos:**

    - Press the **Stop Recording** button to stop capturing.
    - The captured photos will be saved to the Photos library.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgements

- [Apple Developer Documentation](https://developer.apple.com/documentation/avfoundation)

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.
