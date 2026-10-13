# Spike: Do real Pingu videos play embedded on a real Android device?

Throwaway Flutter app for the wayfinder ticket `06-device-embed-spike`. It is not the real app; delete it once the ticket is resolved.

It plays the reference video `cPGTw1rNjrU` as three bounded Episodes using `youtube_player_iframe` + `wakelock_plus`. No video or audio is downloaded; playback is streaming only.

## Run

Requirements: Flutter (stable), Android SDK, network access to `dl.google.com` (Google Maven) for the first Gradle build.

1. On the phone: Settings → About phone → Software information → tap **Build number** 7 times; then Developer options → **USB debugging** on. Connect via USB and allow the debugging prompt.
2. In this folder:

   ```sh
   flutter pub get
   flutter devices        # the phone must be listed
   flutter run            # debug build, installs and starts the app
   ```

`flutter run` streams the app's log; every event is also printed with the prefix `SPIKE`.

## Screens

- **Start screen:** three Episode buttons (0–311 s, 311–611 s, 612 s–end) and variant switches:
  - `privacyEnhancedMode` (youtube-nocookie.com), default on
  - Show YouTube controls, default off
  - Set origin = `https://www.youtube.com` (try it if error 152/153 appears), default off
  - Own stop at end bound (off = let YouTube stop at `endSeconds` and watch what it shows next), default on
  - Wakelock during playback (off = control run for the standby test), default on
- **Player screen:** the player, a status bar (position, player state, error, wakelock), and an event log, newest first.

## Checklist: record results in the ticket

Device: Galaxy S24, Android version: ____

1. **Plays at all?** Start Episode 1 with default switches. Any error (101, 150, 152, 153/unknown)? If it errors, retry with *Set origin* on and with *privacyEnhancedMode* off.
2. **Start bound:** the "first position" log line for Episode 2 and 3 is close to 311 s and 612 s.
3. **End bound:** Episode 1 and 2 end at 311 s and 611 s ("FINISH" log line, "Fertig!" overlay). Note the overshoot in seconds.
4. **YouTube's own stop:** turn *Own stop* off and play Episode 1. What does YouTube show after 311 s (pause, related videos, end screen)?
5. **Screen stays awake:** set the phone's screen timeout to 30 s. Play an Episode for more than 1 minute without touching it; the screen must stay on. Control run: *Wakelock* off, the screen should turn off.
6. **Escape to YouTube:** tap the video title, the YouTube logo, and (with controls on) any "Watch on YouTube" link. Does the YouTube app or browser open?
7. **Episode 3:** plays to the end of the video; note what appears at the end (outro, end screen).
