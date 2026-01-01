# Adding TransmissionRPC Package to Xcode Project

To add the local TransmissionRPC package to the Throttle 2 Xcode project:

1. Open `Throttle 2.xcworkspace` in Xcode
2. Select the `Throttle 2` project in the Project Navigator
3. Select the `Throttle 2` target
4. Go to the "General" tab
5. Scroll to "Frameworks, Libraries, and Embedded Content"
6. Click the "+" button
7. Click "Add Package Dependency..."
8. Click "Add Local..."
9. Navigate to and select the `TransmissionRPC` folder
10. Click "Add Package"
11. Ensure "TransmissionRPC" is selected and click "Add Package"

Alternatively, you can add it via the File menu:
1. File → Add Package Dependencies...
2. Click "Add Local..."
3. Select the `TransmissionRPC` folder
4. Click "Add Package"

The package should now appear under "Package Dependencies" in the project navigator.

## Verification

After adding the package, you should be able to import it in Swift files:

```swift
import TransmissionRPC
```

The build system will automatically compile the package when building the app.
