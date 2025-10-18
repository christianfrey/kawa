# Kawa

<p align="center">
  <img src="./Kawa/Assets.xcassets/AppIcon.appiconset/AppIcon_256.png" width="128">
   <br>
   <strong>Status: </strong>In development<br>
   <!--br>
   <a href="https://github.com/christianfrey/kawa/releases"><strong>Download</strong></a>
    · 
   <a-- href="https://github.com/christianfrey/kawa/commits">Commits</a-->
</p>
</br>

Kawa is a small macOS menu bar app that keeps your Mac awake using system power management.

## Features

- **Prevent Sleep:** Keep the system awake for a preset duration or indefinitely.
- **Menu Bar Control:** Toggle sleep prevention from the menu bar (left-click for menu, right-click to toggle instantly).
- **Custom Durations:** Choose a default duration or set a custom time per session.
- **Clamshell Mode:** Prevent system sleep when the lid is closed (works like Amphetamine).
- **Display Sleep Option:** Allow the display to sleep while keeping the machine awake.
- **Battery Safety:** Automatically disable when battery is low; configurable threshold.
- **Launch at Login:** Option to start Kawa on login.
- **Notifications:** Optional user notifications when sessions start/stop.
- **Lightweight:** Native SwiftUI app with a small footprint.

## Configuration (Settings)

- **General**

  - Launch at login
  - Start a session automatically at launch
  - End session on manual system sleep
  - Start a session after system wake
  - Menu bar icon click behavior (left/right-click actions)

- **Duration**

  - Default session durations (e.g. 1 hour, 5 hours, indefinite)
  - Custom duration picker for a single session

- **Battery**

  - Disable sessions when battery is below a configured percentage
  - Option to always allow sessions on AC power

- **Notifications**
  - Enable/disable notifications
  - Request/manage notification permission

## Installation

1. Clone the repository:

```bash
git clone https://github.com/christianfrey/kawa.git
```

2. Open `Kawa.xcodeproj` in Xcode.
3. Build and run the app.

## License

This project is licensed under the MIT License.
